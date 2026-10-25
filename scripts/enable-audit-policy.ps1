# Turn on the audit categories a SIEM needs. Run in an elevated PowerShell on each machine,
# or set the same options in a Group Policy Object linked to the domain.

auditpol /set /subcategory:"Credential Validation"                 /success:enable /failure:enable
auditpol /set /subcategory:"Kerberos Authentication Service"       /success:enable /failure:enable
auditpol /set /subcategory:"Kerberos Service Ticket Operations"    /success:enable /failure:enable
auditpol /set /subcategory:"User Account Management"               /success:enable /failure:enable
auditpol /set /subcategory:"Security Group Management"             /success:enable /failure:enable
auditpol /set /subcategory:"Process Creation"                      /success:enable
auditpol /set /subcategory:"Logon"                                 /success:enable /failure:enable
auditpol /set /subcategory:"Logoff"                                /success:enable
auditpol /set /subcategory:"Special Logon"                         /success:enable

# Include the command line in process-creation events (Event ID 4688)
reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\Audit /v ProcessCreationIncludeCmdLine_Enabled /t REG_DWORD /d 1 /f

# PowerShell script block logging
reg add HKLM\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging /v EnableScriptBlockLogging /t REG_DWORD /d 1 /f

auditpol /get /category:*
