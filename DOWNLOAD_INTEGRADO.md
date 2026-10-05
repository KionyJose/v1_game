# Download da loja dentro do aplicativo

## Fluxo implementado

1. Clique em Comprar consulta a etapa, mantendo o downloader injetável existente.
2. `EmbeddedTorrentDownloader` abre um painel WebView2 dentro da janela do app.
3. O formulário e JavaScript oficiais executam a preparação. Quando exigido,
   o CAPTCHA permanece visível e é resolvido pelo usuário dentro do painel.
4. O protocolo DevTools captura somente a resposta HTTP 200
   `application/x-bittorrent` do endereço de download solicitado.
5. Os bytes são salvos pelo app, limitados a 10 MB, e validados pelo parser
   existente antes de renomear para o nome seguro e registrar a compra.
6. O painel fecha e a tela apresenta o arquivo confirmado e a opção Abrir pasta.

## Organização

- `downloads/embedded_torrent_downloader.dart`: disponibilidade do Runtime,
  ambiente isolado do app, exclusividade e cancelamento.
- `downloads/torrent_download_view.dart`: painel, formulário oficial,
  captura de resposta e mensagens de progresso.
- `downloads/arquivo_torrent.dart`: validação e confirmação já existentes.
- `downloads/edge_torrent_downloader.dart`: implementação anterior preservada
  para compatibilidade dos testes existentes, sem uso no fluxo padrão da tela.

Não inicia Edge externo nem usa o perfil pessoal do usuário. O perfil WebView2
fica na pasta de suporte do app. CAPTCHA não é automatizado nem contornado.
O download continua sendo do arquivo pequeno .torrent, não do conteúdo do jogo.

## Dependências

Adicionado `flutter_inappwebview` 6.1.5, com implementação Windows WebView2.
O usuário precisa ter WebView2 Runtime instalado; a ausência produz mensagem
dentro do app. O CMake encontra NuGet no PATH ou obtém a versão 6.12.1 de
`dist.nuget.org` na pasta do build. O primeiro build requer internet para os
pacotes nativos do plugin. A validação atual está registrada abaixo.

## Validação

### Correção COM no Windows

O runner mantém o Dart/FFI em `UIThreadPolicy::RunOnSeparateThread`, enquanto
os canais nativos do WebView2 permanecem na thread de plataforma inicializada
em STA. O miniaudio incluído pelo SoLoud tenta inicializar COM em MTA e possui
uma rotina que chama `CoUninitialize` mesmo se essa tentativa falhar em uma
thread STA. Com as threads unidas, isso pode remover a inicialização de COM
necessária ao WebView2 e provocar `CO_E_NOTINITIALIZED` (`-2147221008`).

`tools/test_com_threading.cmd` reproduz essa sequência e verifica que a thread
separada preserva o apartamento STA. O erro nativo de criação do WebView2 agora
é apresentado com seu detalhe, sem ser confundido com falta de internet.
Essa alteração no runner exige fechar e executar novamente o aplicativo;
hot reload ou hot restart do Dart não atualizam a configuração nativa.

- Dependências Dart resolvidas com `flutter pub get`.
- Análise estática: `flutter analyze --no-pub` retornou `No issues found!`
  (código de saída 0), após corrigir os apontamentos de estilo.
- O site ao vivo não foi validado: a ferramenta de navegação não conseguiu
  acessar o JavaScript referenciado pelo projeto. A integração segue o fluxo
  registrado nos fontes; execução real e verificação nativa ficam com o usuário.
- Se o endpoint ou MIME do site mudar, o app não deve registrar sucesso indevido.
