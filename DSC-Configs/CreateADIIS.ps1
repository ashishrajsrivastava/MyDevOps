configuration CreateADIIS 
{ 
   param 
   ( 

        [Parameter(Mandatory)]
        [String]$DomainName,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$Admincreds,

        [Int]$RetryCount=20,
        [Int]$RetryIntervalSec=30
    ) 
    
    Import-DscResource -ModuleName xActiveDirectory, xStorage, xNetworking, PSDesiredStateConfiguration, xPendingReboot, xWebAdministration
    [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($Admincreds.UserName)", $Admincreds.Password)
    $Interface=Get-NetAdapter|Where Name -Like "Ethernet*"|Select-Object -First 1
    $InterfaceAlias=$($Interface.Name)

    Node localhost
    {
        


        LocalConfigurationManager 
        {
            RebootNodeIfNeeded = $true
        }


         #Install the IIS Role
          WindowsFeature IIS
         {
          Ensure = “Present”
          Name = “Web-Server”
         }

         #Install ASP.NET 4.5
         WindowsFeature ASP
         {
          Ensure = “Present”
          Name = “Web-Asp-Net45”
         }

         WindowsFeature WebServerManagementConsole
         {
          Name = "Web-Mgmt-Console"
          Ensure = "Present"
         }
         File devfolder
         {
            Type = 'Directory'
            DestinationPath = 'C:\inetpub\wwwroot\dev'
            Ensure = "Present"
            DependsOn       = '[WindowsFeature]ASP'
         }
         File uatfolder
         {
            Type = 'Directory'
            DestinationPath = 'C:\inetpub\wwwroot\uat'
            Ensure = "Present"
            DependsOn       = '[WindowsFeature]ASP'
         }  
         File prodfolder
         {
            Type = 'Directory'
            DestinationPath = 'C:\inetpub\wwwroot\prod'
            Ensure = "Present"
            DependsOn       = '[WindowsFeature]ASP'
         }
         
          xWebsite DevWebsite
         {
            Ensure          = 'Present'
            Name            = 'dellcost-dev'
            State           = 'Started'
            PhysicalPath    = 'C:\inetpub\wwwroot\dev'
            BindingInfo     = @( MSFT_xWebBindingInformation
                                 {
                                   Protocol              = "HTTP"
                                   Port                  = 80
                                   HostName = 'dellcost-dev.cygrp.com'
                                 }
                                 
                                )
            DependsOn       = '[File]devfolder'
            
         } 
         xWebsite UatWebsite
         {
            Ensure          = 'Present'
            Name            = 'dellcost-uat'
            State           = 'Started'
            PhysicalPath    = 'C:\inetpub\wwwroot\uat'
            BindingInfo     = @( MSFT_xWebBindingInformation
                                 {
                                   Protocol              = "HTTP"
                                   Port                  = 80
                                   HostName = 'dellcost-uat.cygrp.com'
                                 }
                                 
                                )
            DependsOn       = '[File]uatfolder'
         }

         xWebsite prodWebsite
         {
            Ensure          = 'Present'
            Name            = 'dellcost-qa'
            State           = 'Started'
            PhysicalPath    = 'C:\inetpub\wwwroot\prod'
            BindingInfo     = @( MSFT_xWebBindingInformation
                                 {
                                   Protocol              = "HTTP"
                                   Port                  = 80
                                   HostName = 'dellcost-qa.cygrp.com'
                                 }
                                 
                                )
            DependsOn       = '[File]prodfolder'
         }

	    WindowsFeature DNS 
        { 
            Ensure = "Present" 
            Name = "DNS"		
        }

        Script EnableDNSDiags
	    {
      	    SetScript = { 
		        Set-DnsServerDiagnostics -All $true
                Write-Verbose -Verbose "Enabling DNS client diagnostics" 
            }
            GetScript =  { @{} }
            TestScript = { $false }
	        DependsOn = "[WindowsFeature]DNS"
        }

	    WindowsFeature DnsTools
	    {
	        Ensure = "Present"
            Name = "RSAT-DNS-Server"
            DependsOn = "[WindowsFeature]DNS"
	    }

        xDnsServerAddress DnsServerAddress 
        { 
            Address        = '127.0.0.1' 
            InterfaceAlias = $InterfaceAlias
            AddressFamily  = 'IPv4'
	        DependsOn = "[WindowsFeature]DNS"
        }

        xWaitforDisk Disk2
        {
            DiskNumber = 2
            RetryIntervalSec =$RetryIntervalSec
            RetryCount = $RetryCount
        }

        xDisk ADDataDisk {
            DiskNumber = 2
            DriveLetter = "F"
            DependsOn = "[xWaitForDisk]Disk2"
        }

        WindowsFeature ADDSInstall 
        { 
            Ensure = "Present" 
            Name = "AD-Domain-Services"
	        DependsOn="[WindowsFeature]DNS" 
        } 

        WindowsFeature ADDSTools
        {
            Ensure = "Present"
            Name = "RSAT-ADDS-Tools"
            DependsOn = "[WindowsFeature]ADDSInstall"
        }

        WindowsFeature ADAdminCenter
        {
            Ensure = "Present"
            Name = "RSAT-AD-AdminCenter"
            DependsOn = "[WindowsFeature]ADDSInstall"
        }
         
        xADDomain FirstDS 
        {
            DomainName = $DomainName
            DomainAdministratorCredential = $DomainCreds
            SafemodeAdministratorPassword = $DomainCreds
            DatabasePath = "F:\NTDS"
            LogPath = "F:\NTDS"
            SysvolPath = "F:\SYSVOL"
	        DependsOn = @("[xDisk]ADDataDisk", "[WindowsFeature]ADDSInstall")
        } 

   }
} 