# V1 Launcher (Beta)

**V1 Launcher** é um *launcher* para PC inspirado na interface do PlayStation 5, projetado para substituir 99% do uso do mouse e teclado no Windows. Com ele, você pode navegar pelo seu sistema operacional de forma intuitiva e eficiente, sem depender dos métodos tradicionais de entrada.

## 🤝 Apoie o Projeto

Se você gostou do V1 Launcher e deseja apoiar seu desenvolvimento, considere fazer uma doação para ajudar a manter e aprimorar o projeto.

**Chave PIX para doações:** kionydb1@outlook.com

Toda contribuição é bem-vinda e ajudará a levar o V1 Launcher para o próximo nível!

## 🖥️ Sobre o Projeto

O V1 Launcher nasceu de uma necessidade pessoal e do desejo de criar uma nova forma de interação com o Windows. A proposta é permitir a locomoção total pelo sistema sem a necessidade do mouse ou teclado, proporcionando uma experiência fluida e moderna, semelhante à navegação em consoles como o PS5.

## 🔍 Funcionalidades Principais

- Navegação fluida e intuitiva, estilo PS5
- Controle quase total do Windows sem uso do mouse ou teclado
- Interface amigável e personalizável
- Otimizado para desempenho e praticidade

## 📌 Status do Projeto

Atualmente, o V1 Launcher está em **versão beta**, em constante evolução para melhorar a experiência do usuário e expandir suas funcionalidades.

## 📬 Contato

Para dúvidas, sugestões ou feedback, entre em contato através do e-mail: **kionydb1@outlook.com**

Obrigado por apoiar o V1 Launcher! 🚀


## ⚡ Scripts executados pelo sistema

- **disable_xbox_steam.ps1**: Desativa o atalho do botão Xbox para abrir a Xbox Game Bar e impede que o botão Xbox abra a Steam.

- **moovMouse.ahk**: Move o mouse para o canto da tela para simular detecção de movimento.
- **AutoHotkeyA32.exe**: Executa scripts de automação (AutoHotkey) usados pelo sistema.

## 🧩 Processos do launcher no Windows

O V1 Launcher utiliza o processo principal do aplicativo e alguns programas
auxiliares para baixar, preparar e abrir jogos. Eles aparecem no Gerenciador de
Tarefas conforme a função utilizada; não precisam estar todos ativos ao mesmo
tempo.

| Processo | Para que serve | Quando aparece |
|---|---|---|
| 🎮 **v1_game.exe** | É o launcher: reúne a interface, a navegação por controle, a biblioteca, a reprodução de mídia e o gerenciamento dos downloads. | Enquanto o aplicativo estiver em execução, inclusive quando estiver minimizado ou com a janela oculta. |
| 📥 **aria2c.exe** | É o motor que baixa o conteúdo dos jogos por torrent. O launcher controla início, pausa, continuação e cancelamento por uma conexão local. A configuração permite até **5 downloads simultâneos** no mesmo processo. | Ao iniciar um download na área **Downloads**. Pode permanecer ativo enquanto o launcher gerencia a sessão, mesmo após mudar de tela. |
| 🌐 **msedgewebview2.exe** | Executa o navegador interno que abre a etapa oficial do site para obter o arquivo `.torrent`, incluindo a verificação solicitada pelo próprio site. O WebView2 pode utilizar vários processos para renderização, rede e GPU. | Ao utilizar o painel de download da loja. Outros aplicativos também usam WebView2: nem todo processo com esse nome pertence ao V1 Launcher. |
| 📦 **V1Unarc.exe** | Auxilia na verificação de integridade e na extração dos arquivos dos repacks compatíveis com o protocolo de preparação do launcher. | Durante a verificação ou extração automática, após concluir o download e solicitar a preparação do jogo. |
| 🗂️ **innoextract.exe** | Extrai os arquivos necessários de instaladores Inno Setup durante a preparação do repack. | Na etapa de preparação que precisa obter esses arquivos do instalador. Não é o motor do download por torrent. |
| 🛠️ **V1SilentInstall.exe / setup.exe** | O auxiliar `V1SilentInstall.exe` coordena a instalação silenciosa; `setup.exe` é o instalador original do jogo. O instalador também pode iniciar auxiliares próprios. | Quando a opção de **instalação silenciosa** é utilizada. Essa opção é um fluxo específico de instalação, separado da extração direta. |
| ⚙️ **powershell.exe / cmd.exe** | Executam comandos pontuais de integração com o Windows, como localizar arquivos e atalhos, consultar informações do sistema, aplicar configurações e abrir programas. | Durante operações que precisam desses comandos. Também podem aparecer por causa do desenvolvimento do projeto ou de outros aplicativos. |
| 🕹️ **Executável do jogo** | É o programa do jogo cadastrado na biblioteca e iniciado pelo launcher. Seu nome depende do título instalado. | Quando o usuário escolhe **Jogar**. É um processo próprio do jogo, separado do launcher. |

### 🔄 Como esses processos entram no fluxo

1. **Abrir o launcher:** inicia `v1_game.exe`, que apresenta a biblioteca e recebe os comandos do controle.
2. **Comprar na Loja Interna:** o navegador WebView2 obtém o arquivo pequeno `.torrent`. Depois de recebê-lo e registrá-lo, o jogo aparece na área **Downloads**, pronto para iniciar.
3. **Iniciar em Downloads:** o `aria2c.exe` baixa o conteúdo do jogo para o destino escolhido. Um único processo pode gerenciar vários downloads independentes.
4. **Preparar o jogo:** quando necessário, entram os auxiliares de verificação, extração ou instalação. Os programas utilizados dependem do protocolo compatível e da opção escolhida.
5. **Jogar:** o launcher abre o executável identificado e cadastrado para aquele jogo.

### ⏳ Downloads em segundo plano

Mudar de aba ou sair da tela **Downloads** não encerra o motor de torrent. O
gerenciamento fica no controlador do aplicativo, permitindo acompanhar a
transferência ao retornar à tela.

**Baixar o `.torrent` e baixar o jogo são etapas diferentes:** a loja recebe o
arquivo que descreve a transferência; a área **Downloads** usa esse arquivo
para iniciar o download do conteúdo pelo aria2.

O encerramento normal do gerenciador prevê salvar o estado, pausar as
transferências ativas e solicitar a finalização do aria2. **Ocultar ou minimizar
a janela não significa encerrar o aplicativo.**

### 💻 Processos do desenvolvimento: Dart e Codex

- **Dart — `dart.exe`, `dartvm.exe` e `dartaotruntime.exe`:** pertencem às ferramentas do Flutter/Dart usadas na análise, compilação, testes e execução em desenvolvimento. Podem existir várias instâncias por causa do editor e das tarefas em andamento. O launcher distribuído em **Release** normalmente não precisa iniciar esses executáveis separados.
- **Codex — `codex.exe`, `codex-command-runner` e `codex-windows-sandbox-service`:** pertencem ao assistente de desenvolvimento e à execução dos comandos utilizados para trabalhar no projeto. **Não são dependências do V1 Launcher** e não são necessários para o usuário executar a versão distribuída.
- **MediaKit e SoLoud:** são bibliotecas utilizadas pelo aplicativo para vídeo e áudio. Seu uso não exige um processo separado chamado `media_kit.exe` ou `soloud.exe`; parte do trabalho acontece em threads dentro dos processos que carregam essas bibliotecas.

🔎 **O nome do processo, sozinho, não comprova sua origem.** Para identificar
uma instância específica, confira também o caminho do executável e o processo
que a iniciou. A quantidade de processos pode variar conforme o editor, os
aplicativos abertos e as tarefas do launcher.
