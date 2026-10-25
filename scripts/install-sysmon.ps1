# Install Sysmon with a community configuration. Run in an elevated PowerShell.
$work = Join-Path $env:TEMP "sysmon-install"
New-Item -ItemType Directory -Force -Path $work | Out-Null
Set-Location $work

Invoke-WebRequest "https://download.sysinternals.com/files/Sysmon.zip" -OutFile Sysmon.zip
Expand-Archive Sysmon.zip -DestinationPath Sysmon -Force
Invoke-WebRequest "https://raw.githubusercontent.com/SwiftOnSecurity/sysmon-config/master/sysmonconfig-export.xml" -OutFile sysmonconfig.xml

.\Sysmon\Sysmon64.exe -accepteula -i sysmonconfig.xml
Get-Service Sysmon64
