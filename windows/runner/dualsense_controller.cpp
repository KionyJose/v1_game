#include "dualsense_controller.h"
#include <cstring>
#include <algorithm>

DualSenseController::DualSenseController() {
    std::memset(&current_state_, 0, sizeof(DualSenseButtonState));
    std::memset(&previous_state_, 0, sizeof(DualSenseButtonState));
}

DualSenseController::~DualSenseController() {
}

void DualSenseController::SetPSButtonCallback(PSButtonCallback callback) {
    ps_button_callback_ = callback;
}

void DualSenseController::SetButtonCallback(ButtonCallback callback) {
    button_callback_ = callback;
}

bool DualSenseController::IsDualSenseController(DWORD dataSize) {
    // DualSense via USB geralmente tem 64 bytes
    // DualSense via Bluetooth pode ter tamanhos diferentes (78 bytes)
    return (dataSize == 64 || dataSize == 78);
}

void DualSenseController::ProcessRawInput(const BYTE* rawData, DWORD dataSize) {
    if (!rawData || dataSize < 10) {
        return;
    }
    
    // Salva estado anterior
    previous_state_ = current_state_;
    
    // Parse dos dados HID
    ParseHIDData(rawData, dataSize);
    
    // Notifica callbacks se houver mudanças
    NotifyCallbacks();
}

// Seleciona o parser correto conforme o tamanho do buffer
void DualSenseController::ParseHIDData(const BYTE* hidBuffer, DWORD dataSize) {
    if (dataSize == 64) {
        ParseHIDDataUSB(hidBuffer);
    } else if (dataSize == 78) {
        ParseHIDDataBluetooth(hidBuffer);
    } else {
        // fallback para USB
        ParseHIDDataUSB(hidBuffer);
    }
}

