#include "flutter_window.h"

#include <optional>
#include <string>
#include <algorithm>

#include "flutter/generated_plugin_registrant.h"
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <flutter/encodable_value.h>
#include "dualsense_controller.h"

// ============================================================================
// VARIÁVEIS GLOBAIS
// ============================================================================
static std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> canal_botao_guide;
static std::unique_ptr<DualSenseController> controlador_dualsense;

// ============================================================================
// CONSTRUTORES E DESTRUTORES
// ============================================================================

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

// ============================================================================
// MÉTODOS DE CICLO DE VIDA
// ============================================================================

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  
  // Configura comunicação com Flutter
  ConfigurarCanalComunicacaoFlutter();
  
  // Inicializa controlador DualSense
  controlador_dualsense = std::make_unique<DualSenseController>();
  
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  if (controlador_dualsense) {
    controlador_dualsense = nullptr;
  }
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

// ============================================================================
// CONFIGURAÇÃO DO CANAL DE COMUNICAÇÃO COM FLUTTER
// ============================================================================

void FlutterWindow::ConfigurarCanalComunicacaoFlutter() {
  canal_botao_guide = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      flutter_controller_->engine()->messenger(),
      "gamepad_guide_button",
      &flutter::StandardMethodCodec::GetInstance());

  canal_botao_guide->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& chamada,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> resultado) {
        if (chamada.method_name() == "registerRawInput") {
          RegistrarEntradaBrutaGamepad();
          resultado->Success(flutter::EncodableValue(true));
        } else {
          resultado->NotImplemented();
        }
      });
}

void FlutterWindow::RegistrarEntradaBrutaGamepad() {
  RAWINPUTDEVICE dispositivo;
  dispositivo.usUsagePage = 0x01; // HID_USAGE_PAGE_GENERIC
  dispositivo.usUsage = 0x05;     // HID_USAGE_GENERIC_GAMEPAD
  dispositivo.dwFlags = RIDEV_INPUTSINK;
  dispositivo.hwndTarget = GetHandle();

  if (RegisterRawInputDevices(&dispositivo, 1, sizeof(dispositivo))) {
    OutputDebugStringA("✓ Raw Input registrado com sucesso\n");
  } else {
    OutputDebugStringA("✗ Falha ao registrar Raw Input\n");
  }
}

// ============================================================================
// PROCESSAMENTO DE ENTRADA BRUTA (RAW INPUT)
// ============================================================================

LRESULT FlutterWindow::MessageHandler(HWND hwnd, UINT const mensagem,
                                       WPARAM const wparam,
                                       LPARAM const lparam) noexcept {
  if (flutter_controller_) {
    std::optional<LRESULT> resultado =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, mensagem, wparam, lparam);
    if (resultado) {
      return *resultado;
    }
  }

  switch (mensagem) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
    
    case WM_INPUT:
      ProcessarEntradaBrutaControle(lparam);
      break;
  }

  return Win32Window::MessageHandler(hwnd, mensagem, wparam, lparam);
}

void FlutterWindow::ProcessarEntradaBrutaControle(LPARAM lparam) {
  UINT tamanho = 0;
  GetRawInputData((HRAWINPUT)lparam, RID_INPUT, nullptr, &tamanho, sizeof(RAWINPUTHEADER));
  
  if (tamanho == 0) return;
  
  LPBYTE buffer = new BYTE[tamanho];
  
  if (GetRawInputData((HRAWINPUT)lparam, RID_INPUT, buffer, &tamanho, sizeof(RAWINPUTHEADER)) != tamanho) {
    delete[] buffer;
    return;
  }
  
  RAWINPUT* entrada_bruta = (RAWINPUT*)buffer;
  
  if (entrada_bruta->header.dwType == RIM_TYPEHID) {
    BYTE* dados_brutos = entrada_bruta->data.hid.bRawData;
    DWORD tamanho_dados = entrada_bruta->data.hid.dwSizeHid * entrada_bruta->data.hid.dwCount;
    
    if (tamanho_dados > 0) {
      bool eh_xbox = (tamanho_dados == 16);
      bool eh_dualsense = DualSenseController::IsDualSenseController(tamanho_dados);

      if (eh_xbox) {
        ProcessarControleXbox(dados_brutos, tamanho_dados);
      } else if (eh_dualsense && controlador_dualsense) {
        // Se for DualSense via Bluetooth (tamanho típico 78), use o parser BT
        if (tamanho_dados == 78) {
          ProcessarControleDualSenseBluetooth(dados_brutos, tamanho_dados);
        } else {
          ProcessarControleDualSense(dados_brutos, tamanho_dados);
        }
      }
    }
  }
  
  delete[] buffer;
}

