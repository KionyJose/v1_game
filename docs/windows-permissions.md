# 🔐 Permissões e instalação do V1 Launcher no Windows

## 🧭 Na abertura

O launcher verifica escrita na pasta privada de dados, copia configurações e biblioteca antigas quando necessário, verifica `aria2c.exe` no pacote e consulta o WebView2. O relatório fica em `%LOCALAPPDATA%\V1 Launcher\startup-check.json`. Problemas opcionais mostram um aviso navegável pelo Pad. Falha de acesso à biblioteca mostra uma tela de recuperação com **Verificar novamente**, evitando abrir uma biblioteca vazia e gravar por cima dos dados antigos.

Os dados passam de Documentos públicos para `%LOCALAPPDATA%\V1 Launcher`. Os arquivos antigos permanecem intactos. Cada conta do Windows mantém sua própria biblioteca. Imagens novas vão para `FundoGamesV1` nessa pasta; os caminhos absolutos das imagens antigas continuam válidos.

## 🛡️ O que cada funcionalidade precisa

| Funcionalidade | Acesso necessário | Tratamento |
|---|---|---|
| Biblioteca, configurações e imagens | Leitura e escrita nos dados do usuário | Pasta privada; nenhuma permissão de armazenamento Android no Windows |
| Loja, notícias, vídeos e trailers | Internet de saída; runtimes e DLLs de mídia do Release | Distribuir a pasta Release completa; não basta o `.exe` |
| Navegador de downloads | WebView2 Runtime e perfil gravável | Perfil privado; página HTTPS validada; solicitações de câmera, microfone e outras permissões web negadas |
| Arquivos `.torrent` | Escrita em Downloads/games torrent compra | Escrita testada antes de salvar |
| Download dos jogos | Escrita em `DISCO:\V1 Jogos\PASTA DO JOGO` | Verificação ao escolher o disco e ao iniciar/retomar; erro orienta liberar acesso ou escolher outro disco |
| aria2 | Internet, arquivos do jogo e dados DHT privados | RPC somente em loopback com token; estado DHT fora da pasta de instalação |
| Extração | Leitura dos arquivos do repack e escrita no destino | Verificação de escrita antes de preparar arquivos e na pasta de saída |
| Instalação silenciosa do jogo | Pode precisar de administrador | Somente o auxiliar da instalação usa UAC quando necessário; a confirmação do Windows continua obrigatória |
| Pad, teclado interno, sons e volume | Acesso às APIs do Windows e dispositivos presentes | Não requer câmera, microfone ou acesso administrativo geral |
| Comandos enviados para outros aplicativos | Mesmo nível de privilégio do aplicativo de destino | Windows pode impedir injetar comandos em programas executados como administrador |
| Atalhos e início com Windows | Pastas do usuário e chave HKCU | Nada em HKLM; executável de inicialização entre aspas para suportar espaços |
| Configuração do Guide/Game Bar existente | Chaves HKCU do usuário | Script empacotado, caminho absoluto e diagnóstico de falhas; não altera configuração da Steam |

O executável declara `asInvoker` e `uiAccess=false`: funciona com os privilégios do usuário. A capacidade UWP `documentsLibrary` foi removida do manifesto Win32, pois não concede acesso a pastas nesse tipo de aplicativo. Não há exclusões de antivírus, ACLs globais de escrita nem abertura do RPC para a rede.

Firewall, proteção contra ransomware e políticas corporativas continuam valendo. Torrent pode receber menos conexões de entrada se o firewall as bloquear; isso não significa falta de internet. Se o Windows perguntar, a permissão de rede deve corresponder ao aplicativo e à rede em uso. Não criamos uma regra ampla automaticamente.

## 📦 Preparar e distribuir

Na máquina de desenvolvimento, antes do build:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/windows/Prepare-ReleasePrerequisites.ps1
flutter build windows --release
```

O preparo baixa apenas instaladores oficiais Microsoft e valida a assinatura Authenticode. Não executa os instaladores na máquina do desenvolvedor. URLs, versões e SHA-256 ficam em `packages.json`. O build copia para `Release\prerequisites`:

- `vc_redist.x64.exe` — Visual C++ compatível com o executável x64;
- `MicrosoftEdgeWebview2Setup.exe` — bootstrapper Evergreen, precisa de internet no cliente;
- `Install-Prerequisites.ps1` e esta documentação.

O instalador deve executar o script de dependências **antes de abrir o launcher**, na conta do cliente:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "CAMINHO DO APP\prerequisites\Install-Prerequisites.ps1"
```

`-CheckOnly` consulta o estado sem instalar nada. Sem esse parâmetro, instala apenas o que falta: Visual C++ solicita UAC; WebView2 utiliza o escopo disponível para o usuário que executou o script. Assinaturas inválidas interrompem a operação. Cancelamento de UAC e falha de instalação devem interromper a abertura do launcher no instalador. Código 3010 do Visual C++ indica necessidade de reiniciar.

Copie **todo** `build\windows\x64\runner\Release`, incluindo `data`, DLLs, licenças, `aria2c.exe` e `prerequisites`. Instalar em Program Files é permitido quando o instalador tem autorização; o launcher não grava seus dados lá. Um instalador por usuário pode usar `%LOCALAPPDATA%\Programs\V1 Launcher`.

Para distribuição totalmente offline, substitua o bootstrapper pelo instalador Evergreen Standalone oficial e adapte o script. O bootstrapper incluído não é offline. Testar em uma conta padrão e em uma máquina limpa continua necessário: o ambiente de desenvolvimento já possui runtimes e não reproduz todas as políticas do cliente.

Fontes: [manifestos Win32](https://learn.microsoft.com/en-us/windows/win32/sbscs/application-manifests), [distribuição do WebView2](https://learn.microsoft.com/en-us/microsoft-edge/webview2/concepts/distribution), [Visual C++ Redistributable](https://learn.microsoft.com/en-us/cpp/windows/latest-supported-vc-redist).
