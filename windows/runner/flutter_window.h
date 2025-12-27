#ifndef RUNNER_FLUTTER_WINDOW_H_
#define RUNNER_FLUTTER_WINDOW_H_

#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>

#include <memory>

#include "win32_window.h"

// A window that does nothing but host a Flutter view.
class FlutterWindow : public Win32Window {
 public:
  // Creates a new FlutterWindow hosting a Flutter view running |project|.
  explicit FlutterWindow(const flutter::DartProject& project);
  virtual ~FlutterWindow();

 protected:
  // Win32Window:
  bool OnCreate() override;
  void OnDestroy() override;
  LRESULT MessageHandler(HWND window, UINT const message, WPARAM const wparam,
                         LPARAM const lparam) noexcept override;

 private:
  // The project to run.
  flutter::DartProject project_;

  // The Flutter instance hosted by this window.
  std::unique_ptr<flutter::FlutterViewController> flutter_controller_;
  
  // ===== MÉTODOS DE CONFIGURAÇÃO =====
  void ConfigurarCanalComunicacaoFlutter();
  void RegistrarEntradaBrutaGamepad();
  
  // ===== MÉTODOS DE PROCESSAMENTO DE ENTRADA =====
  void ProcessarEntradaBrutaControle(LPARAM lparam);
  void ProcessarControleXbox(BYTE* dadosBrutos, DWORD tamanho);
  void ProcessarControleDualSense(BYTE* dadosBrutos, DWORD tamanho);
  
  // ===== MÉTODOS DE ENVIO PARA FLUTTER =====
  void EnviarBotaoGuideParaFlutter(const char* tipoControle, int indiceByte, bool pressionado);
  void EnviarDadosBrutosParaFlutter(BYTE byte7, BYTE byte8, BYTE byte9);
  void EnviarBotaoDualSenseParaFlutter(const char* nomeBotao, bool pressionado);
  
  // ===== MÉTODOS DE CALLBACK =====
  void ConfigurarCallbackBotaoPS();
};

#endif  // RUNNER_FLUTTER_WINDOW_H_
