@echo off
setlocal
for /f "usebackq tokens=*" %%i in (`"%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do call "%%i\VC\Auxiliary\Build\vcvars32.bat"
if not exist build\repack-analysis mkdir build\repack-analysis
cl /nologo /std:c++17 /EHsc /MT test\fixtures\installer_probe.cpp /Febuild\repack-analysis\installer_probe.exe /Fobuild\repack-analysis\installer_probe.obj /link /MANIFEST:EMBED /MANIFESTUAC:"level='asInvoker' uiAccess='false'"
exit /b %errorlevel%
