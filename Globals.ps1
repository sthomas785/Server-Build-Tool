#--------------------------------------------
# Declare Global Variables and Functions here
#--------------------------------------------

#region Global Variables
$Global:VMCreationSelections = New-Object –TypeName PSObject
$Global:VCenterServer = ""
$Global:Location = ""
$Global:ResourcePool = ""
$Global:VMName = ""
$Global:Datastore = ""
$Global:Template = ""
$Global:OSCustomizationSpec = ""
$Global:VM = ""
$Global:FullIP = ""
$Global:LocalAdminCreds = ""
$Global:FolderObject = ""

[Int]$Global:DriveCounter = 0
[Array]$Global:DriveLetterarray = @('', 'a', 'b', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'q', 'r', 's', 't', 'u', 'v', 'x', 'y', 'z')

#endregion

Function ConnectTo-VCenter{
<#
	.SYNOPSIS
		Function to connect to VCenter.
	
	.DESCRIPTION
		Connects to the proper VCenter Server chosen by the user.
	
	.EXAMPLE
		PS C:\> ConnectTo-VCenter
	
	.NOTES
		Calls Populate-LocalOfficeDropdown when complete.
#>
	
	param(
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[String]$Server,
		[Parameter(Mandatory = $true, Position = 1, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[System.Management.Automation.PSCredential]$DomainCredential
	
	)
	
	Write-RichText -LogType 'Informational' -LogMsg "Connecting to $Server please be patient."
	
	$Connection = Connect-VIServer -Server $Server `
								   -Credential $DomainCredential
	
	If (!$Connection){
		
		Write-Richtext -LogType 'Error' -LogMsg "Unable to connect to $Server ¯\_(ツ)_/¯."
		return;
	}
	
	Else{
		
		Write-Richtext -LogType 'Success' -LogMsg "Connected to $Server."
		Write-Richtext -LogType 'Informational' -LogMsg "Retrieving Local Offices please be patient."
		
		Populate-LocalOfficeDropDown -Server $Server
	}
}

Function Populate-LocalOfficeDropDown{
<#
	.SYNOPSIS
		Function to populate the local office dropdown.
	
	.DESCRIPTION
		Function connects to VCenter and retrieves a list of local offices
		and datacenters available for that region.
	
	.EXAMPLE
		PS C:\> Populate-LocalOfficeDropDown
	
	.NOTES
		N/A
#>
	
	param
	(
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[String]$Server
	)
	
	$LocalOffices = Get-Datacenter -Server $Server
	
	If (!$LocalOffices){
		Write-Richtext -LogType 'Error' -LogMsg "Unable to Gather Local Offices."
		Return
	}
	
	Else{
		
		Write-Richtext -LogType 'Success' -LogMsg "Local Offices retrieved successfully."
		
		$LocalOfficeSelectioncomboBox.Items.clear()
		
		Foreach ($Office in $LocalOffices){
			
			$LocalOfficeSelectioncomboBox.Items.Add($Office)
		}
		
		$LocalOfficeSelectioncomboBox.enabled = $True
	}
	
}

Function Populate-TemplateDropDown{
<#
	.SYNOPSIS
		Function to populate the template combobox.
	
	.DESCRIPTION
		Function connects to VCenter and retrieves a list of templates
		based off of the server and location.
	
	.EXAMPLE
		PS C:\> Populate-TemplateDropDown
	
	.NOTES
		N/A
#>
	
	param (
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[String]$Server,
		[Parameter(Mandatory = $true, Position = 1, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[String]$Location
		
	)
	$Templates = Get-Template -Server $Server `
							  -Location $Location
	
	If (!$Templates)
	{
		Write-Richtext -LogType 'Error' -LogMsg "Unable to Gather templates from $Server."
	}
	
	Else
	{
		Write-Richtext -LogType 'Success' -LogMsg "Templates retrieved from $Server."
		
		$TemplateSelectionComboBox.Items.clear()
		
		Foreach ($Template in $Templates)
		{
			$TemplateSelectionComboBox.Items.Add($Template)
		}
		
		$TemplateSelectionComboBox.enabled = $True
	}
}

Function Populate-CustomizationDropDown{
<#
	.SYNOPSIS
		Function to Populate the CustomizationDropDown combobox.
	
	.DESCRIPTION
		Function connects to VCenter and retrieves all available Customizations.
	
	.EXAMPLE
		PS C:\> Populate-CustomizationDropDown
	
	.NOTES
		N/A
#>
	
	param
	(
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[String]$Server
	)
	
	$Customizations = Get-OSCustomizationSpec -Server $Server
	
	If (!$Customizations)
	{
		Write-Richtext -LogType 'Error' -LogMsg "Unable to Gather customizations."
	}
	
	Else
	{
		Write-Richtext -LogType 'Success' -LogMsg "Customizations retrieved successfully."
		$CustomizationSelectioncomboBox.Items.clear()
		Foreach ($Item in $Customizations)
		{
			$CustomizationSelectioncomboBox.Items.Add($($Item.name))
		}
		
		$CustomizationSelectioncomboBox.enabled = $True
	}
}

Function Populate-ESXClustersDropDown{
<#
	.SYNOPSIS
		Function to populate the ESXClusters DropDown
	
	.DESCRIPTION
		Function connects to vcenter and retrieves both a list of available clusters
		and a list of single hosts. Populates the combobox with both, clusters first.
	
	.EXAMPLE
		PS C:\> Populate-ESXClustersDropDown
	
	.NOTES
		$Erroractionpreference is toggled because i couldn't find a better way to handle the
		errors thrown when either clusters or hosts were not available. Try/Catch didn't work
		how i wanted it to. I should maybe come back to this to make it cleaner later [#TODO]
#>
	
	param (
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[String]$Server,
		[Parameter(Mandatory = $true, Position = 1, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[String]$Location
		
	)
	
	$ErrorActionPreference = 'SilentlyContinue'
	
	$Clusters = Get-Cluster -Server $Server `
							-location $Location
	
	$VMHosts = Get-VMHost -Server $Server `
						  -location $Location
	
	$ErrorActionPreference = 'Continue'
	
	If (!$Clusters -and !$VMHosts)
	{
		Write-Richtext -LogType 'Error' -LogMsg "Unable to Gather ESX Hosts or Clusters."
	}
	
	Else
	{
		Write-Richtext -LogType 'Success' -LogMsg "Clusters retrieved successfully."
		$ESXClustersComboBox.Items.clear()
		
		If ($Clusters)
		{
			Foreach ($Item in $Clusters)
			{
				$ESXClustersComboBox.Items.Add($($Item.name))
			}
		}
		If ($VMHosts)
		{
			Foreach ($Item in $VMHosts)
			{
				$ESXClustersComboBox.Items.Add($($Item.name))
			}
		}
		$ESXClustersComboBox.enabled = $True
	}
	
}

Function Populate-DatastoreClusterDropDown{
<#
	.SYNOPSIS
		Function to Populate the DatastoreCluster DropDown.
	
	.DESCRIPTION
		Function connects to VCenter and retrieves a list of datastore clusters
		and single datastores. Populates the combobox with both, clusters first.
	
	.EXAMPLE
		PS C:\> Populate-DatastoreClusterDropDown
	
	.NOTES
		This was a decent amount of work to get right. Have to first get the ESX Clusters then 
		get the datastores that belong to those. Then get the datastore clusters that belong to them.
	
		There is about a 90% chance i could do this in a more efficient way. Will check on this later.
		[#TODO]
	
		$Erroractionpreference is toggled because i couldn't find a better way to handle the
		errors thrown when either clusters or hosts were not available. Try/Catch didn't work
		how i wanted it to. I should maybe come back to this to make it cleaner later [#TODO]
#>
	
	param
	(
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		$ResourcePool
	)
	
	$ErrorActionPreference = 'SilentlyContinue'
	
	$DataStores = $ResourcePool | Get-Datastore
	
	$DataStoreClusters = $DataStores | Get-DatastoreCluster
	
	$ErrorActionPreference = 'Continue'
	
	
	If (!$DataStoreClusters -and !$DataStores)
	{
		Write-Richtext -LogType 'Error' -LogMsg "Unable to pull and DataStore Clusters or Datastores."
	}
	
	Else
	{
		Write-Richtext -LogType 'Success' -LogMsg "DataStores or Clusters retrieved successfully."
		
		$DataStoreClusterComboBox.Items.clear()
		
		If ($DataStoreClusters)
		{
			Foreach ($Item in $DataStoreClusters)
			{
				$DataStoreClusterComboBox.Items.Add($Item.name)
			}
		}
		
		If ($DataStores)
		{
			Foreach ($Item in $DataStores)
			{
				$DataStoreClusterComboBox.Items.Add($Item.name)
			}
		}
		$DataStoreClusterComboBox.enabled = $True
	}
	
}

Function Populate-PortGroupCombobox{
<#
	.SYNOPSIS
		Function to Populate the Portgroup Combobox.
	
	.DESCRIPTION
		This function is only called if more than one portgroup was matched
		during the automatic filtering process. It simply takes the multiple
		portgroups that were matched and fills in the dropdown.
	
	.PARAMETER Portgroups
		Takes a collection of Portgroup objects.
	
	.EXAMPLE
		PS C:\> Populate-DatastoreClusterDropDown -Portgroups $Portgroups
	
	.NOTES
		N/A
#>	
	param (
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[Array]$Portgroups
	)
	$PortGroupcombobox.Items.clear()
	
	Foreach ($Item in $PortGroups)
	{
		$PortGroupcombobox.Items.Add($Item.name)
	}
	
	$PortGroupcombobox.enabled = $True
}

Function Populate-FolderDropDown{
<#
	.SYNOPSIS
		Function to Populate the Portgroup Combobox.
	
	.DESCRIPTION
		This function is only called if more than one portgroup was matched
		during the automatic filtering process. It simply takes the multiple
		portgroups that were matched and fills in the dropdown.
	
	.PARAMETER Portgroups
		Takes a collection of Portgroup objects.
	
	.EXAMPLE
		PS C:\> Populate-DatastoreClusterDropDown -Portgroups $Portgroups
	
	.NOTES
		N/A
#>	
	
	$Folders = Get-Folder -Location $Global:Location | Where-Object {$_.Type -eq 'VM'} | Sort-Object
	
	$Foldercombobox.Items.clear()
	
	Foreach ($Item in $Folders)
	{
		$Foldercombobox.Items.Add($Item.name)
	}
	
	$Foldercombobox.enabled = $True
}

Function Control-VisibleExtraDrives{
<#
	.SYNOPSIS
		Function to enable/disable drive controls based on the counter.
	
	.DESCRIPTION
		Function to enable/disable drive controls based on the counter.
	
	.EXAMPLE
		PS C:\> Control-VisibleExtraDrives
	
	.NOTES
		This has to be the most inefficient thing i ever wrote :(
#>
	
	switch ($Global:DriveCounter)
	{
		0 {
			#ED1
			$ExtraDrive1_DataStoreComboBox.enabled = $false
			$ExtraDrive1_letterComboBox.enabled = $false
			$ExtraDrive1_SelectionLabel.enabled = $false
			$ExtraDrive1SizeTextBox.enabled = $false
			$ExtraDrive1_SizeLabel.enabled = $false
			$ExtraDrive1_DatastoreLabel.enabled = $false
			#ED2
			$ExtraDrive2_DataStoreComboBox.enabled = $false
			$ExtraDrive2_letterComboBox.enabled = $false
			$ExtraDrive2_SelectionLabel.enabled = $false
			$ExtraDrive2SizeTextBox.enabled = $false
			$ExtraDrive2_SizeLabel.enabled = $false
			$ExtraDrive2_DatastoreLabel.enabled = $false
			#ED3
			$ExtraDrive3_DataStoreComboBox.enabled = $false
			$ExtraDrive3_letterComboBox.enabled = $false
			$ExtraDrive3_SelectionLabel.enabled = $false
			$ExtraDrive3SizeTextBox.enabled = $false
			$ExtraDrive3_SizeLabel.enabled = $false
			$ExtraDrive3_DatastoreLabel.enabled = $false
			#ED4
			$ExtraDrive4_DataStoreComboBox.enabled = $false
			$ExtraDrive4_letterComboBox.enabled = $false
			$ExtraDrive4_SelectionLabel.enabled = $false
			$ExtraDrive4SizeTextBox.enabled = $false
			$ExtraDrive4_SizeLabel.enabled = $false
			$ExtraDrive4_DatastoreLabel.enabled = $false
			#ED5
			$ExtraDrive5_DataStoreComboBox.enabled = $false
			$ExtraDrive5_letterComboBox.enabled = $false
			$ExtraDrive5_SelectionLabel.enabled = $false
			$ExtraDrive5SizeTextBox.enabled = $false
			$ExtraDrive5_SizeLabel.enabled = $false
			$ExtraDrive5_DatastoreLabel.enabled = $false
			
		}
		1 {
			#ED1
			$ExtraDrive1_DataStoreComboBox.enabled = $true
			$ExtraDrive1_letterComboBox.enabled = $true
			$ExtraDrive1_SelectionLabel.enabled = $true
			$ExtraDrive1SizeTextBox.enabled = $true
			$ExtraDrive1_SizeLabel.enabled = $true
			$ExtraDrive1_DatastoreLabel.enabled = $true
			#ED2
			$ExtraDrive2_DataStoreComboBox.enabled = $false
			$ExtraDrive2_letterComboBox.enabled = $false
			$ExtraDrive2_SelectionLabel.enabled = $false
			$ExtraDrive2SizeTextBox.enabled = $false
			$ExtraDrive2_SizeLabel.enabled = $false
			$ExtraDrive2_DatastoreLabel.enabled = $false
			#ED3
			$ExtraDrive3_DataStoreComboBox.enabled = $false
			$ExtraDrive3_letterComboBox.enabled = $false
			$ExtraDrive3_SelectionLabel.enabled = $false
			$ExtraDrive3SizeTextBox.enabled = $false
			$ExtraDrive3_SizeLabel.enabled = $false
			$ExtraDrive3_DatastoreLabel.enabled = $false
			#ED4
			$ExtraDrive4_DataStoreComboBox.enabled = $false
			$ExtraDrive4_letterComboBox.enabled = $false
			$ExtraDrive4_SelectionLabel.enabled = $false
			$ExtraDrive4SizeTextBox.enabled = $false
			$ExtraDrive4_SizeLabel.enabled = $false
			$ExtraDrive4_DatastoreLabel.enabled = $false
			#ED5
			$ExtraDrive5_DataStoreComboBox.enabled = $false
			$ExtraDrive5_letterComboBox.enabled = $false
			$ExtraDrive5_SelectionLabel.enabled = $false
			$ExtraDrive5SizeTextBox.enabled = $false
			$ExtraDrive5_SizeLabel.enabled = $false
			$ExtraDrive5_DatastoreLabel.enabled = $false
		}
		2 {
			#ED1
			$ExtraDrive1_DataStoreComboBox.enabled = $true
			$ExtraDrive1_letterComboBox.enabled = $true
			$ExtraDrive1_SelectionLabel.enabled = $true
			$ExtraDrive1SizeTextBox.enabled = $true
			$ExtraDrive1_SizeLabel.enabled = $true
			$ExtraDrive1_DatastoreLabel.enabled = $true
			#ED2
			$ExtraDrive2_DataStoreComboBox.enabled = $true
			$ExtraDrive2_letterComboBox.enabled = $true
			$ExtraDrive2_SelectionLabel.enabled = $true
			$ExtraDrive2SizeTextBox.enabled = $true
			$ExtraDrive2_SizeLabel.enabled = $true
			$ExtraDrive2_DatastoreLabel.enabled = $true
			#ED3
			$ExtraDrive3_DataStoreComboBox.enabled = $false
			$ExtraDrive3_letterComboBox.enabled = $false
			$ExtraDrive3_SelectionLabel.enabled = $false
			$ExtraDrive3SizeTextBox.enabled = $false
			$ExtraDrive3_SizeLabel.enabled = $false
			$ExtraDrive3_DatastoreLabel.enabled = $false
			#ED4
			$ExtraDrive4_DataStoreComboBox.enabled = $false
			$ExtraDrive4_letterComboBox.enabled = $false
			$ExtraDrive4_SelectionLabel.enabled = $false
			$ExtraDrive4SizeTextBox.enabled = $false
			$ExtraDrive4_SizeLabel.enabled = $false
			$ExtraDrive4_DatastoreLabel.enabled = $false
			#ED5
			$ExtraDrive5_DataStoreComboBox.enabled = $false
			$ExtraDrive5_letterComboBox.enabled = $false
			$ExtraDrive5_SelectionLabel.enabled = $false
			$ExtraDrive5SizeTextBox.enabled = $false
			$ExtraDrive5_SizeLabel.enabled = $false
			$ExtraDrive5_DatastoreLabel.enabled = $false
		}
		3 {
			#ED1
			$ExtraDrive1_DataStoreComboBox.enabled = $true
			$ExtraDrive1_letterComboBox.enabled = $true
			$ExtraDrive1_SelectionLabel.enabled = $true
			$ExtraDrive1SizeTextBox.enabled = $true
			$ExtraDrive1_SizeLabel.enabled = $true
			$ExtraDrive1_DatastoreLabel.enabled = $true
			#ED2
			$ExtraDrive2_DataStoreComboBox.enabled = $true
			$ExtraDrive2_letterComboBox.enabled = $true
			$ExtraDrive2_SelectionLabel.enabled = $true
			$ExtraDrive2SizeTextBox.enabled = $true
			$ExtraDrive2_SizeLabel.enabled = $true
			$ExtraDrive2_DatastoreLabel.enabled = $true
			#ED3
			$ExtraDrive3_DataStoreComboBox.enabled = $true
			$ExtraDrive3_letterComboBox.enabled = $true
			$ExtraDrive3_SelectionLabel.enabled = $true
			$ExtraDrive3SizeTextBox.enabled = $true
			$ExtraDrive3_SizeLabel.enabled = $true
			$ExtraDrive3_DatastoreLabel.enabled = $true
			#ED4
			$ExtraDrive4_DataStoreComboBox.enabled = $false
			$ExtraDrive4_letterComboBox.enabled = $false
			$ExtraDrive4_SelectionLabel.enabled = $false
			$ExtraDrive4SizeTextBox.enabled = $false
			$ExtraDrive4_SizeLabel.enabled = $false
			$ExtraDrive4_DatastoreLabel.enabled = $false
			#ED5
			$ExtraDrive5_DataStoreComboBox.enabled = $false
			$ExtraDrive5_letterComboBox.enabled = $false
			$ExtraDrive5_SelectionLabel.enabled = $false
			$ExtraDrive5SizeTextBox.enabled = $false
			$ExtraDrive5_SizeLabel.enabled = $false
			$ExtraDrive5_DatastoreLabel.enabled = $false
		}
		4 {
			#ED1
			$ExtraDrive1_DataStoreComboBox.enabled = $true
			$ExtraDrive1_letterComboBox.enabled = $true
			$ExtraDrive1_SelectionLabel.enabled = $true
			$ExtraDrive1SizeTextBox.enabled = $true
			$ExtraDrive1_SizeLabel.enabled = $true
			$ExtraDrive1_DatastoreLabel.enabled = $true
			#ED2
			$ExtraDrive2_DataStoreComboBox.enabled = $true
			$ExtraDrive2_letterComboBox.enabled = $true
			$ExtraDrive2_SelectionLabel.enabled = $true
			$ExtraDrive2SizeTextBox.enabled = $true
			$ExtraDrive2_SizeLabel.enabled = $true
			$ExtraDrive2_DatastoreLabel.enabled = $true
			#ED3
			$ExtraDrive3_DataStoreComboBox.enabled = $true
			$ExtraDrive3_letterComboBox.enabled = $true
			$ExtraDrive3_SelectionLabel.enabled = $true
			$ExtraDrive3SizeTextBox.enabled = $true
			$ExtraDrive3_SizeLabel.enabled = $true
			$ExtraDrive3_DatastoreLabel.enabled = $true
			#ED4
			$ExtraDrive4_DataStoreComboBox.enabled = $true
			$ExtraDrive4_letterComboBox.enabled = $true
			$ExtraDrive4_SelectionLabel.enabled = $true
			$ExtraDrive4SizeTextBox.enabled = $true
			$ExtraDrive4_SizeLabel.enabled = $true
			$ExtraDrive4_DatastoreLabel.enabled = $true
			#ED5
			$ExtraDrive5_DataStoreComboBox.enabled = $false
			$ExtraDrive5_letterComboBox.enabled = $false
			$ExtraDrive5_SelectionLabel.enabled = $false
			$ExtraDrive5SizeTextBox.enabled = $false
			$ExtraDrive5_SizeLabel.enabled = $false
			$ExtraDrive5_DatastoreLabel.enabled = $false
		}
		5{
			#ED1
			$ExtraDrive1_DataStoreComboBox.enabled = $true
			$ExtraDrive1_letterComboBox.enabled = $true
			$ExtraDrive1_SelectionLabel.enabled = $true
			$ExtraDrive1SizeTextBox.enabled = $true
			$ExtraDrive1_SizeLabel.enabled = $true
			$ExtraDrive1_DatastoreLabel.enabled = $true
			#ED2
			$ExtraDrive2_DataStoreComboBox.enabled = $true
			$ExtraDrive2_letterComboBox.enabled = $true
			$ExtraDrive2_SelectionLabel.enabled = $true
			$ExtraDrive2SizeTextBox.enabled = $true
			$ExtraDrive2_SizeLabel.enabled = $true
			$ExtraDrive2_DatastoreLabel.enabled = $true
			#ED3
			$ExtraDrive3_DataStoreComboBox.enabled = $true
			$ExtraDrive3_letterComboBox.enabled = $true
			$ExtraDrive3_SelectionLabel.enabled = $true
			$ExtraDrive3SizeTextBox.enabled = $true
			$ExtraDrive3_SizeLabel.enabled = $true
			$ExtraDrive3_DatastoreLabel.enabled = $true
			#ED4
			$ExtraDrive4_DataStoreComboBox.enabled = $true
			$ExtraDrive4_letterComboBox.enabled = $true
			$ExtraDrive4_SelectionLabel.enabled = $true
			$ExtraDrive4SizeTextBox.enabled = $true
			$ExtraDrive4_SizeLabel.enabled = $true
			$ExtraDrive4_DatastoreLabel.enabled = $true
			#ED5
			$ExtraDrive5_DataStoreComboBox.enabled = $true
			$ExtraDrive5_letterComboBox.enabled = $true
			$ExtraDrive5_SelectionLabel.enabled = $true
			$ExtraDrive5SizeTextBox.enabled = $true
			$ExtraDrive5_SizeLabel.enabled = $true
			$ExtraDrive5_DatastoreLabel.enabled = $true
		}
	}
}

Function Load-ExtraDriveComboBoxes{
<#
	.SYNOPSIS
		Function to load in the allowed drive letters into the drive comboboxes.
	
	.DESCRIPTION
		N/A
	
	.EXAMPLE
		PS C:\> Load-ExtraDriveComboBoxes
	
	.NOTES
		Uses the PS Studio helper function Load-Combobox.
#>
	
	Load-ComboBox -ComboBox -$ExtraDrive1_letterComboBox `
				  -Items $Global:DriveLetterarray
	
	Load-ComboBox -ComboBox -$ExtraDrive2_letterComboBox `
				  -Items $Global:DriveLetterarray
	
	Load-ComboBox -ComboBox -$ExtraDrive3_letterComboBox `
				  -Items $Global:DriveLetterarray
	
	Load-ComboBox -ComboBox -$ExtraDrive4_letterComboBox `
				  -Items $Global:DriveLetterarray
	
	Load-ComboBox -ComboBox -$ExtraDrive5_letterComboBox `
				  -Items $Global:DriveLetterarray
}

Function Enable-NetworkingGroupBox{
<#
	.SYNOPSIS
		Function to enable all the controls in the networking groupbox.
	
	.DESCRIPTION
		N/A
	
	.EXAMPLE
		PS C:\> Enable-NetworkingGroupBox
	
	.NOTES
		N/A
#>
	
	$octet1Textbox.Enabled = $true
	$octet2Textbox.Enabled = $true
	$octet3Textbox.Enabled = $true
	$octet4Textbox.Enabled = $true
	$Classificationtextbox.enabled = $true
	$Descriptiontextbox.enabled = $true
	$Notestextbox.enabled = $true
	
}

Function Enable-HardwareGroupBox{
<#
	.SYNOPSIS
		Function to enable all the controls in the hardware groupbox.
	
	.DESCRIPTION
		N/A
	
	.EXAMPLE
		PS C:\> Enable-HardwareGroupBox
	
	.NOTES
		N/A
#>
	
	$VCPUsComboBox.Enabled = $True
	$RAMComboBox.Enabled = $True
	$ExtraDriveCounter.Enabled = $True
}

Function AddTo-ResourcePool{
	$rp="Prod-Cluster05-Build"
	$norp = Get-Cluster $Cluster | Get-VM | where { $_.ResourcePool.Name -eq "Resources" }
	foreach ($i in $norp)
	{
		Write-Host "Moving $i to Resource Pool $rp"
		Get-VM $i -Location $cluster | Move-VM -Destination $rp | Out-Null
		Write-Host "Move completed"
	}
}

Function Create-VM{
<#
	.SYNOPSIS
		Function to create the VM in vcenter.
	
	.DESCRIPTION
		Creates the VM and adds that object to the global variable.
	
	.EXAMPLE
		PS C:\> Create-VM
	
	.NOTES
		N/A
#>
	
	Write-RichText -LogType 'informational' -LogMsg "VM Creation beginning please be patient."
	
	New-VM -Server $Global:VCenterServer `
		   -ResourcePool $Global:ResourcePool `
		   -Name $Global:VMName `
		   -Datastore $Global:Datastore  `
		   -Template $Global:Template `
		   -OSCustomizationSpec $Global:OSCustomizationSpec
	
	$VM = Get-VM -Server $Global:VCenterServer `
				 -Location $Global:Location `
				 -Name $Global:VMName
	
	If (!$VM)
	{
		Write-RichText -LogType 'error' -logmsg "Unable to create VM."
		Return
	}
	
	Else
	{
		Write-RichText -LogType 'Success' -LogMsg "VM Creation Completed!"
		
		$Global:VM = $VM
		
		Change-VMFolder -VM $VM -Folder $Global:FolderObject
		
	}
	
}

Function Change-VMFolder{
	param (
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[VMware.VimAutomation.ViCore.Types.V1.Inventory.VirtualMachine]$VM,
		[Parameter(Mandatory = $true, Position = 1, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		$Folder
	)
	
	Write-RichText -LogType 'informational' -LogMsg "Moving the VM from the Root Folder to $($Folder.name)"
	
	Move-VM -VM $VM -Destination $Folder
	
	$NewVM = Get-VM -Name $VM.name
	
	If ($NewVM.folder.name -eq $Folder.name)
	{
		Write-RichText -LogType 'Success' -LogMsg "VM Successfully Moved."
		$Global:VM = $NewVM
		
		Set-VMCPUCount -VM $Global:VM `
					   -NumCPU $VCPUsComboBox.SelectedItem
	}
	
	Else
	{
		Write-RichText -LogType 'Error' -LogMsg "Failed to Move VM."	
	}
}

Function Set-VMCPUCount{
<#
	.SYNOPSIS
		Function to se the amount of Virtual CPU's on the server.
	
	.DESCRIPTION
		Function connects to VCenter and performs a set-vm command to
		alter the amount of VCPUs available to the machine.
	
	.PARAMETER VM
		The VM to alter.
	
	.PARAMETER NumCPU
		The number of CPU's chosen by the user.
	
	.EXAMPLE
		PS C:\> Set-VMCPUCount -VM $VM -NumCPU 4
	
	.OUTPUTS
		Returns a BOOL value. $True on Success $False on Failure.
	
	.NOTES
		N/A
#>
	param (
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[VMware.VimAutomation.ViCore.Types.V1.Inventory.VirtualMachine]$VM,
		[Parameter(Mandatory = $true, Position = 1, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[Int]$NumCPU
	)
	
	$Set = $VM | Set-VM -NumCpu $NumCPU -Confirm:$false
	
	If ($Set.numcpu -eq $NumCPU)
	{
		Write-RichText -LogType success -LogMsg "VCPU Count Set to $NumCPU"
		Set-VMRamAmount -VM $VM -MemoryGB $RamComboBox.SelectedItem
	}
	
	Else
	{
		Write-RichText -LogType Error -LogMsg "Unable to Set VCPU Count!!"
		Return
	}
}

Function Set-VMRamAmount{
<#
	.SYNOPSIS
		Function to se the amount of RAM on the server.
	
	.DESCRIPTION
		Function connects to VCenter and performs a set-vm command to
		alter the amount of RAM available to the machine.
	
	.PARAMETER VM
		The VM to alter.
	
	.PARAMETER memoryGB
		The number of gigabytes of RAM chosen by the user.
	
	.EXAMPLE
		PS C:\> Set-VMRamAmount -VM $VM -memoryGB 4
	
	.OUTPUTS
		Returns a BOOL value. $True on Success $False on Failure.
	
	.NOTES
		N/A
#>
	param (
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[VMware.VimAutomation.ViCore.Types.V1.Inventory.VirtualMachine]$VM,
		[Parameter(Mandatory = $true, Position = 1, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[Int]$MemoryGB
	)
	
	$Set = $VM | Set-VM -MemoryGB $MemoryGB -Confirm:$false
	
	If ($Set.MemoryGB -eq $MemoryGB)
	{
		Write-RichText -LogType success -LogMsg "RAM Amount (GB) Set to $MemoryGB"
		Add-VMDIsks -VM $VM
		
	}
	
	Else
	{
		Write-RichText -LogType Error -LogMsg "Unable to Set RAM Value!!"
		Return $false
	}
}

Function Add-VMDIsks{
<#
	.SYNOPSIS
		Function adds extra disks to a virtual machine.
	
	.DESCRIPTION
		Checks to see how many extra disks have been requested by the user
		and creates them on the VM. Storage format is set to thin as requested by
		Laszlo.
	
	.PARAMETER VM
		The VM created earlier in the automation process.
	
	.EXAMPLE
		PS C:\> Add-VMDIsks -VM $VM
	
	.NOTES
		N/A
#>
	param (
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[VMware.VimAutomation.ViCore.Types.V1.Inventory.VirtualMachine]$VM
	)
	
	If ($ExtraDrive1_LetterComboBox.enabled -eq $true)
	{
		$VM | New-HardDisk -CapacityGB $ExtraDrive1_SizeTextBox.text -StorageFormat Thin
		Write-RichText -LogType "Success" -LogMsg "Drive added. Size : $($ExtraDrive1_SizeTextBox.text) GB"
	}
	If ($ExtraDrive2_LetterComboBox.enabled -eq $true)
	{
		$VM | New-HardDisk -CapacityGB $ExtraDrive2_SizeTextBox.text -StorageFormat Thin
		Write-RichText -LogType "Success" -LogMsg "Drive added. Size : $($ExtraDrive2_SizeTextBox.text) GB"
	}
	If ($ExtraDrive3_LetterComboBox.enabled -eq $true)
	{
		$VM | New-HardDisk -CapacityGB $ExtraDrive3_SizeTextBox.text -StorageFormat Thin
		Write-RichText -LogType "Success" -LogMsg "Drive added. Size : $($ExtraDrive3_SizeTextBox.text) GB"
	}
	If ($ExtraDrive4_LetterComboBox.enabled -eq $true)
	{
		$VM | New-HardDisk -CapacityGB $ExtraDrive4_SizeTextBox.text -StorageFormat Thin
		Write-RichText -LogType "Success" -LogMsg "Drive added. Size : $($ExtraDrive4_SizeTextBox.text) GB"
	}
	If ($ExtraDrive5_LetterComboBox.enabled -eq $true)
	{
		$VM | New-HardDisk -CapacityGB $ExtraDrive5_SizeTextBox.text -StorageFormat Thin
		Write-RichText -LogType "Success" -LogMsg "Drive added. Size : $($ExtraDrive5_SizeTextBox.text) GB"
	}
	
	Validate-IPAddress -VM $VM
}

Function Validate-IPAddress{
<#
	.SYNOPSIS
		Function validates that the entered IP address is real.
	
	.DESCRIPTION
		Function uses tryparse to tell if an Ip address is valid.
	
	.PARAMETER VM
		The VM created earlier in the automation process.
	
	.EXAMPLE
		PS C:\> Validate-IPAddress -VM $VM
	
	.NOTES
		N/A
#>
	
	param (
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[VMware.VimAutomation.ViCore.Types.V1.Inventory.VirtualMachine]$VM
	)
	
	$FullIP = $Octet1Textbox.text + "." + $Octet2Textbox.text + "." + $Octet3Textbox.text + "." + $Octet4Textbox.text
	
	[ref]$ValidIP = [ipaddress]::None
	If ([ipaddress]::TryParse($FullIP, $ValidIP))
	{
		Write-RichText -LogType 'Success' -LogMsg "IP Address $FullIP is valid."
		$Global:fullip = $Fullip
		Determine-Portgroup -VM $VM
	}
	
	Else
	{
		Write-RichText -LogType 'Error' -LogMsg "IP Address $FullIP is invalid."
		Return
	}
}

Function Determine-Portgroup{
<#
	.SYNOPSIS
		Function determines which Portgroup the VM should be placed into.
	
	.DESCRIPTION
		This function uses our naming convention to determine the proper
		portgroup. If more than one portgroup matches it prompts the user
		to select from a dropdown.
	
	.PARAMETER VM
		The VM created earlier in the automation process.
	
	.EXAMPLE
		PS C:\> Determine-Portgroup -VM $VM
	
	.NOTES
		N/A
#>
	param (
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[VMware.VimAutomation.ViCore.Types.V1.Inventory.VirtualMachine]$VM
	)
	
	[String]$PartialIp = $Octet1Textbox.text + "." + $Octet2Textbox.text + "." + $Octet3Textbox.text
	[String]$Location = $Global:Location
	[Array]$VirtualSwitches = $vm.VMHost | get-virtualswitch
	[Array]$Portgroups = @()
	
	Foreach ($VSwitch in $VirtualSwitches)
	{
		$Portgroups += ($Vswitch | Get-VirtualPortGroup)
	}
	
	If ($Location -in ('AM1', 'AP1', 'EM1'))
	{
		$TrimmedMatches = $Portgroups | where-object { $_.name -like "*$PartialIP*" -and $_.name -like "*PROD*" }
	}
	
	Else
	{
		$TrimmedMatches = $Portgroups | where-object { $_.name -like "*$PartialIP*" }
	}
	
	$PortgroupCount = ($TrimmedMatches | measure-object).count
	
	switch ($PortgroupCount)
	{
		
		0 {
			Write-RichText -LogType 'Error' -LogMSG "Unable to find a matching portgroup."
			Return
		}
		1 {
			Write-RichText -LogType 'Success' -LogMSG "Found only one matching portgroup."
			$Portgroup = $TrimmedMatches
			Set-VMPortGroup -VM $VM -PortGroup $Portgroup.name
		}
		Default
		{
			Write-RichText -LogType 'informational' -LogMSG "More than one possible portgroup was matched. Please choose one."
			Populate-PortGroupCombobox -Portgroups $TrimmedMatches
		}
	}
}

Function Set-VMPortGroup{
<#
	.SYNOPSIS
		Function to set the VM PortGroup.
	
	.DESCRIPTION
		Sets the chosen portgroup on the VM.
	
	.PARAMETER VM
		The VM created earlier in the automation process.
	
	.PARAMETER Portgroup
		The subnet/portgroup chosen by the user.
	
	.EXAMPLE
		PS C:\> Set-VMPortGroup -VM $VM -portgroup $Portgroup
	
	.NOTES
		N/A
#>
	param (
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[VMware.VimAutomation.ViCore.Types.V1.Inventory.VirtualMachine]$VM,
		[Parameter(Mandatory = $true, Position = 1, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[String]$PortGroup
	)
	
	Write-Richtext -LogType 'Informational' -LogMsg "Setting the Portgroup in Vsphere."
	
	$VM | Get-NetworkAdapter | Set-NetworkAdapter -Portgroup $PortGroup -confirm:$false
	
	$NewPortGroup = $VM | get-networkadapter | select -ExpandProperty NetWorkname
	
	If ($NewPortGroup -eq $PortGroup)
	{
		Write-RichText -LogType 'Success' -LogMsg "Successfully Set PortGroup."
		Start-VirtualMachine -VM $VM
	}
	
	Else
	{
		Write-RichText -LogType 'Error' -LogMsg "Failed to Set PortGroup."
		Return
	}
}

Function Start-VirtualMachine{
<#
	.SYNOPSIS
		Function to start the cirtual machine.
	
	.DESCRIPTION
		This function starts the VM passed to it.
	
	.PARAMETER VM
		The VM created earlier in the automation process.
	
	.EXAMPLE
		PS C:\> Start-VirtualMachine -VM $VM
	
	.NOTES
		N/A
#>
	param (
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[VMware.VimAutomation.ViCore.Types.V1.Inventory.VirtualMachine]$VM
	)
	
	Write-Richtext -LogType 'Informational' -LogMsg "Starting VM..."
	$VM | Start-VM -confirm:$False
	
	Wait-ForCustomizationCompletion -VM $Global:VM
}

Function Wait-ForCustomizationCompletion{
<#
	.SYNOPSIS
		This function delays the script while the customization is proccessed on the VM.
	
	.DESCRIPTION
		This function gets around the problem that is caused by cutomizations needing 
		the be applied once the VM starts the first time. It doesn't happen as soon as
		the VM is started. There appears to be a random delay. This function loops
		waiting to see the 'customization started' event. Once it sees it it jumps to
		the next loop to wait for the customization to end.
	
	.PARAMETER VM
		The VM created earlier in the automation process.
	
	.EXAMPLE
		PS C:\> Wait-ForCustomizationCompletion -VM $VM
	
	.NOTES
		This was a fun logical hurdle to overcome. I wasn't initially aware of the 
		Get-VIEvent	commandlet which made this problem solvable.
#>
	param (
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[VMware.VimAutomation.ViCore.Types.V1.Inventory.VirtualMachine]$VM
	)
	
	Write-RichText -LogType 'Informational' -logmsg "Start monitoring customization process for vm $($VM.name)"
	
	#Check for the original Customization started event. Sleep in 1 minute intervals between checks.
	
	$StartTimeEventFilter = (Get-Date).AddMinutes(-10)
	
	for ($i = 1; $i -le 180; $i++)
	{
		
		#Check for the Started Customization Event
		$StartCustomizationEvent = Get-VIEvent -Entity $VM -Start $startTimeEventFilter | `
		where { $_.fullformattedmessage -like '*Started customization of VM*' } | `
		Sort CreatedTime | `
		Select -Last 1
		
		If ($StartCustomizationEvent)
		{
			Write-Richtext -LogType 'Success' -LogMsg "Customization Started Successfully! Please be patient."
			break;
		}
		
		Else
		{
			
			If ($I -Eq 180)
			{
				
				Write-Richtext -LogType 'Error' -LogMsg "Customization was never applied. Please ensure the VM was properly started."
				Return
			}
			
			Write-Richtext -LogType 'Informational' -LogMsg "Waiting for Customization to begin. Sleeping for 10 seconds... Loop ($i of 180)"
			Start-sleep -Seconds 10
		}
	}
	
	#Check for the Customization completed event. Sleep in 30 second intervals between checks.
	
	$StartTimeEventFilter = (Get-Date).AddMinutes(-5)
	
	for ($i = 1; $i -le 180; $i++)
	{
		
		#Check for the Completed Customization Event
		$EndCustomizationEvent = Get-VIEvent -Entity $VM -Start $startTimeEventFilter | `
		where { $_.fullformattedmessage -like "*Customization of VM $($VM.name) succeeded*" } | `
		Sort CreatedTime | `
		Select -Last 1
		
		If ($EndCustomizationEvent)
		{
			Write-Richtext -LogType 'Success' -LogMsg "Customizatiion applied Successfully!"
			break;
		}
		
		Else
		{
			
			If ($I -eq 180)
			{
				
				Write-Richtext -LogType 'Error' -LogMsg "Customization never applied. Please investigate."
				Return
			}
			
			Write-Richtext -LogType 'Informational' -LogMsg "Waiting for Customization to complete. Sleeping for 10 seconds... Loop ($i of 180)"
			Start-sleep -Seconds 10
		}
		
	}
	
	Update-VMWareTools -VM $Global:VM
	
}

Function Update-VMWareTools{
<#
	.SYNOPSIS
		This function updates the VMware tools on the VM.
	
	.DESCRIPTION
		Function waits for the guest tools to be ready since that can 
		take some time after starting up. once they are ready it updates them and waits.
		This function does cause a reboot.
	
	.PARAMETER VM
		The VM created earlier in the automation process.
	
	.EXAMPLE
		PS C:\> Update-VMWareTools -VM $VM
	
	.NOTES
		There is supposed to be a paramter to the Update-Tools commandlet that lets you not 
		reboot but damned if i could get it to work in my experience. It either rebooted anyway
		(WTF VMware) or nothing worked until i rebooted anyway.
#>
	param (
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[VMware.VimAutomation.ViCore.Types.V1.Inventory.VirtualMachine]$VM
	)
	
	for ($i = 1; $i -le 180; $i++)
	{
		
		$RunningStatus = (Get-View $VM.Id -Property Guest).Guest.ToolsRunningStatus
		
		If ($RunningStatus -eq 'guestToolsRunning')
		{
			
			Write-Richtext -LogType 'Success' -LogMsg "VMTools are Running on Guest OS."
			break;
		}
		
		Else
		{
			If ($I -Eq 180)
			{
				
				Write-Richtext -LogType 'Error' -LogMsg "VMTools are taking too long to start. please investigate."
				Return
			}
			
			Write-Richtext -LogType 'informational' -LogMsg "Waiting on VMTools to start. Sleeping for 10 seconds... Loop ($i of 180)"
			Start-sleep -Seconds 10
		}
		
	}
	
	Write-RichText -LogType "informational" -LogMsg "Updating VMWare Tools. Please Be Patient"
	Update-tools -VM $VM
	
	for ($i = 1; $i -le 180; $i++)
	{
		$GuestToolsStatus = (Get-View $VM.Id -Property Guest).Guest.ToolsStatus
		
		If ($GuestToolsStatus -eq 'toolsOk')
		{
			Write-Richtext -LogType 'Success' -LogMsg "VMTools have been successfully updated."
			break;
		}
		
		Else
		{
			If ($i -eq 60)
			{
				Update-tools -VM $VM
			}
			
			ElseIf ($I -eq 180)
			{
				
				Write-Richtext -LogType 'Error' -LogMsg "VMTools are taking too long to update. please investigate."
				Return $false
			}
			
			Write-Richtext -LogType 'Informational' -LogMsg "Waiting on tools to update. Sleeping for 10 seconds... Loop ($i of 180)"
			Start-sleep -Seconds 10
		}
	}
	
	Make-Annotations -VM $Global:VM
}

Function Make-Annotations{
<#
	.SYNOPSIS
		This function makes annotation to record details about the VM.
	
	.DESCRIPTION
		Makes up to 3 seperate entries into the annotations section 
		depending on what the user filled out.
	
	.PARAMETER VM
		The VM created earlier in the automation process.
	
	.EXAMPLE
		PS C:\> Make-Annotations -VM $VM
	
	.NOTES
		The annotations i am updating may not be present for other 
		users in other environments. They are custom attributes which are specific
		to each environment.
#>
	param (
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[VMware.VimAutomation.ViCore.Types.V1.Inventory.VirtualMachine]$VM
	)
	
	If ($ClassificationTextbox.text)
	{
		Set-Annotation -Entity $VM -CustomAttribute Classification -Value $ClassificationTextbox.text
		Write-RichText -LogType 'informational' -LogMsg "Classification Annotation Set."
	}
	
	If ($DescriptionTextbox.text)
	{
		Set-Annotation -Entity $VM -CustomAttribute Description -Value $DescriptionTextbox.text
		Write-RichText -LogType 'informational' -LogMsg "Description Annotation Set."
	}
	
	If ($Notestextbox.text)
	{
		Set-VM -VM $VM -Notes $Notestextbox.text -Confirm:$False
		Write-RichText -LogType 'informational' -LogMsg "Notes Annotation Set."
	}
	
	Wait-ForGuest -VM $VM -LocalCredential $Global:LocalAdminCreds

}

Function Wait-ForGuest{
<#
	.SYNOPSIS
		Function to wait for the guest OS to become available for commands.
	
	.DESCRIPTION
		After updating the VM tools it may take a little while for the OS to
		become available.
	
	.PARAMETER VM
		The VM created earlier in the automation process.
	
	.EXAMPLE
		PS C:\> Wait-ForGuest -VM $VM
	
	.NOTES
		I'm not 100% sold on this being the best way to do this but its what i have to work with right now.
#>
	param (
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[VMware.VimAutomation.ViCore.Types.V1.Inventory.VirtualMachine]$VM,
		[Parameter(Mandatory = $true, Position = 1, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[System.Management.Automation.PSCredential]$LocalCredential
	)
	
	Write-Richtext -LogType 'Informational' -LogMsg "Waiting for guest operations to be ready..."
	Start-sleep -Seconds 10
	
	for ($i = 1; $i -le 180; $i++)
	{
		
		#Check for the GuestOS Status
		$Ready = (Get-View $VM.Id -Property Guest).Guest.GuestOperationsReady
		
		If ($Ready)
		{
			Write-Richtext -LogType 'Success' -LogMsg "OS is ready."
			break;
			
		}
		
		Else
		{
			
			If ($I -eq 180)
			{
				
				Write-Richtext -LogType 'Error' -LogMsg "OS Never became ready. Please investigate"
				Return
			}
			
			Write-Richtext -LogType 'Informational' -LogMsg "Waiting for OS to become ready. Sleeping for 10 seconds... Loop ($i of 180)"
			Start-sleep -Seconds 10
		}
	}
	
	Set-IPInfo -VM $VM -LocalCredential $LocalCredential
	
}

Function Set-IPInfo{
<#
	.SYNOPSIS
		Function sets up the network adapter on the Guest OS.
	
	.DESCRIPTION
		Function uses invoke-vmscript for setting the initial network config.
		Sets the IP, Default gateway and Subnet mask.
	
	.PARAMETER VM
		The VM created earlier in the automation process.
	
	.PARAMETER LocalCredential
		The local admin credential object.
	
	.EXAMPLE
		PS C:\> Set-Networking -VM $VM -LocalCredential $LocalCredential
	
	.NOTES
		I hate Invoke-VMScript. It really sucks This function also calls Set-DNSInfo.
#>
	param (
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[VMware.VimAutomation.ViCore.Types.V1.Inventory.VirtualMachine]$VM,
		[Parameter(Mandatory = $true, Position = 1, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[System.Management.Automation.PSCredential]$LocalCredential
	)
	
	$DefaultGateway = $Octet1Textbox.text + "." + $Octet2Textbox.text + "." + $Octet3Textbox.text + "." + "208"
	
	$IP = $Global:fullip
	
	Write-RichText -LogType 'informational' -LogMsg "Setting IP and Default Gateway in Guest OS."
	
	$ScriptText = "New-NetIPAddress –InterfaceAlias Ethernet –IPAddress $IP -AddressFamily IPv4 –PrefixLength 24 -DefaultGateway $DefaultGateway"
	
	Invoke-VMScript -VM $VM `
					-ScriptText $ScriptText `
					-GuestCredential $LocalCredential `
					-ScriptType Powershell
	
	Write-RichText -LogType 'Success' -LogMsg "Guest OS Network information successfully set."
	
	Set-DNSInfo -VM $VM -LocalCredential $LocalCredential
	
}

Function Set-DNSInfo{
<#
	.SYNOPSIS
		Function sets up the network adapter on the Guest OS.
	
	.DESCRIPTION
		Function uses invoke-vmscript for setting the initial DNS config.
	
	.PARAMETER VM
		The VM created earlier in the automation process.
	
	.PARAMETER LocalCredential
		The local admin credential object.
	
	.EXAMPLE
		PS C:\> Set-DNSInfo -VM $VM -LocalCredential $LocalCredential
	
	.NOTES
		N/A
#>
	param (
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[VMware.VimAutomation.ViCore.Types.V1.Inventory.VirtualMachine]$VM,
		[Parameter(Mandatory = $true, Position = 1, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[System.Management.Automation.PSCredential]$LocalCredential
	)
	
	switch ($Global:VCenterServer)
	{
		'AM1-VCENTER' {
			$DNSString = '158.53.83.125,158.53.83.126'
		}
		'AP1-VCENTER' {
			$DNSString = ' 158.53.248.212,158.53.248.213'
		}
		'EM1-VCENTER' {
			$DNSString = '158.53.185.212,158.53.185.213'
		}
		
	}
	
	$ScriptText = "Set-DnsClientServerAddress -InterfaceAlias Ethernet -ServerAddresses $DNSString"
	
	Invoke-VMScript -VM $VM `
					-ScriptText $ScriptText `
					-GuestCredential $LocalCredential `
					-ScriptType Powershell
	
	Write-RichText -LogType 'Success' -LogMsg "Guest DNS information successfully set."
	
	Enable-Remoting -VM $VM `
					-LocalCredential $LocalCredential `
					-IP $Global:fullip
	
}

Function Enable-Remoting{
<#
	.SYNOPSIS
		Function to enable Powershell Remoting
	
	.DESCRIPTION
		Function runs a few different commands via invoke-vmscript to enable remoting.
	
	.PARAMETER VM
		The VM created earlier in the automation process.
	
	.PARAMETER LocalCredential
		The local admin credential object.
	
	.PARAMETER IP
		The IP of the server.
	
	.EXAMPLE
		PS C:\> Enable-Remoting -VM $VM -LocalCredential $LocalCredential -IP $IP
	
	.NOTES
		N/A
#>
	param (
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[VMware.VimAutomation.ViCore.Types.V1.Inventory.VirtualMachine]$VM,
		[Parameter(Mandatory = $true, Position = 1, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[System.Management.Automation.PSCredential]$LocalCredential,
		[Parameter(Mandatory = $true, Position = 2, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[String]$IP
	)
	
	Write-RichText -LogType 'informational' -LogMsg 'Disabling all Windows FireWall properties.'
	
	$ScriptText = 'netsh advfirewall set allprofiles state off'
	
	$Response = Invoke-VMScript -VM $VM `
								-ScriptText $ScriptText `
								-GuestCredential $LocalCredential `
								-ScriptType Powershell
	
	Write-RichText -LogType 'Success' -LogMsg 'Windows Firewall disabled.'
	
	Write-RichText -LogType 'informational' -LogMsg 'Setting trusted hosts.'
	
	$ScriptText = 'Set-Item WSMan:\localhost\Client\TrustedHosts * -Force'
	
	$Response = Invoke-VMScript -VM $VM `
								-ScriptText $ScriptText `
								-GuestCredential $LocalCredential `
								-ScriptType Powershell
	
	Write-RichText -LogType 'Success' -LogMsg 'Trusted Hosts Set.'
	
	Write-RichText -LogType 'informational' -LogMsg 'Enabling PS Remoting.'
	
	$ScriptText = 'Enable-PSRemoting -Force'
	
	$Response = Invoke-VMScript -VM $VM `
								-ScriptText $ScriptText `
								-GuestCredential $LocalCredential `
								-ScriptType Powershell
	
	Write-RichText -LogType 'success' -LogMsg 'PS Remoting Enabled'
	
	Write-RichText -LogType 'informational' -LogMsg 'Setting WSMAN QuickConfig.'
	
	$Scripttext = 'Set-WSManQuickConfig -Force'
	
	$Response = Invoke-VMScript -VM $VM `
								-ScriptText $ScriptText `
								-GuestCredential $LocalCredential `
								-ScriptType Powershell
	
	Write-RichText -LogType 'Success' -LogMsg 'WSMAN Configured.'
	
	$Remoting = Invoke-Command -Computername $IP `
							   -Credential $LocalCredential `
							   -Scriptblock { Return hostname }
	
	If ($Remoting -eq $($Global:VMName))
	{
		Write-RichText -LogType 'Success' -LogMsg "Remoting is successfully enabled!"
		
		JoinTo-Domain -VM $VM `
					  -LocalCredential $LocalCredential `
					  -DomainCredential $Global:DomainCredentials `
					  -IP $IP
	}
	
	Else
	{
		Write-RichText -LogType 'Error' -LogMsg "PS remoting is NOT enabled! Exiting Process!"
		Return
	}
	
}

Function JoinTo-Domain{
<#
	.SYNOPSIS
		Function to join the remote machine to the domain.
	
	.DESCRIPTION
		Function uses Invoke-VMScript to join a machine to the domain.
		Currently the password for this is hardcoded. I will need to change it to prompt.
	
	.PARAMETER VM
		The VM created earlier in the automation process.
	
	.PARAMETER LocalCredential
		The local credential object for the VM.
	
	.PARAMETER DomainCredential
		The domain credential object.
	
	.PARAMETER IP
		The IP of the VM.
	
	.EXAMPLE
		PS C:\> JoinTo-Domain -VM $VM -LocalCredential $LocalCredential -DomainCredential $DomainCredential -IP $IP
	
	.NOTES
		Since invoke-vm script sucks i have to do it this way. 
		Credentials need to be built in plain text. Need to come back and change this to prompt
		as the credentials change all the time. and i can't pass a stupid credential object. [#TODO]
#>
	param (
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[VMware.VimAutomation.ViCore.Types.V1.Inventory.VirtualMachine]$VM,
		[Parameter(Mandatory = $true, Position = 1, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[System.Management.Automation.PSCredential]$LocalCredential,
		[Parameter(Mandatory = $true, Position = 2, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[System.Management.Automation.PSCredential]$DomainCredential,
		[Parameter(Mandatory = $true, Position = 3, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[String]$IP
	)
	
	Write-RichText -LogType 'informational' -LogMsg "Joining the server to the domain and rebooting."
	
	Invoke-Command -ComputerName $IP `
					-Credential $LocalCredential `
					-ScriptBlock {
		
					Add-Computer -Credential $Using:DomainCredential `
								 -DomainName 'wcnet.whitecase.com' `
								 -Restart `
								 -Force
		
	}
	
	Write-RichText -LogType 'informational' -LogMsg "Domain join attempt has been made."
	
	Wait-ForReboot -VM $VM `
				   -LocalCredential $LocalCredential `
				   -IP $IP
	
}

Function Wait-ForReboot{
<#
	.SYNOPSIS
		Function to wait for a reboot to complete on the VM.
	
	.DESCRIPTION
		After sending the command to join the domain the machine requires a reboot.
		This function handles the waiting the best way i could figure out which is
		to wait for the 'InteractiveGuestOperationsReady' property to become true.
	
		I found that as long as this was false i was unable to use the console, 
		so i would be able to script a login either.
	
	.PARAMETER VM
		The VM created earlier in the automation process.
	
	.PARAMETER LocalCredential
		The local admin credential object.
	
	.PARAMETER IP
		The IP of the server.
	
	.EXAMPLE
		PS C:\> Wait-ForReboot -VM $VM -LocalCredential $Localcredential -IP $IP
	
	.NOTES
		I'm not 100% sold on this being the best way to do this but its what i have to work with right now.
#>
	param (
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[VMware.VimAutomation.ViCore.Types.V1.Inventory.VirtualMachine]$VM,
		[Parameter(Mandatory = $true, Position = 1, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[System.Management.Automation.PSCredential]$LocalCredential,
		[Parameter(Mandatory = $true, Position = 2, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[String]$IP
	)
	
	Write-Richtext -LogType 'Informational' -LogMsg "Waiting for reboot to complete. Sleeping for 30 seconds..."
	Start-sleep -Seconds 10
	
	for ($i = 1; $i -le 180; $i++)
	{
		
		#Check for the GuestOS Status
		$Rebooted = (Get-View $VM.Id -Property Guest).Guest.GuestOperationsReady
		
		If ($Rebooted)
		{
			Write-Richtext -LogType 'Success' -LogMsg "Reboot Successful."
			break;
			
		}
		
		Else
		{
			
			If ($I -eq 180)
			{
				
				Write-Richtext -LogType 'Error' -LogMsg "Reboot never completed. Please investigate"
				Return
			}
			
			Write-Richtext -LogType 'Informational' -LogMsg "Waiting for reboot to complete. Sleeping for 10 seconds... Loop ($i of 180)"
			Start-sleep -Seconds 10
		}
	}
	
	Verify-Domain -LocalCredential $LocalCredential `
				  -IP $IP
	
}

Function Verify-Domain{
<#
	.SYNOPSIS
		Function to verify the machine joined the domain.
	
	.DESCRIPTION
		Function verifies the proper domain is present.
	
	.PARAMETER LocalCredential
		The local admin credential object.
	
	.PARAMETER IP
		The IP of the VM.
	
	.EXAMPLE
		PS C:\> Verify-Domain -LocalCredential $value1 -IP 'Value2'
	
	.NOTES
		N/A
#>
	param (
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[System.Management.Automation.PSCredential]$LocalCredential,
		[Parameter(Mandatory = $true, Position = 1, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[String]$IP
	)
	
	$Response = Invoke-command -ComputerName $IP `
							   -Credential $LocalCredential `
							   -ScriptBlock {
		
		$Domain = (Get-WmiObject Win32_ComputerSystem).Domain
		Return $Domain
	}
	
	If ($Response -eq 'WCNET.whitecase.com')
	{
		Write-RichText -LogType 'success' -LogMsg "Domain Join Was Successfull!"
		
		Invoke-Changes -LocalCredential $LocalCredential `
					   -IP $IP
	}
	
	
	Else
	{
		Write-RichText -LogType 'error' -LogMsg "Domain Join Failed :("
		Return $False
	}
	
}

Function Invoke-Changes{
	param
	(
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[System.Management.Automation.PSCredential]$LocalCredential,
		[Parameter(Mandatory = $true, Position = 1, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[String]$IP
	)
	
	$SetPageFileDef = "Function Set-PageFile { ${function:Set-PageFile} }"
	$SetPageFileSizeDef = "Function Set-PageFileSize { ${function:Set-PageFileSize} }"
	$WriteLogDef = "Function Write-Log { ${function:Write-log} }"
	
	
	$Results = Invoke-Command -ComputerName $IP `
				   -Credential $LocalCredential `
				   -ArgumentList $SetPageFileDef, $SetPageFileSizeDef, $WriteLogDef `
				   -ScriptBlock {
		
		Param ($SetPageFileDef,
			$SetPageFileSizeDef,
			$WriteLogDef)
		
		. ([ScriptBlock]::Create($WriteLogDef))
		. ([ScriptBlock]::Create($SetPageFileDef))
		. ([ScriptBlock]::Create($SetPageFileSizeDef))
		$LogFilePath = 'c:\automationlog.txt'
		
		
		#region Step 1 - Disable UAC#
		
		New-ItemProperty -Path HKLM:Software\Microsoft\Windows\CurrentVersion\policies\system `
						 -Name EnableLUA `
						 -PropertyType DWord `
						 -Value 0 `
						 -Force
		
		$UACStatus = (Get-ItemProperty -Path HKLM:Software\Microsoft\Windows\CurrentVersion\policies\system).EnableLua
		
		If ($UACStatus -eq 0)
		{
			Write-Log -Message "Step 1 - Disable UAC = SUCCESS"
		}
		
		Else
		{
			Write-Log -Message "Step 1 - Disable UAC = FAILURE"
		}
		
		#endregion
		
		#region Step 2 - Set Audit policy#
		
		auditpol /set /category:"account logon" /success:enable /failure:enable | out-null
		auditpol /set /category:"Account Management" /success:enable /failure:enable | out-null
		auditpol /set /category:"logon/logoff" /success:enable /failure:enable | out-null
		auditpol /set /category:"Object Access" /success:enable /failure:enable | out-null
		auditpol /set /category:"Policy Change" /success:enable /failure:disable | out-null
		auditpol /set /category:"Privilege Use" /success:disable /failure:enable | out-null
		auditpol /set /category:"System" /success:enable /failure:disable | out-null
		
		Write-Log -Message "Step 2 - Set Audit Policy = SUCCESS"
		#endregion
		
		#region Step 3 - Set Event Log Size#
		
		New-ItemProperty -Path 'HKLM:System\CurrentControlSet\Services\Eventlog\Application' `
						 -Name MaxSize -PropertyType Dword `
						 -Value 100663296 `
						 -Force
		
		$ApplicationLog = (Get-ItemProperty -Path HKLM:System\CurrentControlSet\Services\Eventlog\Application).MaxSize
		
		If ($ApplicationLog -eq 100663296)
		{
			Write-Log -Message "Step 3a - Set Event Log Size (Application Log) = SUCCESS"
		}
		
		Else
		{
			Write-Log -Message "Step 3a - Set Event Log Size (Application Log) = FAILURE"
		}
		
		
		New-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Services\Eventlog\Security' `
						 -Name MaxSize `
						 -PropertyType Dword `
						 -Value 100663296 `
						 -Force
		
		$SecurityLog = (Get-ItemProperty -Path HKLM:System\CurrentControlSet\Services\Eventlog\Security).MaxSize
		
		If ($SecurityLog -eq 100663296)
		{
			Write-Log -Message "Step 3b - Set Event Log Size (Security Log) = SUCCESS"
		}
		
		Else
		{
			Write-Log -Message "Step 3b - Set Event Log Size (Security Log) = FAILURE"
		}
		
		New-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Services\Eventlog\System' `
						 -Name MaxSize `
						 -PropertyType Dword `
						 -Value 100663296 `
						 -Force
		
		$SystemLog = (Get-ItemProperty -Path HKLM:System\CurrentControlSet\Services\Eventlog\System).MaxSize
		
		If ($SystemLog -eq 100663296)
		{
			Write-Log -Message "Step 3c - Set Event Log Size (System Log) = SUCCESS"
		}
		
		Else
		{
			Write-Log -Message "Step 3c - Set Event Log Size (System Log) = Failure"
		}
		
		#endregion
		
		#region Step 4 - Disable Print Spooler#
		
		Stop-Service spooler
		Set-Service -Name spooler -StartupType Disabled
		
		Write-Log -Message "Step 4 - Disable Print Spooler = SUCCESS"
		
		#endregion
		
		#region Step 5 - Disable Hibernation#
		
		powercfg.exe /hibernate off
	
		Write-Log -Message "Step 5 - Disable Hibernation = SUCCESS"
		
		#endregion
		
		#region Step 6 - Config Memory Dump#
		
		New-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\CrashControl\' `
						 -Name CrashDumpEnabled `
						 -PropertyType Dword `
						 -Value 3 `
						 -Force
		
		New-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\CrashControl\' `
						 -Name MinidumpDir `
						 -PropertyType ExpandString  `
						 -Value "c:\" `
						 -Force
		
		#Set memory dump to KERNEL - required for Failover-Clustering
		wmic recoveros set DebugInfoType = 2
		
		Write-Log -Message "Step 6 - Config Memory Dump = SUCCESS"
		#endregion
		
		#region Step 7 - Rename My Computer Shortcut#
		
		$Shell = new-object -comobject shell.application
		$NSComputer = $Shell.Namespace(17)
		$NSComputer.self.name = $env:COMPUTERNAME
		
		Write-Log -Message "Step 7 - Rename My Computer Shortcut = SUCCESS"
		
		#endregion
		
		#region Step 8 - Create Software and Scripts Dirs#
		
		
		New-Item -ItemType Directory `
				 -Path "$env:windir\Software" `
				 -Force
		
		New-Item -ItemType Directory `
				 -Path "$env:windir\Software\Scripts" `
				 -Force
		
		Write-Log -Message "Step 8 - Create Software and Scripts Dirs = SUCCESS"
		#endregion
		
		#region Step 9 - Sets the Temp Environmental Variable#
		
		[Environment]::SetEnvironmentVariable("Temp", "D:\Temp", "User")
		[Environment]::SetEnvironmentVariable("Tmp", "D:\Temp", "User")
		
		Write-Log -Message "Step 9 - Sets the Temp Environmental Variable = SUCCESS"
		#endregion
		
		#region Step 10 - Edit Manufacturer#
		
		New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OEMInformation\' `
						 -Name Manufacturer `
						 -PropertyType String `
						 -Value "Automated Build Tool" `
						 -Force
		
		Write-Log -Message "Step 10 - Edit Manufacturer = SUCCESS"
		
		#endregion
		
		#region Step 11 - Disabled Automatic Updates#
		
		New-ItemProperty -Path 'HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate\AU' `
						 -Name NoAutoUpdate `
						 -PropertyType DWord `
						 -Value 1 `
						 -Force
		
		Write-Log -Message "Step 11 - Disabled Automatic Updates = SUCCESS"
		
		#endregion
		
		#region Step 12 - Set Disk Timeout Value#
		
		New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\Disk' `
						 -Name TimeoutValue `
						 -PropertyType DWord `
						 -Value 190 `
						 -Force
		
		Write-Log -Message "Step 12 - Set Disk Timeout Value = SUCCESS"
		#endregion
		
		#region Step 13 - Set Disk Timeout#
		
		New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\Disk' `
						 -Name TimeoutValue `
						 -PropertyType DWord `
						 -Value 190 `
						 -Force
		
		Write-Log -Message "Step 13 - Set Disk Timeout = SUCCESS"
		
		#endregion
		
		#region Step 14 - Disable Logon Tasks#
		
		New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\ServerManager' `
						 -Name DoNotOpenServerManagerAtLogon `
						 -PropertyType DWord `
						 -Value 1 `
						 -Force
		
		New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\ServerManager\Oobe' `
						 -Name DoNotOpenInitialConfigurationTasksAtLogon `
						 -PropertyType DWord `
						 -Value 1 `
						 -Force
		
		Write-Log -Message "Step 14 - Disable logon Tasks = SUCCESS"
		
		#endregion
		
		#region Step 15 - Enable RDP from all clients#
		
		New-ItemProperty -Path 'HKLM:\SYSTEM\ControlSet001\Control\Terminal Server' `
						 -Name fDenyTSConnections `
						 -PropertyType DWord `
						 -Value 0 `
						 -Force
		
		New-ItemProperty -Path 'HKLM:\SYSTEM\ControlSet001\Control\Terminal Server\WinStations\RDP-Tcp' `
						 -Name UserAuthentication `
						 -PropertyType DWord `
						 -Value 0 `
						 -Force
		
		Write-Log -Message "Step 15 - Enable RDP from all clients = SUCCESS"
		
		#endregion
		
		#region Step 16 - Disable IPV6 For all Interfaces#
		
		New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters' `
						 -Name DisabledComponents `
						 -PropertyType DWord `
						 -Value 0xFFFFFFFF `
						 -Force
		
		Write-Log -Message "Step 16 - Disable IPV6 For all Interfaces = SUCCESS"
		
		#endregion
		
		#region Step 17 - Set DNS search suffix Order#
		
		New-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Services\TCPIP\Parameters' `
						 -Name SearchList `
						 -PropertyType String `
						 -Value "wcnet.whitecase.com,americas.whitecase.com,emea.whitecase.com,asiapac.whitecase.com,nm.whitecase.com,whitecase.com" `
						 -Force
		
		Write-Log -Message "Step 17 - Set DNS search suffix Order = SUCCESS"
		
		#endregion
		
		#region Step 18 - Add Windows Features#
		
		Import-Module Servermanager -DisableNameChecking
		Add-WindowsFeature SNMP-Service
		Add-WindowsFeature Telnet-Client
		
		Write-Log -Message "Step 18 - Add Windows Features = SUCCESS"
		
		#endregion
		
		#region Step 19 - Set Terminal Services Timeouts
		
		Set-ItemProperty -Path 'HKLM:\SYSTEM\ControlSet001\Control\Terminal Server\Winstations\RDP-Tcp' `
						 -Name MaxDisconnectionTime `
						 -Value 86400000 `
						 -Force
		
		Set-ItemProperty -Path 'HKLM:\SYSTEM\ControlSet001\Control\Terminal Server\Winstations\RDP-Tcp' `
						 -Name MaxIdleTime `
						 -Value 7200000 `
						 -Force
		
		Write-Log -Message "Step 19 - Set Terminal Services Timeouts = SUCCESS"
		
		#endregion
		
		#region Step 20 - Initialize Extra Disks
		
		Set-StorageSetting -NewDiskPolicy OnlineAll
		
		Get-Disk | Where-Object partitionstyle -EQ 'raw' | `
		Initialize-Disk -PartitionStyle GPT -PassThru | `
		New-Partition -AssignDriveLetter:$false -UseMaximumSize | `
		Format-Volume -FileSystem NTFS -AllocationUnitSize 65536 -Force -Confirm:$False
		
		Write-Log "Step 20 - Initialize Extra Disks = SUCCESS"
		
		#endregion
		
		#region Step 21 - Rename NIC
		
		NetSH interface set interface name="Ethernet" newname="Production NIC"
		
		Write-Log "Step 21 - Rename NIC to Production NIC = SUCCESS"
		
		#endregion
		
		#region Step 22 - Rename Admin Account#
		
		$admin = [adsi]("WinNT://./administrator, user")
		$admin.psbase.rename("WC")
		
		Write-Log -Message "Step 22 - Rename Admin Account to 'WC' = SUCCESS"
		
		#endregion
		
		#region Step 23 - Creates Dummy Admin#
		
		$computer = [ADSI]"WinNT://."
		$user = $computer.Create("user", "Administrator")
		$user.SetPassword("SuperPassword123!elugeu74ufj74")
		$user.SetInfo()
		$user.psbase.InvokeSet('AccountDisabled', $true)
		$user.SetInfo()
		
		Write-Log -Message "Step 23 - Create Dummy Admin = SUCCESS"
		
		#endregion
		
		$Data = Get-Content -Path 'c:\automationlog.txt'
		Return $Data
		
	}
	
	
	#region Output Results

	Foreach ($Line in $Results)
	{
		If ($Line -like '*Step*'){
			
			If ($Line -like '*SUCCESS*'){
				
				Write-RichText -LogType 'Success' -LogMsg $Line
			}
			
			Else{
				
				Write-RichText -LogType 'Error' -LogMsg $Line
			}
		}
	}
	
	#endregion
}

Function Set-PageFile{
<#
    .SYNOPSIS
        Set-PageFile is an advanced function which can be used to adjust virtual memory page file size.
    .DESCRIPTION
        Set-PageFile is an advanced function which can be used to adjust virtual memory page file size.
    .PARAMETER  <InitialSize>
        Setting the paging file's initial size.
    .PARAMETER  <MaximumSize>
        Setting the paging file's maximum size.
    .PARAMETER  <DriveLetter>
        Specifies the drive letter you want to configure.
    .PARAMETER  <SystemManagedSize>
        Allow Windows to manage page files on this computer.
    .PARAMETER  <None>        
        Disable page files setting.
    .PARAMETER  <Reboot>      
        Reboot the computer so that configuration changes take effect.
    .PARAMETER  <AutoConfigure>
        Automatically configure the initial size and maximumsize.
    .EXAMPLE
        C:\PS> Set-PageFile -InitialSize 1024 -MaximumSize 2048 -DriveLetter "C:","D:"
 
        Execution Results: Set page file size on "C:" successful.
        Execution Results: Set page file size on "D:" successful.
 
        Name            InitialSize(MB) MaximumSize(MB)
        ----            --------------- ---------------
        C:\pagefile.sys            1024            2048
        D:\pagefile.sys            1024            2048
        E:\pagefile.sys            2048            2048
    .LINK
        Get-WmiObject
        http://technet.microsoft.com/library/hh849824.aspx
#>
	[cmdletbinding(SupportsShouldProcess, DefaultParameterSetName = "SetPageFileSize")]
	Param
	(
		[Parameter(Mandatory, ParameterSetName = "SetPageFileSize")]
		[Alias('is')]
		[Int32]$InitialSize,
		[Parameter(Mandatory, ParameterSetName = "SetPageFileSize")]
		[Alias('ms')]
		[Int32]$MaximumSize,
		[Parameter(Mandatory)]
		[Alias('dl')]
		[ValidatePattern('^[A-Z]$')]
		[String[]]$DriveLetter,
		[Parameter(Mandatory, ParameterSetName = "None")]
		[Switch]$None,
		[Parameter(Mandatory, ParameterSetName = "SystemManagedSize")]
		[Switch]$SystemManagedSize,
		[Parameter()]
		[Switch]$Reboot,
		[Parameter(Mandatory, ParameterSetName = "AutoConfigure")]
		[Alias('auto')]
		[Switch]$AutoConfigure
	)
	Begin { }
	Process
	{
		If ($PSCmdlet.ShouldProcess("Setting the virtual memory page file size"))
		{
			$DriveLetter | ForEach-Object -Process {
				$DL = $_
				$PageFile = $Vol = $null
				try
				{
					$Vol = Get-CimInstance -ClassName CIM_StorageVolume -Filter "Name='$($DL):\\'" -ErrorAction Stop
				}
				catch
				{
					Write-Warning -Message "Failed to find the DriveLetter $DL specified"
					return
				}
				if ($Vol.DriveType -ne 3)
				{
					Write-Warning -Message "The selected drive should be a fixed local volume"
					return
				}
				Switch ($PsCmdlet.ParameterSetName)
				{
					None {
						try
						{
							$PageFile = Get-CimInstance -Query "Select * From Win32_PageFileSetting Where Name='$($DL):\\pagefile.sys'" -ErrorAction Stop
						}
						catch
						{
							Write-Warning -Message "Failed to query the Win32_PageFileSetting class because $($_.Exception.Message)"
						}
						If ($PageFile)
						{
							try
							{
								$PageFile | Remove-CimInstance -ErrorAction Stop
							}
							catch
							{
								Write-Warning -Message "Failed to delete pagefile the Win32_PageFileSetting class because $($_.Exception.Message)"
							}
						}
						Else
						{
							Write-Warning "$DL is already set None!"
						}
						break
					}
					SystemManagedSize {
						Set-PageFileSize -DL $DL -InitialSize 0 -MaximumSize 0
						break
					}
					AutoConfigure {
						$TotalPhysicalMemorySize = @()
						#Getting total physical memory size
						try
						{
							Get-CimInstance Win32_PhysicalMemory -ErrorAction Stop | ? DeviceLocator -ne "SYSTEM ROM" | ForEach-Object {
								$TotalPhysicalMemorySize += [Double]($_.Capacity)/1GB
							}
						}
						catch
						{
							Write-Warning -Message "Failed to query the Win32_PhysicalMemory class because $($_.Exception.Message)"
						}
                    <#
                    By default, the minimum size on a 32-bit (x86) system is 1.5 times the amount of physical RAM if physical RAM is less than 1 GB, 
                    and equal to the amount of physical RAM plus 300 MB if 1 GB or more is installed. The default maximum size is three times the amount of RAM, 
                    regardless of how much physical RAM is installed. 
                    If($TotalPhysicalMemorySize -lt 1) {
                        $InitialSize = 1.5*1024
                        $MaximumSize = 1024*3
                        Set-PageFileSize -DL $DL -InitialSize $InitialSize -MaximumSize $MaximumSize
                    } Else {
                        $InitialSize = 1024+300
                        $MaximumSize = 1024*3
                        Set-PageFileSize -DL $DL -InitialSize $InitialSize -MaximumSize $MaximumSize
                    }
                    #>
						
						
						$InitialSize = (Get-CimInstance -ClassName Win32_PageFileUsage).AllocatedBaseSize
						$sum = $null
						(Get-Counter '\Process(*)\Page File Bytes Peak' -SampleInterval 15 -ErrorAction SilentlyContinue).CounterSamples.CookedValue | % { $sum += $_ }
						$MaximumSize = ($sum * 70/100)/1MB
						if ($Vol.FreeSpace -gt $MaximumSize)
						{
							Set-PageFileSize -DL $DL -InitialSize $InitialSize -MaximumSize $MaximumSize
						}
						else
						{
							Write-Warning -Message "Maximum size of page file being set exceeds the freespace available on the drive"
						}
						break
						
					}
					Default
					{
						if ($Vol.FreeSpace -gt $MaximumSize)
						{
							Set-PageFileSize -DL $DL -InitialSize $InitialSize -MaximumSize $MaximumSize
						}
						else
						{
							Write-Warning -Message "Maximum size of page file being set exceeds the freespace available on the drive"
						}
					}
				}
			}
			
			# Get current page file size information
			try
			{
				Get-CimInstance -ClassName Win32_PageFileSetting -ErrorAction Stop | Select-Object Name,
																								   @{
					Name = "InitialSize(MB)"; Expression = {
						if ($_.InitialSize -eq 0) { "System Managed" }
						else { $_.InitialSize }
					}
				},
																								   @{
					Name = "MaximumSize(MB)"; Expression = {
						if ($_.MaximumSize -eq 0) { "System Managed" }
						else { $_.MaximumSize }
					}
				} |
				Format-Table -AutoSize
			}
			catch
			{
				Write-Warning -Message "Failed to query Win32_PageFileSetting class because $($_.Exception.Message)"
			}
			If ($Reboot)
			{
				Restart-Computer -ComputerName $Env:COMPUTERNAME -Force
			}
		}
	}
	End { }
}

Function Set-PageFileSize{
	[CmdletBinding()]
	Param (
		[Parameter(Mandatory)]
		[Alias('dl')]
		[ValidatePattern('^[A-Z]$')]
		[String]$DriveLetter,
		[Parameter(Mandatory)]
		[ValidateRange(0, [int32]::MaxValue)]
		[Int32]$InitialSize,
		[Parameter(Mandatory)]
		[ValidateRange(0, [int32]::MaxValue)]
		[Int32]$MaximumSize
	)
	Begin { }
	Process
	{
		#The AutomaticManagedPagefile property determines whether the system managed pagefile is enabled. 
		#This capability is not available on windows server 2003,XP and lower versions.
		#Only if it is NOT managed by the system and will also allow you to change these.
		try
		{
			$Sys = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop
		}
		catch
		{
			
		}
		
		If ($Sys.AutomaticManagedPagefile)
		{
			try
			{
				$Sys | Set-CimInstance -Property @{ AutomaticManagedPageFile = $false } -ErrorAction Stop
				Write-Verbose -Message "Set the AutomaticManagedPageFile to false"
			}
			catch
			{
				Write-Warning -Message "Failed to set the AutomaticManagedPageFile property to false in  Win32_ComputerSystem class because $($_.Exception.Message)"
			}
		}
		
		# Configuring the page file size
		try
		{
			$PageFile = Get-CimInstance -ClassName Win32_PageFileSetting -Filter "SettingID='pagefile.sys @ $($DriveLetter):'" -ErrorAction Stop
		}
		catch
		{
			Write-Warning -Message "Failed to query Win32_PageFileSetting class because $($_.Exception.Message)"
		}
		
		If ($PageFile)
		{
			try
			{
				$PageFile | Remove-CimInstance -ErrorAction Stop
			}
			catch
			{
				Write-Warning -Message "Failed to delete pagefile the Win32_PageFileSetting class because $($_.Exception.Message)"
			}
		}
		try
		{
			New-CimInstance -ClassName Win32_PageFileSetting -Property @{ Name = "$($DriveLetter):\pagefile.sys" } -ErrorAction Stop | Out-Null
			
			# http://msdn.microsoft.com/en-us/library/windows/desktop/aa394245%28v=vs.85%29.aspx            
			Get-CimInstance -ClassName Win32_PageFileSetting -Filter "SettingID='pagefile.sys @ $($DriveLetter):'" -ErrorAction Stop | Set-CimInstance -Property @{
				InitialSize = $InitialSize;
				MaximumSize = $MaximumSize;
			} -ErrorAction Stop
			
			Write-Verbose -Message "Successfully configured the pagefile on drive letter $DriveLetter"
			
		}
		catch
		{
			Write-Warning "Pagefile configuration changed on computer '$Env:COMPUTERNAME'. The computer must be restarted for the changes to take effect."
		}
	}
	End { }
}

Function Write-RichText{
	<#
	.SYNOPSIS
		A function to output text to a Rich Text Box.
	
	.DESCRIPTION
		This function appends text to a Rich Text Box and colors it based 
        upon the type of message being displayed.

    .PARAM Logtype
        Used to determine if the text is a success or error message or purely
        informational.

    .PARAM LogMSG
        The message to be added to the RichTextBox.
	
	.EXAMPLE
		Write-Richtext -LogType Error -LogMsg "This is an Error."
		Write-Richtext -LogType Success -LogMsg "This is a Success."
		Write-Richtext -LogType Informational -LogMsg "This is Informational."
	
	.NOTES
		Added Time stamps cause why not.
#>
	
	Param
	(
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[String]$LogType,
		[Parameter(Mandatory = $true, Position = 1, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[String]$LogMsg
	)
	
	switch ($logtype)
	{
		Error {
			$richtextbox1.SelectionColor = 'Red'
			$richtextbox1.AppendText("`n $(Get-date -Format "hh:mm:ss") - $logmsg")
			
		}
		Success {
			$richtextbox1.SelectionColor = 'Green'
			$richtextbox1.AppendText("`n $(Get-date -Format "hh:mm:ss") - $logmsg")
			
		}
		Informational {
			$richtextbox1.SelectionColor = 'Blue'
			$richtextbox1.AppendText("`n $(Get-date -Format "hh:mm:ss") - $logmsg")
			
		}
		
	}
	
}

Function Write-Log{
	<#
	.SYNOPSIS
		A function to write ouput messages to a logfile.
	
	.DESCRIPTION
		This function is designed to send timestamped messages to a logfile of your choosing.
		Use it to replace something like write-host for a more long term log.
	
	.PARAMETER Message
		The message being written to the log file.
	
	.EXAMPLE
		PS C:\> Write-Log -Message 'This is the message being written out to the log.' 
	
	.NOTES
		N/A
#>
	
	Param
	(
		[Parameter(Mandatory = $True, Position = 0)]
		[String]$Message
	)
	
	
	add-content -path $LogFilePath -value ($Message)
}

