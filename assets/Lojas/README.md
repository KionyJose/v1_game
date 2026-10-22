# Logos das lojas

Um PNG por bloco da aba Loja, no lugar do ícone Material. Os nomes são fixos,
lidos de `LojaGame.logo` em `PrincipalCtrl.listLojas`.

| Arquivo         | Bloco        | Origem                              |
| --------------- | ------------ | ----------------------------------- |
| `interna.png`   | Loja Interna | `assets/IconeAppV1.png` do próprio app |
| `gog.png`       | GOG          | Simple Icons `gogdotcom`            |
| `descobrir.png` | Descobrir    | geometria (bússola) — marca nossa   |
| `steam.png`     | Steam        | Simple Icons `steam`                |
| `epic.png`      | Epic         | Simple Icons `epicgames`            |
| `microsoft.png` | Microsoft    | geometria (quatro quadrados)        |
| `ea.png`        | EA           | Simple Icons `ea`                   |
| `ubisoft.png`   | Ubisoft      | Simple Icons `ubisoft`              |
| `blizzard.png`  | Blizzard     | Simple Icons `battledotnet`         |
| `itchio.png`    | itch.io      | Simple Icons `itchdotio`            |
| *(ausente)*     | Mods (ModDB) | **sem logo — usa o ícone Material** |

512×512, RGBA com fundo transparente. As marcas do Simple Icons saem **brancas**,
porque o bloco já carrega a cor da loja em `LojaGame.cor` e branco é o que fica
legível sobre qualquer um desses fundos. A Microsoft é a exceção: nas cores
oficiais, porque em branco viraria só quatro quadrados e a marca se perderia.

## Reproduzir

```powershell
python tools\logos\gerar_logos.py
```

Baixa os SVG do Simple Icons e rasteriza com PIL. Não há ImageMagick nem
Inkscape nesta máquina, e `convert` aqui é o utilitário de sistema de arquivos
do Windows — por isso o script traz o seu próprio rasterizador de path, com
preenchimento *nonzero* (o padrão do SVG), supersample 4× e redução Lanczos.

## Faltando

**ModDB não tem logo.** Foi retirado do Simple Icons a pedido da marca, e o
logotipo é uma tipografia que não dá para reconstruir com fidelidade. O bloco
continua funcionando: `LojaLogo` e `FuturisticItem.logo` voltam ao ícone
Material quando o PNG falta, então ele aparece com o ícone de construção.
Para resolver, baixe o PNG do kit de marca do ModDB e salve como `moddb.png`.

Esse mesmo fallback vale para qualquer arquivo que falte ou esteja corrompido:
nenhum bloco fica vazio por causa de um PNG.

## Licença

Os arquivos do Simple Icons são CC0, mas **as marcas pertencem às respectivas
empresas**. O uso aqui é nominativo — identificar a loja para onde o bloco
leva. Antes de distribuir o aplicativo, confira as regras de uso de marca de
cada uma; algumas restringem cor, proporção e área de respiro.