// ============================================================================
// PROCESSAMENTO ESPECÍFICO XBOX
// ============================================================================

void FlutterWindow::ProcessarControleXbox(BYTE* dados_brutos, DWORD tamanho) {
  static bool estado_anterior_guide = false;
  
  bool estado_atual_guide = (dados_brutos[12] & 0x04) != 0;
  
  if (estado_atual_guide != estado_anterior_guide) {
    char log[128];
    sprintf_s(log, "[XBOX] Botão Guide %s\n", estado_atual_guide ? "PRESSIONADO" : "SOLTO");
    OutputDebugStringA(log);
    
    EnviarBotaoGuideParaFlutter("Xbox", 12, estado_atual_guide);
    estado_anterior_guide = estado_atual_guide;
  }
}

// ============================================================================
// PROCESSAMENTO ESPECÍFICO DUALSENSE
// ============================================================================

void FlutterWindow::ProcessarControleDualSense(BYTE* dados_brutos, DWORD tamanho) {
  static BYTE byte7_anterior = 0xFF;
  static BYTE byte8_anterior = 0xFF;
  static BYTE byte9_anterior = 0xFF;
  static BYTE byte10_anterior = 0xFF;
  static BYTE leftStickX_anterior = 0x80;
  static BYTE leftStickY_anterior = 0x80;
  static BYTE rightStickX_anterior = 0x80;
  static BYTE rightStickY_anterior = 0x80;
  static bool callback_ja_configurado = false;
  
  if (tamanho < 11) return;
  
  BYTE byte7_atual = dados_brutos[7];
  BYTE byte8_atual = dados_brutos[8];
  BYTE byte9_atual = dados_brutos[9];
  BYTE byte10_atual = dados_brutos[10];
  
  // Detecta mudanças em cada botão individualmente
  if (byte7_atual != byte7_anterior) {
    // Byte 7 - Botões principais e D-Pad
    
    // Botões face (bits 4-7)
    // if ((byte7_atual & 0x10) != (byte7_anterior & 0x10)) {
    //   EnviarBotaoDualSenseParaFlutter("square", (byte7_atual & 0x10) != 0);
    // }
    // if ((byte7_atual & 0x20) != (byte7_anterior & 0x20)) {
    //   EnviarBotaoDualSenseParaFlutter("cross", (byte7_atual & 0x20) != 0);
    // }
    // if ((byte7_atual & 0x40) != (byte7_anterior & 0x40)) {
    //   EnviarBotaoDualSenseParaFlutter("circle", (byte7_atual & 0x40) != 0);
    // }
    // if ((byte7_atual & 0x80) != (byte7_anterior & 0x80)) {
    //   EnviarBotaoDualSenseParaFlutter("triangle", (byte7_atual & 0x80) != 0);
    // }
    
    // D-Pad (bits 0-3) - valores de 0x0 a 0x8
    BYTE dpad_atual = byte7_atual & 0x0F;
    BYTE dpad_anterior = byte7_anterior & 0x0F;
    
    if (dpad_atual != dpad_anterior) {
      // Envia estado atual do D-Pad
      // EnviarBotaoDualSenseParaFlutter("dpad_up", dpad_atual == 0 || dpad_atual == 1 || dpad_atual == 7);
      // EnviarBotaoDualSenseParaFlutter("dpad_right", dpad_atual == 1 || dpad_atual == 2 || dpad_atual == 3);
      // EnviarBotaoDualSenseParaFlutter("dpad_down", dpad_atual == 3 || dpad_atual == 4 || dpad_atual == 5);
      // EnviarBotaoDualSenseParaFlutter("dpad_left", dpad_atual == 5 || dpad_atual == 6 || dpad_atual == 7);
    }
    
    byte7_anterior = byte7_atual;
  }
  
  if (byte8_atual != byte8_anterior) {
    // D-Pad - usa valores absolutos, não bits individuais
    // 0x08 = Neutro, 0x00 = CIMA, 0x02 = DIREITA, 0x04 = BAIXO, 0x06 = ESQUERDA
    BYTE dpad_byte8_atual = byte8_atual & 0x0F;
    BYTE dpad_byte8_anterior = byte8_anterior & 0x0F;
    
    if (dpad_byte8_atual != dpad_byte8_anterior) {
      static bool ultimo_cima = false;
      static bool ultimo_direita = false;
      static bool ultimo_baixo = false;
      static bool ultimo_esquerda = false;
      
      bool cima_agora = (dpad_byte8_atual == 0x00);
      bool direita_agora = (dpad_byte8_atual == 0x02);
      bool baixo_agora = (dpad_byte8_atual == 0x04);
      bool esquerda_agora = (dpad_byte8_atual == 0x06);
      
      if (cima_agora != ultimo_cima) {
        EnviarBotaoDualSenseParaFlutter("CIMA", cima_agora);
        ultimo_cima = cima_agora;
      }
      if (direita_agora != ultimo_direita) {
        EnviarBotaoDualSenseParaFlutter("DIREITA", direita_agora);
        ultimo_direita = direita_agora;
      }
      if (baixo_agora != ultimo_baixo) {
        EnviarBotaoDualSenseParaFlutter("BAIXO", baixo_agora);
        ultimo_baixo = baixo_agora;
      }
      if (esquerda_agora != ultimo_esquerda) {
        EnviarBotaoDualSenseParaFlutter("ESQUERDA", esquerda_agora);
        ultimo_esquerda = esquerda_agora;
      }
    }
    
    // Outros botões (bits superiores)
    if ((byte8_atual & 0x10) != (byte8_anterior & 0x10)) {
      EnviarBotaoDualSenseParaFlutter("1", (byte8_atual & 0x10) != 0);
    }
    if ((byte8_atual & 0x20) != (byte8_anterior & 0x20)) {
      EnviarBotaoDualSenseParaFlutter("2", (byte8_atual & 0x20) != 0);
    }
    if ((byte8_atual & 0x40) != (byte8_anterior & 0x40)) {
      EnviarBotaoDualSenseParaFlutter("3", (byte8_atual & 0x40) != 0);
    }
    if ((byte8_atual & 0x80) != (byte8_anterior & 0x80)) {
      EnviarBotaoDualSenseParaFlutter("4", (byte8_atual & 0x80) != 0);
    }
    
    byte8_anterior = byte8_atual;
  }
  
  if (byte9_atual != byte9_anterior) {
    // Byte 9 - PS, Touchpad, Mic
    if ((byte9_atual & 0x01) != (byte9_anterior & 0x01)) {
      EnviarBotaoDualSenseParaFlutter("LB", (byte9_atual & 0x01) != 0);
    }
    if ((byte9_atual & 0x02) != (byte9_anterior & 0x02)) {
      EnviarBotaoDualSenseParaFlutter("RB", (byte9_atual & 0x02) != 0);
    }
    if ((byte9_atual & 0x08) != (byte9_anterior & 0x08)) {
      EnviarBotaoDualSenseParaFlutter("RT", (byte9_atual & 0x08) != 0);
    }
    if ((byte9_atual & 0x04) != (byte9_anterior & 0x04)) {
      EnviarBotaoDualSenseParaFlutter("LT", (byte9_atual & 0x04) != 0);
    }    
    if ((byte9_atual & 0x10) != (byte9_anterior & 0x10)) {
      EnviarBotaoDualSenseParaFlutter("SELECT", (byte9_atual & 0x10) != 0);
    }if ((byte9_atual & 0x20) != (byte9_anterior & 0x20)) {
      EnviarBotaoDualSenseParaFlutter("START", (byte9_atual & 0x20) != 0);
    }
     if ((byte9_atual & 0x40) != (byte9_anterior & 0x40)) {
      EnviarBotaoDualSenseParaFlutter("L3", (byte9_atual & 0x40) != 0);
    }if ((byte9_atual & 0x80) != (byte9_anterior & 0x80)) {
      EnviarBotaoDualSenseParaFlutter("R3", (byte9_atual & 0x80) != 0);
    }
    
    
    byte9_anterior = byte9_atual;
  }
  if (byte10_atual != byte10_anterior) {
    // Byte 10 - Testando todos os bits para encontrar o botão PS
    if ((byte10_atual & 0x01) != (byte10_anterior & 0x01)) {
      EnviarBotaoDualSenseParaFlutter("GUIDE", (byte10_atual & 0x01) != 0);
    }
    if ((byte10_atual & 0x02) != (byte10_anterior & 0x02)) {
      EnviarBotaoDualSenseParaFlutter("CLICK", (byte10_atual & 0x02) != 0);
    }
    
    byte10_anterior = byte10_atual;
  }
  
  // Processar analógicos (sticks)
  // Bytes 1-4: Left Stick X, Left Stick Y, Right Stick X, Right Stick Y
  // Valores de 0-255 (centro é ~128)
  if (tamanho >= 5) {
    BYTE leftStickX = dados_brutos[1];
    BYTE leftStickY = dados_brutos[2];
    BYTE rightStickX = dados_brutos[3];
    BYTE rightStickY = dados_brutos[4];
    
    // Threshold de 5 para evitar jitter/ruído
    const int threshold = 5;
    
    bool leftStickChanged = (abs(leftStickX - leftStickX_anterior) > threshold) ||
                            (abs(leftStickY - leftStickY_anterior) > threshold);
    bool rightStickChanged = (abs(rightStickX - rightStickX_anterior) > threshold) ||
                             (abs(rightStickY - rightStickY_anterior) > threshold);
    
    if (leftStickChanged) {
      EnviarAnalogicoParaFlutter("ANALOGICO ESQUERDO", leftStickX, leftStickY);
      leftStickX_anterior = leftStickX;
      leftStickY_anterior = leftStickY;
    }
    
    if (rightStickChanged) {
      EnviarAnalogicoParaFlutter("ANALOGICO DIREITO", rightStickX, rightStickY);
      rightStickX_anterior = rightStickX;
      rightStickY_anterior = rightStickY;
    }
  }
  
  // if (!callback_ja_configurado) {
  //   ConfigurarCallbackBotaoPS();
  //   callback_ja_configurado = true;
  // }
  
  controlador_dualsense->ProcessRawInput(dados_brutos, tamanho);
}

  // ============================================================================
  // PROCESSAMENTO ESPECÍFICO DUALSENSE (BLUETOOTH)
  // ============================================================================

  // kiony  
  
  // void FlutterWindow::ProcessarControleDualSenseBluetooth(BYTE* dados_brutos, DWORD tamanho) {
  //   metodo pra captar corretamente qual botao e qual botao foi pressionado
  //   if (tamanho < 5) return;

  //   // Guardamos uma cópia do estado anterior para saber o que mudou
  //   static BYTE estado_anterior[64] = {0};
  //   static bool primeiro_run = true;

  //   if (primeiro_run) {
  //       memcpy(estado_anterior, dados_brutos, (tamanho > 64) ? 64 : tamanho);
  //       primeiro_run = false;
  //       return;
  //   }

  //   // Percorre todos os bytes recebidos
  //   for (DWORD i = 0; i < tamanho; i++) {
  //       // Se o valor do byte atual for diferente do que era antes...
  //       if (dados_brutos[i] != estado_anterior[i]) {
            
  //           // 1. Criar uma string para identificar o que mudou
  //           // Formato: "BYTE_8_VAL_128"
  //           std::string log = "BYTE_" + std::to_string(i) + "_VAL_" + std::to_string(dados_brutos[i]);
            
  //           // 2. DISPARAR PARA O SEU BACKEND/FLUTTER
  //           // Aqui você usa sua função existente para enviar o texto do log
  //           EnviarBotaoDualSenseParaFlutter(log.c_str(), true);

  //           // Atualiza o estado anterior
  //           estado_anterior[i] = dados_brutos[i];
  //       }
  //   }
  // }

  void FlutterWindow::ProcessarControleDualSenseBluetooth(BYTE* d, DWORD tamanho) {
    if (tamanho < 10) return;

    // Estados estáticos para controle de borda (enviar apenas na mudança)
    static struct {
        bool quadrado, triangulo, bola, xis;
        bool up, down, left, right;
        bool l1, r1, l2, r2;
        bool select, start, ps;
        BYTE lx, ly, rx, ry;
    } est = {0};

    // --- BYTE 5: FACE BUTTONS & DPAD ---
    BYTE b5 = d[5];
    BYTE dpad = b5 & 0x0F;
    bool c_up    = (dpad == 0);
    bool c_right = (dpad == 2);
    bool c_down  = (dpad == 4);
    bool c_left  = (dpad == 6);
    bool c_quad  = (b5 == 24);
    bool c_tri   = (b5 == 136);
    bool c_bola  = (b5 == 72);
    bool c_xis   = (b5 == 40);

    // --- BYTE 6: BUMPERS, TRIGGERS (DIGITAL) & SISTEMA ---
    BYTE b6 = d[6];
    bool c_l1     = (b6 & 0x01);
    bool c_r1     = (b6 & 0x02);
    bool c_l2_btn = (b6 & 0x04);
    bool c_r2_btn = (b6 & 0x08);
    bool c_select = (b6 & 0x10);
    bool c_start  = (b6 & 0x20);

    // --- BYTE 7: BOTÃO PS ---
    // Verificamos o bit 0x01. Se (valor % 2 != 0), o bit 1 está ativo.
    bool c_ps = (d[7] & 0x01) != 0;

    // --- ANALÓGICOS (STICK E GATILHOS) ---
    BYTE cur_lx = d[1];
    BYTE cur_ly = d[2];
    BYTE cur_rx = d[3];
    BYTE cur_ry = d[4];
    // Gatilhos analógicos (pressão 0-255)
    // BYTE cur_l2_p = d[8]; 
    // BYTE cur_r2_p = d[9];

    // --- FUNÇÃO DE DISPARO ---
    auto DispararSeMudou = [&](const char* nome, bool atual, bool& anterior) {
        if (atual != anterior) {
            EnviarBotaoDualSenseParaFlutter(nome, atual);
            anterior = atual;
        }
    };

    // Executando os disparos
    DispararSeMudou("4", c_tri, est.triangulo);
    DispararSeMudou("3", c_bola, est.bola);
    DispararSeMudou("2", c_xis, est.xis);
    DispararSeMudou("1", c_quad, est.quadrado);

    DispararSeMudou("CIMA", c_up, est.up);
    DispararSeMudou("BAIXO", c_down, est.down);
    DispararSeMudou("ESQUERDA", c_left, est.left);
    DispararSeMudou("DIREITA", c_right, est.right);

    DispararSeMudou("LB", c_l1, est.l1);
    DispararSeMudou("RB", c_r1, est.r1);
    DispararSeMudou("LT", c_l2_btn, est.l2);
    DispararSeMudou("RT", c_r2_btn, est.r2);
    
    DispararSeMudou("SELECT", c_select, est.select);
    DispararSeMudou("START", c_start, est.start);
    DispararSeMudou("GUIDE", c_ps, est.ps); // <--- Adicionado aqui

    // Envio de analógicos com deadzone
    if (abs(cur_lx - est.lx) > 5 || abs(cur_ly - est.ly) > 5) {
        EnviarAnalogicoParaFlutter("ANALOGICO ESQUERDO", cur_lx, cur_ly);
        est.lx = cur_lx; est.ly = cur_ly;
    }
    if (abs(cur_rx - est.rx) > 5 || abs(cur_ry - est.ry) > 5) {
        EnviarAnalogicoParaFlutter("ANALOGICO DIREITO", cur_rx, cur_ry);
        est.rx = cur_rx; est.ry = cur_ry;
    }
}





