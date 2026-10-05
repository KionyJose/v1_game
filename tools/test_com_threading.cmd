@echo off
setlocal
for /f "usebackq tokens=*" %%i in (`"%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do call "%%i\VC\Auxiliary\Build\vcvars32.bat"
if not exist build\native-tests mkdir build\native-tests
cl /nologo /EHsc test\fixtures\com_threading_test.cpp /Febuild\native-tests\com_threading_test.exe /Fobuild\native-tests\com_threading_test.obj /link ole32.lib
if errorlevel 1 exit /b %errorlevel%
build\native-tests\com_threading_test.exe
exit /b %errorlevel%
