# 📚 Estrutura do Código - Sistema de Captura de Botões

## 🎯 Visão Geral

Este sistema captura os botões Guide/PS dos controles Xbox e DualSense e envia para o Flutter.

---

## 📁 Arquitetura de Arquivos

```
windows/runner/
├── flutter_window.h          → Declaração dos métodos
├── flutter_window.cpp        → Implementação (REFATORADO)
├── dualsense_controller.h    → Controlador DualSense
└── dualsense_controller.cpp  → Lógica do DualSense
```

---

## 🔄 Fluxo de Comunicação

```
WINDOWS C++                           FLUTTER DART
═══════════════════════════════════════════════════════════

1. WM_INPUT (Windows)
        ↓
2. ProcessarEntradaBrutaControle()
        ↓
   ┌────────────────────┐
   │  É Xbox?           │──→ ProcessarControleXbox()
   │  É DualSense?      │──→ ProcessarControleDualSense()
   └────────────────────┘
        ↓
3. EnviarBotaoGuideParaFlutter()
        ↓
4. canal_botao_guide.InvokeMethod()
        ║
        ║ (Method Channel)
        ║
        ↓
5. bruta.dart → _handleMethodCall()
        ↓
6. onGuideButton?.call('GUIDE')
        ↓
7. SUA APLICAÇÃO FLUTTER
```

---

## 🛠️ Métodos Principais (flutter_window.cpp)

### 📌 **Configuração**

#### `ConfigurarCanalComunicacaoFlutter()`
- **O que faz:** Cria o canal "gamepad_guide_button" entre C++ e Flutter
- **Quando é chamado:** No `OnCreate()` (inicialização da janela)
- **Envia para:** Ninguém (apenas configura)
- **Recebe de:** Ninguém (setup interno)

#### `RegistrarEntradaBrutaGamepad()`
- **O que faz:** Registra o Windows Raw Input para receber dados de gamepads
- **Quando é chamado:** Pelo Flutter via `registerRawInput`
- **Envia para:** Windows (RegisterRawInputDevices)
- **Recebe de:** Flutter (chamada de método)

---

### 📥 **Processamento de Entrada**

#### `ProcessarEntradaBrutaControle(LPARAM lparam)`
- **O que faz:** Recebe mensagem WM_INPUT e identifica tipo de controle
- **Quando é chamado:** Toda vez que Windows envia WM_INPUT
- **Envia para:** 
  - `ProcessarControleXbox()` se for Xbox
  - `ProcessarControleDualSense()` se for DualSense
- **Recebe de:** Windows (via MessageHandler)

#### `ProcessarControleXbox(BYTE* dados, DWORD tamanho)`
- **O que faz:** Detecta botão Guide do controle Xbox
- **Quando é chamado:** Quando `ProcessarEntradaBrutaControle` detecta Xbox
- **Envia para:** `EnviarBotaoGuideParaFlutter("Xbox", 12, estado)`
- **Recebe de:** `ProcessarEntradaBrutaControle()`
- **Dados processados:**
  - Byte 12, bit 0x04 = Guide Button

#### `ProcessarControleDualSense(BYTE* dados, DWORD tamanho)`
- **O que faz:** 
  1. Filtra mudanças de botões digitais (ignora analógicos)
  2. Envia dados brutos para debug
  3. Configura callback do botão PS (uma vez)
  4. Processa dados no DualSenseController
- **Quando é chamado:** Quando `ProcessarEntradaBrutaControle` detecta DualSense
- **Envia para:** 
  - `EnviarDadosBrutosParaFlutter()` (para debug)
  - `controlador_dualsense->ProcessRawInput()` (processamento interno)
- **Recebe de:** `ProcessarEntradaBrutaControle()`
- **Dados processados:**
  - Byte 7: Square, X, Circle, Triangle + D-Pad
  - Byte 8: L1, R1, L2, R2, Share, Options, L3, R3
  - Byte 9: PS, Touchpad, Mic

---

### 📤 **Envio para Flutter**

#### `EnviarBotaoGuideParaFlutter(tipo, byte, pressionado)`
- **O que faz:** Envia evento de botão Guide/PS para Flutter
- **Quando é chamado:** 
  - Por `ProcessarControleXbox()` (Xbox)
  - Por `ConfigurarCallbackBotaoPS()` (DualSense)
- **Envia para:** Flutter via método:
  - `"onGuideButtonPressed"` (quando pressionado)
  - `"onGuideButtonReleased"` (quando solto)
- **Recebe de:** Métodos de processamento
- **Dados enviados:**
  ```cpp
  {
    "controller": "Xbox" ou "DualSense",
    "byte": 12 (Xbox) ou 9 (DualSense)
  }
  ```

