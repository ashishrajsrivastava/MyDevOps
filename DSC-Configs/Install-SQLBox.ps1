Configuration Install-SQLBox
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
        WindowsFeature NetFramework35Core
        {
            Name = "NET-Framework-Core"
            Ensure = "Present"
        }

        WindowsFeature NetFramework45Core
        {
            Name = "NET-Framework-45-Core"
            Ensure = "Present"
        } 
        
         #Install the IIS Role
          WindowsFeature IIS
         {
          Ensure = "Present"
          Name = "Web-Server"
         }

         #Install ASP.NET 4.5
         WindowsFeature ASP
         {
          Ensure = "Present"
          Name = "Web-Asp-Net45"
         }

         WindowsFeature WebServerManagementConsole
         {
          Name = "Web-Mgmt-Console"
          Ensure = "Present"
         }
         
	    Log ParamLog
        {
            Message = "Running SQLInstall. PackagePath = $PackagePath"
        }

		
		xSQLServerSetup SQLServerSetup

		{           
            SourcePath = $PackagePath
            SourceCredential = $FileShareCreds           
            PsDscRunAsCredential  = $AdminCreds
			SQLSvcAccount = $SQLServiceCreds
            AgtSvcAccount = $SQLAgentCreds
			SAPWd = $SQLSAAccountCreds		
			InstanceName =  $SQLInstanceName  
			InstanceDir = $SQLInstanceDir  
            SecurityMode =  $SecurityMode 
            SQLSysAdminAccounts =  @($SQLSysAdminAccounts)
			UpdateSource = $UpdateSource 
     		InstallSharedDir = $InstallSharedDir
            InstallSharedWOWDir = $InstallSharedWOWDir
			Features = $Features 
			UpdateEnabled =  $UpdateEnabled 
        }                       
   
		LocalConfigurationManager 
        {
            RebootNodeIfNeeded = $True
        }

    }
}
