#ifndef RUNNER_DUALSENSE_CONTROLLER_H_
#define RUNNER_DUALSENSE_CONTROLLER_H_

#include <windows.h>
#include <cstdint>
#include <string>
#include <functional>

// Estrutura para o estado dos botões do DualSense
struct DualSenseButtonState {
    // Botões principais (buttonsAndDpad)
    bool square = false;
    bool cross = false;
    bool circle = false;
    bool triangle = false;
    
    // D-Pad
    bool dpad_left = false;
    bool dpad_right = false;
    bool dpad_up = false;
    bool dpad_down = false;
    
    // Botões Grupo A
    bool left_bumper = false;
    bool right_bumper = false;
    bool left_trigger_button = false;
    bool right_trigger_button = false;
    bool select_button = false;  // Share
    bool menu_button = false;
    bool left_stick_button = false;
    bool right_stick_button = false;
    
    // Botões Grupo B (mais importantes)
    bool ps_button = false;  // Botão PS/Guide
    bool touchpad_button = false;
    bool mic_button = false;
    
    // Analógicos
    int8_t left_stick_x = 0;
    int8_t left_stick_y = 0;
    int8_t right_stick_x = 0;
    int8_t right_stick_y = 0;
    
    // Gatilhos analógicos
    uint8_t left_trigger = 0;
    uint8_t right_trigger = 0;
};

// Defines para máscaras de bits (baseado em DualSense-Windows oficial)
// Byte 0x07 - 4 bits superiores são botões PlayStation
#define DS_BTX_SQUARE     0x10  // Bit 4
#define DS_BTX_CROSS      0x20  // Bit 5  
#define DS_BTX_CIRCLE     0x40  // Bit 6
#define DS_BTX_TRIANGLE   0x80  // Bit 7

// Byte 0x07 - 4 bits inferiores são D-Pad (valores de 0x0 a 0xF)
// D-Pad usa valores absolutos, não máscaras de bits individuais

#define DS_BTN_A_LEFT_BUMPER      0x01
#define DS_BTN_A_RIGHT_BUMPER     0x02
#define DS_BTN_A_LEFT_TRIGGER     0x04
#define DS_BTN_A_RIGHT_TRIGGER    0x08
#define DS_BTN_A_SELECT           0x10
#define DS_BTN_A_MENU             0x20
#define DS_BTN_A_LEFT_STICK       0x40
#define DS_BTN_A_RIGHT_STICK      0x80

#define DS_BTN_B_PS_BUTTON        0x01  // Botão PlayStation/Guide
#define DS_BTN_B_PAD_BUTTON       0x02
#define DS_BTN_B_MIC_BUTTON       0x04

class DualSenseController {
public:
    DualSenseController();
    ~DualSenseController();
    
    // Callback para quando o botão PS é pressionado/liberado
    using PSButtonCallback = std::function<void(bool pressed)>;
    using ButtonCallback = std::function<void(const DualSenseButtonState& state)>;
    
    void SetPSButtonCallback(PSButtonCallback callback);
    void SetButtonCallback(ButtonCallback callback);
    
    // Processa dados HID brutos do DualSense
    void ProcessRawInput(const BYTE* rawData, DWORD dataSize);
    
    // Obtém o estado atual dos botões
    const DualSenseButtonState& GetCurrentState() const { return current_state_; }
    
    // Verifica se é um controle DualSense pelo tamanho do buffer HID
    static bool IsDualSenseController(DWORD dataSize);
    
private:
        void ParseHIDData(const BYTE* hidBuffer, DWORD dataSize);
        void ParseHIDDataUSB(const BYTE* hidBuffer);
        void ParseHIDDataBluetooth(const BYTE* hidBuffer);
    void NotifyCallbacks();
    
    DualSenseButtonState current_state_;
    DualSenseButtonState previous_state_;
    
    PSButtonCallback ps_button_callback_;
    ButtonCallback button_callback_;
};

#endif  // RUNNER_DUALSENSE_CONTROLLER_H_
