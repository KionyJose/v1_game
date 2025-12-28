# 1. Desabilitar Xbox Game Bar no Registro
$RegistryPaths = @(
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR",
    "HKCU:\SOFTWARE\Microsoft\GameBar"
)

foreach ($path in $RegistryPaths) {
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
}

Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -Value 0 -Force
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\GameBar" -Name "UseNexusForGameBarEnabled" -Value 0 -Force # Desativa o botão Guia especificamente

# 2. Localizar o Steam pelo Registro
# $steamPath = (Get-ItemProperty -Path "HKCU:\SOFTWARE\Valve\Steam").SteamPath

# if ($null -ne $steamPath) {
#     $configFile = Join-Path $steamPath "config\config.vdf"
    
#     if (Test-Path $configFile) {
#         Write-Host "Alterando config do Steam em: $configFile"
#         $content = Get-Content $configFile -Raw
        
#         # Altera para 0 (Desativado)
#         if ($content -contains '"GuideButtonSteam"') {
#             $newContent = $content -replace '"GuideButtonSteam"\s+"1"', '"GuideButtonSteam" "0"'
#         } else {
#             # Se não existir, insere a linha (simplificado)
#             $newContent = $content -replace '"InstallConfigStore"\s+\{', "`"InstallConfigStore`"`n`t{`n`t`t`"GuideButtonSteam`"`t`"0`""
#         }
        
#         Set-Content $configFile $newContent -Force
#     }
# } else {
#     Write-Warning "Steam não encontrado no registro."
# }

# Write-Host "Configurações aplicadas. Reinicie o Steam e o PC para garantir o efeito."



