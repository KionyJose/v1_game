@echo off
setlocal
if /I not "%VSCMD_ARG_TGT_ARCH%"=="x86" (
  for /f "usebackq tokens=*" %%i in (`"%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do call "%%i\VC\Auxiliary\Build\vcvars32.bat"
)
if not exist assets\Repack mkdir assets\Repack
if not exist build\repack-analysis mkdir build\repack-analysis
cl /nologo /std:c++17 /EHsc /MT tools\repack\V1Unarc.cpp user32.lib /Feassets\Repack\V1Unarc.exe /Fobuild\repack-analysis\V1Unarc.obj /link /MACHINE:X86
if errorlevel 1 exit /b %errorlevel%
cl /nologo /std:c++17 /EHsc /MT tools\repack\V1SilentInstall.cpp /Feassets\Repack\V1SilentInstall.exe /Fobuild\repack-analysis\V1SilentInstall.obj /link /MACHINE:X86 /MANIFEST:EMBED /MANIFESTUAC:"level='asInvoker' uiAccess='false'"
exit /b %errorlevel%
