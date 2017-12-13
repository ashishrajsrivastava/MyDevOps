# This script will invoke a DSC configuration
 
"`n`tPerforming DSC Configuration`n"

$PSVersionTable.PSVersion

. .\Install-WebServer.ps1

( Install-WebServer -COMPUTERNAME $ENV:COMPUTERNAME ).FullName |
   Set-Content -Path .\Artifacts.txt

Start-DscConfiguration .\Install-WebServer -Wait -Force -verbose