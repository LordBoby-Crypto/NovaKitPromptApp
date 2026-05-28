param(
    [string]$CertificatePath = "ios_distribution.p12",
    [string]$ProfilePath = "NovaKitPromptApp.mobileprovision"
)

if (Test-Path $CertificatePath) {
    [Convert]::ToBase64String([IO.File]::ReadAllBytes($CertificatePath)) | Set-Content cert_base64.txt
    Write-Host "Wrote cert_base64.txt"
} else {
    Write-Host "Certificate not found: $CertificatePath"
}

if (Test-Path $ProfilePath) {
    [Convert]::ToBase64String([IO.File]::ReadAllBytes($ProfilePath)) | Set-Content profile_base64.txt
    Write-Host "Wrote profile_base64.txt"
} else {
    Write-Host "Provisioning profile not found: $ProfilePath"
}
