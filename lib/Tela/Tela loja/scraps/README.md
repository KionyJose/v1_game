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
adaptador e inicia o download com `EdgeTorrentDownloader`. O texto da tela
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
**Comprar**, o app abre uma janela Edge dedicada e dispara o formulário oficial,
incluindo o JavaScript de verificação do próprio site. Se aparecer hCaptcha,
o usuário conclui a verificação e clica em continuar nessa janela.

## Pasta e monitoramento do download (Windows)

`downloads/torrent_download.dart` define o contrato de download.
`downloads/edge_torrent_downloader.dart` implementa o fluxo usando o Microsoft
Edge instalado. O perfil temporário é exclusivo da operação, com uma porta
local dinâmica; a sessão pessoal do usuário não é alterada. Não requer novas
dependências. O suporte atual é Windows com Edge instalado.

`path_provider.getDownloadsDirectory` localiza a pasta Downloads configurada
no Windows, inclusive quando foi redirecionada. O app cria **games torrent compra**
dentro dela e configura o navegador para baixar diretamente nessa pasta.
`Browser.setDownloadBehavior` com `allowAndName` salva primeiro com o GUID do
download; os eventos `Browser.downloadWillBegin`/`Browser.downloadProgress`
identificam e monitoram somente o arquivo solicitado. Downloads inesperados são
cancelados. Não há varredura nem movimentação de outros arquivos de Downloads.

`downloads/arquivo_torrent.dart` só confirma após o evento `completed`, arquivo
presente e parsing válido pelo dtorrent_parser. Em seguida renomeia para o nome
original seguro. Se esse nome já existir, acrescenta `(1)`, `(2)` etc., preservando
os arquivos anteriores. `.crdownload`, HTML e arquivo inexistente não indicam
sucesso. A tela mostra progresso, permite cancelar e exibe o caminho confirmado
com **Abrir pasta**. A janela exclusiva fecha ao terminar/cancelar; a espera tem
limite de 10 minutos. O download é do pequeno arquivo .torrent, sem iniciar o
download do conteúdo completo do jogo.

Testes de integração simulam os eventos reais do protocolo e a gravação no disco
em `test/torrent_download_test.dart`; não comprovam liberação pelo site ao vivo.
A sessão de desenvolvimento não disponibilizou navegador conectado para validar
o download real. Se o site bloquear Edge ou exigir CAPTCHA, a tela deve apresentar
a falha ou aguardar interação humana, sem registrar download concluído.

Referência do protocolo: https://learn.microsoft.com/en-us/microsoft-edge/devtools/protocol/

Fontes inspecionadas:
- https://www.gamestorrents.app/pt-br/jogos-pc/little-nightmares-iii-1/
- https://www.gamestorrents.app/pt-br/download/750e3a42a06f9eeb1ca7cdf80a8b9a12/
- https://www.gamestorrents.app/assets/download.bb733f93e1508c67.js

Fixtures reais: `gamestorrents_detalhes.html` e `gamestorrents_download.html`
em `test/fixtures`. Testes: `jogo_detalhes_scraper_test.dart` e
`detalhes_jogo_tela_test.dart`, além dos testes anteriores do catálogo.
