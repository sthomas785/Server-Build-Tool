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

	[System.Windows.Forms.Application]::EnableVisualStyles()
	
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
	
	#endregion
	
	#Form Wide Controls
	$form = New-Object 'System.Windows.Forms.Form'

    #Labels
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
	
    #ComboBoxes
	$VCenterComboBox                = New-Object System.Windows.Forms.ComboBox
    $TemplateSelectionComboBox      = New-Object System.Windows.Forms.ComboBox
    $LocalOfficeSelectionComboBox   = New-Object System.Windows.Forms.ComboBox
    $CustomizationSelectioncomboBox = New-Object System.Windows.Forms.ComboBox
    $ESXClustersComboBox            = New-Object System.Windows.Forms.ComboBox
    $DataStoreClusterComboBox       = New-Object System.Windows.Forms.ComboBox
	$VCPUsComboBox 				    = New-Object System.Windows.Forms.ComboBox
	$RAMComboBox 					= New-Object System.Windows.Forms.ComboBox
	
    #Buttons
    $CreateVMButton                 = New-Object System.Windows.Forms.Button
    
    #RichtextBoxes
    $richtextbox1                   = New-Object System.Windows.Forms.RichTextBox

    #TextBoxes
	$VMnameInputBox 				= New-Object System.Windows.Forms.TextBox
	$DriveInfoTextBox 				= New-Object System.Windows.Forms.TextBox
	
	#Progress Bars
	$ProgressBar1                   = New-Object System.Windows.Forms.ProgressBar
 
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
		$Progressbar1.Value = 10
		Populate-CustomizationDropDown
    }
	
	$LocalOfficeSelectionMade = {
		
		$Global:VMCreationSelections.Location = $($LocalOfficeSelectionComboBox.SelectedItem)
		Write-Debug -Message "Location = $($Global:VMCreationSelections.Location)"
		
		Write-RichText -LogType 'Informational' -LogMsg "Retrieving ESX Clusters please be patient."
		$Progressbar1.Value = 6
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
		$ProgressBar1.value = 14
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
		$ProgressBar1.value = 18
		Populate-TemplateDropDown
		
	}
	
	$CustomizationSelectionMade = {
		
		$Global:VMCreationSelections.OSCustomizationSpec = Get-OSCustomizationSpec -Server $Global:VMCreationSelections.VCenterServer `
																				   -Name $CustomizationSelectioncomboBox.SelectedItem
		
		$VMnameInputBox.Enabled = $true
		$ProgressBar1.Value = 22
	}
	
	$VMNameEntered = {
		
		$Global:VMCreationSelections.Name = $VMnameInputBox.Text
		$CreateVMButton.Enabled = $True
		$ProgressBar1.Value = 25
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
	
	$SeperatorLine2.Location = '730, 0' #L/R, U/D
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
	
	#region Drive
	$DriveInfoTextBox = New-Object System.Windows.Forms.TextBox
	$DriveInfoTextBox.Location = New-Object System.Drawing.Size(370, 110)
	$DriveInfoTextBox.Size = New-Object System.Drawing.Size(350, 40)
	$DriveInfoTextBox.Enabled = $True
	$DriveInfoTextBox.ReadOnly = $True
	$DriveInfoTextBox.Text = "The C, D, and P drives will be created by default. Please choose how many extra drives you need for this vm."
	$DriveInfoTextBox.WordWrap = $True
	$DriveInfoTextBox.Multiline = $True
	$Form.Controls.Add($DriveInfoTextBox)
	
	#region VM Creation Progress Bar
	$ProgressBar1.Name = 'VM Creation Progress Bar'
	$ProgressBar1.Value = 0
	$ProgressBar1.Style = "Continuous"
	$ProgressBar1.Size = '1010,43'
	$ProgressBar1.Location = "5,505"
	$form.Controls.Add($ProgressBar1)
	
	#endregion
	
    $Form.Add_Shown({$Form.Activate()})
    return $form.ShowDialog()

}

Build-Form | Out-Null