# Install IIS and configure the IIS Website with custome information using DSC.

Followiing DSC Configuration Install IIS on machine and also configure websites with custom information.

```PowerShell
Configuration Configure-Website
{
  param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]     
        [string]$MachineName,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]     
        [string]$WebSitePrefix,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]     
        [string]$DevPublicDNS,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]     
        [string]$UatPublicDNS,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]     
        [string]$ProdPublicDNS



  )
  
  Node $MachineName
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
            Name            = $WebSitePrefix + '-dev'
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
            Name            = $WebSitePrefix +'-uat'
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
            Name            = $WebSitePrefix +'-qa'
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
    
  }
} 

```

To call this DSC Configuration save the PowerShell code above as ps1 file and have it in file format, you may refer the below json snippet and main page help to know more how to use DSC extention in ARM templates.

```json
{
      "type": "Microsoft.Compute/virtualMachines/extensions",
      "name": "[concat(parameters('virtualMachineName'),'/', 'MyDSCConfig')]",
      "apiVersion": "2015-06-15",
      "location": "[resourceGroup().location]",
      "dependsOn": [
        "[concat('Microsoft.Compute/virtualMachines/', parameters('virtualMachineName'))]"
      ],
      "properties": {
        "publisher": "Microsoft.Powershell",
        "type": "DSC",
        "typeHandlerVersion": "2.19",
        "autoUpgradeMinorVersion": true,
        "settings": {
          "ModulesUrl": "https://YourConfigZipfileURL/cygrp-demo-vm-rg/Configure-SomeDSC.zip",
          "ConfigurationFunction": "Configure-SomeDSC.ps1\\Configure-SomeDSC",
          "Properties": {
            "MachineName": "[parameters('virtualMachineName')]",
            "WebSitePrefix":"WebsitePrefix",
            "DevPublicDNS":"WebsitePrefix",
            "UatPublicDNS":"WebsitePrefix",
            "ProdPublicDNS":"WebsitePrefix"
          }
        },
        "protectedSettings": null
      }
}

```