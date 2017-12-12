$script:DSCModuleName      = 'xSQLServer'
$script:DSCResourceName    = 'MSFT_xSQLServerMaxDop'

#region HEADER

# Unit Test Template Version: 1.2.0
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Unit

#endregion HEADER

function Invoke-TestSetup {
}

function Invoke-TestCleanup {
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
}

# Begin Testing
try
{
    Invoke-TestSetup

    InModuleScope $script:DSCResourceName {
        $mockSQLServerName                  = 'localhost'
        $mockSQLServerInstanceName          = 'MSSQLSERVER'
        $mockMaxDegreeOfParallelism         = 4
        $mockExpectedMaxDopForAlterMethod   = 1
        $mockInvalidOperationForAlterMethod = $false
        $mockNumberOfLogicalProcessors      = 4
        $mockNumberOfCores                  = 4

        # Default parameters that are used for the It-blocks
        $mockDefaultParameters = @{
            SQLInstanceName = $mockSQLServerInstanceName
            SQLServer       = $mockSQLServerName
        }
        
        #region Function mocks

        $mockConnectSQL = {
            return @(
                (
                    New-Object Object | 
                        Add-Member -MemberType NoteProperty -Name InstanceName -Value $mockSQLServerInstanceName -PassThru |
                        Add-Member -MemberType NoteProperty -Name ComputerNamePhysicalNetBIOS -Value $mockSQLServerName -PassThru |
                        Add-Member -MemberType ScriptProperty -Name Configuration -Value {
                            return @( ( New-Object Object |
                                Add-Member -MemberType ScriptProperty -Name MaxDegreeOfParallelism -Value {
                                    return @( ( New-Object Object |
                                        Add-Member -MemberType NoteProperty -Name DisplayName -Value 'max degree of parallelism' -PassThru |
                                        Add-Member -MemberType NoteProperty -Name Description -Value 'maximum degree of parallelism' -PassThru |
                                        Add-Member -MemberType NoteProperty -Name RunValue -Value $mockMaxDegreeOfParallelism -PassThru |
                                        Add-Member -MemberType NoteProperty -Name ConfigValue -Value $mockMaxDegreeOfParallelism -PassThru -Force
                                    ) )
                                } -PassThru -Force 
                            ) )
                        } -PassThru |
                        Add-Member -MemberType ScriptMethod -Name Alter -Value {
                            if ( $this.Configuration.MaxDegreeOfParallelism.ConfigValue -ne $mockExpectedMaxDopForAlterMethod )
                            {
                                throw "Called mocked Alter() method without setting the right MaxDegreeOfParallelism. Expected '{0}'. But was '{1}'." `
                                      -f $mockExpectedMaxDopForAlterMethod, $this.Configuration.MaxDegreeOfParallelism.ConfigValue
                            }
                            if ($mockInvalidOperationForAlterMethod)
                            {
                                throw 'Mock Alter Method was called with invalid operation.'
                            }
                        } -PassThru -Force
                )
            )
        }

        $mockCimInstance_Win32Processor = {
            return @(
                (
                    New-Object Object |
                        Add-Member -MemberType NoteProperty -Name NumberOfLogicalProcessors -Value $mockNumberOfLogicalProcessors -PassThru |
                        Add-Member -MemberType NoteProperty -Name NumberOfCores -Value $mockNumberOfCores -PassThru -Force
                )
            )
        }

        #endregion

        Describe "MSFT_xSQLServerMaxDop\Get-TargetResource" -Tag 'Get'{
            Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable
        
            Context 'When the system is either in the desired state or not in the desired state' {
                $testParameters = $mockDefaultParameters

                $result = Get-TargetResource @testParameters
                
                It 'Should return the current value for MaxDop' {
                    $result.MaxDop | Should Be $mockMaxDegreeOfParallelism
                }

                It 'Should return the same values as passed as parameters' {
                    $result.SQLServer | Should Be $testParameters.SQLServer
                    $result.SQLInstanceName | Should Be $testParameters.SQLInstanceName
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }
        
            Assert-VerifiableMocks
        }
        
        Describe "MSFT_xSQLServerMaxDop\Test-TargetResource" -Tag 'Test'{
            BeforeEach {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable

                Mock -CommandName Get-CimInstance -MockWith $mockCimInstance_Win32Processor -ParameterFilter { 
                    $ClassName -eq 'Win32_Processor'
                } -Verifiable

                Mock -CommandName Get-CimInstance -MockWith {
                    throw 'Mocked function Get-CimInstance was called with the wrong set of parameter filters.'
                }
            }            

            Context 'When the system is not in the desired state and DynamicAlloc is set to false' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    MaxDop          = 1
                    DynamicAlloc    = $false
                    Ensure = 'Present'
                }      

                It 'Should return the state as false when desired MaxDop is the wrong value' {
                    $result = Test-TargetResource @testParameters
                    $result | Should Be $false
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }

                It 'Should not call the mock function Get-CimInstance' {
                    Assert-MockCalled Get-CimInstance -Exactly -Times 0 -Scope Context
                }
            }

            $mockMaxDegreeOfParallelism = 6

            Context 'When the system is in the desired state and DynamicAlloc is set to false' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    MaxDop          = 6
                    DynamicAlloc    = $false
                }      

                It 'Should return the state as true when desired MaxDop is the correct value' {
                    $result = Test-TargetResource @testParameters
                    $result | Should Be $true
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }

                It 'Should not call the mock function Get-CimInstance' {
                    Assert-MockCalled Get-CimInstance -Exactly -Times 0 -Scope Context
                }
            }

            $mockMaxDegreeOfParallelism = 4

            Context 'When the system is in the desired state and DynamicAlloc is set to true' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    DynamicAlloc = $true
                }      

                It 'Should return the state as true when desired MaxDop is present' {
                    $result = Test-TargetResource @testParameters
                    $result | Should Be $true
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }

                It 'Should call the mock function Get-CimInstance with ClassName equal to Win32_Processor' {
                    Assert-MockCalled Get-CimInstance -Exactly -Times 1 -ParameterFilter { 
                        $ClassName -eq 'Win32_Processor'
                    } -Scope Context
                }
            }

            $mockNumberOfCores = 2

            Context 'When the system is not in the desired state, DynamicAlloc is set to true, NumberOfLogicalProcessors = 4 and NumberOfCores = 2' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    DynamicAlloc = $true
                }      

                It 'Should return the state as false when desired MaxDop is the wrong value' {
                    $result = Test-TargetResource @testParameters
                    $result | Should Be $false
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }

                It 'Should call the mock function Get-CimInstance with ClassName equal to Win32_Processor' {
                    Assert-MockCalled Get-CimInstance -Exactly -Times 1 -ParameterFilter { 
                        $ClassName -eq 'Win32_Processor'
                    } -Scope Context
                }
            }

            $mockNumberOfLogicalProcessors = 1

            Context 'When the system is not in the desired state, DynamicAlloc is set to true, NumberOfLogicalProcessors = 1 and NumberOfCores = 2' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    DynamicAlloc = $true
                }      

                It 'Should return the state as false when desired MaxDop is the wrong value' {
                    $result = Test-TargetResource @testParameters
                    $result | Should Be $false
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }

                It 'Should call the mock function Get-CimInstance with ClassName equal to Win32_Processor' {
                    Assert-MockCalled Get-CimInstance -Exactly -Times 1 -ParameterFilter { 
                        $ClassName -eq 'Win32_Processor'
                    } -Scope Context
                }
            }

            $mockNumberOfLogicalProcessors = 4
            $mockNumberOfCores = 8

            Context 'When the system is not in the desired state, DynamicAlloc is set to true, NumberOfLogicalProcessors = 4 and NumberOfCores = 8' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    DynamicAlloc = $true
                }      

                It 'Should return the state as false when desired MaxDop is the wrong value' {
                    $result = Test-TargetResource @testParameters
                    $result | Should Be $false
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }

                It 'Should call the mock function Get-CimInstance with ClassName equal to Win32_Processor' {
                    Assert-MockCalled Get-CimInstance -Exactly -Times 1 -ParameterFilter { 
                        $ClassName -eq 'Win32_Processor'
                    } -Scope Context
                }
            }

            Context 'When the system is not in the desired state and Ensure is set to absent' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    Ensure = 'Absent'
                }      

                It 'Should return the state as false when desired MaxDop is the wrong value' {
                    $result = Test-TargetResource @testParameters
                    $result | Should Be $false
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            $mockMaxDegreeOfParallelism = 0

            Context 'When the system is in the desired state and Ensure is set to absent' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    Ensure = 'Absent'
                }      

                It 'Should return the state as true when desired MaxDop is the correct value' {
                    $result = Test-TargetResource @testParameters
                    $result | Should Be $true
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the MaxDop parameter is not null and DynamicAlloc set to true' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    MaxDop          = 4
                    DynamicAlloc    = $true
                }

                It 'Should throw the correct error' {
                    { Test-TargetResource @testParameters } | Should Throw 'MaxDop parameter must be set to $null or not assigned if DynamicAlloc parameter is set to $true.'
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            # This is regression test for issue #576
            Context 'When the system is in the desired state and SQLServer is not set' {
                $testParameters = $mockDefaultParameters
                $testParameters.Remove('SQLServer')
                $testParameters += @{
                    Ensure = 'Absent'
                }

                It 'Should not throw an error' {
                    { Test-TargetResource @testParameters } | Should Not Throw
                }
            }

            Assert-VerifiableMocks
        }
        
        Describe "MSFT_xSQLServerMaxDop\Set-TargetResource" -Tag 'Set'{
            BeforeEach {
                Mock -CommandName Connect-SQL -MockWith $mockConnectSQL -Verifiable

                Mock -CommandName Get-CimInstance -MockWith $mockCimInstance_Win32Processor -ParameterFilter { 
                    $ClassName -eq 'Win32_Processor'
                } -Verifiable

                Mock -CommandName Get-CimInstance -MockWith {
                    throw 'Mocked function Get-CimInstance was called with the wrong set of parameter filters.'
                }
            }

            Context 'When the MaxDop parameter is not null and DynamicAlloc set to true' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    MaxDop          = 4
                    DynamicAlloc    = $true
                    Ensure          = 'Present'
                }

                It 'Should throw the correct error' {
                    { Set-TargetResource @testParameters } | Should Throw 'MaxDop parameter must be set to $null or not assigned if DynamicAlloc parameter is set to $true.'
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            $mockMaxDegreeOfParallelism = 0
            $mockExpectedMaxDopForAlterMethod = 0

            Context 'When the Ensure parameter is set to Absent' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    Ensure = 'Absent'
                }

                It 'Should Not Throw when Ensure parameter is set to Absent' {
                    { Set-TargetResource @testParameters } | Should Not Throw
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            $mockMaxDegreeOfParallelism = 1
            $mockExpectedMaxDopForAlterMethod = 1

            Context 'When the desired MaxDop parameter is not set' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    MaxDop          = 1
                    DynamicAlloc    = $false
                    Ensure          = 'Present'
                }

                It 'Should Not Throw when MaxDop parameter is not null and DynamicAlloc set to false' {
                    { Set-TargetResource @testParameters } | Should Not Throw
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            $mockMaxDegreeOfParallelism = 2
            $mockExpectedMaxDopForAlterMethod = 2
            $mockNumberOfLogicalProcessors = 4
            $mockNumberOfCores = 2

            Context 'When the system is not in the desired state and DynamicAlloc is set to true' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    DynamicAlloc    = $true
                    Ensure          = 'Present'
                }      

                It 'Should Not Throw when MaxDop parameter is not null and DynamicAlloc set to false' {
                    { Set-TargetResource @testParameters } | Should Not Throw
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }

                It 'Should call the mock function Get-CimInstance with ClassName equal to Win32_Processor' {
                    Assert-MockCalled Get-CimInstance -Exactly -Times 1 -ParameterFilter { 
                        $ClassName -eq 'Win32_Processor'
                    } -Scope Context
                }
            }

            $mockInvalidOperationForAlterMethod = $true

            Context 'When the desired MaxDop parameter is not set' {
                $testParameters = $mockDefaultParameters
                $testParameters += @{
                    MaxDop          = 1
                    DynamicAlloc    = $false
                    Ensure          = 'Present'
                }

                It 'Shoud throw the correct error when Alter() method was called with invalid operation' {
                    $throwInvalidOperation = ('Unexpected result when trying to configure the max degree of parallelism ' + `
                                              'server configuration option. InnerException: Exception calling "Alter" ' + `
                                              'with "0" argument(s): "Mock Alter Method was called with invalid operation."')
                    
                    { Set-TargetResource @testParameters } | Should Throw $throwInvalidOperation 
                }

                It 'Should call the mock function Connect-SQL' {
                    Assert-MockCalled Connect-SQL -Exactly -Times 1 -Scope Context
                }
            }

            Assert-VerifiableMocks
        }
    }
}
finally
{
    Invoke-TestCleanup
}
