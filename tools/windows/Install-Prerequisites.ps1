param([switch]$CheckOnly)
$ErrorActionPreference = 'Stop'

function Assert-MicrosoftInstaller([string]$Name) {
    $file = Join-Path $PSScriptRoot $Name
    if (-not (Test-Path -LiteralPath $file)) { throw "Dependencia ausente: $file" }
    $signature = Get-AuthenticodeSignature -LiteralPath $file
    if ($signature.Status -ne 'Valid' -or
        $signature.SignerCertificate.Subject -notmatch 'O=Microsoft Corporation') {
        throw "Assinatura Microsoft invalida: $file. Instalacao bloqueada."
    }
    return $file
}

function Test-WebView2 {
    foreach ($key in @(
        'HKCU:\Software\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}',
        'HKLM:\SOFTWARE\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}'
    )) {
        $value = (Get-ItemProperty -LiteralPath $key -Name pv -ErrorAction SilentlyContinue).pv
        if ($value) {
            try { if ([version]$value -gt [version]'0.0.0.0') { return $true } } catch {}
        }
    }
    return $false
}

$vc = Assert-MicrosoftInstaller 'vc_redist.x64.exe'
$web = Assert-MicrosoftInstaller 'MicrosoftEdgeWebview2Setup.exe'
$requiredText = (Get-Item -LiteralPath $vc).VersionInfo.ProductVersion
if ($requiredText -notmatch '(\d+\.\d+\.\d+(?:\.\d+)?)') {
    throw 'Nao foi possivel identificar a versao do Visual C++ empacotado.'
}
$requiredVersion = [version]$Matches[1]
$vcReady = $false
foreach ($key in @(
    'HKLM:\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\VisualStudio\14.0\VC\Runtimes\x64'
)) {
    $runtime = Get-ItemProperty -LiteralPath $key -ErrorAction SilentlyContinue
    if ($runtime.Installed -eq 1 -and $runtime.Version) {
        try { if ([version]($runtime.Version.TrimStart('v')) -ge $requiredVersion) { $vcReady = $true } } catch {}
    }
}
$webReady = Test-WebView2
Write-Output "Visual C++ x64 atualizado para o pacote: $vcReady; WebView2 presente: $webReady"
if ($CheckOnly) { return }

if (-not $vcReady) {
    # Somente o instalador do runtime solicita elevacao; o launcher fica no usuario.
    $process = Start-Process -FilePath $vc -ArgumentList '/install', '/passive', '/norestart' -Verb RunAs -WindowStyle Hidden -PassThru -Wait
    if ($process.ExitCode -notin @(0, 1638, 3010)) { throw "Visual C++ falhou: $($process.ExitCode)" }
    if ($process.ExitCode -eq 3010) { Write-Output 'Windows solicita reinicializacao para concluir o Visual C++.' }
}
if (-not $webReady) {
    # Chamado pelo usuario normal: instalacao por usuario quando suportada.
    $process = Start-Process -FilePath $web -ArgumentList '/silent', '/install' -WindowStyle Hidden -PassThru -Wait
    if ($process.ExitCode -ne 0) { throw "WebView2 falhou: $($process.ExitCode). Confira acesso a internet." }
    if (-not (Test-WebView2)) { throw 'WebView2 ainda nao detectado apos a instalacao.' }
}
Write-Output 'Dependencias verificadas. O V1 Launcher pode ser iniciado.'
