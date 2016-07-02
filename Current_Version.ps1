Function ConnectTo-VCenter{
	
	$Connection = Connect-VIServer -Server $Global:VMCreationSelections.VCenterServer `
								   -Credential $Script:Credentials

    If(!$Connection){
		Write-Richtext -LogType 'Error' -LogMsg "Unable to connect to $($Global:VMCreationSelections.VCenterServer) ¯\_(ツ)_/¯."
		return;
	}
	
	Else
	{
		Write-Richtext -LogType 'Success' -LogMsg "Connected to $($Global:VMCreationSelections.VCenterServer)."
        Write-Richtext -LogType 'Informational' -LogMsg "Retrieving Local Offices please be patient."
		Populate-LocalOfficeDropDown
    }
}

Function Populate-TemplateDropDown{
	$Templates = Get-Template -Server $Global:VMCreationSelections.VCenterServer `
							  -Location $($LocalOfficeSelectionComboBox.SelectedItem)

    If(!$Templates)
    {
		Write-Richtext -LogType 'Error' -LogMsg "Unable to Gather templates from $($Global:VMCreationSelections.VCenterServer)."
    }

    Else
    {
		Write-Richtext -LogType 'Success' -LogMsg "Templates retrieved from $($Global:VMCreationSelections.VCenterServer)."
		
		$TemplateSelectionComboBox.Items.clear()
		
        Foreach ($Template in $Templates) 
        {
            $TemplateSelectionComboBox.Items.Add($Template)
        }
		
		$TemplateSelectionComboBox.enabled = $True
    }
}

Function Populate-LocalOfficeDropDown{
    
    $LocalOffices = Get-Datacenter -Server $($Global:VMCreationSelections.VCenterServer)

    If(!$LocalOffices)
    {
		Write-Richtext -LogType 'Error' -LogMsg "Unable to Gather Local Offices from $($Global:VMCreationSelections.VCenterServer)"
    }

    Else
    {
		Write-Richtext -LogType 'Success' -LogMsg "Local Offices retrieved from $($Global:VMCreationSelections.VCenterServer)"
		$LocalOfficeSelectioncomboBox.Items.clear()
        Foreach ($Office in $LocalOffices) 
        {
            $LocalOfficeSelectioncomboBox.Items.Add($Office)
		}
		
        $LocalOfficeSelectioncomboBox.enabled = $True
    }

}

Function Populate-CustomizationDropDown{

    $Customizations = Get-OSCustomizationSpec -Server $($Global:VMCreationSelections.VCenterServer)

    If(!$Customizations)
    {
		Write-Richtext -LogType 'Error' -LogMsg "Unable to Gather customizations from $($Global:VMCreationSelections.VCenterServer)."
    }

    Else
	{
		$CustomizationSelectioncomboBox.Items.clear()
        Foreach ($Item in $Customizations) 
        {
            $CustomizationSelectioncomboBox.Items.Add($($Item.name))
        }
		
		$CustomizationSelectioncomboBox.enabled = $True
    }
}

