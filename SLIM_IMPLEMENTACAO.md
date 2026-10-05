# Modo Slim integrado

## Objetivo

Ativar o Slim ao salvar o Config, dentro do mesmo aplicativo. Usar uma faixa
transparente fixa na parte inferior do monitor, com ícones flutuantes para
Jogos, Cinema, Música e Loja. Start oferece
somente `Voltar ao modo Fat`; B/Esc fecha o menu sem mudar o modo.

## Organização

- `lib/Controllers/slim_mode_config_controller.dart`: persistência e estado do modo.
- `lib/Controllers/launcher_window_controller.dart`: posição inferior, percentual
  de altura, transparência nativa e retorno à janela normal.
- `lib/Tela/Tela Principal/PrincipalCtrl.dart`: seleção, abertura e troca de modo.
- `lib/Tela/Tela Principal/Widgets/BodySlim.dart`: apresentação exclusiva do Slim.
- `lib/Interface/launcher_menu.dart`: menu Start compartilhado, respeitando o modo.
- `lib/Widgets/Pops/pop_config.dart`: salvar e aplicar sem abrir outro executável.

Reutilizar biblioteca, catálogos, foco, controle e rotinas de abertura existentes.
Preservar o estilo configurado do Fat. Não carregar vídeos/notícias de jogos nem
animar continuamente o fundo enquanto o Slim estiver ativo.

## Etapas

- [x] Integrar persistência e carregar o modo na inicialização.
- [x] Aplicar a troca ao salvar, sem reinicializar players/controlador.
- [x] Criar apresentação horizontal única e navegação por categoria.
- [x] Restringir Start e atalhos de edição no Slim.
- [x] Restaurar Fat e suas preferências ao sair do Slim.
- [x] Atualizar este documento com a entrega e limitações.

## Controles previstos

- Esquerda/direita: selecionar ícones; na barra superior, selecionar categorias.
- Cima/B/Esc: voltar à barra de categorias.
- Baixo/A/Enter na categoria: entrar na lista.
- LB/RB: categoria anterior/seguinte.
- A/Enter no item: abrir jogo, canal de mídia ou loja.
- Start/F10/+ : menu com a única ação `Voltar ao modo Fat`.
- Select e atalhos de alteração de cards: sem ação no Slim.

## Referência e validação

`C:\_Flutter\Game Interfacie\v1_slim` contém apenas o aplicativo compilado.
O layout é uma faixa transparente inferior de ícones, com categorias e título
compactos. A correspondência visual exata com o
executável depende do feedback visual do usuário.

O usuário autorizou posteriormente executar `flutter analyze` e corrigir os
problemas encontrados antes da entrega. Não executar aplicativo, testes ou
build. A execução e a validação visual serão feitas pelo usuário.

## Entrega

- O arquivo público `v1_game_slim.txt` continua compatível (`ativo == 1/0`).
  Quando não existe, a inicialização permanece no Fat, sem criar configuração
  durante uma simples leitura. O Config salva a escolha explicitamente.
- Não há mais abertura de `v1_slim.exe` nem encerramento do aplicativo ao salvar.
  Removido também o desvio nativo em `windows/runner/main.cpp`, que ainda podia
  abrir o executável externo antes da inicialização do Flutter.
- O Slim usa listas construídas sob demanda e imagens com tamanho de decodificação
  limitado. A rolagem horizontal tem um único responsável, sem animação contínua.
- O estilo salvo do Fat não é substituído pelo layout Slim.
- A barra de janela é compartilhada pelos modos; no Slim fica no canto inferior
  direito com fundo preto, switch de travar/liberar, gamepads e fechar.
- Menus Start compartilhados das telas internas respeitam o Slim. Diálogos de
  confirmação e controles de reprodução mantêm os comandos próprios da tarefa.
- Teclado também aceita WASD, Q/E e PageUp/PageDown para navegação.
- Nenhum teste, build ou execução do aplicativo foi realizado pelo agente.

## Análise estática

- Primeira execução de `flutter analyze --no-pub`: cinco erros no mapa constante
  de teclas e sete apontamentos de estilo.
- Mapa alterado para `static final`, reutilizado entre eventos do teclado.
- Ajustadas as chaves nos fluxos condicionais e os construtores constantes.
  O nome `BodySlim.dart` mantém a convenção dos widgets da pasta.
- Segunda execução de `flutter analyze --no-pub`: `No issues found!`, código de
  saída 0. Sem erros, avisos ou apontamentos de estilo na análise do projeto.

## Feedback pendente do usuário

Após sua execução, registrar aqui ajustes de visual, foco e comportamento.
Para comparar exatamente com o exemplo compilado, usar uma referência visual
fornecida pelo usuário. O layout entregue é a primeira implementação dos
comportamentos descritos, sem alegação de equivalência visual exata.

## Ajuste imersivo

- A faixa usa 100% da largura e 25,5% da altura útil do monitor atual, acima da
  barra de tarefas. O percentual está centralizado em
  `LauncherWindowController.slimHeightFraction` (0.30 × 0.85), aguardando feedback.
