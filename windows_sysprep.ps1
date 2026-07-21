<#
.SYNOPSIS
Installs programs, modules, features, and downkoads settings using Winget, Powershell, and Github.

.DESCRIPTION
Installs & configures all options from preconfig.json

.OUTPUTS
Screen output and operations logged in %Temp%\preconfig.log

.LINK
https://github.com/Clamtacos/windows_sysprep/blob/main/windows_sysprep.ps1
#>

#Requires -RunAsAdministrator
Start-Transcript $ENV:TEMP\windows_sysprep.log

Set-ExecutionPolicy Bypass -Scope Process -Force:$True -Confirm:$False -ErrorAction SilentlyContinue
Set-Variable -Name 'ConfirmPreference' -Value 'None' -Scope Script

$ProgressPreference = 'Continue'
$json = Get-Content "$($PSScriptRoot)\preconfig.json" | ConvertFrom-Json

Write-Host (" ----| Winget Installation |------------------------------------------------------------------")
if (!(Get-AppxPackage -Name Microsoft.Winget.Source)) {
    Write-Host ("Winget not found, installing...")
    Invoke-Webrequest -uri https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx -Outfile $ENV:TEMP\Microsoft.VCLibs.x64.14.00.Desktop.appx -UseBasicParsing
    Add-AppxPackage $ENV:TEMP\Microsoft.VCLibs.x64.14.00.Desktop.appx -ErrorAction SilentlyContinue
    Invoke-Webrequest -uri https://aka.ms/getwinget -Outfile $ENV:TEMP\winget.msixbundle -UseBasicParsing
    Add-AppxPackage -Path $ENV:TEMP\winget.msixbundle -ErrorAction SilentlyContinue
}

Write-Host (" ----| Microsoft Visual C++ Visual Runtime Installations |------------------------------------")
$CurrentVC = Get-WmiObject -Class Win32_Product -Filter "Name LIKE '%Visual C++%'" -ErrorAction SilentlyContinue | Select-Object Name
Foreach ($App in $json.MSVCRuntime) {
    Write-Host ("Verifying if {0} is installed..." -f $App)
    if (!($CurrentVC | Select-String $App.split('+')[2].SubString(0, 4) | Select-String $App.split('-')[1])) {
        Write-Host ("{0} not found, installing..." -f $App)
        winget.exe install $App --force --source winget --accept-package-agreements --accept-source-agreements
    }
}

Write-Host (" ----| App Installs |-------------------------------------------------------------------------")
Foreach ($App in $json.Apps) {
    Write-Host ("Verifying if {0} is installed..." -f $App)
    winget.exe list --id $App --accept-source-agreements | Out-Null
    if ($LASTEXITCODE -eq '-1978335212') {
        Write-Host ("{0} not found, installing..." -f $App.Split('.')[1])
        winget.exe install $App --silent --force --source winget --accept-package-agreements --accept-source-agreements
    } 
}

Write-Host (" ----| Windows Optional Features |------------------------------------------------------------")
Foreach ($Feature in $json.WindowsFeatures) {
    Write-Host ("Verifying if {0} is installed..." -f $Feature)
    if ((Get-WindowsOptionalFeature -Online -FeatureName:$Feature).State -ne 'Enabled') {
        Write-Host ("{0} not found, installing..." -f $Feature)
        Enable-WindowsOptionalFeature -Online -FeatureName:$Feature -NoRestart:$True -ErrorAction SilentlyContinue | Out-Null
    }
}

Write-Host (" ----| PowerShell Modules |-------------------------------------------------------------------")
Set-PSRepository PSGallery -InstallationPolicy Trusted77
Foreach ($Module in $json.PowerShellModules) {
    Write-Host ("Verifying if {0} is installed..." -f $Module)
    if (!(Get-Module $Module -ListAvailable)) {
        Write-Host ("{0} PowerShell module not found, installing..." -f $Module)
        Install-Module -Name $Module -Scope AllUsers -Force:$True -AllowClobber:$True
    }
}

Stop-Transcript