// Parser para dados USB (cabeado)
void DualSenseController::ParseHIDDataUSB(const BYTE* hidBuffer) {
    char debugBuffer[1024];
    sprintf_s(debugBuffer, "\n========== DUALSENSE HID DEBUG ==========\n");
    OutputDebugStringA(debugBuffer);
    sprintf_s(debugBuffer, "Bytes 0x00-0x0F: ");
    for (int i = 0; i < 16 && i < 64; i++) {
        char temp[8];
        sprintf_s(temp, "%02X ", hidBuffer[i]);
        strcat_s(debugBuffer, temp);
    }
    strcat_s(debugBuffer, "\n");
    OutputDebugStringA(debugBuffer);
    sprintf_s(debugBuffer, "Byte 0x07 (Buttons+DPad): 0x%02X\n", hidBuffer[0x07]);
    OutputDebugStringA(debugBuffer);
    sprintf_s(debugBuffer, "Byte 0x08 (Buttons A)    : 0x%02X\n", hidBuffer[0x08]);
    OutputDebugStringA(debugBuffer);
    sprintf_s(debugBuffer, "Byte 0x09 (Buttons B-PS) : 0x%02X <-- PS Button\n", hidBuffer[0x09]);
    OutputDebugStringA(debugBuffer);
    sprintf_s(debugBuffer, "=========================================\n\n");
    OutputDebugStringA(debugBuffer);

    // Analógicos (converte de unsigned para signed)
    if (hidBuffer[0x00] != 0xFF) {
        current_state_.left_stick_x = (int8_t)(hidBuffer[0x00] - 128);
        current_state_.left_stick_y = (int8_t)((hidBuffer[0x01] - 127) * -1);
        current_state_.right_stick_x = (int8_t)(hidBuffer[0x02] - 128);
        current_state_.right_stick_y = (int8_t)((hidBuffer[0x03] - 127) * -1);
    }

    current_state_.left_trigger = hidBuffer[0x04];
    current_state_.right_trigger = hidBuffer[0x05];

    uint8_t buttonsAndDpad = hidBuffer[0x07];
    current_state_.square = (buttonsAndDpad & DS_BTX_SQUARE) != 0;
    current_state_.cross = (buttonsAndDpad & DS_BTX_CROSS) != 0;
    current_state_.circle = (buttonsAndDpad & DS_BTX_CIRCLE) != 0;
    current_state_.triangle = (buttonsAndDpad & DS_BTX_TRIANGLE) != 0;

    uint8_t dpad = buttonsAndDpad & 0x0F;
    current_state_.dpad_left = false;
    current_state_.dpad_right = false;
    current_state_.dpad_up = false;
    current_state_.dpad_down = false;
    switch (dpad) {
        case 0x0: current_state_.dpad_up = true; break;
        case 0x1: current_state_.dpad_right = true; current_state_.dpad_up = true; break;
        case 0x2: current_state_.dpad_right = true; break;
        case 0x3: current_state_.dpad_right = true; current_state_.dpad_down = true; break;
        case 0x4: current_state_.dpad_down = true; break;
        case 0x5: current_state_.dpad_left = true; current_state_.dpad_down = true; break;
        case 0x6: current_state_.dpad_left = true; break;
        case 0x7: current_state_.dpad_left = true; current_state_.dpad_up = true; break;
        default: break;
    }

    uint8_t buttonsA = hidBuffer[0x08];
    current_state_.left_bumper = (buttonsA & DS_BTN_A_LEFT_BUMPER) != 0;
    current_state_.right_bumper = (buttonsA & DS_BTN_A_RIGHT_BUMPER) != 0;
    current_state_.left_trigger_button = (buttonsA & DS_BTN_A_LEFT_TRIGGER) != 0;
    current_state_.right_trigger_button = (buttonsA & DS_BTN_A_RIGHT_TRIGGER) != 0;
    current_state_.select_button = (buttonsA & DS_BTN_A_SELECT) != 0;
    current_state_.menu_button = (buttonsA & DS_BTN_A_MENU) != 0;
    current_state_.left_stick_button = (buttonsA & DS_BTN_A_LEFT_STICK) != 0;
    current_state_.right_stick_button = (buttonsA & DS_BTN_A_RIGHT_STICK) != 0;

    uint8_t buttonsB = hidBuffer[0x09];
    current_state_.ps_button = (buttonsB & DS_BTN_B_PS_BUTTON) != 0;
    current_state_.touchpad_button = (buttonsB & DS_BTN_B_PAD_BUTTON) != 0;
    current_state_.mic_button = (buttonsB & DS_BTN_B_MIC_BUTTON) != 0;

    if (buttonsA != 0 || buttonsB != 0) {
        sprintf_s(debugBuffer, "[BOTÕES] A=0x%02X (L1:%d R1:%d L2:%d R2:%d Share:%d Options:%d L3:%d R3:%d) | B=0x%02X (PS:%d Touch:%d Mic:%d)\n",
                  buttonsA,
                  current_state_.left_bumper,
                  current_state_.right_bumper,
                  current_state_.left_trigger_button,
                  current_state_.right_trigger_button,
                  current_state_.select_button,
                  current_state_.menu_button,
                  current_state_.left_stick_button,
                  current_state_.right_stick_button,
                  buttonsB,
                  current_state_.ps_button,
                  current_state_.touchpad_button,
                  current_state_.mic_button);
        OutputDebugStringA(debugBuffer);
    }
}

