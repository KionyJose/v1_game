# Downloads

A tela `DownloadsTela` usa o mesmo `DownloadsController` em todas as rotas.
O processo aria2 é iniciado somente ao selecionar **Iniciar**, com até cinco
transferências simultâneas e uma fila para os demais itens. Cada torrent tem
GID e pasta de destino próprios. O aria2c precisa estar instalado ou distribuído
com o aplicativo; sua localização é resolvida em `aria2_engine.dart`.

## Arquivos e persistência

- Entrada automática: `Downloads/games torrent compra/*.torrent`.
- Metadados individuais: `<arquivo>.torrent.json`, ao lado do torrent.
- Conteúdo dos jogos: `Downloads/games torrent downloads/<infoHash>/`.
- Índice: `<getApplicationSupportDirectory()>/downloads/downloads.json`.

O JSON individual contém `schemaVersion`, `id` (infoHash), `name`,
`releaseSource: {type, name}`, `edition`, `releaseInfo`, `pageUrl`, `downloadUrl`,
`torrentFiles`, `acquiredAt` e `download`. Este último armazena estado, destino,
bytes totais/recebidos, velocidade, peers, GID, erro e datas de início/conclusão.
Os arquivos são atualizados com o progresso e escritos com arquivo temporário.
Torrents com o mesmo infoHash representam um único download.

O scraper prioriza o texto de `.release-source-name`. `ReleaseSource` distingue
`fitGirl`, `dodi`, `elAmigos`, `other` e `unknown`, preservando também o nome
original. Para adicionar tratamento de outra fonte, estenda a enumeração e
`classifyReleaseSource` em `download_record.dart`. Nenhum instalador é executado
automaticamente: os metadados ficam disponíveis para tratamento posterior.

## Ações e navegação

- Iniciar/Retomar: inicia um novo GID ou retoma o GID pausado.
- Pausar: mantém o item e seus arquivos parciais.
- Cancelar: remove a transferência do motor e mantém os arquivos parciais;
  Iniciar permite recuperá-los, verificando sua integridade.
- Excluir: confirmação remove o item, seus torrents e metadados. A opção
  adicional permite excluir também o conteúdo na pasta gerenciada daquele item.

Ao reabrir o aplicativo, downloads em andamento ficam pausados; o usuário
seleciona Retomar. A pasta de compras é examinada na abertura e monitorada para
novos torrents. Arquivos inválidos ou ainda incompletos não entram na fila.

Somente o cartão com foco expande suas ações. Teclado: setas, Enter e Escape.
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

`download_store.dart` cuida da importação e do JSON; `aria2_engine.dart`, do RPC;
`downloads_controller.dart`, dos estados e ações; `download_card.dart`, de cada
cartão; `downloads_tela.dart`, da fila; `pad_navigation.dart`, do controle;
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