// ============================================================================

// void FlutterWindow::ConfigurarCallbackBotaoPS() {
//   controlador_dualsense->SetPSButtonCallback([](bool pressionado) {
//     char log[128];
//     sprintf_s(log, "[DUALSENSE] Botão PS %s\n", pressionado ? "PRESSIONADO" : "SOLTO");
//     OutputDebugStringA(log);
    
//     if (canal_botao_guide) {
//       if (pressionado) {
//         auto argumentos = std::make_unique<flutter::EncodableValue>(
//           flutter::EncodableMap{
//             {flutter::EncodableValue("controller"), flutter::EncodableValue("DualSense")},
//             {flutter::EncodableValue("byte"), flutter::EncodableValue(9)}
//           }
//         );
//         canal_botao_guide->InvokeMethod("onGuideButtonPressed", std::move(argumentos));
//       } else {
//         canal_botao_guide->InvokeMethod("onGuideButtonReleased", nullptr);
//       }
//     }
//   });
  
//   OutputDebugStringA("✓ Callback do botão PS configurado\n");
// }

// ============================================================================
// MÉTODOS DE ENVIO PARA FLUTTER
// ============================================================================

void FlutterWindow::EnviarBotaoGuideParaFlutter(const char* tipo_controle, int indice_byte, bool pressionado) {
  if (!canal_botao_guide) return;
  
  if (pressionado) {
    auto argumentos = std::make_unique<flutter::EncodableValue>(
      flutter::EncodableMap{
        {flutter::EncodableValue("controller"), flutter::EncodableValue(tipo_controle)},
        {flutter::EncodableValue("byte"), flutter::EncodableValue(indice_byte)}
      }
    );
    canal_botao_guide->InvokeMethod("onGuideButtonPressed", std::move(argumentos));
  } else {
    canal_botao_guide->InvokeMethod("onGuideButtonReleased", nullptr);
  }
}

