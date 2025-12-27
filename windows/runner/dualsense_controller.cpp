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
    ParseHIDData(rawData);
    
    // Notifica callbacks se houver mudanças
    NotifyCallbacks();
}

void DualSenseController::ParseHIDData(const BYTE* hidBuffer) {
    // ===== DEBUG: LOG COMPLETO DOS BYTES =====
    char debugBuffer[1024];
    sprintf_s(debugBuffer, "\n========== DUALSENSE HID DEBUG ==========\n");
    OutputDebugStringA(debugBuffer);
    
    // Mostra os primeiros 16 bytes em formato hexadecimal
    sprintf_s(debugBuffer, "Bytes 0x00-0x0F: ");
    for (int i = 0; i < 16 && i < 64; i++) {
        char temp[8];
        sprintf_s(temp, "%02X ", hidBuffer[i]);
        strcat_s(debugBuffer, temp);
    }
    strcat_s(debugBuffer, "\n");
    OutputDebugStringA(debugBuffer);
    
    // Mostra bytes críticos individuais
    sprintf_s(debugBuffer, "Byte 0x07 (Buttons+DPad): 0x%02X\n", hidBuffer[0x07]);
    OutputDebugStringA(debugBuffer);
    sprintf_s(debugBuffer, "Byte 0x08 (Buttons A)    : 0x%02X\n", hidBuffer[0x08]);
    OutputDebugStringA(debugBuffer);
    sprintf_s(debugBuffer, "Byte 0x09 (Buttons B-PS) : 0x%02X <-- PS Button\n", hidBuffer[0x09]);
    OutputDebugStringA(debugBuffer);
    sprintf_s(debugBuffer, "=========================================\n\n");
    OutputDebugStringA(debugBuffer);
    // ===== FIM DEBUG =====
    
    // Baseado no formato HID do DualSense (USB)
    // Offset 0x00-0x03: Analógicos
    // Offset 0x04-0x05: Gatilhos
    // Offset 0x07: Botões + D-Pad
    // Offset 0x08: Botões grupo A
    // Offset 0x09: Botões grupo B
    
    // Analógicos (converte de unsigned para signed)
    if (hidBuffer[0x00] != 0xFF) {  // Verifica se há dados válidos
        current_state_.left_stick_x = (int8_t)(hidBuffer[0x00] - 128);
        current_state_.left_stick_y = (int8_t)((hidBuffer[0x01] - 127) * -1);
        current_state_.right_stick_x = (int8_t)(hidBuffer[0x02] - 128);
        current_state_.right_stick_y = (int8_t)((hidBuffer[0x03] - 127) * -1);
    }
    
    // Gatilhos analógicos
    current_state_.left_trigger = hidBuffer[0x04];
    current_state_.right_trigger = hidBuffer[0x05];
    
    // Botões principais e D-Pad (byte 0x07)
    uint8_t buttonsAndDpad = hidBuffer[0x07];
    
    // Botões PlayStation
    current_state_.square = (buttonsAndDpad & DS_BTX_SQUARE) != 0;
    current_state_.cross = (buttonsAndDpad & DS_BTX_CROSS) != 0;
    current_state_.circle = (buttonsAndDpad & DS_BTX_CIRCLE) != 0;
    current_state_.triangle = (buttonsAndDpad & DS_BTX_TRIANGLE) != 0;
    
    // D-Pad (4 bits inferiores)
    uint8_t dpad = buttonsAndDpad & 0x0F;
    
    // Reset D-Pad
    current_state_.dpad_left = false;
    current_state_.dpad_right = false;
    current_state_.dpad_up = false;
    current_state_.dpad_down = false;
    
    // Parse D-Pad (pode ter direções combinadas)
    switch (dpad) {
        case 0x0: // Up
            current_state_.dpad_up = true;
            break;
        case 0x1: // Right-Up
            current_state_.dpad_right = true;
            current_state_.dpad_up = true;
            break;
        case 0x2: // Right
            current_state_.dpad_right = true;
            break;
        case 0x3: // Right-Down
            current_state_.dpad_right = true;
            current_state_.dpad_down = true;
            break;
        case 0x4: // Down
            current_state_.dpad_down = true;
            break;
        case 0x5: // Left-Down
            current_state_.dpad_left = true;
            current_state_.dpad_down = true;
            break;
        case 0x6: // Left
            current_state_.dpad_left = true;
            break;
        case 0x7: // Left-Up
            current_state_.dpad_left = true;
            current_state_.dpad_up = true;
            break;
        default: // Centro ou inválido
            break;
    }
    
    // Botões Grupo A (byte 0x08)
    uint8_t buttonsA = hidBuffer[0x08];
    current_state_.left_bumper = (buttonsA & DS_BTN_A_LEFT_BUMPER) != 0;
    current_state_.right_bumper = (buttonsA & DS_BTN_A_RIGHT_BUMPER) != 0;
    current_state_.left_trigger_button = (buttonsA & DS_BTN_A_LEFT_TRIGGER) != 0;
    current_state_.right_trigger_button = (buttonsA & DS_BTN_A_RIGHT_TRIGGER) != 0;
    current_state_.select_button = (buttonsA & DS_BTN_A_SELECT) != 0;
    current_state_.menu_button = (buttonsA & DS_BTN_A_MENU) != 0;
    current_state_.left_stick_button = (buttonsA & DS_BTN_A_LEFT_STICK) != 0;
    current_state_.right_stick_button = (buttonsA & DS_BTN_A_RIGHT_STICK) != 0;
    
    // Botões Grupo B (byte 0x09) - MAIS IMPORTANTE: BOTÃO PS
    uint8_t buttonsB = hidBuffer[0x09];
    current_state_.ps_button = (buttonsB & DS_BTN_B_PS_BUTTON) != 0;
    current_state_.touchpad_button = (buttonsB & DS_BTN_B_PAD_BUTTON) != 0;
    current_state_.mic_button = (buttonsB & DS_BTN_B_MIC_BUTTON) != 0;
    
    // ===== DEBUG DETALHADO DOS BOTÕES =====
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
    // ===== FIM DEBUG BOTÕES =====
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
