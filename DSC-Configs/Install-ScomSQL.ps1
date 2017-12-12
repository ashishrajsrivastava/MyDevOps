Configuration Install-ScomSQL
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]$PackagePath,

        [Parameter(Mandatory)]
		[System.Management.Automation.PSCredential]$AdminCreds,
		
		[Parameter(Mandatory)]
		[System.Management.Automation.PSCredential]$FileShareCreds,
		
		[Parameter(Mandatory)]
		[System.Management.Automation.PSCredential]$SQLAgentCreds,
		
		[Parameter(Mandatory)]
		[System.Management.Automation.PSCredential]$SQLServiceCreds,
		
		[Parameter(Mandatory)]
		[System.Management.Automation.PSCredential]$SQLSAAccountCreds,
		
		[Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]$Features,
		
		[Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]$UpdateSource,
		
		[Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]$UpdateEnabled,
		
		[Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]$InstallSharedDir,
		
		[Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]$InstallSharedWOWDir,
		
		[Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]$SQLInstanceName,
		
		[Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]$SQLInstanceDir,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]$SQLDataPath,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]$SQLLogPath,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]$SQLTempPath,
		
		[Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]$SecurityMode,
		
		[Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]$SQLSysAdminAccounts
		

    )
	Import-DscResource -ModuleName xSQLServer,xWebAdministration
			
    Node localhost
    {
        

        #
        # Ensure that .NET framework features are installed (pre-reqs for SQL)
        #
       WindowsFeature "Web-WebServer"
            {
                Ensure = "Present"
                Name = "Web-WebServer"
            }

            WindowsFeature "Web-Request-Monitor"
            {
                Ensure = "Present"
                Name = "Web-Request-Monitor"
            }

            WindowsFeature "Web-Windows-Auth"
            {
                Ensure = "Present"
                Name = "Web-Windows-Auth"
            }

            WindowsFeature "Web-Asp-Net"
            {
                Ensure = "Present"
                Name = "Web-Asp-Net"
            }

            WindowsFeature "Web-Asp-Net45"
            {
                Ensure = "Present"
                Name = "Web-Asp-Net45"
            }

            WindowsFeature "NET-WCF-HTTP-Activation45"
            {
                Ensure = "Present"
                Name = "NET-WCF-HTTP-Activation45"
            }

            WindowsFeature "Web-Mgmt-Console"
            {
                Ensure = "Present"
                Name = "Web-Mgmt-Console"
            }

            WindowsFeature "Web-Metabase"
            {
                Ensure = "Present"
                Name = "Web-Metabase"
            }
         
	    Log ParamLog
        {
            Message = "Running SQLInstall. PackagePath = $PackagePath"
        }

        File sqldatafolder
         {
            Type = 'Directory'
            DestinationPath = $SQLDataPath
            Ensure = "Present"
         }

           File sqllogfolder
         {
            Type = 'Directory'
            DestinationPath = $SQLLogPath
            Ensure = "Present"
         }

            File sqltempfolder
         {
            Type = 'Directory'
            DestinationPath = $SQLTempPath
            Ensure = "Present"
         }

         $DependsOn = @(
                "[File]sqldatafolder",
                "[File]sqllogfolder",
                "[File]sqltempfolder",
                "[WindowsFeature]Web-WebServer",
                "[WindowsFeature]Web-Request-Monitor",
                "[WindowsFeature]Web-Windows-Auth",
                "[WindowsFeature]Web-Asp-Net",
                "[WindowsFeature]NET-WCF-HTTP-Activation45",
                "[WindowsFeature]Web-Mgmt-Console",
                "[WindowsFeature]Web-Metabase",
                "[WindowsFeature]Web-Asp-Net45"
            )

		
		xSQLServerSetup SQLServerSetup

		{   
            DependsOn = $DependsOn        
            SourcePath = $PackagePath
            SourceCredential = $FileShareCreds           
            PsDscRunAsCredential  = $AdminCreds
			SQLSvcAccount = $SQLServiceCreds
            AgtSvcAccount = $SQLAgentCreds
			SAPWd = $SQLSAAccountCreds		
			InstanceName =  $SQLInstanceName  
			InstanceDir = $SQLInstanceDir
            SQLUserDBDir = $SQLDataPath
            SQLUserDBLogDir = $SQLLogPath
            SQLTempDBDir = $SQLTempPath
            SecurityMode =  $SecurityMode 
            SQLSysAdminAccounts =  @($SQLSysAdminAccounts)
			UpdateSource = $UpdateSource 
     		InstallSharedDir = $InstallSharedDir
            InstallSharedWOWDir = $InstallSharedWOWDir
			Features = $Features 
			UpdateEnabled =  $UpdateEnabled 
        }

        #adding sql server feature firewall rules.
        xSqlServerFirewall SqlFirewallRules
        {
                        DependsOn = '[xSQLServerSetup]SQLServerSetup'
                        Ensure               = 'Present'
                        Features             = 'SQLENGINE'
                        InstanceName         = $SQLInstanceName
                        SourcePath           = $PackagePath
                        SourceCredential = $AdminCreds
        }                       
   
		LocalConfigurationManager 
        {
            RebootNodeIfNeeded = $True
        }

    }
}