- A janela usa composição transparente do `window_manager`, sem moldura,
  sombra nativa, wallpaper ou preenchimento por trás dos cards. Scaffolds
  externos também foram tornados transparentes.
- Ícones têm foco por escala e textos com sombra para leitura sobre o desktop.
- Retorno de foco respeita a faixa, em vez de maximizar. A fixação acima de outras
  janelas é suspensa durante a abertura de jogos/mídias pelas rotinas existentes.
- Mudanças de monitor/resolução reajustam a faixa; a posição é reaplicada apenas
  quando diverge, com tolerância ao arredondamento de DPI.
- Telas internas se expandem temporariamente para conteúdo e retornam à faixa
  ao sair. Start continua respeitando o modo Slim.
- `screen_retriever` já existia como dependência transitiva; foi declarado
  explicitamente, sem alterar sua versão, com `flutter pub get --offline`.
- Análise estática deste ajuste: `flutter analyze --no-pub` concluiu com
  `No issues found!` (código de saída 0). Não foi compilado ou executado o
  aplicativo; transparência, geometria e alterações C++ serão validadas pelo usuário.

## Refinamento visual solicitado

- Escala uniforme de 85% para os elementos da faixa e altura reduzida em 15%.
- Abas agrupadas no centro horizontal da faixa, somente ícones, com nomes nos tooltips.
- Controles de janela extraídos para `lib/Widgets/launcher_window_controls.dart`,
  reutilizados no Fat e no Slim. No Slim ficam abaixo à direita sobre preto.
- Sombra em degradê atrás do conteúdo: preto na base, desaparecendo para cima,
  ocupando toda a largura da janela, inclusive as margens laterais e o rodapé.
  A camada ignora cliques, preservando a navegação pelos ícones.
- A referência mencionada não foi anexada à mensagem; ajuste baseado na descrição.
- Análise estática do refinamento: `flutter analyze --no-pub` retornou
  `No issues found!` (saída 0). Os quatro arquivos envolvidos foram formatados
  com `dart format`. Aplicativo, testes e build não foram executados.

## Centralização e largura

- Janela mantida com 100% da largura útil do monitor.
- Sombreamento movido para a camada externa, sem recorte pela margem da lista.
- Categorias centralizadas horizontalmente, mantendo o agrupamento dos ícones.
- Análise estática deste ajuste: `flutter analyze --no-pub` retornou
  `No issues found!` (saída 0), após corrigir dois apontamentos de estilo.

## Caixa de abas e instruções

- Abas movidas para a caixa de instruções no rodapé, na ordem: ícones das
  categorias, separador e descrição dos comandos de uso.
- Caixa preta arredondada, seguindo o visual dos controles de janela à direita.
- Caixa de abas e instruções fixada à esquerda no rodapé, em vez de centralizada.
- Margem externa esquerda da caixa: 8 pixels lógicos após aplicar a escala do Slim;
  o espaçamento lateral da lista de itens permanece independente.
- Categoria selecionada com ícone, contorno e realce em verde-claro.
- Texto se adapta ao espaço disponível; tooltip contém as instruções completas.
- Removido o nome fixo do item no canto superior esquerdo. Permanecem os nomes
  individuais abaixo dos ícones.
- Análise estática após a remoção do título: `flutter analyze --no-pub` retornou
  `No issues found!` (saída 0). Sem execução do aplicativo, testes ou build.

## Sons do Slim

- Copiados todos os arquivos da pasta `assets/sounds` do exemplo compilado:
  `move_8bit.wav` (navegação) e `open_8bit.wav` (abertura/confirmação).
- Destino: `assets/Sons/Slim/`, registrado no `pubspec.yaml`.
- Reutilizado `SonsSistema` e seu cache SoLoud, com pré-carregamento dos dois sons.
- Cada reprodução usa `configSistema.volume`, limitado a 0–1; volume zero
  silencia os efeitos. Não há volume separado ou fixo para o Slim.
- Navegação entre itens/categorias toca apenas quando a seleção muda; transição
  entre barra e lista também tem feedback de navegação.
- Abertura de jogo, mídia, loja, menu Start e confirmação do Fat usam `open_8bit`.
- Evitada a reprodução duplicada pelos comandos antigos de mídia no Slim.
- Análise estática desta integração: `flutter analyze --no-pub` retornou
  `No issues found!` (saída 0). Reprodução será avaliada pelo usuário;
  aplicativo, testes e build não foram executados.

## Proximidade dos nomes e cards da loja

- Imagens alinhadas à base da área disponível, próximas aos nomes, inclusive
  quando a seleção aplica escala ao ícone. Margem inferior e distância até o
  nome reduzidas para posicionar o conjunto um pouco mais abaixo.
- Cada loja ganha um fundo quadrado arredondado em gradiente, usando a cor da
  loja e um tom escuro, com ícone branco e contorno de seleção.
- Análise estática desta alteração: `flutter analyze --no-pub` retornou
  `No issues found!` (saída 0). Aplicativo, testes e build não foram executados.

## Nomes apenas em foco

- Nome visível apenas quando o ícone possui foco; ao sair, o texto fica oculto.
- Espaço da legenda preservado para evitar mudança de posição dos cards.
