# This script will invoke a DSC configuration
 
"`n`tPerforming DSC Configuration`n"

. .\DSC-Configs\Install-Web.ps1

( ContosoWebsite -COMPUTERNAME $ENV:COMPUTERNAME ).FullName |
   Set-Content -Path .\Artifacts.txt

Start-DscConfiguration .\Install-Web -Wait -Force -verbose