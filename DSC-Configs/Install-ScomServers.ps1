configuration Install-ScomServers
{
 param(
        
        [Parameter(Mandatory)]
		[System.Management.Automation.PSCredential]$SystemCenter2012OperationsManagerActionAccount,

        [Parameter(Mandatory)]
		[System.Management.Automation.PSCredential]$SystemCenter2012OperationsManagerDASAccount,

         [Parameter(Mandatory)]
		[System.Management.Automation.PSCredential]$SystemCenter2012OperationsManagerDataReader,

        [Parameter(Mandatory)]
		[System.Management.Automation.PSCredential]$SystemCenter2012OperationsManagerDataWriter,

        [Parameter(Mandatory)]
		[System.Management.Automation.PSCredential]$InstallerServiceAccount,

        [Parameter(Mandatory)]
		[string]$SystemCenter2016ProductKey,

        [Parameter(Mandatory)]
		[string]$SystemCenter2016OperationsManagerDatabaseServer,

        [Parameter(Mandatory)]
		[string]$SystemCenter2016OperationsManagerDatabaseInstance,

        [Parameter(Mandatory)]
		[string]$SystemCenter2016OperationsManagerDatawarehouseInstance,

        [Parameter(Mandatory)]
		[string]$SystemCenter2016OperationsManagerReportingInstance,

        [Parameter(Mandatory)]
        [string]$MachineName,

        [Parameter(Mandatory)]
        [string]$ManagementGroupName,
        
        [Parameter(Mandatory)]
        [string]$PackagePath,

        [Parameter(Mandatory)]
        [string]$SQLServer2012SystemCLRTypesPath,

        [Parameter(Mandatory)]
        [string]$ReportViewer2012RedistributablePath
 
       )

    Import-DscResource -Module xCredSSP
    Import-DscResource -Module xSQLServer
    Import-DscResource -Module xSCOM
    # One can evaluate expressions to get the node list
    # E.g: $AllNodes.Where("Role -eq Web").NodeName
    node $MachineName
    {
        
         # Set LCM to reboot if needed   
           LocalConfigurationManager
            {
            DebugMode = $true
            RebootNodeIfNeeded = $true
            }

         # Install .NET Framework 3.5 on SQL and Web Console nodes    
            WindowsFeature "NET-Framework-Core"
            {
                Ensure = "Present"
                Name = "NET-Framework-Core"
            }

          # Install IIS on Web Console Servers

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


        # Add service accounts to admins on Management Servers
           Group "Administrators"
            {
                GroupName = "Administrators"
                MembersToInclude = @(
                    $SystemCenter2012OperationsManagerActionAccount.UserName,
                    $SystemCenter2012OperationsManagerDASAccount.UserName
                )
                Credential = $InstallerServiceAccount
            
             }

        # Install first Management Server
           
            # Enable CredSSP - required for ProductKey PS cmdlet
            xCredSSP "Server"
            {
                Ensure = "Present"
                Role = "Server"
            }

            xCredSSP "Client"
            {
                Ensure = "Present"
                Role = "Client"
                DelegateComputers = $MachineName
            }

            # Create DependsOn for first Management Server
            $DependsOn = @(
                "[xCredSSP]Server",
                "[xCredSSP]Client",
                "[Group]Administrators"
            )

          
          
            # Install first Management Server
            xSCOMManagementServerSetup "OMMS"
            {
                DependsOn = $DependsOn
                Ensure = "Present"
                SourcePath = $PackagePath
                SetupCredential = $InstallerServiceAccount
                ProductKey = $SystemCenter2016ProductKey
                ManagementGroupName = $ManagementGroupName
                FirstManagementServer = $true
                ActionAccount = $SystemCenter2012OperationsManagerActionAccount
                DASAccount = $SystemCenter2012OperationsManagerDASAccount
                DataReader = $SystemCenter2012OperationsManagerDataReader
                DataWriter = $SystemCenter2012OperationsManagerDataWriter
                SqlServerInstance = $SystemCenter2016OperationsManagerDatabaseServer
                DatabaseName = $SystemCenter2016OperationsManagerDatabaseInstance
                DwSqlServerInstance = $SystemCenter2016OperationsManagerDatabaseServer
                DwDatabaseName = $SystemCenter2016OperationsManagerDatawarehouseInstance
            }


            # Install Report Viewer 2012 on Web Console Servers and Consoles

            

            Package "SQLServer2016SystemCLRTypes"
            {
                Ensure = "Present"
                Name = "Microsoft System CLR Types for SQL Server 2016 (x64)"
                ProductId = ""
                Path = $SQLServer2012SystemCLRTypesPath
                Arguments = "ALLUSERS=2"
                Credential = $InstallerServiceAccount
            }


            Package "ReportViewer2016Redistributable"
            {
                DependsOn = "[Package]SQLServer2016SystemCLRTypes"
                Ensure = "Present"
                Name = "Microsoft Report Viewer 2016 Runtime"
                ProductID = ""
                Path = $ReportViewer2012RedistributablePath
                Arguments = "ALLUSERS=2"
                Credential = $InstallerServiceAccount
            }

             # Install Reporting Server
            xSCOMReportingServerSetup "OMRS"
            {
                DependsOn = "[xSCOMManagementServerSetup]OMMS"
                Ensure = "Present"
                SourcePath = $PackagePath
                SetupCredential = $InstallerServiceAccount
                ManagementServer = $MachineName
                SRSInstance = ($SystemCenter2016OperationsManagerDatabaseServer + "\" + $SystemCenter2016OperationsManagerReportingInstance)
                DataReader = $SystemCenter2012OperationsManagerDataReader
            }


            # Install Web Console Servers
            $DependsOn += @(
                "[WindowsFeature]NET-Framework-Core",
                "[WindowsFeature]Web-WebServer",
                "[WindowsFeature]Web-Request-Monitor",
                "[WindowsFeature]Web-Windows-Auth",
                "[WindowsFeature]Web-Asp-Net",
                "[WindowsFeature]Web-Asp-Net45",
                "[WindowsFeature]NET-WCF-HTTP-Activation45",
                "[WindowsFeature]Web-Mgmt-Console",
                "[WindowsFeature]Web-Metabase",
                "[Package]SQLServer2012SystemCLRTypes",
                "[Package]ReportViewer2012Redistributable",
                "[xSCOMManagementServerSetup]OMMS"
            )
           
            xSCOMWebConsoleServerSetup "OMWC"
            {
                DependsOn = $DependsOn
                Ensure = "Present"
                SourcePath = $PackagePath
                SetupCredential = $InstallerServiceAccount
                ManagementServer = $MachineName
            }

            # Install Consoles
            xSCOMConsoleSetup "OMC"
            {
                DependsOn = @(
                    "[Package]SQLServer2012SystemCLRTypes",
                    "[Package]ReportViewer2012Redistributable"
                )
                Ensure = "Present"
                SourcePath = $PackagePath
                SetupCredential = $InstallerServiceAccount
            }

  
    }
}