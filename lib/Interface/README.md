# Integração com o launcher

## Modo Futurista 🌊

Em **Mais (+/Start) → Configurações → Interface**, selecione **Futurista**
e salve. O modo Slim tem prioridade: desative-o para usar a nova apresentação.
Jogos, Cinema, Música e Lojas usam a biblioteca e as ações do launcher existente.

### Detalhes do jogo e entrada futurista 🎮

Com um card de jogo selecionado, **Baixo** ou **A/Enter** abre os detalhes:
o card gira para baixo em 450 ms e a página entra com perspectiva suave.
As outras categorias continuam usando suas ações originais.

- `futuristic_game_details.dart`: Jogar e capa ficam à esquerda, o vídeo grande
  à direita. Os títulos Vídeos e Notícias recebem foco com escala e glow;
  baixo entra no título e depois no primeiro item. Cima retorna ao Jogar ou ao
  viewer, revelando o topo completo. O cabeçalho permanece fixo. Skeletons
  mostram a estrutura enquanto os dados chegam; a lista de vídeos tem luz
  suave na borda direita. A reproduz; R3 expande com animação, R3/B retorna;
  LB/RB controlam 10 s e LT/RT o volume. As instruções desaparecem com fade
  após 2 s sem comando. Start abre o menu/Downloads.
- `futuristic_game_feed.dart`: reutiliza WebScrap e as tags de `game_video_tags.dart`
  compartilhadas com `PrincipalCtrl.tagVideo`. Cada busca concluída alterna
  tags e prioriza IDs ainda não exibidos. Somente notícias usam cache de 5 min;
  chamadas de vídeos simultâneas compartilham a requisição em andamento.
  Se todos os resultados já foram exibidos, embaralha os disponíveis.
- `futuristic_launch.dart`: Jogar fecha os detalhes, aguarda a transição e
  revela os cards antes de apresentar o Lottie `assets/Futurista/game_controller.json`
  sobre a biblioteca desfocada, com “Iniciando seu jogo” e som original.
  Mantém o fluxo do executável, mouse, janela e reordenação da biblioteca.
  A/B/Enter retornam à seleção de jogos após confirmação do início e
  introdução mínima de 2 s. Falhas permanecem na biblioteca com aviso.
- `pad_playback_hints.dart`: faixa reutilizável de instruções com timeout e fade.
  `TrailerPlayer` mantém o Player/VideoController ao expandir ou recolher.
- `tools/generate_futuristic_launch.py`: recria a composição sem samples;
  `SonsSistema` pré-carrega o som e respeita o volume global.

Teste: `flutter test --no-pub test/futuristic_game_details_test.dart`.

Em **Configurações → FPS da UI**, escolha **30**, **60** ou **Livre** e salve.
Livre é o padrão e permite acompanhar o vsync do monitor, sem limite adicional.
A preferência é persistida no JSON e aplicada ao iniciar o launcher e ao salvar.
Pad: esquerda/direita alteram a opção e A avança; teclado: setas e Enter.
`ui_frame_binding.dart` controla os pedidos de quadros da interface por prazo
monotônico; mudanças de FPS não alteram a duração das animações. Quadros forçados
de janela/inicialização e a reprodução de vídeo preservam o comportamento nativo.
FPS efetivo continua dependendo do tempo de renderização e da GPU.

No Futurista, o cabeçalho mostra engrenagem, cadeado, controles conectados e X
nessa ordem. O cadeado usa somente o ícone: vermelho travado, verde livre.

