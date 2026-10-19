# Downloads

A tela `DownloadsTela` usa o mesmo `DownloadsController` em todas as rotas.
O processo aria2 é iniciado somente ao selecionar **Iniciar**, com até cinco
transferências simultâneas e uma fila para os demais itens. Cada torrent tem
GID e pasta de destino próprios. O aria2c precisa estar instalado ou distribuído
com o aplicativo; sua localização é resolvida em `aria2_engine.dart`.

## Arquivos e persistência

### Distribuição no Windows

O build inclui `aria2c.exe` na mesma pasta de `v1_game.exe`, usando a cópia
em `windows/third_party/aria2`. As licenças acompanham o pacote em
`licenses/aria2`. O launcher prioriza esse executável antes de procurar uma
instalação externa. Exporte toda a pasta `build/windows/x64/runner/Release`,
incluindo `data`, DLLs, `aria2c.exe` e `licenses`; não copie somente o launcher.

No instalador, coloque `aria2c.exe` na raiz da pasta de instalação do launcher
e preserve `licenses/aria2`. Não é necessário instalar aria2 pelo WinGet no cliente.

- Entrada automática: `Downloads/games torrent compra/*.torrent`.
- Metadados individuais: `<arquivo>.torrent.json`, ao lado do torrent.
- Conteúdo dos novos jogos: `<disco>:\V1 Jogos\<nome do jogo> - <infoHash curto>\`.
  Downloads já iniciados mantêm o destino anterior.
- Índice: `<getApplicationSupportDirectory()>/downloads/downloads.json`.

O JSON individual contém `schemaVersion`, `id` (infoHash), `name`,
`releaseSource: {type, name}`, `edition`, `releaseInfo`, `pageUrl`, `downloadUrl`,
`torrentFiles`, `acquiredAt` e `download`. Este último armazena estado, destino,
`destinationChosen`, bytes totais/recebidos, velocidade, peers, GID, erro e datas
de início/conclusão. O destino escolhido é preservado no índice e no sidecar.
Os arquivos são atualizados com o progresso e escritos com arquivo temporário.
Torrents com o mesmo infoHash representam um único download.

O scraper prioriza o texto de `.release-source-name`. `ReleaseSource` distingue
`fitGirl`, `dodi`, `elAmigos`, `other` e `unknown`, preservando também o nome
original. Para adicionar tratamento de outra fonte, estenda a enumeração e
`classifyReleaseSource` em `download_record.dart`. O botão Jogar usa o protocolo
FitGirl/Inno/FreeArc de `game_preparation.dart`. Outros releases exibem o aviso
de protocolo indisponível e abrem somente a pasta recebida.

## Preparação do jogo

Ao clicar em Jogar, o controller procura um executável válido e, se necessário,
extrai as ferramentas do setup com innoextract e tenta extrair os `fg-*.bin`
com o helper nativo x86 `V1Unarc`. A saída fica em `<destino>/Jogo` e as ferramentas
em `<destino>/.v1-tools`. Status, protocolo, pasta e erros ficam no JSON do torrent.
Não executa `setup.exe`, scripts de hosts ou utilitários de verificação do repack.

A extração pode continuar enquanto o usuário navega pelo launcher. Cancelar
preparo encerra o helper e os decodificadores no seu Job Object, preservando
os arquivos para nova tentativa. Fechar o aplicativo também cancela a preparação.
Após dez minutos sem progresso, a tentativa termina com erro, sem registrar o jogo.
Reabrir um estado interrompido permite nova tentativa.

O manifesto `MD5/fitgirl-bins.md5`, quando presente, valida os arquivos recebidos
antes da extração. Depois, todos os arquivos de `fitgirl.md5` são conferidos por
MD5; arquivos faltantes impedem o cadastro. Uma pasta `Jogo` parcial é retomada
pela extração, sem confundir um executável isolado com instalação concluída.
Um launcher único na raiz tem prioridade sobre binários da engine. Havendo dúvidas,
ausência do executável ou falha na preparação, um navegador interno lista todas
as pastas e arquivos, permite selecionar o `.exe` pelo Pad e salva a escolha.
Instaladores e utilitários como QuickSFV ficam visíveis, mas não podem ser escolhidos
como executável do jogo.

`installed_game_library.dart` grava no catálogo original, colocando o jogo em
primeiro sem duplicar seu caminho. A tela principal recarrega ao retornar da rota.

**Limitação observada:** a listagem do FACEMINER fornecido funciona, mas seu
decodificador travou durante a extração de `fg-05.bin`. A instalação automática
desse pacote ainda não foi validada. O fluxo da interface, cadastro e cancelamento
têm testes separados; esses testes não comprovam a extração real desse repack.

Recompile o helper com `tools/repack/build.cmd` em um ambiente Visual Studio com
MSVC x86. Os executáveis distribuídos estão em `assets/Repack`, com as licenças
do innoextract e de suas dependências. `V1Unarc.cpp` documenta o contrato da DLL.

O protocolo `fitgirl-inno-freearc-v2` inicializa `Init_MapFile_` com `Local\`.
As cópias privadas dos módulos e workers CLS têm o prefixo IPC `Global\`
substituído pelo mesmo prefixo local, evitando a exigência de privilégios para
criar memória global no Windows. O setup e os arquivos `.bin` originais não são
alterados. Um mutex da sessão serializa os hosts de extração, pois os codecs
legados usam nomes fixos; os downloads continuam simultâneos. A espera pelo
mutex emite heartbeat e permite cancelamento.

O canal `Init_MapFile_` é prendido em `Local\` por `repack_decoder_channel.dart`
durante toda a extração direta. Um codec pode gravar `Global\` nesse canal e um
decodificador que não encerre o mantém vivo: sem esse cuidado a preparação
seguinte da mesma sessão do Windows falha com *Another installer is using the
decoder initialization channel*, mesmo com o download íntegro.

`repack_decoder_tuning.dart` reescreve o `CLS.ini` do repack. Além de resolver
`{app}`, reduz `Memory`, `MaxMemoryUsage` e `ldmfMaxMemoryUsage` ao que a
máquina tem de memória livre. O repack pede porcentagens da RAM **total**
(`75%-10m`, `60%-2048m`); com pouca RAM livre o worker x64 do CLS morre no meio
da extração e o unarc acusa `broken compressed data` — um erro que parece
corrupção de download, mas não é. Limites de thread e caminhos de temporários
ficam como o repack definiu.

## Áudio recomprimido (patch `.x5`)

O sinal comum a todos esses repacks é um arquivo **`.x5`**: um patch
[HDiffPatch] que devolve o áudio ao formato do jogo. O arquivo que ele corrige
chega como Ogg Vorbis cru, e sem aplicar o patch o jogo instala completo, roda
e fica **mudo** — com o `fitgirl.md5` acusando exatamente esse arquivo.

O patch aparece em duas formas, e `_restoreRecompressedAudio` trata as duas:

- **Ao lado do alvo**, como `Ben10_Data/StreamingAssets/Master Bank.bank.x5`,
  quando o Ogg já está gravado no lugar do arquivo final. Basta aplicar o
  patch sobre ele. Esse formato pode estar em qualquer profundidade da árvore,
  por isso a procura é recursiva — olhar só a raiz deixava o jogo mudo.
- **Sozinho**, como `inner.fgpack.x5`, quando o alvo ainda precisa ser montado
  a partir dos segmentos `NN.fgpack` (ver abaixo).

Se o resultado do patch for um arquivo FreeArc (assinatura `ArC\x01`), o áudio
vem dentro dele e é extraído com o `V1Unarc` na pasta do jogo; caso contrário,
ele substitui o alvo. Os intermediários saem no fim.

Validado em dois repacks de formatos diferentes: *Ben 10 - Power Trip*
(516/516, patch ao lado do alvo, recomprime com `cls-mpzz.dll`) e *Stick It to
the Stickman* (262/262, patch com segmentos, recomprime com `oggre_dec.exe`).

### Segmentos `.fgpack`

Parte dos repacks recomprime o áudio FMOD como Ogg Vorbis. Nesses pacotes os
`fg-*.bin` **não** contêm os `*.resource` do jogo: entregam segmentos
`NN.fgpack` com o Ogg restaurado pelo `oggre_dec.exe`, o tamanho real de cada
segmento em `NN.fgpack.x2` e um patch `*.fgpack.x5`. Extrair só os `.bin`
produz uma instalação que abre, roda e fica **muda**, deixando os `.fgpack` para
trás como sinal. O `fitgirl.md5` acusa exatamente os `*.resource` ausentes.

`_montarAlvoDoPatch` refaz o caminho do instalador original, com as
ferramentas que o próprio repack traz:

1. corta cada `NN.fgpack` no tamanho de 8 bytes little-endian de `NN.fgpack.x2`;
2. `fsb.exe <segmento> <segmento>.fsb` converte cada um de Ogg Vorbis para FSB5
   — por segmento, nunca no arquivo já concatenado, senão o resultado perde os
   cabeçalhos intermediários e o patch recusa o tamanho;
3. concatena os `.fsb` na ordem dos nomes;
4. `x5.exe` (HDiffPatch `hpatchz`) aplica o `*.fgpack.x5` sobre essa junção;
5. o resultado é um arquivo FreeArc, extraído com o `V1Unarc` na pasta do jogo,
   e traz os `*.resource` definitivos;
6. os intermediários são apagados.

Validado em *Stick It to the Stickman*: 262/262 arquivos do `fitgirl.md5` e os
14 `*.resource` idênticos byte a byte aos de uma instalação feita pelo
`setup.exe` original. `fsb.exe` e `x5.exe` trabalham calados, então `_run`
acompanha o avanço pelo arquivo que estão gravando (`growthProbe`) em vez das
linhas de saída. Um pacote com mais de um `*.fgpack.x5`, ou sem essas
ferramentas, interrompe a preparação com erro em vez de cadastrar um jogo mudo.

O diagnóstico do canal de inicialização também é documentado pelo
[autor de um host independente](https://soyuka.me/forza-horizon-6-linux-offline-saves/#eight-bytes-that-were-missing).
O teste nativo opcional abaixo usa um pacote local existente, verifica a extração
real e cadastra em uma biblioteca de teste. Ele fica desativado na suíte normal:

```powershell
$env:V1_REPACK_TEST_METADATA = '<caminho do arquivo .torrent.json>'
flutter test --no-pub --reporter expanded test/game_preparation_native_test.dart
```

Definir adicionalmente `V1_REPACK_REGISTER=1` autoriza esse teste manual a
cadastrar na biblioteca real e atualizar o sidecar, preservando uma cópia anterior.

## Ações e navegação

### Comparação de instalação FitGirl

**Jogar** mantém a extração direta. **Instalar silent**, disponível no cartão
FitGirl concluído e navegável pelo Pad, executa o setup original em `Jogo-Silent`.
A pasta `Jogo` existente é preservada. Se o teste falhar ou for cancelado, o
executável anteriormente pronto continua cadastrado. Após sucesso, o novo caminho
substitui a entrada anterior no início da biblioteca, sem duplicar o jogo.

O helper `V1SilentInstall` tem manifesto `asInvoker`: o processo inicial inicia
normalmente e solicita a elevação convencional do Windows somente para seu worker.
A autorização UAC não é automatizada. O worker monitora o processo pai; cancelar
preparo encerra o seu Job Object, incluindo instalador e decodificadores.
QuickSFV e o instalador web de DirectX são dispensados somente quando pertencem
ao próprio Job Object e estão em `_Redist` da pasta escolhida. A integridade é
verificada pelo launcher. Este protocolo não instala pré-requisitos adicionais.

As flags Inno são `/SP- /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /NOICONS
/TASKS="" /DIR=... /LOG=...`. Elas não garantem a supressão das ações customizadas
do repack: o setup original ainda pode executar scripts e abrir sites. Veja a
[documentação oficial do Inno](https://jrsoftware.org/ishelp/topic_setupcmdline.htm).
Por isso silent é uma alternativa experimental, não uma garantia de instalação
sem ações extras. O resultado do piloto está em `tools/repack/SILENT_TEST.md`.

Status e cancelamento aparecem no cartão. Após a verificação completa, o JSON
do torrent guarda `installation.metrics` com método, duração, manifesto e log.
Relatórios detalhados ficam em `.v1-tools/direct-installation.json` ou
`.v1-tools/silent-installation.json`; o instalador gera `silent-install.log`.
O cartão exibe a duração da última preparação. Reutilizar uma instalação pronta
não produz uma nova medição; o tempo registrado inclui validação, instalação
e verificação final, sem misturá-lo ao tempo do download.

Para testar o helper e o cancelamento sem instalar um jogo:

```powershell
cmd /c tools\repack\build_probe.cmd
$env:RUN_SILENT_RUNNER_NATIVE_TEST = '1'
flutter test --no-pub test/silent_runner_native_test.dart
```

O teste real opcional aceita `V1_REPACK_METHOD=silent`,
`V1_REPACK_OUTPUT=Jogo-Silent-Teste` e `V1_REPACK_FORCE=1`. Sem `FORCE`, uma pasta
que já passa no manifesto é reaproveitada. Não ative `REGISTER` para comparar
sem alterar a biblioteca real.

- Iniciar: antes da primeira transferência, `download_destination.dart` lista
  as unidades acessíveis e oferece um seletor interno pelo Pad. A escolha cria
  `V1 Jogos` na raiz e a subpasta do jogo; nomes são normalizados e o identificador
  distingue edições. Voltar cancela a escolha sem iniciar o download.
- Retomar: usa o mesmo destino e retoma o GID pausado.
- Pausar: mantém o item e seus arquivos parciais.
- Cancelar: remove a transferência do motor e mantém os arquivos parciais;
  Iniciar permite recuperá-los, verificando sua integridade.
- Abrir pasta: abre a pasta recebida no Explorer, em qualquer estado do item.
  Fica imediatamente antes de Excluir, na ordem do Pad e na tela. O Explorer
  não se navega pelo Pad, então o botão libera a tela antes de abrir: a janela
  deixa de ficar presa à frente e `Paad.ativaMouse` entrega o mouse do sistema.
  Ao voltar o foco ao launcher, `onWindowFocus` restaura a fixação anterior.
  Só o Explorer recebe esse tratamento: o seletor de capa se navega pelo Pad e
  roda sem liberar mouse nem mexer na fixação da janela.

  A reposição da fixação sai sempre em `addPostFrameCallback`: `dispose` roda
  com a árvore de widgets travada e `telaPresaReverse` notifica o provider do
  `JanelaCtrl`, o que derruba o quadro com *setState() called when widget tree
  was locked*. `ensureVisualUpdate` garante um próximo quadro quando a saída
  acontece fora de um.
- Excluir: confirmação remove o item, seus torrents e metadados e libera o
  espaço do download — o repack, os arquivos de conferência, as ferramentas de
  extração e o torrent da pasta — **preservando o jogo instalado**, que segue
  na biblioteca. A pasta de instalação é reconhecida por `installationDirectory`
  e por `launchPath`; sem nada a preservar, a pasta gerenciada sai inteira.
  A opção adicional exclui também o jogo instalado, apagando a pasta completa.

Ao reabrir o aplicativo, downloads em andamento ficam pausados; o usuário
seleciona Retomar. A pasta de compras é examinada na abertura e monitorada para
novos torrents. Arquivos inválidos ou ainda incompletos não entram na fila.

Somente o cartão com foco expande suas ações. Os botões compartilham tamanho
e estilo; o fundo fica roxo apenas no botão em foco. Teclado: setas, Enter e Escape.
Controle XInput: direcional/analógico esquerdo, A para selecionar e B para voltar.
A leitura do controle é local à tela e não movimenta o cursor do Windows.

A barra tem 52 pixels de altura e texto interno. Sem dados recebidos, exibe
**Analisando torrent** por 5 minutos ativos, depois **Verificando dados finais**
por mais 3. Nessas etapas, um indicador indeterminado percorre a barra atrás
do texto e da contagem regressiva, em violeta na análise e ciano na verificação.
Bytes recebidos ou velocidade positiva encerram a espera
e a barra passa a usar o progresso real. Pausa e fila não consomem esse prazo.
Se os 8 minutos terminarem sem dados, a transferência é cancelada, o item recebe
um erro explicativo e pode ser iniciado novamente. Seus arquivos são preservados.

Cancelar é idempotente: GID já removido não é erro. Respostas HTTP 400 com erro
JSON-RPC são interpretadas antes de classificar falhas de transporte; a limpeza
do resultado aguarda a remoção assíncrona. Excluir um ativo cancela primeiro e
somente depois remove seus arquivos. Falhas de autenticação ou conexão continuam
visíveis e impedem uma exclusão que não tenha confirmado a parada do motor.

## Componentes

Em Downloads, cima/baixo alternam cartões na ordem da fila; esquerda/direita
alternam apenas ações habilitadas do cartão atual. A rolagem revela o cartão
inteiro depois de sua expansão, sem reposicioná-lo a cada botão.

Downloads FitGirl concluídos oferecem **Jogar**; os outros releases exibem o
aviso de protocolo indisponível no próprio cartão e contam com **Abrir pasta**.
`download_game_launcher.dart` procura
executáveis na pasta recebida, ignorando instaladores, MD5 e pré-requisitos.
Um navegador interno pelo Pad permite definir o executável quando necessário.

O primeiro **Jogar** de um jogo ainda não cadastrado descompacta, cadastra e
**para aí**: o jogo não abre nessa vez, e o cartão avisa que o Jogar seguinte
pede a capa.

**Um jogo sem capa própria não sai da fila.** O Jogar consulta
`InstalledGameLibrary.hasCover`: enquanto a entrada guardar o ícone padrão
(`BGICOdefault.png`), o seletor de imagens da tela principal é aberto e a
escolha é gravada só naquela entrada (`setCover`). Desistir do seletor mantém a
tela aberta, com o aviso de que falta a capa. Assim o jogo nunca chega ao
início sem identidade.

**A fila nunca executa o jogo.** Com a capa pronta, a tela de Downloads apenas
fecha: quem dá play é o jogador, na tela principal. O cadastro já aconteceu
dentro de `prepareForPlay`, que chama `registerInstalledGame` e leva o jogo
para o primeiro card; ao voltar da rota, `PrincipalCtrl.abrirTelaInterna` nota
a mudança de revisão da biblioteca, recarrega a lista e seleciona o índice 0.
Por isso a tela não tem mais um caminho de execução — `DB().openFile` e o
parâmetro `onLaunchGame` saíram daqui.

A condição é a capa, não o instante da instalação: se a extração terminar
enquanto o jogador está em outra tela, o Jogar seguinte ainda pede a capa. O
aviso no cartão é da visita à tela e não vai para o JSON; a capa, sim, fica no
catálogo. Um jogo que já tem capa fecha a fila de primeira.

`chooseCover` é a costura de teste que substitui seletor e download da imagem.

`launchPath` é salvo
no JSON e reutilizado nas próximas aberturas. A abertura usa o backend `DB`
do launcher com a pasta do executável como diretório de trabalho; a retenção
de foco da janela é suspensa enquanto o jogo assume a frente e restaurada ao
retornar ao aplicativo. Nenhum instalador é executado automaticamente.

`download_store.dart` cuida da importação e do JSON; `aria2_engine.dart`, do RPC;
`downloads_controller.dart`, dos estados e ações; `download_card.dart`, de cada
cartão; `downloads_tela.dart`, da fila; `Paad` e `Interface/launcher_pad_scope.dart`, do controle;
`downloads_lifecycle.dart`, da pausa e persistência ao sair do aplicativo.

Os testes usam diretórios temporários, motor injetado e servidor RPC local.
Eles não precisam baixar conteúdo de jogos para validar os controles da fila.

No Windows, os testes opcionais com o aria2 instalado podem ser executados com:

```powershell
$env:RUN_ARIA2_NATIVE_TEST = '1'
flutter test --no-pub test/aria2_native_test.dart
```

Eles validam RPC autenticado, dois torrents independentes, pausa/retomada,
cancelamento e download completo com verificação de integridade via webseed
local. O cliente RPC envia JSON em bytes UTF-8 com `Content-Length` explícito,
mantendo a compatibilidade com o servidor HTTP do aria2.
