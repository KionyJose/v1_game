# Integração com o launcher

## Modo Futurista 🌊

Em **Mais (+/Start) → Configurações → Interface**, selecione **Futurista**
e salve. O modo Slim tem prioridade: desative-o para usar a nova apresentação.
Jogos, Cinema, Música e Lojas usam a biblioteca e as ações do launcher existente.

- Pad: esquerda/direita navegam; LB/RB mudam a categoria; cima/B levam à barra;
  baixo retorna aos cartões; A abre; Start abre o menu original.
- Teclado: setas ou WASD, Q/E ou PageUp/PageDown, Enter/Espaço, Esc e +/F10.
- `futuristic_material.dart`: paleta violeta/pérola/água e Liquid Glass com
  refração por shader, reflexos ópticos nas bordas, blur e sombras de profundidade.
  `GlassBackdrop` fornece a paisagem ao renderer Skia do Windows; Impeller é
  detectado pela capacidade de usar filtros shader. A captura usa meia resolução
  e 24 Hz, separadamente das animações da interface, para reduzir o custo.
  `body_futurista.dart`
  reúne apresentação, cartões, controles da janela no cabeçalho e ciclo da trilha.
- `launcher_more_grid.dart`: menu Mais em duas colunas, com ícones, nomes e
  altura uniforme. Esquerda/direita percorrem colunas, cima/baixo percorrem linhas,
  A confirma e B/Start fecha. A rolagem acompanha a seleção em janelas pequenas.
  O menu reutiliza uma captura estática do Futurista para refratar o cenário;
  a imagem só é liberada depois da animação de saída do diálogo.
- Movimento: bordas e foco em 220 ms; rolagem por mola amortecida com velocidade
  preservada entre comandos e chegada exata (tolerância de 0,1 pixel);
  brilho somente após parar no cartão selecionado. Cards mantêm tamanho e
  orientação, e os ícones das categorias permanecem nas mesmas posições.
- Carrossel: cards quadrados 1:1 passam por uma moldura de destaque fixa.
  O espaço ao fim da lista permite que até o último card ocupe exatamente
  essa posição. A mola dos cards usa rigidez 100 e amortecimento 22.
- `futuristic_game_backdrop.dart`: capa do item selecionado como fundo;
  acompanha a posição real do carrossel com atraso de 90 ms e uma segunda
  mola mais lenta (rigidez 28, amortecimento 12). As imagens se mesclam por
  1,3 s, em no máximo duas camadas, mantendo a mesma direção do deslocamento.
  Sem capa, permanece a paisagem de lago e aurora. Reduzir animações elimina
  o atraso e o movimento.
- `futuristic_view_box.dart`: painel Liquid Glass com o mesmo material das abas
  e controles do cabeçalho, incluindo blur, refração e reflexos ópticos.
  Troca de abas recortada, com entrada
  desacelerada em 580 ms e parallax da página anterior usando uma imagem estática.
  Há apenas uma árvore de foco ativa; inversões rápidas descartam a imagem anterior.
- `futuristic_landscape.dart`: paisagem própria de lago e aurora em
  `assets/Futurista/aurora_lake.png`, com deriva lenta de 36 s e parallax por aba.
  `Oxanium.ttf` fornece títulos e rótulos gamer offline, com licença em
  `OFL-Oxanium.txt`. A preferência de reduzir animações é respeitada.
- Os controles antigos de janela pertencem agora ao scaffold do modo original
  ou Slim. `Begin` não os sobrepõe ao cabeçalho próprio do Futurista.
- Sons originais em `assets/Sons/Futurista`: navegação suave, confirmação e
  trilha de console com acordes suspensos, sinos e ambiência discreta.
  Respeitam o volume global; zero silencia tudo.
  A trilha pausa ao perder foco, abrir menus/outras telas ou iniciar um jogo,
  e libera seu canal ao sair do modo. Não contém gravações da Sony/Apple.
- `tools/generate_futuristic_audio.py` recria os WAVs sem bibliotecas externas.
  Para manutenção visual, `GENERATE_FUTURISTIC_PREVIEW=1` no teste
  `futuristic_home_test.dart` gera `build/futuristic-preview.png` no Windows.
  A faixa de instruções foi removida; o menu continua acessível por Start/+,
  F10 e pelo ícone no cabeçalho. Na troca de modo, a árvore de foco anterior
  é desmontada antes de montar a nova, e callbacks antigos são invalidados.
  Animações usam o vsync da tela; FPS real depende de GPU, resolução e monitor.

Referências: [materiais da Apple](https://developer.apple.com/design/human-interface-guidelines/materials)
e [interface PS5](https://www.playstation.com/en-us/ps5/ps5-features/).
Implementação do vidro: [liquid_glass_easy](https://pub.dev/packages/liquid_glass_easy)
e [shaders no Flutter](https://docs.flutter.dev/ui/design/graphics/fragment-shaders).

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
