﻿<#
.EXAMPLE
    This example will enable TCP/IP protocol and set the custom static port to 4509.
    When RestartService is set to $true the resource will also restart the SQL service.
#>
Configuration Example
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $SysAdminAccount
    )

    Import-DscResource -ModuleName xSqlServer

    node localhost
    {
        xSQLServerNetwork 'ChangeTcpIpOnDefaultInstance'
        {
            InstanceName = 'MSSQLSERVER'
            ProtocolName = 'Tcp'
            IsEnabled = $true
            TCPDynamicPorts = '0'
            RestartService = $true
        }
    }
}
