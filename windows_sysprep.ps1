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
Set-ExecutionPolicy Bypass -Force:$True -Confirm:$False -ErrorAction SilentlyContinue
