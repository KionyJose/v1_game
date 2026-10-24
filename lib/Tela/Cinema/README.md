# Cinema

Catálogo de filmes e séries em mosaico, na aba **Cinema** da tela principal.
Entra no lugar da grade de canais, que continua inteira em
[`../Tela Principal/Widgets/BodyIconesCinema.dart`](../Tela%20Principal/Widgets/BodyIconesCinema.dart)
— a troca é uma linha em `PrincipalPage.bodyPageView`, com a antiga comentada
logo abaixo.

## Os canais não sumiram, mudaram de lugar

`listCinema` (Netflix, Max, Disney+…) virou a **coluna fixa da esquerda**:
mesmos índices, mesmos `FocusNode`, mesma `selectedIndexCinema`. Por isso
abrir o streaming, editar e remover cartão continuam no `PrincipalCtrl`, sem
uma linha duplicada — o que mudou foi só o enquadramento, de grade central
para ícone de margem.

A coluna vai de ponta a ponta da tela; quem desce para baixo da barra de
abas é a primeira capa, pelo `paddingTopo` de dentro dela. Sem rótulo: a
capa de cada canal já diz o que ele é.

A coluna **nunca sai de cena**: é nela que se vê qual canal está escolhido.
O que troca é o miolo da tela, ao lado dela.

Com o foco na coluna, a **capa do canal escolhido preenche a tela inteira**,
em opacidade cheia e sem texto nem painel por cima, enquanto o catálogo
recua em fade. A capa é uma camada **abaixo da coluna** na pilha: a foto
toma a tela toda e a barra fica por cima dela — é o que deixa ver qual canal
está escolhido enquanto se olha a arte.

O catálogo não é desmontado, só fica invisível: por isso a volta também é
fusão e a rolagem continua onde estava.

Entre um canal e outro, de novo fusão: a capa que entra se sobrepõe à que
sai, no mesmo lugar (`layoutBuilder` do `AnimatedSwitcher`). A saída para o
site do streaming segue a de sempre, pelo `PrincipalCtrl`.

## Quem faz o quê

| Arquivo | Papel |
| --- | --- |
| `tmdb_cine.dart` | modelos, contrato `CineFonte`, cliente TMDB e catálogo de demonstração |
| `cinema_catalogo.dart` | estado: carrega, guarda, completa a ficha e cai para a demonstração |
| `body_cinema.dart` | a tela: mosaico, cabeçalho, navegação do Pad e medidas |
| `cinema_ladrilho.dart` | o ladrilho, nos cinco formatos |
| `cinema_efeitos.dart` | arte estática, brilho, reflexo, virada, entrada |
| `cinema_ficha.dart` | a ficha em tela cheia |
| `cinema_trailer.dart` | trailer do YouTube tocando atrás |
| `cinema_trilho_canais.dart` | a coluna de canais |

A tela não conhece endereço nem JSON, e a fonte não conhece widget. É o que
deixa os testes trocarem o TMDB por uma fonte falsa sem tocar no desenho.

## A chave do TMDB

Sem chave a tela **não fica vazia**: mostra um catálogo de demonstração e diz
no rodapé onde colar a chave. Com chave, o catálogo é real, em português, com
trailer e "onde assistir" da região BR.

A chave sai de <https://www.themoviedb.org/settings/api> (gratuita). Vale
tanto a **API Key (v3)** quanto o **Read Access Token (v4)** — o cliente
descobre qual é e manda na query ou no cabeçalho.

O caminho normal é pelas **Configurações**: com o catálogo ligado,
aparecem o campo *Chave da API do TMDB* — que abre o teclado do controle
e mostra a chave resumida, nunca inteira na tela — e o botão *Como
conseguir a chave*, que abre o passo a passo (`pop_tutorial_tmdb.dart`)
com um botão para abrir o site. Só a ação **Acessar o site** destrava a
janela e libera o mouse antes de abrir o navegador. Fechar as Configurações
preserva o modo de entrada atual. O tutorial descarta o comando que o abriu,
evitando que o mesmo toque confirme também a abertura do site.

Por baixo, ela é procurada em três lugares, nesta ordem:

1. `--dart-define=TMDB_KEY=...` na compilação;
2. `%LOCALAPPDATA%\V1 Launcher\v1_tmdb.json` — `{"chave": "..."}`;
3. a variável de ambiente `TMDB_API_KEY`.

O arquivo é o caminho normal: é dado do usuário, fica fora do repositório e
não vai parar num commit. **Nesta máquina ele já está gravado** — quem clonar
o projeto em outro computador precisa criar o seu.

## Formato é leitura

Cada faixa tem a forma que combina com o que ela mostra, e não uma grade
igual para tudo:

