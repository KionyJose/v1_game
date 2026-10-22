# Descobrir

Grade de descoberta da Steam, dentro do launcher. É o destino do bloco
**Descobrir** da aba Loja (`LojaGame.descobrir` em `PrincipalCtrl.listLojas`);
os outros blocos continuam abrindo o site no navegador do sistema.

## Grade, não carrossel

Cinco cartões por linha, proporção **21:9** (`DescobrirTela.proporcao`). Bem
mais larga que a capa da loja, ela faz a imagem preencher a altura inteira e
sobrar nas pontas, em vez de deixar faixa vazia — e deixa a linha baixa, então
cabem mais linhas sem encolher a largura de cada capa.

`DescobrirTela.colunas` é fixo: é o enquadramento pedido para a tela, e deixar
variável faria o salto de linha do Pad mudar de tamanho conforme a janela.

O carrossel anterior mostrava um jogo por vez e exigia percorrer a esteira
inteira para ver o que havia. A grade mostra vinte de uma vez, e as margens
são curtas de propósito: o conteúdo é que ocupa a tela.

## Navegação pelo Pad

A tela tem três faixas e o movimento entre elas é **explícito**, em vez de
depender da travessia automática de foco — em grade larga ela pula para onde
ninguém espera. `_Faixa` diz onde o Pad está:

| Faixa | Esquerda/Direita | Cima | Baixo | A |
| --- | --- | --- | --- | --- |
| busca | — | — | gêneros | abre o teclado |
| gêneros | troca de gênero | busca | grade | aplica o filtro |
| grade | cartão anterior/seguinte | linha acima, ou gêneros na 1ª linha | linha abaixo | abre a ficha |

LB/RB saltam duas linhas. Na faixa de gêneros, **apontado** (onde o direcional
está) e **ativo** (o filtro valendo) são estados distintos: juntá-los escondia
para onde o Pad tinha andado antes de confirmar.

`_revelarLinha` mantém a linha inteira à vista ao descer, não só o cartão, e a
página seguinte é pedida uma linha antes do fim para a grade não parar debaixo
do dedo de quem está rolando.

## Sons

`SonsSistema.futuristicMove` ao trocar de cartão e ao trocar de captura na
ficha; `futuristicOpen` ao abrir a ficha e ao abrir a loja; `click` no filtro
de gênero. O parâmetro `sons: false` desliga tudo nos testes — o motor de áudio
não sobe no ambiente de teste e imprime aviso a cada chamada.

## Ficha

Empilhada, na ordem em que o olho lê:

1. **nome + Visitar site**, na mesma linha — com preço e gêneros sob o nome;
2. **imagem grande**, que leva a maior parte da altura;
3. **faixa de miniaturas** com capturas e trailers;
4. **descrição**, rolável.

O botão fica **acima** da imagem de propósito: é para lá que o direcional sobe
a partir das miniaturas. Antes ele estava num painel lateral, e chegar nele
exigia atravessar a galeria inteira.

Sem painel de compra — a Steam não entrega torrent, e oferecer download ali
seria mentira.

O Pad percorre três zonas (`_Zona`), na mesma ordem vertical: ação, galeria e
descrição. Esquerda e direita **passam as imagens** selecionando na faixa;
cima sobe para o botão; baixo desce para a descrição, que rola com o
direcional quando é maior que o espaço. A borda violeta marca a zona em foco.

Capturas e trailers dividem a faixa. Um trailer traz o selo de play e, ao ser
confirmado, abre no navegador — o player interno só toca YouTube, e os vídeos
da Steam são mp4 próprios. `_imagemGrande` mantém na tela a última **captura**
escolhida, então passar por um trailer não apaga a imagem.

Sem mídia nenhuma, a galeria diz isso e a faixa não é desenhada.

## Erros

As duas telas usam o mesmo `ErroCatalogoPainel` e o mesmo
`DiagnosticoCatalogo` da Loja Interna, então uma falha de DNS na Steam dá o
mesmo código e o mesmo relatório copiável. Ver
[`../Tela loja/scraps/README.md`](../Tela%20loja/scraps/README.md).

## Testes

`flutter test test/descobrir_tela_test.dart` cobre o enquadramento da grade
(cinco por linha, 16:9, sem `PageView`), o Pad andando na linha e pulando de
linha sem passar das pontas, a seleção de gênero pelo direcional com `tags`
indo à Steam, a subida até a busca, o painel de erro, monitor pequeno e as
quatro situações da ficha — incluindo o Pad percorrendo as três zonas. O scraper tem testes próprios em
`test/steam_scraper_test.dart`, com JSON real da Steam em fixtures.
