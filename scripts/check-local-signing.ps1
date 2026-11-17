# CarOs: local-only check. Does not upload, export, or change certificates.
# Run in Windows PowerShell 5.1+ with the two files on your Desktop.
$ErrorActionPreference = 'Stop'
$desktop = [Environment]::GetFolderPath('Desktop')
$p12Path = Join-Path $desktop 'Apple\1and1padel-distribution-protected.p12'
$profilePath = Join-Path $desktop 'CarOs_App_Store_Distribution.mobileprovision'

if (-not (Test-Path -LiteralPath $p12Path)) { throw "P12 not found: $p12Path" }
if (-not (Test-Path -LiteralPath $profilePath)) { throw "Profile not found: $profilePath" }

$password = Read-Host 'P12 password (not displayed)' -AsSecureString
$pfxData = Get-PfxData -FilePath $p12Path -Password $password
$appleCertificate = $pfxData.EndEntityCertificates |
    Where-Object { $_.Subject -match 'Apple Distribution' } |
    Select-Object -First 1

Add-Type -AssemblyName System.Security -ErrorAction SilentlyContinue
$cms = New-Object System.Security.Cryptography.Pkcs.SignedCms
$cms.Decode([System.IO.File]::ReadAllBytes($profilePath))
[xml]$plist = [System.Text.Encoding]::UTF8.GetString($cms.ContentInfo.Content)

$developerCertificates = $plist.SelectSingleNode("/plist/dict/key[.='DeveloperCertificates']/following-sibling::*[1]")
$profileThumbprints = @()
if ($developerCertificates) {
    foreach ($node in $developerCertificates.SelectNodes('data')) {
        $base64 = $node.InnerText -replace '\s', ''
        $certificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 -ArgumentList (,[Convert]::FromBase64String($base64))
        $profileThumbprints += $certificate.Thumbprint
    }
}
$entitlements = $plist.SelectSingleNode("/plist/dict/key[.='Entitlements']/following-sibling::dict[1]")
$appIdNode = if ($entitlements) { $entitlements.SelectSingleNode("key[.='application-identifier']/following-sibling::string[1]") }
$videoKey = if ($entitlements) { $entitlements.SelectSingleNode("key[.='com.apple.developer.carplay-video']") }
$audioKey = if ($entitlements) { $entitlements.SelectSingleNode("key[.='com.apple.developer.carplay-audio']") }
$videoValue = if ($videoKey) { $videoKey.SelectSingleNode('following-sibling::*[1]') }
$audioValue = if ($audioKey) { $audioKey.SelectSingleNode('following-sibling::*[1]') }

$appleDistribution = $null -ne $appleCertificate
$certMatch = $appleDistribution -and ($profileThumbprints -contains $appleCertificate.Thumbprint)
$bundleMatch = $null -ne $appIdNode -and $appIdNode.InnerText -eq 'MJ8M4C9V9M.com.marcpico.aronaos'
$videoEnabled = $null -ne $videoValue -and $videoValue.Name -eq 'true'
$audioEnabled = $null -ne $audioValue -and $audioValue.Name -eq 'true'

Write-Host ''
Write-Host ('P12 Apple Distribution: ' + $appleDistribution)
Write-Host ('P12 matches App Store profile: ' + $certMatch)
Write-Host ('CarOs App ID matches: ' + $bundleMatch)
Write-Host ('CarPlay Video enabled in profile: ' + $videoEnabled)
Write-Host ('CarPlay Audio enabled in profile: ' + $audioEnabled)
Write-Host ''
if ($appleDistribution -and $certMatch -and $bundleMatch -and $videoEnabled -and -not $audioEnabled) {
    Write-Host 'READY: certificate and profile match. Do not share the P12, its password or the profile.' -ForegroundColor Green
} else {
    Write-Host 'STOP: signing materials are not yet a verified match; do not configure CI signing yet.' -ForegroundColor Yellow
}