| Faixa | Forma | Por quê |
| --- | --- | --- |
| Em alta esta semana | quadro 16:9 | a arte larga conta a história sozinha |
| Nos cinemas | cartaz 2:3 que **vira** | parado, o cartaz mostra a sinopse no verso |
| Séries do momento | quadrado com **reflexo** | o chão de vidro separa a faixa sem moldura |
| Leves | **círculo** | recorte leve para animação e família |
| Aclamados | **mosaico** assimétrico | tamanhos diferentes quebram a esteira |

**O cartão não escreve o título.** A arte do filme já o traz; texto por cima
é a mesma informação tapando desenho. O que sobra na face é a linha curta de
dados — nota, ano, gênero — e nada mais. O nome aparece no cabeçalho da
tela, no verso do cartão e na ficha, que é onde ele informa alguma coisa.

Sem imagem (demonstração, ou título sem capa), `ArteCine` desenha um gradiente
próprio daquele título com a inicial em marca d'água. É parte do visual, não
um ícone de erro.

## O ciclo do cartão: parado, vira, cartaz, trailer

Após dois segundos em foco, o cartão vira para os detalhes. O giro é
ortográfico, sem perspectiva, escala ou deslocamento vertical: o verso
mantém o tamanho e a posição da frente.

Depois da virada, saem dois cartões pela lateral, um por vez:

1. O cartaz do filme, com os mesmos 247,2 × 370,8 px de **Nos cinemas**.
2. O trailer em **16:9**, com os mesmos 370,8 px de altura do cartaz
   (659,2 px de largura).

Os cards de **Nos cinemas**, **Aclamados** e **Pra ficar acordado** usam
dimensões 20% maiores, mantendo as proporções e a navegação do mosaico.

As imagens dos cards ficam estáticas, sem paralaxe ao navegar entre eles.
Cada slide dura 460 ms. As imagens deslizam sob um recorte, sem esticar.
O player só é criado depois que o segundo slide termina. Sem trailer
cadastrado, a arte do filme continua preenchendo a caixa.

A mesma sequência vale para todos os formatos que já viravam: os cartazes
e os blocos pequenos e altos de **Aclamados**. Quadros largos, quadrados,
círculos e o bloco grande continuam sem flip.

As faixas reservam a largura dos dois cartões durante a abertura. No
mosaico, as colunas seguintes deslizam para a direita, sem cobrir outros
filmes. A altura da faixa fica reservada desde o início, para a abertura
não levantar o cartão selecionado. A rolagem considera a largura do conjunto
e preserva o acesso ao verso quando a janela é mais estreita que ele.

`_agendarCartao` controla a espera e o giro; `PreviaCine` encadeia os dois
slides. O primeiro toque lateral com o cartão aberto recolhe os slides em
240 ms (trailer primeiro, cartaz depois) e desvira o cartão em 260 ms, sem
mudar a seleção. Depois disso, outro toque lateral navega. Cima e baixo
continuam navegando normalmente. Trocar de item interrompe o vídeo. A prévia fechada
não monta imagens nem player, e o conteúdo das imagens fica fora do builder
da animação.

## Escrita não fica por cima de vídeo

Quando um trailer entra no ar — na prévia do cartão ou na ficha — o texto
que está sobre ele **sai em dois segundos**, em fade, e volta do mesmo jeito
quando o vídeo para. Quem avisa é o próprio player (`TrailerCine.onTocando`),
e não um cronômetro adivinhando: se o trailer não resolveu, a escrita fica.

O aviso pode chegar de dentro de um `dispose` do player, então a tela sempre
adia a reconstrução para depois do quadro.

## Logo de Em alta

A área da logo tem altura reservada. Enquanto os detalhes ou a imagem
carregam, o nome escrito não é exibido nesse espaço. A logo entra em fade
de 500 ms depois do primeiro quadro da imagem. Sem logo ou em caso de erro,
a área permanece vazia.

## Brilho dos cards

A varredura diagonal considera largura e altura do cartão. O percurso vai
de antes do primeiro canto até depois do último, deixando o card inteiro
sem faixa residual no intervalo entre passagens. O painter escuta o relógio
diretamente, sem reconstruir a arte a cada quadro.

## A faixa de destaque toca sozinha

Em *Em alta esta semana*, o trailer aparece **só de selecionar o cartão** —
sem confirmar nada. Ele toca com som numa **caixa fixa**, de bordas bem
arredondadas (raio 32), ancorada no canto superior direito do cabeçalho, ao
lado do título e da sinopse — nunca por cima deles. A arte do título
preenche a caixa desde o primeiro quadro; o trailer funde por cima assim que
resolve, e a troca de um cartão para o outro é o próprio `TrailerCine`
fazendo o crossfade entre os dois vídeos.

A é um passo só: abre a ficha direto, como em qualquer outra faixa. Não há
mais confirmação para "ligar" o trailer — ele já está tocando.

