# Scrapers do catálogo

`CatalogoScraper` é o contrato para novas fontes. Ele retorna `PaginaCatalogo`
com jogos normalizados (`JogoCatalogo`), próxima página e filtros de gênero.
Implemente outra fonte e injete em `ScrapLoja(scraper: MinhaFonte())`.

`GamesTorrentsScraper` concentra URL, requisições e interpretação do HTML.
Atualize `GamesTorrentsSeletores` e `interpretar` quando o site mudar.
O nome exclui textos auxiliares de acessibilidade e a capa prioriza a imagem
original. URLs relativas são resolvidas usando a página de origem.

`CatalogoController` gerencia carregamento, deduplicação, filtros, erros e
novas tentativas; os widgets ficam fora desta pasta. A busca na tela cobre
os jogos já carregados. O botão de paginação permite percorrer todo o catálogo
sem baixar milhares de registros na abertura. Não há persistência offline.

`catalogoPorGenero` pertence à fonte, não à tela: o nome do parâmetro é do site
(`genre` na GamesTorrents, `tags` na Steam) e o endereço base pode ter campos
obrigatórios. A tela montava esse endereço com `catalogo.replace(queryParameters:
{})`, o que apagava a query inteira da fonte.

## Diagnóstico de falhas

`diagnostico_catalogo.dart` existe por um motivo específico: **na máquina do
cliente o catálogo não carregava e a tela dizia só "Verifique sua conexão"**.
Essa frase cobria causas que pedem ações opostas — provedor bloqueando o
domínio no DNS, Cloudflare recusando o IP, antivírus cortando o HTTPS, site
fora do ar, mudança de layout — e não dava nada para relatar.

`FalhaCatalogo` separa cada uma. `DiagnosticoCatalogo` carrega a frase que o
cliente lê, um código curto (`LOJA-DNSBLOQUEADO`, `LOJA-ACESSORECUSADO`…) que
ele consegue ditar, e o detalhe técnico. `DiagnosticoCatalogo.de` desembrulha o
`ClientException` do pacote http antes de olhar o tipo, porque ele engole o
`SocketException` e perde a causa.

Quem classifica é a fonte: `carregar` embrulha a chamada de rede, o status e o
decode, e lança `ErroCatalogo.diagnosticado`. Erro que escapar do contrato
ainda recebe código no `CatalogoController`, para nenhum caminho ficar mudo.

O que o cliente vê é o `ErroCatalogoPainel` (em `../componentes/`): a causa
provável, o código, **Detalhes técnicos** recolhido e **Copiar detalhes**.

Tudo é gravado em `%LOCALAPPDATA%\V1 Launcher\loja-erros.log`, truncado em
256 KB — um log que cresce sem limite é um log que ninguém consegue enviar.
Gravar é melhor-esforço: disco cheio não apaga a mensagem da tela.

## Contorno automático do bloqueio de DNS

O caso real do cliente foi `LOJA-DNSBLOQUEADO`: o provedor devolve "host não
encontrado" para o domínio da loja, embora o site esteja no ar e alcançável.
**O cliente não configura nada** — `cliente_loja.dart` resolve sozinho.

`ClienteDaLoja` tenta o caminho normal primeiro, que é mais rápido e reaproveita
conexão. Só quando a falha é de DNS (`Failed host lookup`, `errorCode 11001`)
ele troca para `ClienteDireto`, e **lembra a troca** pelo resto da sessão: a
primeira página paga a falha, as seguintes vão direto. Qualquer outra falha de
rede sobe como antes, sem virar contorno.

`ResolvedorDoH` pergunta o endereço por HTTPS à Cloudflare e, se ela não
responder, ao Google — o mesmo que todo navegador moderno faz. As respostas
ficam 10 minutos em cache, e um cache vencido ainda é usado se os dois
resolvedores caírem.

**Por que não `HttpClient.connectionFactory`.** A fábrica precisa devolver um
socket **já seguro**, e as formas públicas de criar um
`ConnectionTask<SecureSocket>` usam o mesmo argumento para conectar e para o
SNI. Medido: devolvendo um `Socket` cru, a Cloudflare responde *"400 The plain
HTTP request was sent to HTTPS port"* — o dart:io não faz o TLS. Apontando
`SecureSocket.startConnect` para o IP, o handshake morre em
`HANDSHAKE_FAILURE_ON_CLIENT_HELLO`, porque o certificado é de
`gamestorrents.app`. Só `SecureSocket.secure(socket, host: ...)` aceita o SNI
separado do endereço, e é por isso que `ClienteDireto` monta a requisição
HTTP/1.1 por cima do socket em vez de usar `HttpClient`.

