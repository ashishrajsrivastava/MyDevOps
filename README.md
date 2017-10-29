# How to use the DSC Configuration hosted here.

Each file have powershell dsc configuration like below:

```PowerShell
Configuration Configure-SomeDSC
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]$PackagePath,

        [Parameter(Mandatory)]
		[System.Management.Automation.PSCredential]$AdminCreds,
		
		

    )
	Import-DscResource -ModuleName SomeModuleName,AnotherModuleName
			
    Node localhost
    {
     #DSC work here   

        
    }
}
```

Copy the complete config and save as Configure-SomeDSC.ps1 file format. Zip the file with the same name as the ps1 file name.

Upload the zip file on a blob or file storage or any other internet accessible location. To have the file non public make sure you use Azure blob or file storage and use storage account access key in the following steps.

Now you need to reference the same uploaded DSC configuration in to your arm template using following resourse code.

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
            "MachineName": "[parameters('virtualMachineName')]"
            
          }
        },
        "protectedSettings": null
      }
}
```

Run your arm deployment and your deployment should be able install DSC extenstion and Apply the DSC Configuration.