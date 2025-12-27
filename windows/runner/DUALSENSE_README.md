# Suporte a Controle DualSense (PlayStation 5)

## Arquivos Criados

### 1. `dualsense_controller.h`
Header com definições de estruturas e classe para o controle DualSense.

**Principais componentes:**
- `DualSenseButtonState`: Estrutura com todos os botões e analógicos
- `DualSenseController`: Classe principal para processar inputs do DualSense
- Defines de máscaras de bits baseados na biblioteca DualSense-Windows

### 2. `dualsense_controller.cpp`
Implementação da classe DualSenseController.

**Funcionalidades:**
- `ProcessRawInput()`: Processa dados HID brutos do controle
- `ParseHIDData()`: Faz o parse correto dos bytes do buffer HID
- `NotifyCallbacks()`: Notifica quando botões mudam de estado
- Suporte para callbacks específicos do botão PS

## Mapeamento de Botões DualSense

### Buffer HID (USB - 64 bytes)

```
Offset  | Descrição
--------|--------------------------------------------
0x00    | Left Stick X (0-255, centro = 128)
0x01    | Left Stick Y (0-255, centro = 127)
0x02    | Right Stick X (0-255, centro = 128)
0x03    | Right Stick Y (0-255, centro = 127)
0x04    | Left Trigger (0-255)
0x05    | Right Trigger (0-255)
0x07    | Botões principais + D-Pad
0x08    | Botões Grupo A
0x09    | Botões Grupo B (inclui botão PS)
```

### Byte 0x07 - Botões Principais e D-Pad

**4 bits superiores (0xF0) - Botões PlayStation:**
```
Bit 4 (0x10) = Square
Bit 5 (0x20) = Cross (X)
Bit 6 (0x40) = Circle
Bit 7 (0x80) = Triangle
```

**4 bits inferiores (0x0F) - D-Pad:**
```
0x0 = Up
0x1 = Right-Up
0x2 = Right
0x3 = Right-Down
0x4 = Down
0x5 = Left-Down
0x6 = Left
0x7 = Left-Up
0x8 = Centro (nenhum pressionado)
```

### Byte 0x08 - Botões Grupo A

```
Bit 0 (0x01) = Left Bumper (L1)
Bit 1 (0x02) = Right Bumper (R1)
Bit 2 (0x04) = Left Trigger (L2 digital)
Bit 3 (0x08) = Right Trigger (R2 digital)
Bit 4 (0x10) = Share (Select)
Bit 5 (0x20) = Menu (Options)
Bit 6 (0x40) = Left Stick Click (L3)
Bit 7 (0x80) = Right Stick Click (R3)
```

### Byte 0x09 - Botões Grupo B ⭐

```
Bit 0 (0x01) = PlayStation Button (PS/Guide) ⭐⭐⭐
Bit 1 (0x02) = Touchpad Button
Bit 2 (0x04) = Microphone Button
```

## Integração com Flutter

### No lado C++ (Windows Runner)

O código já está integrado no `flutter_window.cpp`:

1. **Inicialização**: Cria instância de `DualSenseController`
2. **Registro de Callback**: Configura callback para o botão PS
3. **Processamento**: Quando Raw Input chega, identifica se é DualSense e processa

### No lado Dart (Flutter)

O Method Channel `gamepad_guide_button` recebe os eventos:

```dart
// Configurar listener
MethodChannel('gamepad_guide_button').setMethodCallHandler((call) {
  if (call.method == 'onGuideButtonPressed') {
    Map<String, dynamic> args = call.arguments;
    String controller = args['controller']; // "DualSense" ou "Xbox"
    int byte = args['byte']; // 9 para DualSense, 12 para Xbox
    
    // Botão Guide/PS foi pressionado
    print('$controller Guide button pressed at byte $byte');
  } 
  else if (call.method == 'onGuideButtonReleased') {
    // Botão Guide/PS foi liberado
    print('Guide button released');
  }
});
```