Ele manda `Accept-Encoding: identity` e `Connection: close` para o corpo
terminar no EOF, mas **desfaz `Transfer-Encoding: chunked`** mesmo assim: a
Cloudflare usa chunked de qualquer forma, e sem desfazer os marcadores de
tamanho entram no meio do HTML e corrompem o conteúdo em pontos espalhados —
um estrago silencioso, que o parser de HTML engole sem reclamar.

As capas moram no mesmo domínio e o `CachedNetworkImage` tem pilha HTTP
própria, que usa o DNS do sistema. `CacheDaLoja` dá a ele um `HttpFileService`
com o mesmo cliente; sem isso o catálogo abria pelo contorno e todos os
cartões ficavam sem arte.

### O Comprar também passa

O WebView2 resolve DNS pelo Windows e não usa o `ClienteDaLoja`: com o
provedor bloqueando o domínio, o catálogo abria e o **Comprar** morria em
`HOST_NAME_NOT_RESOLVED`. `EmbeddedTorrentDownloader._regraDeResolucao`
resolve o host por DoH e passa ao ambiente do WebView2 o argumento do Chromium
`--host-resolver-rules="MAP <host> <ip>"`. Essa regra troca **só a resolução**:
`Host` e SNI continuam com o nome original, então o certificado segue válido.

A regra só entra quando `ClienteDaLoja.contornoAtivo` já está ligado — ou seja,
quando o DNS do provedor falhou de verdade. Com DNS saudável o WebView2 segue
normal, e qualquer falha do resolvedor devolve nulo: é melhor tentar e ver o
erro do site do que recusar a compra por causa de um resolvedor fora do ar.

Só o domínio da loja é mapeado. O hCaptcha e os demais recursos resolvem pelo
caminho normal, que não está bloqueado.

**O ambiente é um só, e vive enquanto o aplicativo viver.** O processo do
navegador do WebView2 é compartilhado e não morre junto com a janela: criar
outro ambiente enquanto ele respira falha com `ERROR_INVALID_STATE` — *"o grupo
ou recurso não está no estado correto"*. A versão anterior criava e descartava
um ambiente por compra, então a segunda compra da sessão sempre quebrava.

O argumento também precisa ser **determinístico**, e aqui estava o outro lado
do mesmo defeito: `_regraDeResolucao` criava um `ResolvedorDoH` novo a cada
compra, o cache nascia vazio e a Cloudflare devolve os dois endereços em ordem
alternada. O IP escolhido mudava, o argumento mudava junto e o ambiente novo
batia de frente com o processo antigo. Agora o resolvedor é único e
`mapeamentoDeHost` ordena os endereços antes de escolher, então o mesmo
conjunto sempre gera o mesmo texto (`test/webview_mapeamento_test.dart`).

Se `ERROR_INVALID_STATE` aparecer mesmo assim, o ambiente guardado é solto e a
mensagem avisa para tentar de novo — a tentativa seguinte cria um limpo.

### Erros do Comprar

As três etapas da compra falavam línguas diferentes. Agora todas usam
`DiagnosticoCatalogo`:

- **consulta da etapa** (`gamestorrents_download_scraper.dart`): classifica
  rede, status e estrutura, como o catálogo — e manda o mesmo User-Agent de
  navegador, que faltava ali e rendia 403 do Cloudflare.
- **WebView2** (`torrent_download_view.dart`): `_explicar` traduz
  `WebResourceErrorType` — `HOST_LOOKUP`, `TIMEOUT`, `CANNOT_CONNECT_TO_HOST` —
  em causa, código e detalhe, no lugar de "Verifique sua conexão".
- **painel da compra** (`detalhes_jogo_tela.dart`): o erro deixou de ser uma
  linha vermelha solta; vem com código e **Copiar detalhes**, e a falha ao
  carregar a própria ficha agora usa o mesmo `ErroCatalogoPainel` do catálogo.
