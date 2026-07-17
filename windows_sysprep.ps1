<#
.SYNOPSIS
Installs programs, modules, features, and downkoads settings using Winget, Powershell, and Github.

.DESCRIPTION
Installs & configures all options from windows_sysprep.json

.OUTPUT
Screen output and operations logged in %Temp%\windows_sysprep.log

.LINK
None
#>

#Requires -RunAsAdministrator
Start-Transcript $ENV:TEMP\windows_sysprep.log

Set-ExecutionPolicy Bypass -Scope Process -Force:$True -Confirm:$False -ErrorAction SilentlyContinue
Set-Variable -Name 'ConfirmPreference' -Value 'None' -Scope Global
$ProgressPreference = 'SilentlyContinue'
$json = Get-Content "($PSScriptRoot)windows_sysprep.json" | ConvertFrom-Json

if (!(Get-AppxPackage -Name Microsoft.Winget.Source)) {
    Write-Host ("Winget not found, installing...")
    Invoke-Webrequest -uri https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx -Outfile $ENV:TEMP\Microsoft.VCLibs.x64.14.00.Desktop.appx -UseBasicParsing
    Invoke-Webrequest -uri https://aka.ms/getwinget -Outfile $ENV:TEMP\winget.msixbundle -UseBasicParsing
    Add-AppxPackage $ENV:TEMP\Microsoft.VCLibs.x64.14.00.Desktop.appx -ErrorAction SilentlyContinue
    Add-AppxPackage -Path $ENV:TEMP\winget.msixbundle -ErrorAction SilentlyContinue
}

$CurrentVC = Get-WmiObject -Class Win32_Product -Filter "Name LIKE '%Visual C++%'" -ErrorAction SilentlyContinue | Select-Object Name
Foreach ($App in $json.MSVCRuntime) {
    Write-Host ("Verifying if {0} is installed..." -f $App)
    if (!($CurrentVC | Select-String $App.split('+')[2].SubString(0, 4) | Select-String $App.split('-')[1])) {
        Write-Host ("{0} not found, installing..." -f $App)
        winget.exe install $App --force --source winget --accept-package-agreements --accept-source-agreements
    }
}

Foreach ($App in $json.Apps) {
    Write-Host ("Verifying if {0} is installed..." -f $App)
    winget.exe list --id $App --accept-source-agreements | Out-Null
    if ($LASTEXITCODE -eq '-1978335212') {
        Write-Host ("{0} not found, installing..." -f $App.Split('.')[1])
        winget.exe install $App --silent --force --source winget --accept-package-agreements --accept-source-agreements
    } 
}

Stop-Transcript