Function Populate-ESXClustersDropDown{
	
	$Clusters = Get-Cluster -Server $($Global:VMCreationSelections.VCenterServer) `
								   -location $($LocalOfficeSelectionComboBox.SelectedItem)
	
	$VMHosts = Get-VMHost -Server $($VCenterComboBox.SelectedItem) `
						  -location $($LocalOfficeSelectionComboBox.SelectedItem)
	
    If(!$Clusters -and !$VMHosts)
    {
		Write-Richtext -LogType 'Error' -LogMsg "Unable to Gather ESX Hosts or Clusters."
    }

    Else
    {
		Write-Richtext -LogType 'Success' -LogMsg "Clusters retrieved from $($LocalOfficeSelectionComboBox.SelectedItem)."
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
	
	$DataStoreClusters = Get-Cluster -Server $Global:VMCreationSelections.VCenterServer `
									 -Name $($ESXClustersComboBox.SelectedItem) `
									 | Get-Datastore | Get-DatastoreCluster
	
	$DataStores = Get-VMHOST -Server $Global:VMCreationSelections.VCenterServer `
							 -Name $ESXClustersComboBox.SelectedItem `
							 | Get-Datastore

    If(!$DataStoreClusters -and !$DataStores)
    {
		Write-Richtext -LogType 'Error' -LogMsg "Unable to pull and DataStore Clusters or Datastores from  $($ESXClustersComboBox.SelectedItem). "
    }

    Else
    {
		Write-Richtext -LogType 'Success' -LogMsg "DataStores or Clusters retrieved from $($ESXClustersComboBox.SelectedItem)."
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

Function Populate-ExtraDiskClusterDropDown{
	param
	(
		[System.Windows.Forms.ComboBox]$ComboBox
	)
	
	$DataStoreClusters = Get-Cluster -Server $Global:VMCreationSelections.VCenterServer `
									 -Name $($ESXClustersComboBox.SelectedItem) `
	| Get-Datastore | Get-DatastoreCluster
	
	$DataStores = Get-VMHOST -Server $Global:VMCreationSelections.VCenterServer `
							 -Name $ESXClustersComboBox.SelectedItem `
	| Get-Datastore
	
	If (!$DataStoreClusters -and !$DataStores)
	{
		Write-Richtext -LogType 'Error' -LogMsg "Unable to pull and DataStore Clusters or Datastores from  $($ESXClustersComboBox.SelectedItem). "
	}
	
	Else
	{
		Write-Richtext -LogType 'Success' -LogMsg "DataStores or Clusters retrieved from $($ESXClustersComboBox.SelectedItem)."
		$DataStoreClusterComboBox.Items.clear()
		
		If ($DataStoreClusters)
		{
			Foreach ($Item in $DataStoreClusters)
			{
				$ComboBox.Items.Add($Item.name)
			}
		}
		
		If ($DataStores)
		{
			Foreach ($Item in $DataStores)
			{
				$ComboBox.Items.Add($Item.name)
			}
		}
	}
	
}

Function Set-VMCPUCount{
	$VM = Get-VM -Server $Global:VMCreationSelections.VCenterServer `
				 -Location $Global:VMCreationSelections.Location `
				 -Name $Global:VMCreationSelections.Name
	
	$Set = Set-VM -Server $Global:VMCreationSelections.VCenterServer `
				  -VM $VM `
				  -NumCpu $VCPUsComboBox.SelectedItem `
				  -Confirm
	
	If ($Set.numcpu -eq $VCPUsComboBox.SelectedItem){
		Write-RichText -LogType success -LogMsg "VCPU Count Set to $($Set.numcpu)"
		
	}
	
	Else{
		Write-RichText -LogType Error -LogMsg "Unable to Set VCPU Count!!"
	}
}

Function Set-VMRamAmount{
	$VM = Get-VM -Server $Global:VMCreationSelections.VCenterServer `
				 -Location $Global:VMCreationSelections.Location `
				 -Name $Global:VMCreationSelections.Name
	
	$Set = Set-VM -Server $Global:VMCreationSelections.VCenterServer `
				  -VM $VM `
				  -MemoryGB $RamComboBox.SelectedItem `
				  -Confirm
	
	If ($Set.MemoryGB -eq $RamComboBox.SelectedItem)
	{
		Write-RichText -LogType success -LogMsg "RAM Amount (GB) Set to $($Set.numcpu)"
		
	}
	
	Else
	{
		Write-RichText -LogType Error -LogMsg "Unable to Set RAM Value!!"
	}
}

function Control-VisibleExtraDrives{
	
	switch ($Global:DriveCounter)
	{
		1 {
			#ED1
			$ExtraDrive1_DataStoreComboBox.visible = $true
			$ExtraDrive1_letterComboBox.visible = $true
			$ExtraDrive1_SelectionLabel.visible = $true
			$ExtraDrive1SizeTextBox.visible = $true
			$ExtraDrive1_SizeLabel.visible = $true
			$ExtraDrive1_DatastoreLabel.visible = $true
			#ED2
			$ExtraDrive2_DataStoreComboBox.visible = $false
			$ExtraDrive2_letterComboBox.visible = $false
			$ExtraDrive2_SelectionLabel.visible = $false
			$ExtraDrive2SizeTextBox.visible = $false
			$ExtraDrive2_SizeLabel.visible = $false
			$ExtraDrive2_DatastoreLabel.visible = $false
			#ED3
			$ExtraDrive3_DataStoreComboBox.visible = $false
			$ExtraDrive3_letterComboBox.visible = $false
			$ExtraDrive3_SelectionLabel.visible = $false
			$ExtraDrive3SizeTextBox.visible = $false
			$ExtraDrive3_SizeLabel.visible = $false
			$ExtraDrive3_DatastoreLabel.visible = $false
			#ED4
			$ExtraDrive4_DataStoreComboBox.visible = $false
			$ExtraDrive4_letterComboBox.visible = $false
			$ExtraDrive4_SelectionLabel.visible = $false
			$ExtraDrive4SizeTextBox.visible = $false
			$ExtraDrive4_SizeLabel.visible = $false
			$ExtraDrive4_DatastoreLabel.visible = $false
			#ED5
			$ExtraDrive5_DataStoreComboBox.visible = $false
			$ExtraDrive5_letterComboBox.visible = $false
			$ExtraDrive5_SelectionLabel.visible = $false
			$ExtraDrive5SizeTextBox.visible = $false
			$ExtraDrive5_SizeLabel.visible = $false
			$ExtraDrive5_DatastoreLabel.visible = $false
		}
		2 {
			#ED1
			$ExtraDrive1_DataStoreComboBox.visible = $true
			$ExtraDrive1_letterComboBox.visible = $true
			$ExtraDrive1_SelectionLabel.visible = $true
			$ExtraDrive1SizeTextBox.visible = $true
			$ExtraDrive1_SizeLabel.visible = $true
			$ExtraDrive1_DatastoreLabel.visible = $true
			#ED2
			$ExtraDrive2_DataStoreComboBox.visible = $true
			$ExtraDrive2_letterComboBox.visible = $true
			$ExtraDrive2_SelectionLabel.visible = $true
			$ExtraDrive2SizeTextBox.visible = $true
			$ExtraDrive2_SizeLabel.visible = $true
			$ExtraDrive2_DatastoreLabel.visible = $true
			#ED3
			$ExtraDrive3_DataStoreComboBox.visible = $false
			$ExtraDrive3_letterComboBox.visible = $false
			$ExtraDrive3_SelectionLabel.visible = $false
			$ExtraDrive3SizeTextBox.visible = $false
			$ExtraDrive3_SizeLabel.visible = $false
			$ExtraDrive3_DatastoreLabel.visible = $false
			#ED4
			$ExtraDrive4_DataStoreComboBox.visible = $false
			$ExtraDrive4_letterComboBox.visible = $false
			$ExtraDrive4_SelectionLabel.visible = $false
			$ExtraDrive4SizeTextBox.visible = $false
			$ExtraDrive4_SizeLabel.visible = $false
			$ExtraDrive4_DatastoreLabel.visible = $false
			#ED5
			$ExtraDrive5_DataStoreComboBox.visible = $false
			$ExtraDrive5_letterComboBox.visible = $false
			$ExtraDrive5_SelectionLabel.visible = $false
			$ExtraDrive5SizeTextBox.visible = $false
			$ExtraDrive5_SizeLabel.visible = $false
			$ExtraDrive5_DatastoreLabel.visible = $false
		}
		3 {
			#ED1
			$ExtraDrive1_DataStoreComboBox.visible = $true
			$ExtraDrive1_letterComboBox.visible = $true
			$ExtraDrive1_SelectionLabel.visible = $true
			$ExtraDrive1SizeTextBox.visible = $true
			$ExtraDrive1_SizeLabel.visible = $true
			$ExtraDrive1_DatastoreLabel.visible = $true
			#ED2
			$ExtraDrive2_DataStoreComboBox.visible = $true
			$ExtraDrive2_letterComboBox.visible = $true
			$ExtraDrive2_SelectionLabel.visible = $true
			$ExtraDrive2SizeTextBox.visible = $true
			$ExtraDrive2_SizeLabel.visible = $true
			$ExtraDrive2_DatastoreLabel.visible = $true
			#ED3
			$ExtraDrive3_DataStoreComboBox.visible = $true
			$ExtraDrive3_letterComboBox.visible = $true
			$ExtraDrive3_SelectionLabel.visible = $true
			$ExtraDrive3SizeTextBox.visible = $true
			$ExtraDrive3_SizeLabel.visible = $true
			$ExtraDrive3_DatastoreLabel.visible = $true
			#ED4
			$ExtraDrive4_DataStoreComboBox.visible = $false
			$ExtraDrive4_letterComboBox.visible = $false
			$ExtraDrive4_SelectionLabel.visible = $false
			$ExtraDrive4SizeTextBox.visible = $false
			$ExtraDrive4_SizeLabel.visible = $false
			$ExtraDrive4_DatastoreLabel.visible = $false
			#ED5
			$ExtraDrive5_DataStoreComboBox.visible = $false
			$ExtraDrive5_letterComboBox.visible = $false
			$ExtraDrive5_SelectionLabel.visible = $false
			$ExtraDrive5SizeTextBox.visible = $false
			$ExtraDrive5_SizeLabel.visible = $false
			$ExtraDrive5_DatastoreLabel.visible = $false
		}
		4 {
			#ED1
			$ExtraDrive1_DataStoreComboBox.visible = $true
			$ExtraDrive1_letterComboBox.visible = $true
			$ExtraDrive1_SelectionLabel.visible = $true
			$ExtraDrive1SizeTextBox.visible = $true
			$ExtraDrive1_SizeLabel.visible = $true
			$ExtraDrive1_DatastoreLabel.visible = $true
			#ED2
			$ExtraDrive2_DataStoreComboBox.visible = $true
			$ExtraDrive2_letterComboBox.visible = $true
			$ExtraDrive2_SelectionLabel.visible = $true
			$ExtraDrive2SizeTextBox.visible = $true
			$ExtraDrive2_SizeLabel.visible = $true
			$ExtraDrive2_DatastoreLabel.visible = $true
			#ED3
			$ExtraDrive3_DataStoreComboBox.visible = $true
			$ExtraDrive3_letterComboBox.visible = $true
			$ExtraDrive3_SelectionLabel.visible = $true
			$ExtraDrive3SizeTextBox.visible = $true
			$ExtraDrive3_SizeLabel.visible = $true
			$ExtraDrive3_DatastoreLabel.visible = $true
			#ED4
			$ExtraDrive4_DataStoreComboBox.visible = $true
			$ExtraDrive4_letterComboBox.visible = $true
			$ExtraDrive4_SelectionLabel.visible = $true
			$ExtraDrive4SizeTextBox.visible = $true
			$ExtraDrive4_SizeLabel.visible = $true
			$ExtraDrive4_DatastoreLabel.visible = $true
			#ED5
			$ExtraDrive5_DataStoreComboBox.visible = $false
			$ExtraDrive5_letterComboBox.visible = $false
			$ExtraDrive5_SelectionLabel.visible = $false
			$ExtraDrive5SizeTextBox.visible = $false
			$ExtraDrive5_SizeLabel.visible = $false
			$ExtraDrive5_DatastoreLabel.visible = $false
		}
		5{
			#ED1
			$ExtraDrive1_DataStoreComboBox.visible = $true
			$ExtraDrive1_letterComboBox.visible = $true
			$ExtraDrive1_SelectionLabel.visible = $true
			$ExtraDrive1SizeTextBox.visible = $true
			$ExtraDrive1_SizeLabel.visible = $true
			$ExtraDrive1_DatastoreLabel.visible = $true
			#ED2
			$ExtraDrive2_DataStoreComboBox.visible = $true
			$ExtraDrive2_letterComboBox.visible = $true
			$ExtraDrive2_SelectionLabel.visible = $true
			$ExtraDrive2SizeTextBox.visible = $true
			$ExtraDrive2_SizeLabel.visible = $true
			$ExtraDrive2_DatastoreLabel.visible = $true
			#ED3
			$ExtraDrive3_DataStoreComboBox.visible = $true
			$ExtraDrive3_letterComboBox.visible = $true
			$ExtraDrive3_SelectionLabel.visible = $true
			$ExtraDrive3SizeTextBox.visible = $true
			$ExtraDrive3_SizeLabel.visible = $true
			$ExtraDrive3_DatastoreLabel.visible = $true
			#ED4
			$ExtraDrive4_DataStoreComboBox.visible = $true
			$ExtraDrive4_letterComboBox.visible = $true
			$ExtraDrive4_SelectionLabel.visible = $true
			$ExtraDrive4SizeTextBox.visible = $true
			$ExtraDrive4_SizeLabel.visible = $true
			$ExtraDrive4_DatastoreLabel.visible = $true
			#ED5
			$ExtraDrive5_DataStoreComboBox.visible = $true
			$ExtraDrive5_letterComboBox.visible = $true
			$ExtraDrive5_SelectionLabel.visible = $true
			$ExtraDrive5SizeTextBox.visible = $true
			$ExtraDrive5_SizeLabel.visible = $true
			$ExtraDrive5_DatastoreLabel.visible = $true
		}
	}
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
		N/A
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
			$richtextbox1.AppendText("`n $logmsg")
			
		}
		Success {
			$richtextbox1.SelectionColor = 'Green'
			$richtextbox1.AppendText("`n $logmsg")
			
		}
		Informational {
			$richtextbox1.SelectionColor = 'Blue'
			$richtextbox1.AppendText("`n $logmsg")
			
		}
		
	}
	
}

Function Build-Form {

	#region Import Assemblies and Modules

	Add-Type -AssemblyName System.Windows.Forms
	Add-Type -AssemblyName System.Data
	Add-Type -AssemblyName System.Drawing
	Import-Module -Name VMware.VimAutomation.Core
	$DebugPreference = 'Continue'
	#Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -confirm
	
	#endregion

	#region Declare Form Objects

	#region Global Selection Storage Variables
	
	$Global:VMCreationSelections = New-Object –TypeName PSObject
	$Global:VMCreationSelections | Add-Member -MemberType NoteProperty -Name VCenterServer -Value ''
	$Global:VMCreationSelections | Add-Member -MemberType NoteProperty -Name Location -Value ''
	$Global:VMCreationSelections | Add-Member -MemberType NoteProperty -Name ResourcePool -Value ''
	$Global:VMCreationSelections | Add-Member -MemberType NoteProperty -Name Name -Value ''
	$Global:VMCreationSelections | Add-Member -MemberType NoteProperty -Name Datastore -Value ''
	$Global:VMCreationSelections | Add-Member -MemberType NoteProperty -Name Template -Value ''
	$Global:VMCreationSelections | Add-Member -MemberType NoteProperty -Name OSCustomizationSpec -Value ''
	$Global:VMCreationSelections | Add-Member -MemberType NoteProperty -Name VCPUs -Value '2'
	
	[Int]$Global:DriveCounter = 0
	[Array]$Global:DriveLetterarray = @('','a','b','e','f','g','h','i','j','k','l','m','n','o','q','r','s','t','u','v','x','y','z')
	
	#endregion
	
	#region Form Wide Controls
	[System.Windows.Forms.Application]::EnableVisualStyles()
	$form = New-Object 'System.Windows.Forms.Form'
	#endregion
	
	#region Labels
    $TemplateSelectionLabel         = New-Object System.Windows.Forms.label
    $VCenterSelection               = New-Object System.Windows.Forms.label
    $LocalOfficeSelectionLabel      = New-Object System.Windows.Forms.label
    $ESXHostsSelectionLabel         = New-Object System.Windows.Forms.label
    $DataStoreClusterSelectionLabel = New-Object System.Windows.Forms.label
    $CustomizationSelectionLabel    = New-Object System.Windows.Forms.label
	$VMnameInputBoxLabel            = New-Object System.Windows.Forms.label
	$SeperatorLine1      	 		= New-Object System.Windows.Forms.label
	$SeperatorLine2 				= New-Object System.Windows.Forms.label
	$VCPUsSelectionLabel 		    = New-Object System.Windows.Forms.label
	$RAMSelectionLabel 				= New-Object System.Windows.Forms.label
	$ExtraDrive1_SelectionLabel 	= New-Object System.Windows.Forms.label
	$ExtraDrive2_SelectionLabel 	= New-Object System.Windows.Forms.label
	$ExtraDrive3_SelectionLabel 	= New-Object System.Windows.Forms.label
	$ExtraDrive4_SelectionLabel 	= New-Object System.Windows.Forms.label
	$ExtraDrive5_SelectionLabel 	= New-Object System.Windows.Forms.label
	$ExtraDrive1_SizeLabel			= New-Object System.Windows.Forms.label
	$ExtraDrive2_SizeLabel 			= New-Object System.Windows.Forms.label
	$ExtraDrive3_SizeLabel			= New-Object System.Windows.Forms.label
	$ExtraDrive4_SizeLabel			= New-Object System.Windows.Forms.label
	$ExtraDrive5_SizeLabel 			= New-Object System.Windows.Forms.label
	$ExtraDrive1_DatastoreLabel 	= New-Object System.Windows.Forms.label
	$ExtraDrive2_DatastoreLabel 	= New-Object System.Windows.Forms.label
	$ExtraDrive3_DatastoreLabel 	= New-Object System.Windows.Forms.label
	$ExtraDrive4_DatastoreLabel 	= New-Object System.Windows.Forms.label
	$ExtraDrive5_DatastoreLabel 	= New-Object System.Windows.Forms.label
	
	#endregion
	
    #region ComboBoxes
	$VCenterComboBox                = New-Object System.Windows.Forms.ComboBox
    $TemplateSelectionComboBox      = New-Object System.Windows.Forms.ComboBox
    $LocalOfficeSelectionComboBox   = New-Object System.Windows.Forms.ComboBox
    $CustomizationSelectioncomboBox = New-Object System.Windows.Forms.ComboBox
    $ESXClustersComboBox            = New-Object System.Windows.Forms.ComboBox
    $DataStoreClusterComboBox       = New-Object System.Windows.Forms.ComboBox
	$VCPUsComboBox 				    = New-Object System.Windows.Forms.ComboBox
	$RAMComboBox 					= New-Object System.Windows.Forms.ComboBox
	$ExtraDrive1_letterComboBox 	= New-Object System.Windows.Forms.ComboBox
	$ExtraDrive2_letterComboBox 	= New-Object System.Windows.Forms.ComboBox
	$ExtraDrive3_letterComboBox 	= New-Object System.Windows.Forms.ComboBox
	$ExtraDrive4_letterComboBox 	= New-Object System.Windows.Forms.ComboBox
	$ExtraDrive5_letterComboBox 	= New-Object System.Windows.Forms.ComboBox
	$ExtraDrive1_DataStoreComboBox 	= New-Object System.Windows.Forms.ComboBox
	$ExtraDrive2_DataStoreComboBox 	= New-Object System.Windows.Forms.ComboBox
	$ExtraDrive3_DataStoreComboBox 	= New-Object System.Windows.Forms.ComboBox
	$ExtraDrive4_DataStoreComboBox 	= New-Object System.Windows.Forms.ComboBox
	$ExtraDrive5_DataStoreComboBox 	= New-Object System.Windows.Forms.ComboBox
	#endregion
	
    #region Buttons
	$CreateVMButton 				= New-Object System.Windows.Forms.Button
	$IncrementDrivesButton 			= New-Object System.Windows.Forms.Button
	$DecrementDrivesButton 			= New-Object System.Windows.Forms.Button
	#endregion
	
    #region RichtextBoxes
    $richtextbox1                   = New-Object System.Windows.Forms.RichTextBox
	#endregion
	
    #region TextBoxes
	$VMnameInputBox 				= New-Object System.Windows.Forms.TextBox
	$DriveInfoTextBox 				= New-Object System.Windows.Forms.TextBox
	$NumDrivesTextBox 				= New-Object System.Windows.Forms.TextBox
	$ExtraDrive1SizeTextBox 		= New-Object System.Windows.Forms.TextBox
	$ExtraDrive2SizeTextBox 		= New-Object System.Windows.Forms.TextBox
	$ExtraDrive3SizeTextBox 		= New-Object System.Windows.Forms.TextBox
	$ExtraDrive4SizeTextBox 		= New-Object System.Windows.Forms.TextBox
	$ExtraDrive5SizeTextBox 		= New-Object System.Windows.Forms.TextBox
	
	#endregion
	
    #endregion

    #region Event Handlers
	
	$ServerSelectionMade = {
		$Global:VMCreationSelections.VCenterServer = $($VCenterComboBox.SelectedItem)
		Write-Debug -Message "Server = $($Global:VMCreationSelections.VCenterServer)"
		Write-RichText -LogType 'Informational' -LogMsg "Connecting to $($Global:VMCreationSelections.VCenterServer) please be patient."
        $Script:Credentials = Get-Credential
        ConnectTo-VCenter
	}

    $TemplateSelectionMade = {
		
		$Global:VMCreationSelections.Template = Get-Template -Server $($Global:VMCreationSelections.VCenterServer) `
					 										  -Location $($Global:VMCreationSelections.Location) `
					 										  -Name $($TemplateSelectionComboBox.SelectedItem)
		
		
		Write-RichText -LogType 'Informational' -LogMsg "Retrieving Customizations please be patient."

		Populate-CustomizationDropDown
    }
	
	$LocalOfficeSelectionMade = {
		
		$Global:VMCreationSelections.Location = $($LocalOfficeSelectionComboBox.SelectedItem)
		Write-Debug -Message "Location = $($Global:VMCreationSelections.Location)"
		
		Write-RichText -LogType 'Informational' -LogMsg "Retrieving ESX Clusters please be patient."

		Populate-ESXClustersDropDown
	}

    $ESXClustersSelectionMade = {
		
		$Clusters = Get-Cluster -Server $Global:VMCreationSelections.VCenterServer `
								-location $Global:VMCreationSelections.Location `
								-Name $ESXClustersComboBox.SelectedItem
		If ($Clusters){
			$Global:VMCreationSelections.ResourcePool = $Clusters
		}
		
		Else { 
			$VMHosts = Get-VMHost -Server $Global:VMCreationSelections.VCenterServer `
								  -location $Global:VMCreationSelections.Location `
								  -Name $ESXClustersComboBox.SelectedItem
			
			$Global:VMCreationSelections.ResourcePool = $VMHosts
		}
		
		Write-Debug -Message "Location = $($Global:VMCreationSelections.ResourcePool)"
		Write-RichText -LogType 'Informational' -LogMsg "Retrieving Datastores please be patient."

		Populate-DatastoreClusterDropDown
       
    }

    $DataStoreClustersSelectionMade = {
		
		$DataStoreClusters = Get-DataStoreCluster -Server $Global:VMCreationSelections.VCenterServer `
												  -Location $Global:VMCreationSelections.Location `
												  -name $DataStoreClusterComboBox.SelectedItem
		
		If ($DataStoreClusters)
		{
			$Global:VMCreationSelections.Datastore = $DataStoreClusters
		}
		
		Else
		{
			$DataStores = Get-DataStore -Server $Global:VMCreationSelections.VCenterServer `
										-Location $Global:VMCreationSelections.Location `
										-name $DataStoreClusterComboBox.SelectedItem
			
			$Global:VMCreationSelections.Datastore = $DataStores
		}
		
		Write-Debug -Message "Location = $($Global:VMCreationSelections.DataStore)"
		Write-RichText -LogType 'Informational' -LogMsg "Retrieving Templates please be patient."

		Populate-TemplateDropDown
		
	}
	
	$CustomizationSelectionMade = {
		
		$Global:VMCreationSelections.OSCustomizationSpec = Get-OSCustomizationSpec -Server $Global:VMCreationSelections.VCenterServer `
																				   -Name $CustomizationSelectioncomboBox.SelectedItem
		
		$VMnameInputBox.Enabled = $true

	}
	
	$VMNameEntered = {
		
		$Global:VMCreationSelections.Name = $VMnameInputBox.Text
		$CreateVMButton.Enabled = $True

	}
	
	$CreateVMButton_Click = {
		
		$richtextbox1.clear()
		
		Write-RichText -LogType informational -LogMsg "VCenter server : $($Global:VMCreationSelections.VCenterServer)"
		Write-RichText -LogType informational -LogMsg "ESXCluster : $($Global:VMCreationSelections.ResourcePool)"
		Write-RichText -LogType informational -LogMsg "Location : $($Global:VMCreationSelections.Location)"
		Write-RichText -LogType informational -LogMsg "VM Name : $($Global:VMCreationSelections.Name)"
		Write-RichText -LogType informational -LogMsg "DataStore : $($Global:VMCreationSelections.Datastore)"
		Write-RichText -LogType informational -LogMsg "Template : $($Global:VMCreationSelections.Template)"
		Write-RichText -LogType informational -LogMsg "Customization : $($Global:VMCreationSelections.OSCustomizationSpec)"
		
		
		Write-RichText -LogType informational -LogMsg "VM Creation beginning please be patient."
	
		
			
		New-VM -Server $Global:VMCreationSelections.VCenterServer `
			   -ResourcePool $Global:VMCreationSelections.ResourcePool `
			   -Name $Global:VMCreationSelections.Name `
			   -Datastore $Global:VMCreationSelections.Datastore  `
			   -Template $Global:VMCreationSelections.Template `
			   -OSCustomizationSpec $Global:VMCreationSelections.OSCustomizationSpec
		
		Write-RichText -LogType informational -LogMsg "VM Creation Completed!"
		$VCPUsComboBox.Enabled = $True
		$RAMComboBox.Enabled = $True

		
		
	}
	
	$IncrementDrivesButton_Click = {
		
		If ($Global:DriveCounter -lt 5){
			
			[Int]$Global:DriveCounter++
			$NumDrivesTextBox.Text = $Global:DriveCounter
			Control-VisibleExtraDrives
			}

		Else{
			Write-RichText -LogType error -LogMsg "This tool only allows for up to 5 extra drives."
		}
	}
	
	$DecrementDrivesButton_Click = {
		
		If ($Global:DriveCounter -gt 0){
			
			[Int]$Global:DriveCounter--
			$NumDrivesTextBox.Text = $Global:DriveCounter
			Control-VisibleExtraDrives
		}
		
	}
	
	#endregion
	
	#region Form properties

	$form.Controls.Add($buttonFinish)
	$form.ClientSize = '1024, 850'
	$form.FormBorderStyle = 'FixedDialog'
	$form.MaximizeBox = $False
	$form.Name = 'formWizard'
	$form.StartPosition = 'CenterScreen'
	$form.Text = 'White & Case Server Build Tool'
    $Form.BackColor = [System.Drawing.Color]::FromArgb(255,185,209,234)
	
	#endregion
	
	#region VCenter Server Selection Label
	
	$VCenterSelection.Location = '5, 10' #L/R, U/D
	$VCenterSelection.Name = 'VCenter Selection Label'
	$VCenterSelection.Size = '350, 20' #L/R, U/D
	$VCenterSelection.TabIndex = 0
	$VCenterSelection.Text = 'Please select the VCenter Region'
    $form.Controls.Add($VCenterSelection)
	
	#endregion

	#region VCenter ComboBox

	$VCenterComboBox.FormattingEnabled = $True
	[void]$VCenterComboBox.Items.Add('AM1-Vcenter')
	[void]$VCenterComboBox.Items.Add('EM1-Vcenter')
	[void]$VCenterComboBox.Items.Add('AP1-VCenter')
	$VCenterComboBox.Location = '5, 30'
	$VCenterComboBox.Name = 'VCenterComboBox'
	$VCenterComboBox.Size = '350, 20'
	$VCenterComboBox.TabIndex = 0
    $VCenterComboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
	$VCenterComboBox.add_SelectedIndexChanged($ServerSelectionMade)
	$form.Controls.Add($VCenterComboBox)
	
	#endregion

	#region Local Office Selection Label
	
	$LocalOfficeSelectionLabel.Location = '5, 60' #L/R, U/D
	$LocalOfficeSelectionLabel.Name = 'VCenter Selection Label'
	$LocalOfficeSelectionLabel.Size = '350, 20' #L/R, U/D
	$LocalOfficeSelectionLabel.TabIndex = 0
	$LocalOfficeSelectionLabel.Text = 'Please select the Local Office or Datacenter'
	$LocalOfficeSelectionLabel.Enabled = $true
    $form.Controls.Add($LocalOfficeSelectionLabel)
	
	#endregion

	#region Local Office ComboBox

	$LocalOfficeSelectioncomboBox.FormattingEnabled = $True
	$LocalOfficeSelectioncomboBox.Location = '5, 80'
	$LocalOfficeSelectioncomboBox.Name = 'VCenterComboBox'
	$LocalOfficeSelectioncomboBox.Size = '350, 20'
	$LocalOfficeSelectioncomboBox.TabIndex = 0
	$LocalOfficeSelectioncomboBox.add_SelectedIndexChanged($LocalOfficeSelectionMade)
    $LocalOfficeSelectioncomboBox.Enabled = $False
    $LocalOfficeSelectionComboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
	$form.Controls.Add($LocalOfficeSelectioncomboBox)
	
	#endregion

	#region Template Selection Label
	
	$TemplateSelectionLabel.Location = '5, 210' #L/R, U/D
	$TemplateSelectionLabel.Name = 'VCenter Selection Label'
	$TemplateSelectionLabel.Size = '350, 20' #L/R, U/D
	$TemplateSelectionLabel.TabIndex = 0
	$TemplateSelectionLabel.Text = 'Please select the Template'
    $TemplateSelectionLabel.Enabled = $true
    $form.Controls.Add($TemplateSelectionLabel)
	
	#endregion

	#region Template ComboBox

	$TemplateSelectionComboBox.FormattingEnabled = $True
	$TemplateSelectionComboBox.Location = '5, 230'
	$TemplateSelectionComboBox.Name = 'VCenterComboBox'
	$TemplateSelectionComboBox.Size = '350, 20'
	$TemplateSelectionComboBox.TabIndex = 0
	$TemplateSelectionComboBox.add_SelectedIndexChanged($TemplateSelectionMade)
    $TemplateSelectionComboBox.Enabled = $False
    $TemplateSelectionComboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
	$form.Controls.Add($TemplateSelectionComboBox)
	
	#endregion

	#region ESX Clusters Selection Label
	
	$ESXHostsSelectionLabel.Location = '5, 110' #L/R, U/D
	$ESXHostsSelectionLabel.Name = 'ESX Host Selection Label'
	$ESXHostsSelectionLabel.Size = '350, 20' #L/R, U/D
	$ESXHostsSelectionLabel.TabIndex = 0
	$ESXHostsSelectionLabel.Text = 'Please select the ESX Cluster'
    $ESXHostsSelectionLabel.Enabled = $true
    $form.Controls.Add($ESXHostsSelectionLabel)
	
	#endregion

	#region ESX Clusters ComboBox
    
    $ESXClustersComboBox.FormattingEnabled = $True
	$ESXClustersComboBox.Location = '5, 130'
	$ESXClustersComboBox.Name = 'ESXClustersComboBox'
	$ESXClustersComboBox.Size = '350, 20'
	$ESXClustersComboBox.TabIndex = 0
	$ESXClustersComboBox.add_SelectedIndexChanged($ESXClustersSelectionMade)
    $ESXClustersComboBox.Enabled = $False
    $ESXClustersComboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
	$form.Controls.Add($ESXClustersComboBox)

	#endregion

	#region DataStore Clusters Selection Label
	
	$DataStoreClusterSelectionLabel.Location = '5, 160' #L/R, U/D
	$DataStoreClusterSelectionLabel.Name = 'ESX Host Selection Label'
	$DataStoreClusterSelectionLabel.Size = '350, 20' #L/R, U/D
	$DataStoreClusterSelectionLabel.TabIndex = 0
	$DataStoreClusterSelectionLabel.Text = 'Please select the DataStore Cluster'
    $DataStoreClusterSelectionLabel.Enabled = $true
    $form.Controls.Add($DataStoreClusterSelectionLabel)
	
	#endregion

	#region Datastore Clusters ComboBox
    
    $DataStoreClusterComboBox.FormattingEnabled = $True
	$DataStoreClusterComboBox.Location = '5, 180'
	$DataStoreClusterComboBox.Name = 'ESXClustersComboBox'
	$DataStoreClusterComboBox.Size = '350, 20'
	$DataStoreClusterComboBox.TabIndex = 0
	$DataStoreClusterComboBox.add_SelectedIndexChanged($DataStoreClustersSelectionMade)
    $DataStoreClusterComboBox.Enabled = $False
    $DataStoreClusterComboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
	$form.Controls.Add($DataStoreClusterComboBox)

	#endregion

    #region Customization Selection Label
	
	$CustomizationSelectionLabel.Location = '5, 260' #L/R, U/D
	$CustomizationSelectionLabel.Name = 'VCenter Selection Label'
	$CustomizationSelectionLabel.Size = '350, 20' #L/R, U/D
	$CustomizationSelectionLabel.TabIndex = 0
	$CustomizationSelectionLabel.Text = 'Please select the Customization'
    $CustomizationSelectionLabel.Enabled = $true
    $form.Controls.Add($CustomizationSelectionLabel)
	
	#endregion

	#region Customization ComboBox

	$CustomizationSelectioncomboBox.FormattingEnabled = $True
	$CustomizationSelectioncomboBox.Location = '5, 280'
	$CustomizationSelectioncomboBox.Name = 'VCenterComboBox'
	$CustomizationSelectioncomboBox.Size = '350, 20'
	$CustomizationSelectioncomboBox.TabIndex = 0
	$CustomizationSelectioncomboBox.add_SelectedIndexChanged($CustomizationSelectionMade)
    $CustomizationSelectioncomboBox.Enabled = $False
    $CustomizationSelectionComboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
	$form.Controls.Add($CustomizationSelectioncomboBox)
	
	#endregion

    #region VM Name Input Box Label
	
	$VMnameInputBoxLabel.Location = '5, 310' #L/R, U/D
	$VMnameInputBoxLabel.Name = 'VCenter Selection Label'
	$VMnameInputBoxLabel.Size = '350, 20' #L/R, U/D
	$VMnameInputBoxLabel.TabIndex = 0
	$VMnameInputBoxLabel.Text = 'Please enter the desired VM Name.'
    $VMnameInputBoxLabel.Enabled = $true
    $form.Controls.Add($VMnameInputBoxLabel)
	
	#endregion

    #region VM name Input Box
    
    $VMnameInputBox = New-Object System.Windows.Forms.TextBox 
    $VMnameInputBox.Location = New-Object System.Drawing.Size(5,330)
	$VMnameInputBox.Size = New-Object System.Drawing.Size(350, 20)
	$VMnameInputBox.add_TextChanged($VMNameEntered)
	$VMnameInputBox.Enabled = $false
    $Form.Controls.Add($VMnameInputBox) 

    #endregion

	#region Logging Rich Text Box
	
	$richtextbox1 = New-Object 'System.Windows.Forms.RichTextBox'
	$richtextbox1.Location = '5, 550'
	$richtextbox1.Size ='1009, 280'
	$richtextbox1.Name = "Logging Box"
	$richtextbox1.TabIndex = 0
	$richtextbox1.Text = ""
	$richtextbox1.font = "Arial"
	$richtextbox1.BackColor = 'Gainsboro'
	$richtextbox1.Visible = $true
	$form.Controls.Add($richtextbox1)
	
	#endregion

    #region Create VM Button
    
    $CreateVMButton.UseVisualStyleBackColor = $True
    $CreateVMButton.Text = 'Create VM'
    $CreateVMButton.DataBindings.DefaultDataSourceUpdateMode = 0
    $CreateVMButton.Name = 'DGVSubmit'
    $CreateVMButton.Size = "100,50"
    $CreateVMButton.Location = "5,375"
    $CreateVMButton.Enabled = $False
    $CreateVMButton.add_Click($CreateVMButton_Click)
    $form.Controls.Add($CreateVMButton)
	
	#endregion
	
	#region Seperator Line 1
	
	$SeperatorLine1.Location = '365, 0' #L/R, U/D
	$SeperatorLine1.Name = 'VCenter Selection Label'
	$SeperatorLine1.Size = '2, 500' #L/R, U/D
	$SeperatorLine1.TabIndex = 0
	$SeperatorLine1.Text = ''
	$SeperatorLine1.Enabled = $true
	$SeperatorLine1.BorderStyle = 'Fixed3D'
	$SeperatorLine1.AutoSize = $false
	$form.Controls.Add($SeperatorLine1)
	
	#endregion
	
	#region Seperator Line 2
	
	$SeperatorLine2.Location = '800, 0' #L/R, U/D
	$SeperatorLine2.Name = 'VCenter Selection Label'
	$SeperatorLine2.Size = '2, 500' #L/R, U/D
	$SeperatorLine2.TabIndex = 0
	$SeperatorLine2.Text = ''
	$SeperatorLine2.Enabled = $true
	$SeperatorLine2.BorderStyle = 'Fixed3D'
	$SeperatorLine2.AutoSize = $false
	$form.Controls.Add($SeperatorLine2)
	
	#endregion
	
	#region CPU Cores Selection Label
	
	$VCPUsSelectionLabel.Location = '370, 10' #L/R, U/D
	$VCPUsSelectionLabel.Name = 'VCenter Selection Label'
	$VCPUsSelectionLabel.Size = '350, 20' #L/R, U/D
	$VCPUsSelectionLabel.TabIndex = 0
	$VCPUsSelectionLabel.Text = 'Please Select the desired # of Cores.'
	$VCPUsSelectionLabel.Enabled = $true
	$form.Controls.Add($VCPUsSelectionLabel)
	
	#endregion
	
	#region VCPUs ComboBox
	
	$VCPUsComboBox.FormattingEnabled = $True
	$VCPUsComboBox.Location = '370, 30'
	$VCPUsComboBox.Name = 'VCenterComboBox'
	$VCPUsComboBox.Size = '350, 20'
	$VCPUsComboBox.TabIndex = 0
	$VCPUsComboBox.Enabled = $False
	$VCPUsComboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
	$VCPUsChoices = @(1,2,4,8,16)
	$VCPUsComboBox.Items.AddRange($VCPUsChoices)
	$VCPUsComboBox.selectedindex = 1
	$form.Controls.Add($VCPUsComboBox)
	
	#endregion
	
	#region RAM Selection Label
	
	$RAMSelectionLabel.Location = '370, 60' #L/R, U/D
	$RAMSelectionLabel.Name = 'VCenter Selection Label'
	$RAMSelectionLabel.Size = '350, 20' #L/R, U/D
	$RAMSelectionLabel.TabIndex = 0
	$RAMSelectionLabel.Text = 'Please Select the desired amount of RAM (GB).'
	$RAMSelectionLabel.Enabled = $true
	$form.Controls.Add($RAMSelectionLabel)
	
	#endregion
	
	#region RAM ComboBox
	
	$RAMComboBox.FormattingEnabled = $True
	$RAMComboBox.Location = '370, 80'
	$RAMComboBox.Name = 'VCenterComboBox'
	$RAMComboBox.Size = '350, 20'
	$RAMComboBox.TabIndex = 0
	$RAMComboBox.Enabled = $False
	$RAMComboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
	$RAMChoices = @(2, 4, 8, 16, 32, 64 ,128 ,256)
	$RAMComboBox.Items.AddRange($RAMChoices)
	$RAMComboBox.SelectedIndex = 1
	$form.Controls.Add($RAMComboBox)
	
	#endregion
	
	#region Drive Information Text Box
	
	$DriveInfoTextBox = New-Object System.Windows.Forms.TextBox
	$DriveInfoTextBox.Location = New-Object System.Drawing.Size(370, 110)
	$DriveInfoTextBox.Size = New-Object System.Drawing.Size(200, 100)
	$DriveInfoTextBox.Enabled = $True
	$DriveInfoTextBox.ReadOnly = $True
	$DriveInfoTextBox.Text = "The C, D, and P drives will be created by default. Please choose how many extra drives you need for this vm."
	$DriveInfoTextBox.WordWrap = $True
	$DriveInfoTextBox.Multiline = $True
	$Form.Controls.Add($DriveInfoTextBox)
	
	#endregion
	
	#region Increment Drives Button
	
	$IncrementDrivesButton.UseVisualStyleBackColor = $True
	$IncrementDrivesButton.Text = '+'
	$IncrementDrivesButton.Font = "Times New Roman,14"
	$IncrementDrivesButton.DataBindings.DefaultDataSourceUpdateMode = 0
	$IncrementDrivesButton.Name = 'DGVSubmit'
	$IncrementDrivesButton.Size = "40,40"
	$IncrementDrivesButton.Location = "680,110"
	$IncrementDrivesButton.Enabled = $True
	$IncrementDrivesButton.add_Click($IncrementDrivesButton_Click)
	$form.Controls.Add($IncrementDrivesButton)
	
	#endregion
	
	#region Decrement Drives Button
	
	$DecrementDrivesButton.UseVisualStyleBackColor = $True
	$DecrementDrivesButton.Text = '-'
	$DecrementDrivesButton.Font = "Times New Roman,14"
	$DecrementDrivesButton.DataBindings.DefaultDataSourceUpdateMode = 0
	$DecrementDrivesButton.Name = 'DGVSubmit'
	$DecrementDrivesButton.Size = "40,40"
	$DecrementDrivesButton.Location = "680,160"
	$DecrementDrivesButton.Enabled = $True
	$DecrementDrivesButton.add_Click($DecrementDrivesButton_Click)
	$form.Controls.Add($DecrementDrivesButton)
	
	#endregion
	
	#region Num Drives Text Box
	
	$NumDrivesTextBox = New-Object System.Windows.Forms.TextBox
	$NumDrivesTextBox.Location = New-Object System.Drawing.Size(580, 110)
	$NumDrivesTextBox.Size = New-Object System.Drawing.Size(60, 130)
	$NumDrivesTextBox.Font = "Times New Roman,47"
	$NumDrivesTextBox.Enabled = $True
	$NumDrivesTextBox.ReadOnly = $True
	$NumDrivesTextBox.Text = $Global:DriveCounter
	$Form.Controls.Add($NumDrivesTextBox)
	
	#endregion
	
	#region Extra Drives Letter ComboBoxes

	$ExtraDrive1_letterComboBox.Location = "370, 240"
	$ExtraDrive1_letterComboBox.Size = "50, 20"
	$ExtraDrive1_letterComboBox.Font = "Times New Roman,12"
	$ExtraDrive1_letterComboBox.Visible = $False
	$ExtraDrive1_letterComboBox.items.addrange($Global:DriveLetterarray)
	$ExtraDrive1_letterComboBox.selectedindex = 0
	$Form.Controls.Add($ExtraDrive1_letterComboBox)

	$ExtraDrive2_letterComboBox.Location = "370, 290"
	$ExtraDrive2_letterComboBox.Size = "50, 20"
	$ExtraDrive2_letterComboBox.Font = "Times New Roman,12"
	$ExtraDrive2_letterComboBox.Visible = $False
	$ExtraDrive2_letterComboBox.items.addrange($Global:DriveLetterarray)
	$ExtraDrive2_letterComboBox.selectedindex = 0
	$Form.Controls.Add($ExtraDrive2_letterComboBox)
	
	$ExtraDrive3_letterComboBox.Location = "370, 340"
	$ExtraDrive3_letterComboBox.Size = "50, 20"
	$ExtraDrive3_letterComboBox.Font = "Times New Roman,12"
	$ExtraDrive3_letterComboBox.Visible = $False
	$ExtraDrive3_letterComboBox.items.addrange($Global:DriveLetterarray)
	$ExtraDrive3_letterComboBox.selectedindex = 0
	$Form.Controls.Add($ExtraDrive3_letterComboBox)
	
	$ExtraDrive4_letterComboBox.Location = "370, 390"
	$ExtraDrive4_letterComboBox.Size = "50, 20"
	$ExtraDrive4_letterComboBox.Font = "Times New Roman,12"
	$ExtraDrive4_letterComboBox.Visible = $False
	$ExtraDrive4_letterComboBox.items.addrange($Global:DriveLetterarray)
	$ExtraDrive4_letterComboBox.selectedindex = 0
	$Form.Controls.Add($ExtraDrive4_letterComboBox)
	
	$ExtraDrive5_letterComboBox.Location = "370, 440"
	$ExtraDrive5_letterComboBox.Size = "50, 20"
	$ExtraDrive5_letterComboBox.Font = "Times New Roman,12"
	$ExtraDrive5_letterComboBox.Visible = $False
	$ExtraDrive5_letterComboBox.items.addrange($Global:DriveLetterarray)
	$ExtraDrive5_letterComboBox.selectedindex = 0
	$Form.Controls.Add($ExtraDrive5_letterComboBox)

	#endregion
	
	#region Extra Drives Selection Labels

	$ExtraDrive1_SelectionLabel.Location = '370, 220' #L/R, U/D
	$ExtraDrive1_SelectionLabel.Name = 'VCenter Selection Label'
	$ExtraDrive1_SelectionLabel.Size = '60, 20' #L/R, U/D
	$ExtraDrive1_SelectionLabel.TabIndex = 0
	$ExtraDrive1_SelectionLabel.Text = 'Drive'
	$ExtraDrive1_SelectionLabel.Visible = $False
	$form.Controls.Add($ExtraDrive1_SelectionLabel)
	
	$ExtraDrive2_SelectionLabel.Location = '370, 270' #L/R, U/D
	$ExtraDrive2_SelectionLabel.Name = 'VCenter Selection Label'
	$ExtraDrive2_SelectionLabel.Size = '60, 20' #L/R, U/D
	$ExtraDrive2_SelectionLabel.TabIndex = 0
	$ExtraDrive2_SelectionLabel.Text = 'Drive'
	$ExtraDrive2_SelectionLabel.Visible = $False
	$form.Controls.Add($ExtraDrive2_SelectionLabel)
	
	$ExtraDrive3_SelectionLabel.Location = '370, 320' #L/R, U/D
	$ExtraDrive3_SelectionLabel.Name = 'VCenter Selection Label'
	$ExtraDrive3_SelectionLabel.Size = '60, 20' #L/R, U/D
	$ExtraDrive3_SelectionLabel.TabIndex = 0
	$ExtraDrive3_SelectionLabel.Text = 'Drive'
	$ExtraDrive3_SelectionLabel.Visible = $False
	$form.Controls.Add($ExtraDrive3_SelectionLabel)
	
	$ExtraDrive4_SelectionLabel.Location = '370, 370' #L/R, U/D
	$ExtraDrive4_SelectionLabel.Name = 'VCenter Selection Label'
	$ExtraDrive4_SelectionLabel.Size = '60, 20' #L/R, U/D
	$ExtraDrive4_SelectionLabel.TabIndex = 0
	$ExtraDrive4_SelectionLabel.Text = 'Drive'
	$ExtraDrive4_SelectionLabel.Visible = $False
	$form.Controls.Add($ExtraDrive4_SelectionLabel)
	
	$ExtraDrive5_SelectionLabel.Location = '370, 420' #L/R, U/D
	$ExtraDrive5_SelectionLabel.Name = 'VCenter Selection Label'
	$ExtraDrive5_SelectionLabel.Size = '60, 20' #L/R, U/D
	$ExtraDrive5_SelectionLabel.TabIndex = 0
	$ExtraDrive5_SelectionLabel.Text = 'Drive'
	$ExtraDrive5_SelectionLabel.Visible = $False
	$form.Controls.Add($ExtraDrive5_SelectionLabel)

	#endregion
	
	#region Extra Drives Size TextBoxes
	$ExtraDrive1SizeTextBox.Location = New-Object System.Drawing.Size(460, 240)
	$ExtraDrive1SizeTextBox.Size = New-Object System.Drawing.Size(80, 20)
	$ExtraDrive1SizeTextBox.Visible = $False
	$Form.Controls.Add($ExtraDrive1SizeTextBox)
	
	$ExtraDrive2SizeTextBox.Location = New-Object System.Drawing.Size(460, 290)
	$ExtraDrive2SizeTextBox.Size = New-Object System.Drawing.Size(80, 20)
	$ExtraDrive2SizeTextBox.Visible = $False
	$Form.Controls.Add($ExtraDrive2SizeTextBox)
	
	$ExtraDrive3SizeTextBox.Location = New-Object System.Drawing.Size(460, 340)
	$ExtraDrive3SizeTextBox.Size = New-Object System.Drawing.Size(80, 20)
	$ExtraDrive3SizeTextBox.Visible = $False
	$Form.Controls.Add($ExtraDrive3SizeTextBox)
	
	$ExtraDrive4SizeTextBox.Location = New-Object System.Drawing.Size(460, 390)
	$ExtraDrive4SizeTextBox.Size = New-Object System.Drawing.Size(80, 20)
	$ExtraDrive4SizeTextBox.Visible = $False
	$Form.Controls.Add($ExtraDrive4SizeTextBox)
	
	$ExtraDrive5SizeTextBox.Location = New-Object System.Drawing.Size(460, 440)
	$ExtraDrive5SizeTextBox.Size = New-Object System.Drawing.Size(80, 20)
	$ExtraDrive5SizeTextBox.Visible = $False
	$Form.Controls.Add($ExtraDrive5SizeTextBox)
	
	#endregion
	
	#region Extra Drives Size Labels
	
	$ExtraDrive1_SizeLabel.Location = '460, 220'
	$ExtraDrive1_SizeLabel.Name = 'Extra Drives Size Label'
	$ExtraDrive1_SizeLabel.Size = '80, 20'
	$ExtraDrive1_SizeLabel.Text = 'Size (GB)'
	$ExtraDrive1_SizeLabel.Visible = $False
	$ExtraDrive1_SizeLabel.TabIndex = 0
	$form.Controls.Add($ExtraDrive1_SizeLabel)
	
	$ExtraDrive2_SizeLabel.Location = '460, 270'
	$ExtraDrive2_SizeLabel.Size = '80, 20'
	$ExtraDrive2_SizeLabel.Text = 'Size (GB)'
	$ExtraDrive2_SizeLabel.Visible = $False
	$Form.Controls.Add($ExtraDrive2_SizeLabel)
	

	$ExtraDrive3_SizeLabel.Location = '460, 320'
	$ExtraDrive3_SizeLabel.Size = '80, 20'
	$ExtraDrive3_SizeLabel.Text = 'Size (GB)'
	$ExtraDrive3_SizeLabel.Visible = $False
	$Form.Controls.Add($ExtraDrive3_SizeLabel)
	
	$ExtraDrive4_SizeLabel.Location = '460, 370'
	$ExtraDrive4_SizeLabel.Size = '80, 20'
	$ExtraDrive4_SizeLabel.Text = 'Size (GB)'
	$ExtraDrive4_SizeLabel.Visible = $False
	$Form.Controls.Add($ExtraDrive4_SizeLabel)
	
	$ExtraDrive5_SizeLabel.Location = '460, 420'
	$ExtraDrive5_SizeLabel.Size = '80, 20'
	$ExtraDrive5_SizeLabel.Text = 'Size (GB)'
	$ExtraDrive5_SizeLabel.Visible = $False
	$Form.Controls.Add($ExtraDrive5_SizeLabel)
	
	#endregion
	
	#region Extra Drives Size Labels
	
	$ExtraDrive1_DatastoreLabel.Location = '560, 220'
	$ExtraDrive1_DatastoreLabel.Name = 'Extra Drives Size Label'
	$ExtraDrive1_DatastoreLabel.Size = '80, 20'
	$ExtraDrive1_DatastoreLabel.Text = 'Datastore'
	$ExtraDrive1_DatastoreLabel.Visible = $False
	$ExtraDrive1_DatastoreLabel.TabIndex = 0
	$form.Controls.Add($ExtraDrive1_DatastoreLabel)
	
	$ExtraDrive2_DatastoreLabel.Location = '560, 270'
	$ExtraDrive2_DatastoreLabel.Size = '80, 20'
	$ExtraDrive2_DatastoreLabel.Text = 'Datastore'
	$ExtraDrive2_DatastoreLabel.Visible = $False
	$Form.Controls.Add($ExtraDrive2_DatastoreLabel)
	
	$ExtraDrive3_DatastoreLabel.Location = '560, 320'
	$ExtraDrive3_DatastoreLabel.Size = '80, 20'
	$ExtraDrive3_DatastoreLabel.Text = 'Datastore'
	$ExtraDrive3_DatastoreLabel.Visible = $False
	$Form.Controls.Add($ExtraDrive3_DatastoreLabel)
	
	$ExtraDrive4_DatastoreLabel.Location = '560, 370'
	$ExtraDrive4_DatastoreLabel.Size = '80, 20'
	$ExtraDrive4_DatastoreLabel.Text = 'Datastore'
	$ExtraDrive4_DatastoreLabel.Visible = $False
	$Form.Controls.Add($ExtraDrive4_DatastoreLabel)
	
	$ExtraDrive5_DatastoreLabel.Location = '560, 420'
	$ExtraDrive5_DatastoreLabel.Size = '80, 20'
	$ExtraDrive5_DatastoreLabel.Text = 'Datastore'
	$ExtraDrive5_DatastoreLabel.Visible = $False
	$Form.Controls.Add($ExtraDrive5_DatastoreLabel)
	
	#endregion
	
	#region Extra Drives Letter ComboBoxes
	
	$ExtraDrive1_DataStoreComboBox.Location = "560, 240"
	$ExtraDrive1_DataStoreComboBox.Size = "235, 20"
	$ExtraDrive1_DataStoreComboBox.Font = "Times New Roman,12"
	$ExtraDrive1_DataStoreComboBox.Visible = $False
	$Form.Controls.Add($ExtraDrive1_DataStoreComboBox)
	
	$ExtraDrive2_DataStoreComboBox.Location = "560, 290"
	$ExtraDrive2_DataStoreComboBox.Size = "235, 20"
	$ExtraDrive2_DataStoreComboBox.Font = "Times New Roman,12"
	$ExtraDrive2_DataStoreComboBox.Visible = $False
	$Form.Controls.Add($ExtraDrive2_DataStoreComboBox)
	
	$ExtraDrive3_DataStoreComboBox.Location = "560, 340"
	$ExtraDrive3_DataStoreComboBox.Size = "235, 20"
	$ExtraDrive3_DataStoreComboBox.Font = "Times New Roman,12"
	$ExtraDrive3_DataStoreComboBox.Visible = $False
	$Form.Controls.Add($ExtraDrive3_DataStoreComboBox)
	
	$ExtraDrive4_DataStoreComboBox.Location = "560, 390"
	$ExtraDrive4_DataStoreComboBox.Size = "235, 20"
	$ExtraDrive4_DataStoreComboBox.Font = "Times New Roman,12"
	$ExtraDrive4_DataStoreComboBox.Visible = $False
	$Form.Controls.Add($ExtraDrive4_DataStoreComboBox)
	
	$ExtraDrive5_DataStoreComboBox.Location = "560, 440"
	$ExtraDrive5_DataStoreComboBox.Size = "235, 20"
	$ExtraDrive5_DataStoreComboBox.Font = "Times New Roman,12"
	$ExtraDrive5_DataStoreComboBox.Visible = $False
	$Form.Controls.Add($ExtraDrive5_DataStoreComboBox)
	
	#endregion
		
#endregion
	
	$Form.Add_Shown({ $Form.Activate() })
	return $form.ShowDialog()
}

Build-Form | Out-Null