- **captura do arquivo** (`_response`): o tipo e a mensagem do erro eram
  jogados fora, e torrent inválido, pasta sem permissão ou DevTools fora de
  hora chegavam ao cliente como a mesma frase. Agora saem com
  `LOJA-DESCONHECIDA` e o `runtimeType` junto. Cancelamento continua sendo
  cancelamento, sem virar relatório.

Códigos próprios desta etapa: `LOJA-WEBVIEW` (criação do ambiente),
`LOJA-WEBVIEW-ESTADO` (processo anterior preso), `LOJA-WEBVIEW-DEVTOOLS`
(canal de captura) e `LOJA-WEBVIEW-TEMPO` (10 minutos sem conclusão).

Tudo cai no mesmo `loja-erros.log`.

Sondas ao vivo: `test/contorno_dns_live_test.dart` simula o DNS bloqueado do
cliente e confere catálogo, ficha, capa e paginação pelo contorno.
Testes offline: `test/cliente_loja_test.dart` e `test/erro_compra_test.dart`.

**Para apurar um caso:** peça o print com o código, ou o arquivo de log.
`LOJA-DNSBLOQUEADO` agora só aparece quando **o contorno automático também
falhou** — a rede bloqueia o site de forma mais ampla que o DNS, e por isso a
mensagem não manda mais trocar o DNS da máquina. `LOJA-ACESSORECUSADO`
continua sendo a Cloudflare recusando o IP (VPN ou rede compartilhada).

Testes: `test/diagnostico_catalogo_test.dart` (classificação e controller) e
`test/erro_catalogo_painel_test.dart` (o que aparece na tela e o que é copiado).

## Steam

`steam_scraper.dart` alimenta a tela **Descobrir** ([`../../Descobrir/`](../../Descobrir/README.md)),
não a Loja Interna. Usa dois endereços públicos, nenhum deles HTML de página
inteira:

- catálogo: `/search/results/` com `infinite=1`, que devolve JSON com o
  fragmento `results_html`; a paginação anda pelo `start` e o fim vem de
  `total_count`. `cc=br` e `l=portuguese` fixam real e português — sem eles a
  Steam decide pelo IP e o mesmo jogo aparece com moedas diferentes.
- ficha: `/api/appdetails?appids=<id>`, com descrição, gêneros, capturas e preço.

A linha de busca não traz gênero, então `JogoCatalogo.generos` recebe lançamento
e preço, que é o que o cartão mostra como legenda. A ficha é endereçada por
`/app/<appid>/`, montada do `data-ds-appid` em vez do `href`, que vem com
rastreamento `?snr=`.

Os filtros de `generosSteam` são **ids de tag**: a busca aceita `tags=19` e
ignora `genre=Ação`.

Os vídeos da Steam são mp4 próprios, não ids do YouTube. `TrailerPlayer` só toca
YouTube, então `trailers` vem vazio e a galeria mostra apenas as capturas.

Fixtures com JSON real: `steam_busca.json` e `steam_appdetails.json`.
Teste: `flutter test test/steam_scraper_test.dart`.

## Sonda ao vivo

`test/loja_live_probe_test.dart` roda os scrapers reais contra os dois sites e
imprime catálogo, filtro, ficha — e, quando falha, o relatório de diagnóstico
já classificado. É o atalho para reproduzir o problema **na máquina do
cliente** sem abrir o aplicativo:

```powershell
$env:RUN_LOJA_LIVE_PROBE = '1'
flutter test --no-pub --reporter expanded test/loja_live_probe_test.dart
```

Os testes usam HTML real em `test/fixtures/gamestorrents_catalogo.html`:
`flutter test test/catalogo_scraper_test.dart`.
Atualize a fixture ao revisar uma mudança de estrutura do site.

O card agora abre `DetalhesJogoTela` dentro do app. O cliente HTTP deve ser
descartado junto com a tela/controller. Em Flutter Web, acesso direto depende do CORS do site;
se necessário, mantenha este adaptador em um backend autorizado.

## Detalhes, galeria e trailers

`jogo_detalhes.dart` contém os contratos `DetalhesScraper`/`DownloadScraper`
e os modelos de imagens, trailers, versões e etapa de download.
`gamestorrents_detalhes_scraper.dart` concentra os seletores da página de jogo.
Usa somente a galeria principal para evitar duplicar miniaturas e extrai os
IDs de trailers cadastrados, sem pesquisar vídeos por nome.