As categorias mantêm o painel de abas original, sem reflexos.
Os cards dos jogos têm lentes de Liquid Glass individuais nas bordas, com as
capas nítidas no centro e sem painel grande atrás da lista.
`futuristic_card_mirror.dart` desenha um reflexo invertido verticalmente que se
dissipa abaixo de cada card, sem duplicar foco, semântica ou captura de refração.
O reflexo ocupa metade da altura do card. A lista vai até a borda direita e fica
mais próxima da base da janela. A faixa de vidro ao redor da capa tem 9 pixels
(4 a mais), e o selecionado tem escala 1 contra 0,8 dos outros: 25% maior.
As escalas dos cards e reflexos mudam suavemente sem alterar os slots da lista.
O brilho percorre uma faixa inclinada em 1,05 s e sai inteiramente pela direita
antes de a animação ser removida.
`futuristic_particles.dart` acrescenta 44 partículas à frente da imagem de fundo,
atrás da interface. Um único painter recebe os movimentos do carrossel e produz
uma rajada na mesma direção, com amortecimento baseado no tempo. A camada usa
`RepaintBoundary`, sem reconstruir os widgets por quadro; pausa com a tela oculta,
o aplicativo inativo ou a preferência de reduzir animações.

- Pad: esquerda/direita navegam; LB/RB mudam a categoria; cima/B levam à barra;
  baixo retorna aos cartões; A abre; Start abre o menu original.
- Teclado: setas ou WASD, Q/E ou PageUp/PageDown, Enter/Espaço, Esc e +/F10.
- `futuristic_material.dart`: paleta violeta/pérola/água e Liquid Glass com
  refração por shader, reflexos ópticos nas bordas, blur e sombras de profundidade.
  `GlassBackdrop` fornece a paisagem ao renderer Skia do Windows; Impeller é
  detectado pela capacidade de usar filtros shader. A captura usa meia resolução
  e `deviceRefreshRate`: acompanha cada quadro do monitor, inclusive 120/165 Hz.
  No Skia, uma captura compartilhada ocorre durante a pintura do próprio quadro,
  evitando a imagem atrasada e o limite anterior de aproximadamente 24 Hz.
  `body_futurista.dart`
  reúne apresentação, cartões, controles da janela no cabeçalho e ciclo da trilha.
- `launcher_more_grid.dart`: menu Mais em duas colunas, com ícones, nomes e
  altura uniforme. Esquerda/direita percorrem colunas, cima/baixo percorrem linhas,
  A confirma e B/Start fecha. A rolagem acompanha a seleção em janelas pequenas.
  O menu reutiliza uma captura estática do Futurista para refratar o cenário;
  a imagem só é liberada depois da animação de saída do diálogo.
- `pad_shortcuts_sheet.dart`: o card **Atalhos** é o único item só de leitura, e
  por isso não fecha o menu. `mostrarAtalhosDoPad` abre `assets/tutorial.png`
  por cima do Mais; B, A, Start, Esc, o clique fora ou o botão Fechar saem, e o
  foco volta ao próprio card de Atalhos, de onde a navegação continua. A folha
  consome todo comando do Pad, então nada vaza para o menu atrás dela.
  A imagem é carregada do bundle (`Image.asset`), não de um caminho em disco:
  a entrada `assets/tutorial.png` precisa continuar declarada no `pubspec.yaml`.
- Movimento: bordas e foco em 220 ms; rolagem por mola amortecida com velocidade
  preservada entre comandos e chegada exata (tolerância de 0,1 pixel);
  brilho somente após parar no cartão selecionado. Cards mantêm tamanho e
  orientação, e os ícones das categorias permanecem nas mesmas posições.
- Carrossel: cards quadrados 1:1 passam por uma moldura de destaque fixa.
  O espaço ao fim da lista permite que até o último card ocupe exatamente
  essa posição. A mola dos cards usa rigidez 100 e amortecimento 22.
- `futuristic_game_backdrop.dart`: capa do item selecionado como fundo;
  acompanha a posição real do carrossel com atraso de 90 ms e uma segunda
  mola mais lenta (rigidez 28, amortecimento 12).
  O acompanhamento usa um ticker contínuo, preservando velocidade quando o alvo
  muda a cada quadro, sem reiniciar a desaceleração durante a rolagem.
  As imagens se mesclam por 1,3 s, em no máximo duas camadas, mantendo a mesma
  direção do deslocamento.
  Sem capa, permanece a paisagem de lago e aurora. Reduzir animações elimina
  o atraso e o movimento.
