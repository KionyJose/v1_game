# 🎮 Como Usar Todos os Botões do DualSense

## 1. Inicializar (no main.dart ou initState)

```dart
await RawInputGamepad.inicializar();
```

## 2. Escutar TODOS os botões

```dart
RawInputGamepad.escutarBotoesDualSense((botao, pressionado) {
  debugPrint('$botao ${pressionado ? "↓ PRESSIONADO" : "↑ SOLTO"}');
  
  switch(botao) {
    // Botões de Face
    case 'square':    // □ Quadrado
      if (pressionado) {
        // Ação ao pressionar Quadrado
      }
      break;
      
    case 'cross':     // ✕ X
      if (pressionado) {
        // Ação ao pressionar X
      }
      break;
      
    case 'circle':    // ○ Círculo
      if (pressionado) {
        // Ação ao pressionar Círculo
      }
      break;
      
    case 'triangle':  // △ Triângulo
      if (pressionado) {
        // Ação ao pressionar Triângulo
      }
      break;
    
    // Shoulders e Gatilhos
    case 'L1':        // L1 (bumper esquerdo)
    case 'R1':        // R1 (bumper direito)
    case 'L2':        // L2 (gatilho esquerdo)
    case 'R2':        // R2 (gatilho direito)
      break;
    
    // Analógicos (clique)
    case 'L3':        // L3 (clicar analógico esquerdo)
    case 'R3':        // R3 (clicar analógico direito)
      break;
    
    // Botões do meio
    case 'share':     // Share (esquerda)
    case 'options':   // Options (direita)
    case 'PS':        // Botão PlayStation (centro)
      break;
    
    // Outros
    case 'touchpad':  // Clicar no touchpad
    case 'mic':       // Botão Mute do microfone
      break;
    
    // D-Pad
    case 'dpad_up':   // D-Pad para cima
    case 'dpad_down': // D-Pad para baixo
    case 'dpad_left': // D-Pad para esquerda
    case 'dpad_right':// D-Pad para direita
      break;
  }
});
```

## 3. Todos os botões disponíveis

| Botão       | Nome        | Descrição                    |
|-------------|-------------|------------------------------|
| `square`    | Quadrado    | □ Botão face superior        |
| `cross`     | X           | ✕ Botão face inferior        |
| `circle`    | Círculo     | ○ Botão face direito         |
| `triangle`  | Triângulo   | △ Botão face esquerdo        |
| `L1`        | L1          | Shoulder esquerdo            |
| `R1`        | R1          | Shoulder direito             |
| `L2`        | L2          | Gatilho esquerdo             |
| `R2`        | R2          | Gatilho direito              |
| `L3`        | L3          | Analógico esquerdo clicado   |
| `R3`        | R3          | Analógico direito clicado    |
| `share`     | Share       | Botão Share (esquerda)       |
| `options`   | Options     | Botão Options (direita)      |
| `PS`        | PlayStation | Botão PS central             |
| `touchpad`  | Touchpad    | Pressionar touchpad          |
| `mic`       | Mic Mute    | Botão mute do microfone      |
| `dpad_up`   | D-Pad ↑     | Direcional para cima         |
| `dpad_down` | D-Pad ↓     | Direcional para baixo        |
| `dpad_left` | D-Pad ←     | Direcional para esquerda     |
| `dpad_right`| D-Pad →     | Direcional para direita      |

## 4. Ver logs no DebugView

Todos os eventos aparecem no **DebugView** (sysinternals):

```
[DUALSENSE] cross PRESSIONADO
[DUALSENSE] cross SOLTO
[DUALSENSE] PS PRESSIONADO
```

E no console do Flutter:

```
🎮 DualSense: cross PRESSIONADO
🎮 DualSense: cross SOLTO
```
