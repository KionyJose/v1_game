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
