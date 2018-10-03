$vault = Get-AzureRmRecoveryServicesVault -Name "demobackupvault" -ResourceGroupName backupvaultrgs

Set-AzureRmRecoveryServicesVaultContext -Vault $vault

$RetPol = Get-AzureRmRecoveryServicesBackupRetentionPolicyObject -WorkloadType AzureVM 
$RetPol.IsWeeklyScheduleEnabled =$true
$RetPol.IsDailyScheduleEnabled = $false
$SchPol = Get-AzureRmRecoveryServicesBackupSchedulePolicyObject -WorkloadType AzureVM 
$SchPol.ScheduleRunFrequency = "Weekly"
New-AzureRmRecoveryServicesBackupProtectionPolicy -Name "NewPolicy" -WorkloadType AzureVM -RetentionPolicy $RetPol -SchedulePolicy $SchPol