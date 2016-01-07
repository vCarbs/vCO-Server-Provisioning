# Variables retrieved from vCenter Orchestrator
param(
	[string]$vmName, #User defined vCO
	[string]$Datastore, #Dropdown, Configurations
	[string]$SpecFile, #Auto Assigned, Configurations
	[string]$ipMode, #Dropdown, Configurations
	[string]$ipAddress,
	[string]$subnet, #Auto Assigned, Configurations
	[string]$gateway, #Auto Assigned, Configurations
	[string]$vlan,
	[string]$dns1, #Auto Assigned, Configurations
	[string]$dns2, #Auto Assigned, Configurations
	[string]$Template, #Auto Assigned, Configurations
	[string]$vmHost, #Auto Assigned, Configurations
	[string]$vmFolder,
	[string]$diskType = 'Thin',
	[string]$OU, #Auto Assigned, Configurations
	[string]$Description,
	[string]$PS_User,
	[string]$PS_PW,
	[string]$VC_Server,
	[int]$vmCPU, #Dropdown, Configurations
	[int]$vmMemory #Dropdown, Configurations
)

# Loads PowerShell Modules
Add-PSSnapin VMware.VimAutomation.Core

# Creates credential store
$SecurePassword = Convertto-SecureString -String $PS_PW -AsPlainText -force
$mycred = New-Object System.Management.Automation.PSCredential $PS_User, $SecurePassword

#Connects to the vCenter Server
Connect-VIServer $VC_Server -Force -Credential $mycred | Out-Null

#Deploys VM based on provided input
if ($ipMode -eq "UseStaticIP"){
    Get-OSCustomizationSpec $SpecFile | Get-OScustomizationNicMapping | Set-OSCustomizationNicMapping -ipMode $ipMode -ipAddress $ipAddress -subnetMask $subnet -defaultGateway $gateway -DNS $dns1,$dns2 | Out-Null
}
Else{
    Get-OSCustomizationSpec $SpecFile | Get-OScustomizationNicMapping | Set-OSCustomizationNicMapping -ipMode $ipMode | Out-Null
}

Write-Host "Starting VM build"
New-VM -Name $vmName -Template $Template -VMHost $vmHost -Datastore $Datastore -OSCustomizationSpec $SpecFile -RunASync | Wait-Task | Out-Null

$vm = Get-VM -Name $vmName

Write-Host "Setting $vmCPU CPU's and $vmMemory GB RAM"
Set-VM -VM $vm -NumCpu $vmCPU -MemoryGB $vmMemory -Notes "$Description" -Confirm:$false -RunASync | Wait-Task | Out-Null

Write-Host "Setting $vlan vlan name"
Get-NetworkAdapter -VM $vm | Set-NetworkAdapter -NetworkName $vlan -Confirm:$false -RunASync | Wait-Task | Out-Null

# Power on VM
Write-Host "Powering on VM"
Start-VM -VM $vm -Confirm:$false -RunASync | Wait-Task | Out-Null

Disconnect-VIServer -Force -Confirm:$false -ErrorAction SilentlyContinue