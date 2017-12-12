﻿<#
    .EXAMPLE
        This example will make sure that the endpoint DefaultMirrorEndpoint is in started state in the default instance, if not it will start the endpoint.

    .EXAMPLE
        This example will make sure that the endpoint HADR is in started state in the default instance, if not it will start the endpoint.

    .EXAMPLE
        This example will make sure that the endpoint DefaultMirrorEndpoint is in started state in the named instance INSTANCE1, if not it will start the endpoint.

    .NOTES
        There is three different scenarios in this example to validate the schema during unit testing.
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

    Import-DscResource -ModuleName xSQLServer

    node localhost
    {
        # Start the DefaultMirrorEndpoint in the default instance
        xSQLServerEndpointState StartEndpoint1
        {
            NodeName = 'SQLNODE01.company.local'
            InstanceName = 'MSSQLSERVER'
            Name = 'DefaultMirrorEndpoint'
            State = 'Started'

            PsDscRunAsCredential = $SysAdminAccount
        }

        # Start the HADR in the default instance
        xSQLServerEndpointState StartEndpoint2
        {
            NodeName = 'SQLNODE01.company.local'
            InstanceName = 'MSSQLSERVER'
            Name = 'HADR'
            State = 'Started'

            PsDscRunAsCredential = $SysAdminAccount
        }

        # Start the DefaultMirrorEndpoint in the named instance INSTANCE1
        xSQLServerEndpointState StartEndpoint3
        {
            NodeName = 'SQLNODE01.company.local'
            InstanceName = 'INSTANCE1'
            Name = 'DefaultMirrorEndpoint'
            State = 'Started'

            PsDscRunAsCredential = $SysAdminAccount
        }
    }
}
