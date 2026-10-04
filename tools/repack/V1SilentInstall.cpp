#define NOMINMAX
#include <windows.h>
#include <shellapi.h>
#include <string>
#include <filesystem>
#include <cstdio>
#include <algorithm>
#include <tlhelp32.h>
#include <vector>
#pragma comment(lib,"shell32.lib")
#pragma comment(lib,"advapi32.lib")
namespace fs=std::filesystem;
static std::wstring quote(const std::wstring &value) {
  std::wstring out=L"\""; unsigned slashes=0;
  for(auto c:value) {
    if(c==L'\\') {slashes++;continue;}
    out.append(slashes*(c==L'"'?2:1),L'\\'); slashes=0;
    if(c==L'"')out+=L'\\'; out+=c;
  }
  out.append(slashes*2,L'\\');return out+L'"';
}
static bool administrator() {
  SID_IDENTIFIER_AUTHORITY authority=SECURITY_NT_AUTHORITY; PSID group=nullptr; BOOL member=FALSE;
  if(AllocateAndInitializeSid(&authority,2,SECURITY_BUILTIN_DOMAIN_RID,DOMAIN_ALIAS_RID_ADMINS,0,0,0,0,0,0,&group)) {
    CheckTokenMembership(nullptr,group,&member);FreeSid(group);
  }
  return member;
}
static void closeOwnedVerifier(HANDLE job,const fs::path &dest) {
  static std::vector<DWORD> auxiliaryPids;
  static std::vector<HANDLE> retainedHandles; // Keep terminated PIDs from reuse.
  // These repacks can launch interactive post-install tools despite silent
  // flags. The launcher verifies MD5 itself; optional legacy web prerequisites
  // are not part of this protocol. Restrict cleanup to this job and output.
  BYTE buffer[8192]{};
  if(!QueryInformationJobObject(job,JobObjectBasicProcessIdList,buffer,sizeof(buffer),nullptr))return;
  auto list=reinterpret_cast<JOBOBJECT_BASIC_PROCESS_ID_LIST*>(buffer);
  auto expected=fs::weakly_canonical(dest/L"_Redist"/L"QuickSFV.exe").wstring();
  std::transform(expected.begin(),expected.end(),expected.begin(),towlower);
  auto webSetup=fs::weakly_canonical(dest/L"_Redist"/L"dxwebsetup.exe").wstring();
  std::transform(webSetup.begin(),webSetup.end(),webSetup.begin(),towlower);
  for(DWORD i=0;i<list->NumberOfProcessIdsInList;i++) {
    HANDLE process=OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION|PROCESS_TERMINATE,FALSE,(DWORD)list->ProcessIdList[i]);
    if(!process)continue;
    wchar_t path[32768]{};DWORD size=32768;
    if(QueryFullProcessImageNameW(process,0,path,&size)) {
      auto actual=fs::weakly_canonical(path).wstring();
      std::transform(actual.begin(),actual.end(),actual.begin(),towlower);
      if(actual==expected || actual==webSetup) {
        auto pid=(DWORD)list->ProcessIdList[i];
        if(std::find(auxiliaryPids.begin(),auxiliaryPids.end(),pid)==auxiliaryPids.end()) {
          auxiliaryPids.push_back(pid);retainedHandles.push_back(process);process=nullptr;
        }
      }
    }
    if(process)CloseHandle(process);
  }
  HANDLE snapshot=CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS,0);
  if(snapshot!=INVALID_HANDLE_VALUE) {
    PROCESSENTRY32W entry{sizeof(entry)};bool changed;
    do {
      changed=false;
      if(Process32FirstW(snapshot,&entry))do {
        bool owned=false;
        for(DWORD i=0;i<list->NumberOfProcessIdsInList;i++) if(list->ProcessIdList[i]==entry.th32ProcessID)owned=true;
        if(owned && std::find(auxiliaryPids.begin(),auxiliaryPids.end(),entry.th32ParentProcessID)!=auxiliaryPids.end() &&
            std::find(auxiliaryPids.begin(),auxiliaryPids.end(),entry.th32ProcessID)==auxiliaryPids.end()) {
          HANDLE process=OpenProcess(PROCESS_TERMINATE,FALSE,entry.th32ProcessID);
          if(process) {auxiliaryPids.push_back(entry.th32ProcessID);retainedHandles.push_back(process);changed=true;}
        }
      }while(Process32NextW(snapshot,&entry));
    }while(changed);
    CloseHandle(snapshot);
  }
  for(auto process:retainedHandles)TerminateProcess(process,0);
}
static int install(const fs::path &setup,const fs::path &dest,const fs::path &log,DWORD parent) {
  HANDLE job=CreateJobObjectW(nullptr,nullptr);
  JOBOBJECT_EXTENDED_LIMIT_INFORMATION limit{};
  limit.BasicLimitInformation.LimitFlags=JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE;
  if(!job || !SetInformationJobObject(job,JobObjectExtendedLimitInformation,&limit,sizeof(limit)) ||
      !AssignProcessToJobObject(job,GetCurrentProcess())) return 20;
  HANDLE owner=parent?OpenProcess(SYNCHRONIZE,FALSE,parent):nullptr;
  if(parent && !owner) return 21;
  auto command=quote(setup.wstring())+L" /SP- /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /NOICONS /TASKS=\"\" /DIR="+
      quote(dest.wstring())+L" /LOG="+quote(log.wstring());
  STARTUPINFOW startup{sizeof(startup)}; PROCESS_INFORMATION process{};
  startup.dwFlags=STARTF_USESHOWWINDOW;startup.wShowWindow=SW_HIDE;
  if(!CreateProcessW(setup.c_str(),command.data(),nullptr,nullptr,FALSE,CREATE_NO_WINDOW,nullptr,
      setup.parent_path().c_str(),&startup,&process)) return (int)GetLastError();
  CloseHandle(process.hThread);
  while(WaitForSingleObject(process.hProcess,500)==WAIT_TIMEOUT) {
    closeOwnedVerifier(job,dest);
    puts("HEARTBEAT\tinstaller");fflush(stdout);
    // An elevated worker lives outside the medium-integrity parent's job.
    // If the app cancels/closes that parent, end this worker's entire job.
    if(owner && WaitForSingleObject(owner,0)==WAIT_OBJECT_0) TerminateJobObject(job,3);
  }
  DWORD code=1;GetExitCodeProcess(process.hProcess,&code);
  JOBOBJECT_BASIC_ACCOUNTING_INFORMATION accounting{};
  while(QueryInformationJobObject(job,JobObjectBasicAccountingInformation,&accounting,sizeof(accounting),nullptr) && accounting.ActiveProcesses>1) {
    closeOwnedVerifier(job,dest);
    if(owner && WaitForSingleObject(owner,0)==WAIT_OBJECT_0) TerminateJobObject(job,3);
    puts("HEARTBEAT\tinstaller-children");fflush(stdout);Sleep(500);
  }
  CloseHandle(process.hProcess);
  if(owner)CloseHandle(owner);
  // Returning closes the job and cleans up any remaining installer children.
  return (int)code;
}
int wmain(int argc,wchar_t **argv) {
  if(argc!=4 && !(argc==6 && std::wstring(argv[1])==L"--worker"))return 2;
  try {
    bool worker=argc==6;
    auto setup=fs::absolute(argv[worker?3:1]);
    auto dest=fs::absolute(argv[worker?4:2]);
    auto log=fs::absolute(argv[worker?5:3]);
    if(!fs::is_regular_file(setup) || !fs::is_directory(dest) || fs::is_symlink(dest))return 22;
    if(worker)return install(setup,dest,log,std::stoul(argv[2]));
    HANDLE lock=CreateMutexW(nullptr,FALSE,L"Local\\V1RepackDecoderHost");
    if(!lock)return 25;
    DWORD waiting;
    while((waiting=WaitForSingleObject(lock,2000))==WAIT_TIMEOUT) {
      puts("HEARTBEAT\twaiting-decoder");fflush(stdout);
    }
    if(waiting!=WAIT_OBJECT_0 && waiting!=WAIT_ABANDONED)return 26;
    if(administrator())return install(setup,dest,log,0);
    wchar_t self[32768]{};if(!GetModuleFileNameW(nullptr,self,32768))return 23;
    auto args=L"--worker "+std::to_wstring(GetCurrentProcessId())+L" "+quote(setup.wstring())+L" "+quote(dest.wstring())+L" "+quote(log.wstring());
    SHELLEXECUTEINFOW launch{sizeof(launch)};
    launch.fMask=SEE_MASK_NOCLOSEPROCESS;launch.lpVerb=L"runas";launch.lpFile=self;launch.lpParameters=args.c_str();launch.nShow=SW_HIDE;
    if(!ShellExecuteExW(&launch)) {
      auto code=GetLastError();printf("ERROR\tSilentStart\t%lu\n",code);return (int)code;
    }
    while(WaitForSingleObject(launch.hProcess,1000)==WAIT_TIMEOUT) {
      puts("HEARTBEAT\tinstaller");fflush(stdout);
    }
    DWORD code=1;GetExitCodeProcess(launch.hProcess,&code);CloseHandle(launch.hProcess);
    printf("RESULT\t%lu\n",code);return (int)code;
  } catch(const std::exception &error) {printf("ERROR\t%s\n",error.what());return 24;}
}