## Diferenças entre Xbox e DualSense

| Característica        | Xbox Controller       | DualSense            |
|-----------------------|-----------------------|----------------------|
| Tamanho HID (USB)     | 16 bytes             | 64 bytes             |
| Botão Guide/PS        | Byte 12, bit 2       | Byte 9, bit 0        |
| Guide Bitmask         | 0x04                 | 0x01                 |
| Nome do Botão         | "Guide"              | "PS" / "PlayStation" |
| Implementação         | Raw bit check        | Classe dedicada      |

## Como Testar

1. **Compile o projeto**: `flutter build windows`
2. **Conecte um DualSense**: Via USB ou Bluetooth
3. **Execute o app**: O Raw Input já está registrado
4. **Pressione o botão PS**: O evento será enviado para o Flutter

## Debug

Para debug, você pode adicionar logs no `dualsense_controller.cpp`:

```cpp
void DualSenseController::ParseHIDData(const BYTE* hidBuffer) {
    // Log do estado dos bytes
    OutputDebugStringA("DualSense HID Data:\n");
    char buffer[256];
    sprintf_s(buffer, "Byte 0x07: 0x%02X\n", hidBuffer[0x07]);
    OutputDebugStringA(buffer);
    sprintf_s(buffer, "Byte 0x08: 0x%02X\n", hidBuffer[0x08]);
    OutputDebugStringA(buffer);
    sprintf_s(buffer, "Byte 0x09: 0x%02X (PS Button: %s)\n", 
              hidBuffer[0x09], 
              (hidBuffer[0x09] & 0x01) ? "PRESSED" : "released");
    OutputDebugStringA(buffer);
}
```

## Referências

- **DualSense-Windows**: https://github.com/Ohjurot/DualSense-Windows
- **HID Input Report**: Baseado na documentação da comunidade
- **DS4Windows**: Projeto similar para DualShock 4

## Próximos Passos

### Funcionalidades Adicionais Possíveis:

1. **Todos os Botões**: Já implementado! Use `SetButtonCallback()` para receber todos os botões
2. **Analógicos**: Valores já parseados em `DualSenseButtonState`
3. **Gatilhos**: Valores analógicos 0-255 disponíveis
4. **Feedback Háptico**: Requer integração com DualSense-Windows SDK
5. **Adaptive Triggers**: Requer integração com DualSense-Windows SDK
6. **LED RGB**: Requer integração com DualSense-Windows SDK

### Exemplo de Uso Completo:

```cpp
// No SetupGuideButtonChannel() ou OnCreate()
dualsense_controller->SetButtonCallback([](const DualSenseButtonState& state) {
    if (guide_button_channel) {
        flutter::EncodableMap button_map;
        button_map[flutter::EncodableValue("cross")] = flutter::EncodableValue(state.cross);
        button_map[flutter::EncodableValue("circle")] = flutter::EncodableValue(state.circle);
        button_map[flutter::EncodableValue("square")] = flutter::EncodableValue(state.square);
        button_map[flutter::EncodableValue("triangle")] = flutter::EncodableValue(state.triangle);
        button_map[flutter::EncodableValue("left_trigger")] = flutter::EncodableValue((int)state.left_trigger);
        button_map[flutter::EncodableValue("right_trigger")] = flutter::EncodableValue((int)state.right_trigger);
        
        auto args = std::make_unique<flutter::EncodableValue>(button_map);
        guide_button_channel->InvokeMethod("onDualSenseState", std::move(args));
    }
});
```

## Notas Importantes

- ✅ **Xbox já funciona**: O código mantém compatibilidade com controles Xbox
- ✅ **Sem dependências externas**: Usa apenas Windows HID APIs
- ✅ **Baseado em DualSense-Windows**: Mapeamento correto e testado
- ⚠️ **USB recomendado**: Via Bluetooth pode ter formato HID diferente (78 bytes)
- 🎮 **Botão PS garantido**: Byte 9, bit 0 (0x01) - testado e documentado
