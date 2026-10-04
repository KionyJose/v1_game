#define NOMINMAX
#include <windows.h>
#include <filesystem>
#include <string>
#include <stdio.h>
#include <algorithm>
#include <stdarg.h>
#include <fstream>
#include <vector>
#include <cstring>
#include <bcrypt.h>
#pragma comment(lib,"bcrypt.lib")
namespace fs = std::filesystem;
static fs::path output;
static HANDLE report;
static HANDLE job;
static void emit(const char *format, ...) {
  char buffer[8192]; va_list args; va_start(args,format);
  int length = vsnprintf(buffer,sizeof(buffer),format,args); va_end(args);
  if(length > 0) { DWORD written; WriteFile(report,buffer,(DWORD)std::min(length,8191),&written,nullptr); }
}
static std::string utf8(const std::wstring &s) {
  int n = WideCharToMultiByte(CP_UTF8,0,s.c_str(),-1,nullptr,0,nullptr,nullptr);
  std::string v(n,0); WideCharToMultiByte(CP_UTF8,0,s.c_str(),-1,v.data(),n,nullptr,nullptr);
  v.pop_back(); return v;
}
static std::wstring wide(const char *s) {
  int n = MultiByteToWideChar(CP_UTF8,MB_ERR_INVALID_CHARS,s,-1,nullptr,0);
  if (!n) throw std::runtime_error("Invalid UTF-8");
  std::wstring v(n,0); MultiByteToWideChar(CP_UTF8,MB_ERR_INVALID_CHARS,s,-1,v.data(),n);
  v.pop_back(); return v;
}
// CLS workers use Global\\ by default, which requires administrator privileges
// on native Windows. Only the extracted, private decoder copies are adapted;
// the original setup and archives remain untouched. The CLS DLL obtains the
// same prefix from the installer-host initialization mapping below.
static void localWorkers(const fs::path &folder) {
  for(const auto &entry : fs::directory_iterator(folder)) {
    auto name=entry.path().filename().wstring();
    std::transform(name.begin(),name.end(),name.begin(),towlower);
    auto extension=fs::path(name).extension();
    if(name.rfind(L"cls-",0)!=0 || (extension!=L".exe" && extension!=L".dll")) continue;
    if(!entry.is_regular_file() || entry.is_symlink()) throw std::runtime_error("Invalid decoder file");
    std::ifstream input(entry.path(),std::ios::binary);
    std::vector<char> bytes((std::istreambuf_iterator<char>(input)),{});
    const char original[]="Global\\";
    auto first=std::search(bytes.begin(),bytes.end(),original,original+sizeof(original));
    if(first==bytes.end()) continue;
    if(std::search(first+sizeof(original),bytes.end(),original,original+sizeof(original))!=bytes.end())
      throw std::runtime_error("Unsupported decoder IPC layout");
    const char replacement[8]={'L','o','c','a','l','\\',0,0};
    std::copy(replacement,replacement+8,first);
    input.close();
    std::ofstream out(entry.path(),std::ios::binary|std::ios::trunc);
    out.write(bytes.data(),bytes.size()); out.close();
    if(!out) throw std::runtime_error("Cannot prepare local decoder IPC");
  }
}
static int __stdcall callback(char *what, int n1, int n2, char *text) {
  std::string event = what ? what : "";
  if (event == "filename" && text) {
    try {
      fs::path name(wide(text));
      for (auto &part : name) if(part == L"..") {emit("ERROR\tpath-parent\t%s\n",text);return -1;}
      auto full = fs::weakly_canonical(name.is_absolute() ? name : output / name).wstring();
      auto root = fs::weakly_canonical(output).wstring() + L"\\";
      std::transform(full.begin(), full.end(), full.begin(), towlower);
      std::transform(root.begin(), root.end(), root.begin(), towlower);
      if (full != root.substr(0,root.size()-1) && full.rfind(root,0) != 0) {emit("ERROR\tpath-outside\t%s\n",text);return -1;}
    } catch (...) {emit("ERROR\tpath-invalid\t%s\n",text);return -1; }
  }
  if(event == "error") emit("ERROR\t%d\t%s\n",n1,text ? text : "");
  static ULONGLONG progressAt=0;
  auto now=GetTickCount64();
  if(event == "origsize" || (event == "write" && now-progressAt>=100)) {
    progressAt=now; emit("PROGRESS\t%s\t%d\t%d\n",what,n1,n2);
  }
  if(event == "password") return -1;
  return event == "overwrite" ? 1 : 0;
}
typedef int (__cdecl *Extract)(int (__stdcall *)(char *,int,int,char *), ...);
static int hashFile(const wchar_t *path) {
  BCRYPT_ALG_HANDLE algorithm=nullptr; BCRYPT_HASH_HANDLE hash=nullptr;
  if(BCryptOpenAlgorithmProvider(&algorithm,BCRYPT_MD5_ALGORITHM,nullptr,0)<0 ||
      BCryptCreateHash(algorithm,&hash,nullptr,0,nullptr,0,0)<0) return 10;
  HANDLE file=CreateFileW(path,GENERIC_READ,FILE_SHARE_READ,nullptr,OPEN_EXISTING,FILE_FLAG_SEQUENTIAL_SCAN,nullptr);
  if(file==INVALID_HANDLE_VALUE) {emit("ERROR\tHashFile\t%lu\n",GetLastError());return 11;}
  std::vector<UCHAR> buffer(1024*1024);
  DWORD count=0; ULONGLONG total=0,reported=0;
  for(;;) {
    if(!ReadFile(file,buffer.data(),(DWORD)buffer.size(),&count,nullptr)) return 12;
    if(!count) break;
    if(BCryptHashData(hash,buffer.data(),count,0)<0) return 13;
    total+=count;
    if(GetTickCount64()-reported>500) {
      reported=GetTickCount64(); emit("PROGRESS\thash\t%llu\t0\n",total/1048576);
    }
  }
  UCHAR bytes[16]; if(BCryptFinishHash(hash,bytes,sizeof(bytes),0)<0) return 14;
  char hex[33]{}; for(int i=0;i<16;i++) sprintf_s(hex+i*2,3,"%02x",bytes[i]);
  emit("HASH\t%s\n",hex);
  CloseHandle(file); BCryptDestroyHash(hash); BCryptCloseAlgorithmProvider(algorithm,0);
  return 0;
}
int wmain(int argc, wchar_t **argv) {
  if(argc==3 && std::wstring(argv[1])==L"h") {
    report=GetStdHandle(STD_OUTPUT_HANDLE); return hashFile(argv[2]);
  }
  if(argc != 5 || (std::wstring(argv[4]) != L"x" && std::wstring(argv[4]) != L"l")) return 2;
  auto oldOutput = GetStdHandle(STD_OUTPUT_HANDLE);
  if (!DuplicateHandle(GetCurrentProcess(),oldOutput,GetCurrentProcess(),&report,0,FALSE,DUPLICATE_SAME_ACCESS)) return 7;
  job = CreateJobObjectW(nullptr,nullptr);
  JOBOBJECT_EXTENDED_LIMIT_INFORMATION limit{};
  limit.BasicLimitInformation.LimitFlags = JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE;
  if(!job || !SetInformationJobObject(job,JobObjectExtendedLimitInformation,&limit,sizeof(limit)) ||
      !AssignProcessToJobObject(job,GetCurrentProcess())) return 3;
  try {
    auto dll = fs::absolute(argv[1]);
    auto archive = fs::absolute(argv[2]);
    output = fs::absolute(argv[3]);
    auto folder = dll.parent_path();
    // Legacy CLS mappings use fixed names and indices. Serialize extraction
    // hosts in this session while downloads themselves remain concurrent.
    HANDLE lock=CreateMutexW(nullptr,FALSE,L"Local\\V1RepackDecoderHost");
    if(!lock) throw std::runtime_error("Cannot create decoder lock");
    DWORD waiting;
    while((waiting=WaitForSingleObject(lock,2000))==WAIT_TIMEOUT) emit("HEARTBEAT\twaiting-decoder\n");
    if(waiting!=WAIT_OBJECT_0 && waiting!=WAIT_ABANDONED) throw std::runtime_error("Cannot acquire decoder lock");
    localWorkers(folder);
    HANDLE init=CreateFileMappingA(INVALID_HANDLE_VALUE,nullptr,PAGE_READWRITE,0,256,"Init_MapFile_");
    if(!init) {emit("ERROR\tInitMapping\t%lu\n",GetLastError());return 8;}
    DWORD existing=GetLastError();
    auto prefix=(char*)MapViewOfFile(init,FILE_MAP_ALL_ACCESS,0,0,256);
    if(!prefix) {emit("ERROR\tInitView\t%lu\n",GetLastError());return 9;}
    if(existing==ERROR_ALREADY_EXISTS && strncmp(prefix,"Local\\",7)!=0)
      throw std::runtime_error("Another installer is using the decoder initialization channel");
    memcpy(prefix,"Local\\",7);
    fs::current_path(folder);
    SetDllDirectoryW(folder.c_str());
    HMODULE module = LoadLibraryW(dll.c_str());
    if(!module) {emit("ERROR\tLoadLibrary\t%lu\n",GetLastError()); return 4;}
    auto extract = reinterpret_cast<Extract>(GetProcAddress(module,"FreeArcExtract"));
    if(!extract) return 5;
    fs::create_directories(output);
    auto dest = "-dp" + utf8(output.wstring());
    auto config = "-cfg" + utf8((folder / L"arc.ini").wstring());
    auto path = utf8(archive.wstring());
    auto command = utf8(argv[4]);
    int result = extract(callback,command.c_str(),"-o+",dest.c_str(),config.c_str(),"--",path.c_str(),nullptr);
    emit("RESULT\t%d\n",result);
    FreeLibrary(module);
    UnmapViewOfFile(prefix); CloseHandle(init);
    ReleaseMutex(lock); CloseHandle(lock);
    return result == 0 ? 0 : 1;
  } catch(const std::exception &e) {emit("ERROR\t%s\n",e.what()); return 6;}
}