A caixa mede sua própria altura a partir do espaço livre do cabeçalho
(`altura - topo - paddings`), com um teto de 236 px: numa janela baixa, ela
encolhe para nunca estourar o cabeçalho; a largura segue 16:9 a partir daí.
Como o trailer toca ao lado do texto — não atrás dele —, ele **não** aciona
o apagamento do texto que os outros vídeos da tela fazem (prévia, ficha): os
dois ficam visíveis ao mesmo tempo.

## Som e gatilhos

Os trailers automáticos também começam com som. L2/LT diminui e R2/RT
aumenta o volume em passos de 5%, entre 0 e 100%, no destaque, na prévia e
na ficha, inclusive quando o texto volta sobre o trailer. O nível escolhido
é compartilhado entre os players enquanto a tela existe. Soltura e zona
morta dos gatilhos não alteram o volume; eventos analógicos consecutivos são
limitados a um ajuste a cada 120 ms.

A navegação entre os serviços da ficha revela apenas a lista horizontal
local, preservando a posição do PageView das abas.

## O player da ficha

Confirmar o trailer na ficha leva a uma terceira zona, a do **player**: o
texto sai de cena e o direcional vira controle de vídeo.

| | no player |
| --- | --- |
| A | pausa e volta |
| B | traz o texto de volta, **com o trailer rodando atrás** |
| A na ação de trailer, de novo | devolve a tela ao player |
| LB / RB (e ←/→) | 10 s para trás e para frente |

Sair da ficha continua sendo B, um passo acima. Com o texto fora, uma régua
fina embaixo mostra nome, tempo e progresso — ela escuta o
`ControleTrailer` direto, para a ficha inteira não se reconstruir quatro
vezes por segundo por causa de um relógio.

LB/RB só são engolidos **dentro** do player. Fora dele continuam trocando de
aba, e a ficha fecha junto para não ficar uma tela cheia aberta atrás da aba
seguinte — o desvio para isso está no `escutaPad`, que oferece o evento à
aba de cinema antes de trocar de guia.

## Onde assistir é botão, não enfeite

A ficha mostra o ícone de play abaixo de Trailer, os serviços disponíveis
abaixo de Onde assistir e apenas uma seta para voltar, sem letras de teclas
nos controles. O direcional percorre play → serviços → voltar; ↓ também
acessa os serviços e ↑ retorna às ações. Confirmar ou clicar abre o alvo. Confirmar **copia
o nome do título** e abre o site — é o caminho que a pessoa faria à mão, com
o nome já pronto para colar na busca de lá. O recado aparece no rodapé e se
apaga sozinho.

Os serviços de assinatura, gratuitos, aluguel e compra informados pela API
ficam numa faixa horizontal rolável, sem limite de seis opções. O serviço
em foco fica visível ao navegar pelo Pad. Sem serviços identificados, o
card **Google** pesquisa o nome do título seguido de “filme” ou “série”.

Cada serviço mostra a fotinha **e o nome embaixo**: o logo sozinho a 44 px
não identifica — Disney+, Prime Video e Max têm ícones parecidos nesse
tamanho — e o nome resolve isso antes de confirmar.

O endereço sai primeiro dos **canais do próprio usuário** (`listCinema`),
casando pelo nome: é a conta dele, com o login dele. Só quando não casa é
que cai numa tabela de endereços conhecidos, e por último no link de "onde
assistir" do TMDB.

Quem abre o endereço é injetável (`BodyCinema.abrirUrl`); no app é o
`sairDaTelaMedia`, que solta a janela e devolve o foco, e nos testes é um
registrador — teste não abre navegador.

## Peso

A tela ficou pesada antes de ficar leve. O que custava, e o que foi feito:

| Custava | Agora |
| --- | --- |
| `BackdropFilter` de tela cheia, relido a cada quadro | o fundo já nasce desfocado (`ArteCine.desfoque`), uma vez só |
| fundo e cabeçalho reconstruídos a cada pixel de rolagem | vão como `child` do `AnimatedBuilder`; a rolagem só move |
| um `AnimationController` de brilho por ladrilho, mais de cem parados | criado só quando o ladrilho acende |
| a varredura de luz repintando o cartão inteiro | `RepaintBoundary` separando a arte |
| capa de 780 px decodificada num cartaz de 247,2 px | `memCacheWidth` pelo tamanho real do ladrilho |
| fundo da ficha em `original` (até 4K) | `w1280` |
| prévia montada fechada em todo ladrilho | só existe quando abre |
| vídeo de fundo no mosaico | removido |

A regra que ficou: nada que seja imagem ou vídeo deve ser construído dentro
do `builder` de uma animação, e nenhuma imagem é decodificada maior do que
a caixa onde ela cabe.

## Navegação pelo Pad

Duas zonas, e o caminho entre elas é explícito:

| Zona | ←/→ | ↑/↓ | A | B |
| --- | --- | --- | --- | --- |
| canais | → entra no mosaico | troca de canal | abre o streaming (fluxo antigo) | — |
| mosaico | card da coluna vizinha; ← na 1ª coluna entra nos canais | card acima/abaixo; só troca de faixa quando não há vizinho vertical | abre a ficha | — |
| ficha | percorre play, serviços e seta de voltar | ↓ acessa os serviços, ↑ volta às ações | confirma | fecha, ou volta às ações |
| player | 10 s para trás/frente | — | pausa e volta | volta ao texto, trailer rodando |

Em Aclamados, cima e baixo percorrem os dois cards empilhados antes de sair
do tópico. Esquerda e direita procuram a coluna vizinha pela geometria,
sem passar do card superior para o inferior. A linha escolhida é preservada
ao atravessar um card alto e voltar.

A coluna tem **três** portas de entrada — ← na primeira coluna, ↑ na
primeira faixa, e qualquer direcional quando o mosaico está vazio (ainda
carregando, ou fora do ar). Com uma porta só, voltar coluna por coluna no
meio de uma faixa de vinte fazia a coluna parecer inacessível.

Nada disso é impresso na tela: a aba não tem legenda de botões. O rodapé só
aparece para avisar que o catálogo é de demonstração.

`PrincipalCtrl.cinemaPadHandler` é o desvio: a tela devolve `true` no que
consumiu e **`false` no que é dos canais** (A e SELECT com o direcional na
coluna), e aí o `movFilmes` de sempre assume. Sem isso seria preciso copiar
para cá o código de abrir streaming e editar cartão.

LB/RB continuam trocando de aba — são interceptados antes, no `escutaPad`.

## Cache durante a execução

`CinemaCatalogo.sessao` mantém catálogo e detalhes em memória durante toda
a execução do app. A primeira visita carrega as faixas; trocar de aba,
remontar a tela ou desligar e religar a apresentação do catálogo reutiliza
os dados. Reiniciar o aplicativo cria uma nova sessão. Os detalhes de um
título ainda não consultado são buscados uma vez, sob demanda.

## O que a tela faz sozinha

- **Carga preguiçosa**: o `PageView` monta as quatro abas juntas, então o
  catálogo só é pedido quando a aba de cinema aparece pela primeira vez.
- **Detalhe por demora**: parado ~0,45 s num título, a tela busca a ficha
  completa dele — é o que faz o logo e o trailer aparecerem sem uma
  requisição por tecla apertada. A espera é menor que os 2 s do ciclo do
  cartão de propósito: quando o painel abre, o id do trailer já precisa
  estar na mão.
- **Um vídeo por vez**, e nunca um que vá ser descartado em seguida.
- **Congela fora de vista**: `TickerMode` desliga as animações quando a aba
  não está à mostra; cartaz girando atrás da tela de jogos custa quadro.

## Medidas

`MedidaCine.margemFaixa` é o recuo das pontas da faixa, e entra na conta da
rolagem: sem ele o alvo saía 44 px curto e o último cartão parava cortado
na borda. `respiroDireita` são mais 30 px de sobra à direita, para o último
cartão nunca encostar.

`MedidaCine.topo` são 80 px reservados no alto para a barra de abas, que é
desenhada por cima desta tela: é onde o cabeçalho começa e é a distância
que a rolagem deixa acima da faixa em foco, para nenhum item selecionado
parar atrás dela. A coluna de canais usa a mesma medida para a primeira
capa.

`MedidaCine` guarda altura de faixa, tamanho de ladrilho e a geometria do
mosaico. São fixas de propósito: o salto do Pad é calculado por aritmética, e
perguntar ao `RenderObject` onde o cartão foi parar atrasa a rolagem em um
quadro visível. Mudou uma medida no desenho, muda aqui também — é o mesmo
número que a rolagem usa.

## Testes

`flutter test test/config_cinema_test.dart` cobre o interruptor da tela
de cinema, inclusive a config antiga sem o campo gravado, que não pode
virar `false` e tirar a aba de quem já tinha o launcher.

`flutter test test/cinema_tela_test.dart` cobre a geometria do mosaico, a
queda para a demonstração, o cache de detalhes, a leitura do JSON do TMDB
(gêneros, melhor trailer, logo em português, provedores, chave recusada,
token v4) e a tela: faixas desenhadas, direcional andando e saindo para os
canais pelas três portas, a capa do canal tomando a tela e fundindo de uma para
a outra, a ausência de legenda de botões, o trailer do destaque tocando
sozinho ao selecionar (sem confirmação) e sumindo com a ficha aberta, A
abrindo a ficha, e A **não** sendo consumido na coluna de canais.

`pumpAndSettle` não serve aqui: o brilho do item em foco é animação em laço e
nunca assenta. Os testes avançam o relógio em passos de um segundo.
