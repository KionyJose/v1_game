param(
    [string]$OutputDirectory = (Join-Path $PSScriptRoot '../../windows/third_party/prerequisites')
)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$outputPath = [IO.Path]::GetFullPath($OutputDirectory)
New-Item -ItemType Directory -Path $outputPath -Force | Out-Null

function Get-MicrosoftInstaller([string]$Url, [string]$Name) {
    $target = Join-Path $outputPath $Name
    if (-not (Test-Path -LiteralPath $target)) {
        Invoke-WebRequest -Uri $Url -OutFile $target -UseBasicParsing
    }
    $signature = Get-AuthenticodeSignature -LiteralPath $target
    if ($signature.Status -ne 'Valid' -or
        $signature.SignerCertificate.Subject -notmatch 'O=Microsoft Corporation') {
        throw "Assinatura Microsoft invalida: $target. O arquivo nao sera executado."
    }
    $version = (Get-Item -LiteralPath $target).VersionInfo.ProductVersion
    [pscustomobject]@{
        file = $Name
        version = $version
        sha256 = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash
        source = $Url
    }
}

$installers = @(
    Get-MicrosoftInstaller 'https://aka.ms/vc14/vc_redist.x64.exe' 'vc_redist.x64.exe'
    Get-MicrosoftInstaller 'https://go.microsoft.com/fwlink/p/?LinkId=2124703' 'MicrosoftEdgeWebview2Setup.exe'
)
$installers | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $outputPath 'packages.json') -Encoding UTF8
Write-Output "Dependencias oficiais preparadas em $outputPath. Nenhum instalador foi executado."
