<#
.EXAMPLE
    These two example shows how to run SQL script using Windows Authentication.
    First example shows how the resource is run as account SYSTEM. And the second example shows how the resource is run with a user account.
#>

Configuration Example
{
    param(
        [Parameter(Mandatory = $true)]
        [PSCredential]
        $WindowsCredential
    )

    Import-DscResource -ModuleName xSQLServer

    Node localhost
    {
        xSQLServerScript 'RunSQLScript-AsSYSTEM'
        {
            ServerInstance = 'localhost\SQL2016'

            SetFilePath = 'C:\DSCTemp\SQLScripts\Set-RunSQLScript-AsSYSTEM.sql'
            TestFilePath = 'C:\DSCTemp\SQLScripts\Test-RunSQLScript-AsSYSTEM.sql'
            GetFilePath = 'C:\DSCTemp\SQLScripts\Get-RunSQLScript-AsSYSTEM.sql'
            Variable = @("FilePath=C:\temp\log\AuditFiles")
        }

        xSQLServerScript 'RunSQLScript-AsUSER'
        {
            ServerInstance = 'localhost\SQL2016'

            SetFilePath = 'C:\DSCTemp\SQLScripts\Set-RunSQLScript-AsUSER.sql'
            TestFilePath = 'C:\DSCTemp\SQLScripts\Test-RunSQLScript-AsUSER.sql'
            GetFilePath = 'C:\DSCTemp\SQLScripts\Get-RunSQLScript-AsUSER.sql'
            Variable = @("FilePath=C:\temp\log\AuditFiles")

            PsDscRunAsCredential = $WindowsCredential
        }

        xSQLServerScript 'RunSQLScript-With30SecondTimeout'
        {
            ServerInstance = 'localhost\SQL2016'

            SetFilePath = 'C:\DSCTemp\SQLScripts\Set-RunSQLScript-WithQueryTimeout.sql'
            TestFilePath = 'C:\DSCTemp\SQLScripts\Test-RunSQLScript-WithQueryTimeout.sql'
            GetFilePath = 'C:\DSCTemp\SQLScripts\Get-RunSQLScript-WithQueryTimeout.sql'
            QueryTimeout = 30
            Variable = @("FilePath=C:\temp\log\AuditFiles")

            PsDscRunAsCredential = $WindowsCredential
        }
    }
}
