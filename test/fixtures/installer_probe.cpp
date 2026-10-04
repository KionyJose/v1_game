#define NOMINMAX
#include <windows.h>
#include <filesystem>
#include <fstream>
#include <string>
namespace fs=std::filesystem;
static PROCESS_INFORMATION spawn(const fs::path &exe,const std::wstring &args) {
  auto command=L"\""+exe.wstring()+L"\" "+args;
  STARTUPINFOW startup{sizeof(startup)};PROCESS_INFORMATION process{};
  CreateProcessW(exe.c_str(),command.data(),nullptr,nullptr,FALSE,CREATE_NO_WINDOW,nullptr,nullptr,&startup,&process);
  CloseHandle(process.hThread);return process;
}
int wmain(int argc,wchar_t **argv) {
  if(argc==2 && std::wstring(argv[1])==L"--wait") {Sleep(60000);return 0;}
  fs::path output;
  for(int i=1;i<argc;i++)if(std::wstring(argv[i]).rfind(L"/DIR=",0)==0)output=std::wstring(argv[i]).substr(5);
  if(output.empty())return 2;
  std::wofstream args(output/L"arguments.txt");for(int i=1;i<argc;i++)args<<argv[i]<<L"\n";args.close();
  wchar_t self[32768]{};GetModuleFileNameW(nullptr,self,32768);
  fs::create_directories(output/L"_Redist");
  bool cancel=fs::exists(output/L"cancel-case");
  auto child=output/(cancel?L"Child.exe":L"_Redist\\QuickSFV.exe");
  CopyFileW(self,child.c_str(),FALSE);
  auto process=spawn(child,L"--wait");
  std::ofstream pid(output/L"child.pid");pid<<process.dwProcessId;pid.close();
  if(WaitForSingleObject(process.hProcess,cancel?60000:5000)!=WAIT_OBJECT_0)return 3;
  CloseHandle(process.hProcess);
  if(!cancel) {
    auto web=output/L"_Redist"/L"dxwebsetup.exe";CopyFileW(self,web.c_str(),FALSE);
    auto webProcess=spawn(web,L"--wait");
    if(WaitForSingleObject(webProcess.hProcess,5000)!=WAIT_OBJECT_0)return 4;
    CloseHandle(webProcess.hProcess);
  }
  std::ofstream done(output/L"complete.txt");done<<"complete";
  return 0;
}
