<#
.EXAMPLE
This example shows how to ensure that the Availability Group 'TestAG' does not exist.
#>

$ConfigurationData = @{
    AllNodes = @(
        @{
            NodeName= '*'
            SQLInstanceName = 'MSSQLSERVER'
        },

        @{
            NodeName = 'SP23-VM-SQL1'
            Role = 'PrimaryReplica'
        }
    )
}

Configuration Example
{
    param(
        [Parameter(Mandatory = $true)]
        [PSCredential]
        $SysAdminAccount
    )

    Import-DscResource -ModuleName xSqlServer

    Node $AllNodes.NodeName {
        if ( $Node.Role -eq 'PrimaryReplica' )
        {
            # Create the availability group on the instance tagged as the primary replica
            xSQLServerAlwaysOnAvailabilityGroup RemoveTestAG
            {
                Ensure = 'Absent'
                Name = 'TestAG'
                SQLInstanceName = $Node.SQLInstanceName
                SQLServer = $Node.NodeName
                PsDscRunAsCredential = $SysAdminAccount
            }
        }
    }
}