void FlutterWindow::EnviarDadosBrutosParaFlutter(BYTE byte7, BYTE byte8, BYTE byte9) {
  if (!canal_botao_guide) return;
  
  auto argumentos = std::make_unique<flutter::EncodableValue>(
    flutter::EncodableMap{
      {flutter::EncodableValue("byte7"), flutter::EncodableValue((int)byte7)},
      {flutter::EncodableValue("byte8"), flutter::EncodableValue((int)byte8)},
      {flutter::EncodableValue("byte9"), flutter::EncodableValue((int)byte9)}
    }
  );
  
  canal_botao_guide->InvokeMethod("onDualSenseRawData", std::move(argumentos));
}

void FlutterWindow::EnviarBotaoDualSenseParaFlutter(const char* nomeBotao, bool pressionado) {
  if (!canal_botao_guide) return;
  
  auto argumentos = std::make_unique<flutter::EncodableValue>(
    flutter::EncodableMap{
      {flutter::EncodableValue("button"), flutter::EncodableValue(nomeBotao)},
      {flutter::EncodableValue("pressed"), flutter::EncodableValue(pressionado)}
    }
  );
  
  canal_botao_guide->InvokeMethod("onDualSenseButton", std::move(argumentos));
  
  char log[128];
  sprintf_s(log, "[DUALSENSE] %s %s\n", nomeBotao, pressionado ? "PRESSIONADO" : "SOLTO");
  OutputDebugStringA(log);
}

void FlutterWindow::EnviarAnalogicoParaFlutter(const char* nomeStick, BYTE x, BYTE y) {
  if (!canal_botao_guide) return;
  
  // Normalizar valores de 0-255 para -1.0 a 1.0
  double normalizedX = (x - 128.0) / 128.0;
  double normalizedY = (y - 128.0) / 128.0;
  
  auto argumentos = std::make_unique<flutter::EncodableValue>(
    flutter::EncodableMap{
      {flutter::EncodableValue("stick"), flutter::EncodableValue(nomeStick)},
      {flutter::EncodableValue("x"), flutter::EncodableValue(normalizedX)},
      {flutter::EncodableValue("y"), flutter::EncodableValue(normalizedY)},
      {flutter::EncodableValue("rawX"), flutter::EncodableValue((int)x)},
      {flutter::EncodableValue("rawY"), flutter::EncodableValue((int)y)}
    }
  );
  
  canal_botao_guide->InvokeMethod("onDualSenseAnalog", std::move(argumentos));
}