`GaleriaJogo` oferece paginação, miniaturas e ampliação com zoom.
`TrailerPlayer` usa as dependências existentes media_kit e youtube_explode_dart,
com inicialização de MediaKit em main.dart. Reproduz ao clicar, descarta o player
ao fechar e oferece YouTube como alternativa se não houver stream compatível
ou o serviço bloquear a reprodução. Reprodução ao vivo depende do YouTube.

## Resposta do clique em torrent

`gamestorrents_download_scraper.dart` é o segundo adaptador: consulta por GET
a URL do botão **Baixar torrent** da versão escolhida e interpreta a resposta
HTML do formulário (`data-download-config`). O botão **Comprar** usa esse
adaptador e inicia o download com `EmbeddedTorrentDownloader`. O texto da tela
esclarece que não há pagamento; o site não fornece checkout nesse fluxo.

Na página Little Nightmares III examinada em 03/10/2026, o catálogo apresentava
3 imagens, 3 trailers e 2 versões. O clique na primeira versão entregou uma
página de download, não bytes do torrent. A página informou o nome
`Little Nightmares III [FitGirl Repack].torrent` e tamanho de `53,5 KiB`.

O JavaScript público `/assets/download.bb733f93e1508c67.js` mostra o fluxo:

1. O navegador envia POST `action=prepare` ao endereço da página de download.
2. A resposta contém challenge/difficulty e indica se hCaptcha é necessário.
3. O script do site faz a verificação e, quando solicitado, o usuário resolve hCaptcha.
4. POST `action=download` envia os dados da verificação. Para torrent, o script
   espera `Content-Type: application/x-bittorrent`, valida tamanho/conteúdo e salva
   o arquivo no navegador.
5. O arquivo salvo deve ser aberto em um cliente torrent para baixar o conteúdo.

Não existe URL estática de `.torrent` no HTML inspecionado. Ao clicar em
**Comprar**, o app abre um painel WebView2 dentro da própria janela e dispara
o formulário oficial. O JavaScript do site executa suas verificações; quando
aparece hCaptcha, o usuário conclui a etapa dentro do painel.

## Download integrado (Windows)

`downloads/torrent_download.dart` preserva o contrato injetável.
`downloads/embedded_torrent_downloader.dart` gerencia WebView2 e cancelamento.
`downloads/torrent_download_view.dart` mostra o site e intercepta a resposta
liberada usando Fetch do protocolo DevTools, apenas para o endereço solicitado
e MIME `application/x-bittorrent`. Não abre o Edge externo.

Os bytes são limitados a 10 MB, salvos em
**Downloads/games torrent compra** e validados por `ArquivoTorrent.confirmar`.
O parser existente rejeita HTML e arquivos inválidos. Nomes são sanitizados e
arquivos anteriores preservados. Após confirmação, a tela registra a compra na
fila e apresenta o caminho salvo com **Abrir pasta**.

O perfil do WebView2 é próprio do app, dentro da pasta de suporte.
Requer WebView2 Runtime instalado. A espera pela liberação tem limite de
10 minutos; operações DevTools têm limite de 25 segundos. Cancelamento
durante recebimento aguarda a operação atual terminar antes de limpar o parcial.

A implementação antiga `EdgeTorrentDownloader` permanece para compatibilidade
dos testes existentes, mas não é o downloader padrão. Os testes antigos não
comprovam este novo fluxo WebView2 nem a liberação do site ao vivo.
Não foram executados aplicativo, build ou testes nesta alteração.

Detalhes de dependências e limitações: [DOWNLOAD_INTEGRADO.md](../../../../DOWNLOAD_INTEGRADO.md).
Referência do plugin: https://inappwebview.dev/docs/webview/in-app-webview/
Referência do protocolo: https://chromedevtools.github.io/devtools-protocol/tot/Fetch/

Fontes inspecionadas:
- https://www.gamestorrents.app/pt-br/jogos-pc/little-nightmares-iii-1/
- https://www.gamestorrents.app/pt-br/download/750e3a42a06f9eeb1ca7cdf80a8b9a12/
- https://www.gamestorrents.app/assets/download.bb733f93e1508c67.js

Fixtures reais: `gamestorrents_detalhes.html` e `gamestorrents_download.html`
em `test/fixtures`. Testes: `jogo_detalhes_scraper_test.dart` e
`detalhes_jogo_tela_test.dart`, além dos testes anteriores do catálogo.
