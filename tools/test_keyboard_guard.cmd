@echo off
setlocal
for /f "usebackq tokens=*" %%i in (`"%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do call "%%i\VC\Auxiliary\Build\vcvars32.bat"
if not exist build\native-tests mkdir build\native-tests
cl /nologo /EHsc test\fixtures\keyboard_event_guard_test.cpp /Febuild\native-tests\keyboard_event_guard_test.exe /Fobuild\native-tests\keyboard_event_guard_test.obj
if errorlevel 1 exit /b %errorlevel%
build\native-tests\keyboard_event_guard_test.exe
exit /b %errorlevel%
