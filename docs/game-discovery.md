# Procurar jogos: leitura local e interferência de terceiros

A busca lê pastas, manifestos, atalhos e programas registrados no Windows. Não precisa de internet e não inicia os executáveis encontrados. A categoria **Outros** também pode incluir aplicativos, inclusive utilitários de rede; aparecer na lista não significa que o aplicativo foi executado.

A leitura de atalhos e do Registro agora utiliza APIs do Windows em workers Dart, sem iniciar PowerShell ou cmd. Atalhos são abertos em modo de leitura e consultados com `IShellLinkW.GetPath(SLGP_RAWPATH)`; não usamos `Resolve`, `ShellExecute` ou os argumentos dos atalhos. Uma busca vazia não inicia outra varredura automaticamente a cada reconstrução da tela. Falha em uma fonte de programas não impede consultar as fontes seguintes. Eventos de Pad são ignorados após escolher um item ou fechar a busca.

O teste nativo cria um atalho cujo programa escreveria um arquivo de marcação se fosse iniciado. A leitura repetida retorna seu caminho, preserva o atalho e não produz a marca. Outro teste confirma leitura de registros com acentos, tabulações e vírgulas em caminhos.

O relato de abertura repetida do ExitLag com uma confirmação é compatível com um conflito entre processos/atalhos ou foco de janelas, mas não estabelece sua causa. ExitLag não está instalado neste ambiente e o comportamento no PC do cliente não foi reproduzido. As alterações retiram os processos de shell da busca; não encerram, desativam ou modificam o ExitLag.

Se persistir no cliente, registrar o texto exato da confirmação e o instante: ao abrir **Procurar jogos**, ao selecionar um resultado ou ao escolher **Jogar**. São etapas distintas. Uma gravação que mostre a mensagem ajudará a distinguir instalação/reparo de aplicativo, aviso do ExitLag e problema de foco. Os logs `[GAMES_BUSCA]` identificam início, falhas nas fontes e término da varredura.

Referências: [GetPath do Windows](https://learn.microsoft.com/en-us/windows/win32/api/shobjidl_core/nf-shobjidl_core-ishelllinkw-getpath), [como o ExitLag detecta a abertura de um jogo](https://www.exitlag.com/knowledgebase/96?language=english).
