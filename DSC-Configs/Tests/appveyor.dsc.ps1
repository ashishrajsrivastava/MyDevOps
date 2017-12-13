# This script will invoke a DSC configuration
 
"`n`tPerforming DSC Configuration`n"

. .\DSC-Configs\Install-WebServer.ps1

( Install-WebServer -COMPUTERNAME $ENV:COMPUTERNAME ).FullName |
   Set-Content -Path .\Artifacts.txt

Start-DscConfiguration .\Install-WebServer -Wait -Force -verbose