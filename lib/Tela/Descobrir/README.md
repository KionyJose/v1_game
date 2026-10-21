# Descobrir

Carrossel de descoberta da Steam, dentro do launcher. É o destino do bloco
**Descobrir** da aba Loja (`LojaGame.descobrir` em `PrincipalCtrl.listLojas`);
os outros blocos continuam abrindo o site no navegador do sistema.

## Por que carrossel e não grade

A Loja Interna é tela de procurar: grade, muitos cards, busca por nome. Esta é
de navegar olhando — um jogo grande no centro, vizinhos recuados dos lados. Por
isso o carrossel manda: **o cartão central é o selecionado**, e esquerda/direita
movem a esteira em vez de mudar o foco de widget. Nenhum `DescobrirCard` tem
`FocusNode`; quem tem foco é o `PageView` inteiro.

Busca e filtros de gênero ficam acima porque sem eles 297 mil jogos não têm
serventia.

## Movimento

`PageView` com `viewportFraction: .26` deixa o cartão central e os vizinhos na
tela ao mesmo tempo. A física é `PageScrollPhysics(parent: BouncingScrollPhysics())`:
dá o encaixe em página com a inércia macia do Bouncing, então o arrasto do mouse
desacelera em vez de parar seco.

O destaque de cada cartão (`escala`, brilho, nitidez da borda) vem de
`_posicao`, lida do `PageController` **a cada quadro**, não do índice. É isso
que faz o cartão crescer junto com o arrasto, e não só quando a animação acaba.

Pelo Pad e pelo teclado, `animateToPage` com `easeOutCubic` em 420 ms. LB/RB
pulam 10 de uma vez. A página seguinte é pedida 6 cartões antes do fim, para a
esteira não parar enquanto o jogador percorre.

## Sons

`SonsSistema.futuristicMove` ao trocar de cartão e ao trocar de captura na
ficha; `futuristicOpen` ao abrir a ficha e ao abrir a loja; `click` no filtro
de gênero. O parâmetro `sons: false` desliga tudo nos testes — o motor de áudio
não sobe no ambiente de teste e imprime aviso a cada chamada.

## Ficha

`descobrir_detalhes.dart` segue a leitura da ficha da Loja Interna — mídia à
esquerda, painel de ação à direita, descrição abaixo — mas **sem painel de
compra**: a Steam não entrega torrent, e oferecer download ali seria mentira.
No lugar entram preço, gêneros e **Abrir na loja**.

Esquerda/direita percorrem as capturas. Sem capturas, a galeria diz isso em vez
de deixar um buraco.

## Erros

As duas telas usam o mesmo `ErroCatalogoPainel` e o mesmo
`DiagnosticoCatalogo` da Loja Interna, então uma falha de DNS na Steam dá o
mesmo código e o mesmo relatório copiável. Ver
[`../Tela loja/scraps/README.md`](../Tela%20loja/scraps/README.md).

## Testes

`flutter test test/descobrir_tela_test.dart` cobre abertura centralizada,
busca, filtro por gênero (confere que vai `tags` e não `genre`), painel de erro,
monitor pequeno e os três estados da ficha. O scraper tem testes próprios em
`test/steam_scraper_test.dart`, com JSON real da Steam em fixtures.
