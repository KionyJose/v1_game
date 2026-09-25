#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <shellapi.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

namespace {

constexpr const wchar_t kSingleInstanceMutex[] =
    L"Local\\V1Launcher_v1_game_single_instance";
constexpr const wchar_t kMainWindowTitle[] = L"v1_game";
constexpr const wchar_t kFlutterWindowClass[] = L"FLUTTER_RUNNER_WIN32_WINDOW";
constexpr const wchar_t kSlimConfigPath[] =
    L"C:\\Users\\Public\\Documents\\v1_game_slim.txt";
constexpr const wchar_t kSlimConfigActive[] = L"ativo == 1";
constexpr const wchar_t kSlimConfigInactive[] = L"ativo == 0";

void BringExistingInstanceToFront() {
  HWND existing_window = ::FindWindowW(kFlutterWindowClass, kMainWindowTitle);
  if (existing_window == nullptr) {
    existing_window = ::FindWindowW(nullptr, kMainWindowTitle);
  }

  if (existing_window == nullptr) {
    return;
  }

  if (::IsIconic(existing_window)) {
    ::ShowWindow(existing_window, SW_RESTORE);
  } else {
    ::ShowWindow(existing_window, SW_SHOW);
  }

  ::SetForegroundWindow(existing_window);
}

bool FileExists(const std::wstring& path) {
  const DWORD attributes = ::GetFileAttributesW(path.c_str());
  return attributes != INVALID_FILE_ATTRIBUTES &&
         (attributes & FILE_ATTRIBUTE_DIRECTORY) == 0;
}

std::wstring GetExecutableDirectory() {
  wchar_t buffer[MAX_PATH];
  const DWORD length = ::GetModuleFileNameW(nullptr, buffer, MAX_PATH);
  if (length == 0 || length == MAX_PATH) {
    return L"";
  }

  std::wstring path(buffer, length);
  const size_t separator = path.find_last_of(L"\\/");
  if (separator == std::wstring::npos) {
    return L"";
  }

  return path.substr(0, separator);
}

std::wstring JoinPath(const std::wstring& left, const std::wstring& right) {
  if (left.empty()) {
    return right;
  }
  if (left.back() == L'\\' || left.back() == L'/') {
    return left + right;
  }
  return left + L"\\" + right;
}

std::wstring ReadTextFile(const std::wstring& path) {
  HANDLE file = ::CreateFileW(path.c_str(), GENERIC_READ, FILE_SHARE_READ,
                              nullptr, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL,
                              nullptr);
  if (file == INVALID_HANDLE_VALUE) {
    return L"";
  }

  char buffer[128] = {};
  DWORD bytes_read = 0;
  ::ReadFile(file, buffer, sizeof(buffer) - 1, &bytes_read, nullptr);
  ::CloseHandle(file);
  buffer[bytes_read] = '\0';

  std::wstring content;
  content.reserve(bytes_read);
  for (DWORD i = 0; i < bytes_read; i++) {
    content.push_back(static_cast<wchar_t>(buffer[i]));
  }
  return content;
}

void WriteSlimConfigDefaultActive() {
  HANDLE file = ::CreateFileW(kSlimConfigPath, GENERIC_WRITE, 0, nullptr,
                              CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr);
  if (file == INVALID_HANDLE_VALUE) {
    return;
  }

  const char content[] = "ativo == 1";
  DWORD bytes_written = 0;
  ::WriteFile(file, content, sizeof(content) - 1, &bytes_written, nullptr);
  ::CloseHandle(file);
}

bool IsSlimModeActive() {
  if (!FileExists(kSlimConfigPath)) {
    WriteSlimConfigDefaultActive();
    return true;
  }

  const std::wstring content = ReadTextFile(kSlimConfigPath);
  return content.find(kSlimConfigInactive) == std::wstring::npos;
}

std::wstring FindSlimExecutable() {
  const std::wstring executable_dir = GetExecutableDirectory();
  if (!executable_dir.empty()) {
    const std::wstring candidate =
        JoinPath(executable_dir, L"v1_slim\\v1_slim.exe");
    if (FileExists(candidate)) {
      return candidate;
    }
  }

  wchar_t current_dir[MAX_PATH];
  const DWORD length = ::GetCurrentDirectoryW(MAX_PATH, current_dir);
  if (length > 0 && length < MAX_PATH) {
    const std::wstring candidate =
        JoinPath(current_dir, L"v1_slim\\v1_slim.exe");
    if (FileExists(candidate)) {
      return candidate;
    }
  }

  return L"";
}

bool OpenSlimAppIfActive() {
  if (!IsSlimModeActive()) {
    return false;
  }

  const std::wstring slim_executable = FindSlimExecutable();
  if (slim_executable.empty()) {
    return false;
  }

  const std::wstring working_directory =
      slim_executable.substr(0, slim_executable.find_last_of(L"\\/"));
  const HINSTANCE result =
      ::ShellExecuteW(nullptr, L"open", slim_executable.c_str(), nullptr,
                      working_directory.c_str(), SW_SHOWNORMAL);
  return reinterpret_cast<intptr_t>(result) > 32;
}

}  // namespace

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  if (OpenSlimAppIfActive()) {
    return EXIT_SUCCESS;
  }

  HANDLE single_instance_mutex =
      ::CreateMutexW(nullptr, TRUE, kSingleInstanceMutex);
  if (single_instance_mutex == nullptr) {
    return EXIT_FAILURE;
  }

  if (::GetLastError() == ERROR_ALREADY_EXISTS) {
    BringExistingInstanceToFront();
    ::CloseHandle(single_instance_mutex);
    return EXIT_SUCCESS;
  }
                        
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(kMainWindowTitle, origin, size)) {
    ::ReleaseMutex(single_instance_mutex);
    ::CloseHandle(single_instance_mutex);
    return EXIT_FAILURE;
  }
  ::ShowWindow(window.GetHandle(), SW_MAXIMIZE);
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  ::ReleaseMutex(single_instance_mutex);
  ::CloseHandle(single_instance_mutex);
  return EXIT_SUCCESS;
}
