# Script para desabilitar Xbox Game Bar
# Desabilita Xbox Game Bar
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -Value 0 -Force
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\GameBar" -Name "ShowStartupPanel" -Value 0 -Force
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\GameBar" -Name "AutoGameModeEnabled" -Value 0 -Force
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\GameBar" -Name "GamePanelStartupTipIndex" -Value 3 -Force

# Não encerra Steam, apenas impede Xbox Game Bar

# Desabilita "Guia do botão Xbox abre Steam" no config.vdf
$steamPath = "$env:APPDATA\Steam"
$configFile = Join-Path $steamPath 'config\config.vdf'

if (Test-Path $configFile) {
	$content = Get-Content $configFile -Raw
	if ($content -match '"GuideButtonSteam"\s+"1"') {
		$newContent = $content -replace '"GuideButtonSteam"\s+"1"', '"GuideButtonSteam" "0"'
		Set-Content $configFile $newContent -Force
	}
}