- `futuristic_view_box.dart`: transição de páginas, com vidro opcional. Na lista
  de jogos usa `glass: false`, deixando o fundo visível entre os cards.
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

## Ordem de abertura de um jogo 🎬

Vale para todos os modos — Grid, Moderno, Retro, Slim, Transversal e
Futurista — porque todos passam por `PrincipalCtrl.btnEntrar`.

1. **Clique.** `_entrandoNoJogo`, `gameIniciado` e `stateTela` mudam **antes do
   primeiro `await`**. A partir daí `mouseBloqueado` é verdadeiro e nenhum
   outro clique entra.
2. **Animação.** A folha "Entrando no game..." aparece imediatamente, antes de
   qualquer trabalho de bastidor.
3. **Preparação.** Mouse, fixação da janela, reposicionamento do ícone e foco
   acontecem *dentro* da espera, não depois dela.
4. **Dois segundos** (`esperaAntesDoJogo`), descontando o que a preparação já
   consumiu: o jogo sobe sempre 2 s depois de a animação aparecer.
5. **`db.openFile`.** Só agora o jogo abre.
6. **Espera do jogador.** A folha **não** se fecha sozinha: ela fica na tela
   enquanto o jogo está na frente e só sai com A ou B, com mínimo de 2 s.
   **Quem decide a volta ao launcher é o jogador**, pelas ações que já existem.
7. **Liberação.** Só depois dessa ação `_liberarSistema()` devolve mouse,
   janela e foco, espera `resfriamentoDoClique` (600 ms) e reabre os eventos.
   Roda **uma vez por abertura**.

**A ordem era inversa.** `db.openFile` vinha primeiro, e só ~650 ms depois a
animação aparecia — por isso ela parecia atrasada: o jogo já estava subindo.
Pior, as guardas só eram marcadas *depois* desse `await`, e ele é longo:
`openFile` consulta `Win32_Process` pelo PowerShell **duas vezes** (~370 ms
cada, medido) e ainda espera 700 ms por dentro. Durante esses segundos
`mouseBloqueado` continuava falso e cada clique extra abria outra cópia do
jogo. No Transversal era pior, porque `_openGame` chama `btnEntrar` direto do
`onTap` do cartão, sem passar por `abrirItemSlim`.

**Duas regressões que esta ordem já causou**, e que os testes agora travam:

- *A folha fechando sozinha.* Uma versão intermediária avisava a folha quando
  o jogo subia, e ela saía junto. Isso restaurava o launcher sem o jogador
  pedir, tirando dele o ponto de retorno. A espera é dele, sempre.
- *A troca de interface atropelada.* Essa mesma versão chamava
  `_liberarSistema()` duas vezes, a segunda 600 ms depois de tudo pronto.
  Nessa janela ela reescrevia `focusScope`, `cardInf` e `stateTela` por cima
  de um `aplicarModoInterface` em andamento — cuja segunda callback, aliás,
  aborta quando `stateTela` é falso. Agora a restauração é única e respeita
  `interfaceChanging`: durante uma troca de modo, quem manda no foco é ela.

A folha de carga não usa `transitionAnimationController` próprio: o anterior
nascia com `vsync: Navigator.of(ctx)` e nunca era descartado, deixando um
Ticker vivo por abertura. Descartá-lo ao fim também não resolve — ele conduz a
animação de saída, e liberá-lo cedo deixa a folha congelada na tela.

Testes: `flutter test test/ordem_abertura_jogo_test.dart` cobre a ordem, os
dois segundos, rajada de cliques, liberação ao fim, segundo jogo em seguida e
falha de abertura.