#### `EnviarDadosBrutosParaFlutter(byte7, byte8, byte9)`
- **O que faz:** Envia bytes brutos do DualSense para debug
- **Quando é chamado:** Por `ProcessarControleDualSense()` quando botões mudam
- **Envia para:** Flutter via método `"onDualSenseRawData"`
- **Recebe de:** `ProcessarControleDualSense()`
- **Dados enviados:**
  ```cpp
  {
    "byte7": valor do byte 7,
    "byte8": valor do byte 8,
    "byte9": valor do byte 9
  }
  ```

---

### 🔔 **Callbacks**

#### `ConfigurarCallbackBotaoPS()`
- **O que faz:** Registra lambda que será chamada quando botão PS mudar
- **Quando é chamado:** Na primeira vez que DualSense envia dados
- **Envia para:** `canal_botao_guide` (Flutter)
- **Recebe de:** `dualsense_controller->NotifyCallbacks()` (interno)
- **Lambda registrada:**
  ```cpp
  [](bool pressionado) {
    // Chamada quando PS button muda de estado
    EnviarBotaoGuideParaFlutter("DualSense", 9, pressionado);
  }
  ```

---

## 🔍 Rastreamento de Dados

### **XBOX:**
```
WM_INPUT → dados[12] & 0x04
    ↓
Estado mudou?
    ↓
EnviarBotaoGuideParaFlutter("Xbox", 12, true/false)
    ↓
Flutter: onGuideButtonPressed/Released
```

### **DUALSENSE:**
```
WM_INPUT → dados[0-63]
    ↓
ProcessarControleDualSense()
    ↓
controlador_dualsense.ProcessRawInput()
    ↓
ParseHIDData() → extrai botões
    ↓
NotifyCallbacks() → detecta mudança PS
    ↓
Lambda callback() → disparado
    ↓
EnviarBotaoGuideParaFlutter("DualSense", 9, true/false)
    ↓
Flutter: onGuideButtonPressed/Released
```

---

## 📊 Variáveis Globais

```cpp
static std::unique_ptr<flutter::MethodChannel<>> canal_botao_guide;
```
- **Propósito:** Canal de comunicação C++ ↔ Flutter
- **Usado por:** Todos os métodos EnviarXParaFlutter()

```cpp
static std::unique_ptr<DualSenseController> controlador_dualsense;
```
- **Propósito:** Gerencia estado do controle DualSense
- **Usado por:** ProcessarControleDualSense()

---

## 🎮 Formato dos Bytes (DualSense)

```
Byte 7: [TRIANGLE|CIRCLE|X|SQUARE|DPAD_3|DPAD_2|DPAD_1|DPAD_0]
Byte 8: [R3|L3|OPTIONS|SHARE|R2|L2|R1|L1]
Byte 9: [--|--|--|--|--|MIC|TOUCH|PS]
         7  6  5  4  3   2    1     0  (bit positions)
```

### Exemplo:
```
Botão PS pressionado:
byte9 = 0x01 (binário: 00000001)
        Bit 0 = 1 → PS ativo
```

---

## 💡 Nomenclatura em Português

| Antes (Inglês)           | Depois (Português)                   |
|--------------------------|--------------------------------------|
| `guide_button_channel`   | `canal_botao_guide`                  |
| `dualsense_controller`   | `controlador_dualsense`              |
| `SetupGuideButtonChannel`| `ConfigurarCanalComunicacaoFlutter`  |
| `ProcessRawInput`        | `ProcessarEntradaBrutaControle`      |
| `SendToFlutter`          | `EnviarBotaoGuideParaFlutter`        |
| `ConfigureCallback`      | `ConfigurarCallbackBotaoPS`          |

---

## 🚀 Como Testar

1. **Compile o projeto:**
   ```bash
   flutter build windows
   ```

2. **Abra Output do Visual Studio** (Tools → Output)

3. **Conecte o controle e pressione botão PS/Guide**

4. **Você verá:**
   ```
   ✓ Raw Input registrado com sucesso
   [DUALSENSE] Botão PS PRESSIONADO
   ✓ Callback do botão PS configurado
   ```

5. **No Flutter (bruta.dart) verá:**
   ```
   🎮 Botão Guide DETECTADO!
      Controller: DualSense | Byte Index: 9
      ✅ PlayStation (DualSense) - PS Button
   ```

---

## 📝 Checklist de Manutenção

- [ ] Todos os métodos têm nomes em português?
- [ ] Cada método tem um propósito único e claro?
- [ ] Comentários explicam **POR QUE**, não **O QUE**?
- [ ] Logs de debug em pontos críticos?
- [ ] Variáveis `static` documentadas?
- [ ] Fluxo de dados está claro?

---

**Última atualização:** 27/12/2025
**Autor:** Refatoração Senior Developer