// Parser para dados Bluetooth
void DualSenseController::ParseHIDDataBluetooth(const BYTE* hidBuffer) {
    // O report Bluetooth do DualSense tem um header extra de 2 bytes:
    // Byte 0: Report ID (0x31)
    // Byte 1: Contador de sequência
    // Os dados reais começam no offset 2
    const BYTE* data = hidBuffer + 2;

    char debugBuffer[1024];
    sprintf_s(debugBuffer, "\n========== DUALSENSE HID DEBUG (BT) ==========\n");
    OutputDebugStringA(debugBuffer);
    sprintf_s(debugBuffer, "Bytes 0x00-0x0F: ");
    for (int i = 0; i < 16 && i < 76; i++) {
        char temp[8];
        sprintf_s(temp, "%02X ", data[i]);
        strcat_s(debugBuffer, temp);
    }
    strcat_s(debugBuffer, "\n");
    OutputDebugStringA(debugBuffer);

    if (data[0x00] != 0xFF) {
        current_state_.left_stick_x = (int8_t)(data[0x00] - 128);
        current_state_.left_stick_y = (int8_t)((data[0x01] - 127) * -1);
        current_state_.right_stick_x = (int8_t)(data[0x02] - 128);
        current_state_.right_stick_y = (int8_t)((data[0x03] - 127) * -1);
    }
    current_state_.left_trigger = data[0x04];
    current_state_.right_trigger = data[0x05];

    uint8_t buttonsAndDpad = data[0x07];
    current_state_.square = (buttonsAndDpad & DS_BTX_SQUARE) != 0;
    current_state_.cross = (buttonsAndDpad & DS_BTX_CROSS) != 0;
    current_state_.circle = (buttonsAndDpad & DS_BTX_CIRCLE) != 0;
    current_state_.triangle = (buttonsAndDpad & DS_BTX_TRIANGLE) != 0;

    uint8_t dpad = buttonsAndDpad & 0x0F;
    current_state_.dpad_left = false;
    current_state_.dpad_right = false;
    current_state_.dpad_up = false;
    current_state_.dpad_down = false;
    switch (dpad) {
        case 0x0: current_state_.dpad_up = true; break;
        case 0x1: current_state_.dpad_right = true; current_state_.dpad_up = true; break;
        case 0x2: current_state_.dpad_right = true; break;
        case 0x3: current_state_.dpad_right = true; current_state_.dpad_down = true; break;
        case 0x4: current_state_.dpad_down = true; break;
        case 0x5: current_state_.dpad_left = true; current_state_.dpad_down = true; break;
        case 0x6: current_state_.dpad_left = true; break;
        case 0x7: current_state_.dpad_left = true; current_state_.dpad_up = true; break;
        default: break;
    }

    uint8_t buttonsA = data[0x08];
    current_state_.left_bumper = (buttonsA & DS_BTN_A_LEFT_BUMPER) != 0;
    current_state_.right_bumper = (buttonsA & DS_BTN_A_RIGHT_BUMPER) != 0;
    current_state_.left_trigger_button = (buttonsA & DS_BTN_A_LEFT_TRIGGER) != 0;
    current_state_.right_trigger_button = (buttonsA & DS_BTN_A_RIGHT_TRIGGER) != 0;
    current_state_.select_button = (buttonsA & DS_BTN_A_SELECT) != 0;
    current_state_.menu_button = (buttonsA & DS_BTN_A_MENU) != 0;
    current_state_.left_stick_button = (buttonsA & DS_BTN_A_LEFT_STICK) != 0;
    current_state_.right_stick_button = (buttonsA & DS_BTN_A_RIGHT_STICK) != 0;

    uint8_t buttonsB = data[0x09];
    current_state_.ps_button = (buttonsB & DS_BTN_B_PS_BUTTON) != 0;
    current_state_.touchpad_button = (buttonsB & DS_BTN_B_PAD_BUTTON) != 0;
    current_state_.mic_button = (buttonsB & DS_BTN_B_MIC_BUTTON) != 0;

    if (buttonsA != 0 || buttonsB != 0) {
        sprintf_s(debugBuffer, "[BOTÕES BT] A=0x%02X (L1:%d R1:%d L2:%d R2:%d Share:%d Options:%d L3:%d R3:%d) | B=0x%02X (PS:%d Touch:%d Mic:%d)\n",
                  buttonsA,
                  current_state_.left_bumper,
                  current_state_.right_bumper,
                  current_state_.left_trigger_button,
                  current_state_.right_trigger_button,
                  current_state_.select_button,
                  current_state_.menu_button,
                  current_state_.left_stick_button,
                  current_state_.right_stick_button,
                  buttonsB,
                  current_state_.ps_button,
                  current_state_.touchpad_button,
                  current_state_.mic_button);
        OutputDebugStringA(debugBuffer);
    }
}

void DualSenseController::NotifyCallbacks() {
    // Callback específico do botão PS (SOMENTE byte 0x09, bit 0x01)
    if (ps_button_callback_ && current_state_.ps_button != previous_state_.ps_button) {
        // Debug: confirma qual botão mudou
        char logMsg[256];
        sprintf_s(logMsg, "✅ PS BUTTON CALLBACK: %s (was:%d now:%d)\n", 
                  current_state_.ps_button ? "PRESSED" : "RELEASED",
                  previous_state_.ps_button,
                  current_state_.ps_button);
        OutputDebugStringA(logMsg);
        ps_button_callback_(current_state_.ps_button);
    }
    
    // Callback geral de botões (se qualquer botão mudou)
    if (button_callback_) {
        bool any_change = false;
        
        // Verifica se houve mudança em qualquer botão
        if (std::memcmp(&current_state_, &previous_state_, sizeof(DualSenseButtonState)) != 0) {
            any_change = true;
        }
        
        if (any_change) {
            button_callback_(current_state_);
        }
    }
}
