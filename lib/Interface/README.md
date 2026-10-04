# Integração com o launcher

`main.dart` chama `iniciarLauncherAnterior`, inicializando MediaKit e o launcher
original. `MyApp` mantém os provedores de `Paad`, janela e notificações; o builder
do MaterialApp envolve a navegação em `DownloadsLifecycle` para persistir e
pausar a fila quando o aplicativo fecha.

Em **Loja**, o card **Loja Interna** abre `ScrapLoja` com a transição definida em
`launcher_routes.dart`. O launcher pausa seus players enquanto essa rota está
aberta, preserva a seleção e restaura o foco e a reprodução ao voltar.

`Paad.interfaceRouter` encaminha comandos à interface aberta mais recentemente.
`LauncherPadScope` registra e remove seu handler com o ciclo de vida da tela.
As novas telas não abrem outro leitor XInput: usam os eventos normalizados do
controlador existente, incluindo Xbox e DualSense. Diálogos de teclado, imagem ampliada
e menu recebem prioridade. Telas que ficam por baixo não recebem o mesmo comando.

- Direcional / analógico: mover o foco e revelar o item na área de rolagem.
- A (`2`): acionar o botão em foco. B (`3`): voltar/fechar o diálogo.
- Start: menu flutuante; **Downloads** está disponível no menu original e nas
  telas internas. F10 oferece o mesmo acesso para teste com teclado físico.
- Busca: A no campo ou botão de teclado abre `pad_keyboard.dart`.
- Loja: abre com o primeiro jogo em foco e o topo visível. `LojaIntro` reúne
  logo original, título 10% maior, descrição e busca centralizados; em telas
  largas a busca ocupa 1/3 da largura, com adaptação para janelas pequenas.
  O cabeçalho superior mantém apenas os controles, sem título.
  Baixo na busca entra na primeira categoria; baixo nas categorias entra
  no primeiro jogo; cima na primeira linha retorna à primeira categoria. A
  categoria aplicada usa preenchimento lilás e marca de seleção; foco usa borda
  branca. As mudanças de foco também centralizam o alvo na área de rolagem,
  incluindo o retorno de trailers para galeria e compra nos detalhes.
- Teclado interno: A insere; X apaga; Y adiciona espaço; Start conclui; B cancela.
  Também oferece maiúsculas, números, acentos e uso do teclado físico.
- Trailer: A/Enter na miniatura reproduz no próprio box; repetir pausa/retoma.
  LB/RB retrocedem/avançam 10 segundos. Start pausa antes de abrir o menu.
  Selecionar outra mídia encerra e libera o player anterior.
- Detalhes: a primeira miniatura recebe foco ao carregar; esquerda/direita
  selecionam miniaturas e atualizam a imagem grande. Cima abre o foco de Comprar;
  baixo entra na descrição. Fotos e trailers compartilham a mesma faixa.
  Cima em Comprar leva à versão; baixo na versão retorna a Comprar e baixo
  em Comprar retorna à miniatura selecionada. A descrição tem destaque, texto
  selecionável e rolagem própria pelas setas; cima no início volta à mídia. A/Enter na miniatura abre a imagem ampliada; B fecha
  e restaura a seleção. Capa, nome e gêneros não recebem foco.
- Downloads: A abre as ações do cartão; esquerda/direita percorrem as ações
  habilitadas, incluindo cancelar e excluir. Na confirmação, cima acessa a opção
  de remover os arquivos, A altera/confirma e B volta ao botão Excluir.

O tema das telas internas fica em `launcher_pad_scope.dart`: fundo preto, painéis
neutros e destaque visível no foco. `LauncherHeader` mantém título à esquerda e
trava de tela, Pads conectados e fechar à direita, com `ExcludeFocus` para que
nenhum controle do cabeçalho entre na navegação pelo Pad ou teclado.
Nos detalhes, `GameIdentity`, `GaleriaJogo` e o painel da versão/compra ficam na
mesma linha em telas largas, com adaptação para janelas estreitas. `JogoMidia`
oferece a descrição focável abaixo, enquanto `GaleriaJogo` reúne fotos e trailers. `PadDirectionalGroup` compartilha a ordem
explícita de foco entre os comandos do Pad e as setas do teclado.

`DownloadsController` continua único entre todas as rotas: fechar a loja ou
voltar ao launcher não interrompe transferências. A fila é acessível pelo Start.

Validação do roteamento, teclado, retorno à loja e menu anterior:
`flutter test --no-pub test/launcher_pad_integration_test.dart`.
