Function ConnectTo-VCenter{
    Param
    (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[String]$Server
    )
    
    $Connection = Connect-VIServer -Server $Server -Credential $Script:Credentials

    If(!$Connection)
    {
        $FailureMessage = @"
Unable to connect to $Server. 
Please verify your account has the required permissions or choose a different server.
"@
        Write-Richtext -LogType 'Error' -LogMsg $FailureMessage
    }

    Else
    {
        $SuccessMessage = @"
Connected to $Server.
"@
        Write-Richtext -LogType 'Success' -LogMsg $SuccessMessage
        Write-Richtext -LogType 'Informational' -LogMsg "Retrieving Local Offices please be patient."
        Populate-LocalOfficeDropDown -Server $Server
    }
}

Function Populate-TemplateDropDown{
    Param
    (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[String]$Server,
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[String]$LocalOffice
    )

    $Templates = Get-Template -Server $Server -Location $LocalOffice

    If(!$Templates)
    {
        $FailureMessage = @"
Unable to Gather templates from $Server. 
Please verify your account has the required permissions or choose a different server.
"@
        Write-Richtext -LogType 'Error' -LogMsg $FailureMessage
    }

    Else
    {
        Foreach ($Template in $Templates) 
        {
            $TemplateSelectionComboBox.Items.Add($Template)
        }

        $TemplateSelectionComboBox.enabled = $True
    }
}

Function Populate-LocalOfficeDropDown{

    Param
    (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[String]$Server
    )
    
    $LocalOffices = Get-datacenter -Server $Server

    If(!$LocalOffices)
    {
        $FailureMessage = @"
Unable to Gather Local Offices from $Server. 
Please verify your account has the required permissions or choose a different server.
"@
        Write-Richtext -LogType 'Error' -LogMsg $FailureMessage
    }

    Else
    {
        $SuccessMessage = @"
Local Offices retrieved from $Server.
"@
        Write-Richtext -LogType 'Success' -LogMsg $SuccessMessage
        
        Foreach ($Office in $LocalOffices) 
        {
            $LocalOfficeSelectioncomboBox.Items.Add($Office)
        }

        $LocalOfficeSelectioncomboBox.enabled = $True
    }

}

Function Populate-CustomizationDropDown{
    Param
    (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[String]$Server
    )

    $Customizations = (Get-OSCustomizationSpec -Server $Server).name

    If(!$Customizations)
    {
        $FailureMessage = @"
Unable to Gather customizations from $Server. 
Please verify your account has the required permissions or choose a different server.
"@
        Write-Richtext -LogType 'Error' -LogMsg $FailureMessage
    }

    Else
    {
        Foreach ($Item in $Customizations) 
        {
            $CustomizationSelectioncomboBox.Items.Add($Item)
        }

        $CustomizationSelectioncomboBox.enabled = $True
    }
}

Function Populate-ESXHostDGV{

    Param
    (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[String]$Server,
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[String]$LocalOffice
    )
    
    [Array]$ESXHosts = Get-VMHost -Server $Server -Location $LocalOffice

    If(!$ESXHosts)
    {
        $FailureMessage = @"
Unable to Gather ESX Hosts from $Server and Local Office $Localoffice. 
Please verify your account has the required permissions or choose a different server.
"@
        Write-Richtext -LogType 'Error' -LogMsg $FailureMessage
    }

    Else
    {
        $SuccessMessage = @"
ESX Hosts retrieved from $Server and Local Office $Localoffice. Please choose the ESX Host from the dropdown.
"@
        Write-Richtext -LogType 'Success' -LogMsg $SuccessMessage
        

        $array= New-Object System.Collections.ArrayList
        $array.AddRange(@($ESXHosts | select -Property   Name, `
                                                        ConnectionState, `
                                                        PowerState, `
                                                        MemoryTotalGB, `
                                                        MemoryUsageGB))
        $ESXHostsDataGridView.DataSource = $array
    }

}

Function Populate-DatastoreDGV{

    Param
    (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[String]$Server,
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[String]$Location
    )
    
    $DataStores = Get-Datastore -Server $Server -Location $Location

    If(!$DataStores)
    {
        $FailureMessage = @"
Unable to Gather DataStores from Local Office $Location. 
Please verify your account has the required permissions or choose a different server.
"@
        Write-Richtext -LogType 'Error' -LogMsg $FailureMessage
    }

    Else
    {
        $SuccessMessage = @"
Datastores retrieved from $Location. Please choose the DataStore from the dropdown.
"@
        Write-Richtext -LogType 'Success' -LogMsg $SuccessMessage
        
        $array= New-Object System.Collections.ArrayList
        $array.AddRange(($DataStores | select -Property Name, `
                                                        FreeSpaceGB, `
                                                        CapacityGB))
        $DatastoreDataGridView.DataSource = $array
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
	#Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -confirm
	
	#endregion

	#region Declare Form Objects

	[System.Windows.Forms.Application]::EnableVisualStyles()
	
	#Form Wide Controls
	$form = New-Object 'System.Windows.Forms.Form'

    #Labels
    $LoggingBoxLabel = New-Object System.Windows.Forms.label
    $TemplateSelectionLabel = New-Object System.Windows.Forms.label
    $VCenterSelection = New-Object System.Windows.Forms.label
    $LocalOfficeSelectionLabel = New-Object System.Windows.Forms.label
    $ESXHostsSelectionLabel = New-Object System.Windows.Forms.label
    $DatastoreSelectionLabel = New-Object System.Windows.Forms.label
    $CustomizationSelectionLabel = New-Object System.Windows.Forms.label

    #ComboBoxes
	$VCenterComboBox = New-Object System.Windows.Forms.ComboBox
    $TemplateSelectionComboBox = New-Object System.Windows.Forms.ComboBox
    $LocalOfficeSelectionComboBox = New-Object System.Windows.Forms.ComboBox
    $CustomizationSelectioncomboBox = New-Object System.Windows.Forms.ComboBox

    #DataGridViews
    $ESXHostsDataGridView = New-Object System.Windows.Forms.DataGridView
    $DatastoreDataGridView = New-Object System.Windows.Forms.DataGridView
    
    #Buttons
    $ESXDGVSubmitButton = New-Object System.Windows.Forms.Button
    $DatastoreDGVSubmitButton = New-Object System.Windows.Forms.Button
    $CreateVMButton = New-Object System.Windows.Forms.Button
    
    #RichtextBoxes
    $richtextbox1 = New-Object System.Windows.Forms.RichTextBox

    #InputBoxes
    $VMnameInputBox = New-Object System.Windows.Forms.TextBox
 
    #endregion

    #region Event Handlers

    $ServerSelectionMade = {
        Write-RichText -LogType 'Informational' -LogMsg "Connecting to $($VCenterComboBox.SelectedItem) please be patient."
        $Script:Credentials = Get-Credential
        ConnectTo-VCenter -Server $VCenterComboBox.SelectedItem
	}

    $TemplateSelectionMade = {
        
        Write-RichText -LogType 'Informational' -LogMsg "Retrieving ESX Hosts please be patient."
        Populate-ESXHostDGV -Server $VCenterComboBox.SelectedItem -LocalOffice $LocalOfficeSelectionComboBox.SelectedItem
    }

    $LocalOfficeSelectionMade = {
        Write-RichText -LogType 'Informational' -LogMsg "Retrieving Templates please be patient."
        Populate-TemplateDropDown -Server $VCenterComboBox.SelectedItem -LocalOffice $LocalOfficeSelectionComboBox.SelectedItem
    }

    $ESX_DGV_Submit_Button_Click = {
        
        If(!$ESXHostsDataGridView.SelectedRows)
        {
            Write-RichText -LogType 'Error' -LogMsg "You must select an ESX Host to continue."  
        }

        Else
        {
           Write-RichText -LogType 'Informational' -LogMsg "Retrieving Datastores please be patient."
           Populate-DatastoreDGV -Server $VCenterComboBox.SelectedItem -Location $LocalOfficeSelectionComboBox.SelectedItem
        }
        
    }

    $DataStore_DGV_Submit_Button_Click = {

    If(!$DatastoreDataGridView.SelectedRows)
    {
        Write-RichText -LogType 'Error' -LogMsg "You must select a Datastore to continue."  
    }

    Else
    {
        Write-RichText -LogType 'Informational' -LogMsg "Retrieving Customizations please be patient."
        Populate-CustomizationDropDown -Server $VCenterComboBox.SelectedItem
        
    }
        
    }

    $CreateVMButton_Click = {
        $richtextbox1.clear()
        Write-RichText -LogType informational -LogMsg "VCenter server : $($VCenterComboBox.SelectedItem)"
        Write-RichText -LogType informational -LogMsg "VMHost : $($ESXHostsDataGridView.selectedcells[0].value)"
        Write-RichText -LogType informational -LogMsg "VM Name : MarshPH-Test-VM"
        Write-RichText -LogType informational -LogMsg "DataStore : $($DataStoreDataGridView.selectedcells[0].value)"
        Write-RichText -LogType informational -LogMsg "Template : $(Get-Template -Server "$($VCenterComboBox.SelectedItem)" -Location $($Localofficeselectioncombobox.SelectedItem) -Name $($TemplateSelectionComboBox.SelectedItem))"
        #$richtextbox1.ScrollToCaret()
        
        New-VM  -Server "$($VCenterComboBox.SelectedItem)" `
                -VMHost "$($ESXHostsDataGridView.selectedcells[0].value)" `
                -Name 'MarshPH-Test-VM' `
                -Datastore "$($DataStoreDataGridView.selectedcells[0].value)" `
                -Template $(Get-Template -Server "$($VCenterComboBox.SelectedItem)" -Location $($Localofficeselectioncombobox.SelectedItem) -Name $($TemplateSelectionComboBox.SelectedItem))
    
    
        
    }

    $CustomizationSelectionMade = {

        $CreateVMButton.Enabled = $True
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
	
	$VCenterSelection.Location = '5, 25' #L/R, U/D
	$VCenterSelection.Name = 'VCenter Selection Label'
	$VCenterSelection.Size = '210, 20' #L/R, U/D
	$VCenterSelection.TabIndex = 0
	$VCenterSelection.Text = 'Please select the VCenter Region'
    $form.Controls.Add($VCenterSelection)
	
	#endregion

	#region VCenter ComboBox

	$VCenterComboBox.FormattingEnabled = $True
	[void]$VCenterComboBox.Items.Add('AM1-Vcenter')
	[void]$VCenterComboBox.Items.Add('EM1-Vcenter')
	[void]$VCenterComboBox.Items.Add('AP1-VCenter')
	$VCenterComboBox.Location = '5, 50'
	$VCenterComboBox.Name = 'VCenterComboBox'
	$VCenterComboBox.Size = '300, 50'
	$VCenterComboBox.TabIndex = 0
    $VCenterComboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
	$VCenterComboBox.add_SelectedIndexChanged($ServerSelectionMade)
	$form.Controls.Add($VCenterComboBox)
	
	#endregion
	
	#region Logging Rich Text Box Label
	
	$LoggingBoxLabel.Location = '5, 515' #L/R, U/D
	$LoggingBoxLabel.Name = 'Logging Box'
	$LoggingBoxLabel.Size = '210, 35' #L/R, U/D
	$LoggingBoxLabel.TabIndex = 0
	$LoggingBoxLabel.Text = 'Logging Box'
    $LoggingBoxLabel.ForeColor = 'Green'
    $LoggingBoxLabel.Font = "Arial, 15"
    $form.Controls.Add($LoggingBoxLabel)
	
	#endregion

	#region Logging Rich Text Box
	
    $Welcomemessage = @"
Welcome to the White & Case Server build Tool. The following Wizard will guide you through making the selections needed to create a new VM from a template.
If you have any questions or feedback please contact : phillip.marshall@whitecase.com
"@
	$richtextbox1 = New-Object 'System.Windows.Forms.RichTextBox'
	$richtextbox1.Location = '5, 550'
	$richtextbox1.Size ='1009, 280'
	$richtextbox1.Name = "Logging Box"
	$richtextbox1.TabIndex = 0
	$richtextbox1.Text = "$Welcomemessage"
	$richtextbox1.font = "Arial"
	$richtextbox1.BackColor = 'Gainsboro'
	$form.Controls.Add($richtextbox1)
	
	#endregion

	#region Template Selection Label
	
	$TemplateSelectionLabel.Location = '5, 200' #L/R, U/D
	$TemplateSelectionLabel.Name = 'VCenter Selection Label'
	$TemplateSelectionLabel.Size = '210, 20' #L/R, U/D
	$TemplateSelectionLabel.TabIndex = 0
	$TemplateSelectionLabel.Text = 'Please select the Template'
    $TemplateSelectionLabel.Enabled = $true
    $form.Controls.Add($TemplateSelectionLabel)
	
	#endregion

	#region Template ComboBox

	$TemplateSelectionComboBox.FormattingEnabled = $True
	$TemplateSelectionComboBox.Location = '5, 220'
	$TemplateSelectionComboBox.Name = 'VCenterComboBox'
	$TemplateSelectionComboBox.Size = '300, 50'
	$TemplateSelectionComboBox.TabIndex = 0
	$TemplateSelectionComboBox.add_SelectedIndexChanged($TemplateSelectionMade)
    $TemplateSelectionComboBox.Enabled = $False
    $TemplateSelectionComboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
	$form.Controls.Add($TemplateSelectionComboBox)
	
	#endregion

	#region Local Office Selection Label
	
	$LocalOfficeSelectionLabel.Location = '5, 110' #L/R, U/D
	$LocalOfficeSelectionLabel.Name = 'VCenter Selection Label'
	$LocalOfficeSelectionLabel.Size = '210, 20' #L/R, U/D
	$LocalOfficeSelectionLabel.TabIndex = 0
	$LocalOfficeSelectionLabel.Text = 'Please select the Local Office'
    $LocalOfficeSelectionLabel.Enabled = $true
    $form.Controls.Add($LocalOfficeSelectionLabel)
	
	#endregion

	#region Local Office ComboBox

	$LocalOfficeSelectioncomboBox.FormattingEnabled = $True
	$LocalOfficeSelectioncomboBox.Location = '5, 130'
	$LocalOfficeSelectioncomboBox.Name = 'VCenterComboBox'
	$LocalOfficeSelectioncomboBox.Size = '300, 50'
	$LocalOfficeSelectioncomboBox.TabIndex = 0
	$LocalOfficeSelectioncomboBox.add_SelectedIndexChanged($LocalOfficeSelectionMade)
    $LocalOfficeSelectioncomboBox.Enabled = $False
    $LocalOfficeSelectionComboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
	$form.Controls.Add($LocalOfficeSelectioncomboBox)
	
	#endregion

	#region ESX Hosts Selection Label
	
	$ESXHostsSelectionLabel.Location = '5, 290' #L/R, U/D
	$ESXHostsSelectionLabel.Name = 'ESX Host Selection Label'
	$ESXHostsSelectionLabel.Size = '170, 20' #L/R, U/D
	$ESXHostsSelectionLabel.TabIndex = 0
	$ESXHostsSelectionLabel.Text = 'Please select the ESX Host'
    $ESXHostsSelectionLabel.Enabled = $true
    $form.Controls.Add($ESXHostsSelectionLabel)
	
	#endregion

	#region ESX Hosts DataGridView

    $ESXHostsDataGridView.RowTemplate.DefaultCellStyle.ForeColor = [System.Drawing.Color]::FromArgb(255,0,128,0)
    $ESXHostsDataGridView.Name = 'dataGridView'
    $ESXHostsDataGridView.DataBindings.DefaultDataSourceUpdateMode = 0
    $ESXHostsDataGridView.ReadOnly = $True
    $ESXHostsDataGridView.AllowUserToDeleteRows = $False
    $ESXHostsDataGridView.RowHeadersVisible = $False
    $System_Drawing_Size = New-Object System.Drawing.Size
        $System_Drawing_Size.Width = 600
        $System_Drawing_Size.Height = 200
    $ESXHostsDataGridView.Size = $System_Drawing_Size
    $ESXHostsDataGridView.TabIndex = 8
    $ESXHostsDataGridView.Anchor = 15
    $ESXHostsDataGridView.AutoSizeColumnsMode = 16
    $ESXHostsDataGridView.AllowUserToAddRows = $False
    $ESXHostsDataGridView.ColumnHeadersHeightSizeMode = 2
    $System_Drawing_Point = New-Object System.Drawing.Point
        $System_Drawing_Point.X = 5
        $System_Drawing_Point.Y = 310
    $ESXHostsDataGridView.Location = $System_Drawing_Point
    $ESXHostsDataGridView.AllowUserToOrderColumns = $True
    $ESXHostsDataGridView.SelectionMode = 'FullRowSelect'
    $form.Controls.Add($ESXHostsDataGridView)
	
	#endregion

    #region ESX DGV Submit Button
    $ESXDGVSubmitButton.UseVisualStyleBackColor = $True
    $ESXDGVSubmitButton.Text = 'Submit'
    $ESXDGVSubmitButton.DataBindings.DefaultDataSourceUpdateMode = 0
    $ESXDGVSubmitButton.Name = 'DGVSubmit'
    $System_Drawing_Size = New-Object System.Drawing.Size
        $System_Drawing_Size.Width = 75
        $System_Drawing_Size.Height = 23
    $ESXDGVSubmitButton.Size = $System_Drawing_Size
    $System_Drawing_Point = New-Object System.Drawing.Point
        $System_Drawing_Point.X = 180
        $System_Drawing_Point.Y = 285
    $ESXDGVSubmitButton.Location = $System_Drawing_Point
    $ESXDGVSubmitButton.add_Click($ESX_DGV_Submit_Button_Click)
    $form.Controls.Add($ESXDGVSubmitButton)

    #endregion

    #region Datastore Selection Label
	
	$DatastoreSelectionLabel.Location = '650, 290' #L/R, U/D
	$DatastoreSelectionLabel.Name = 'DataStore Selection Label'
	$DatastoreSelectionLabel.Size = '275, 20' #L/R, U/D
	$DatastoreSelectionLabel.TabIndex = 0
	$DatastoreSelectionLabel.Text = 'Please select the Datastore for the OS Drive'
    $DatastoreSelectionLabel.Enabled = $true
    $form.Controls.Add($DatastoreSelectionLabel)
	
	#endregion

	#region Datastore DataGridView

    $DatastoreDataGridView.RowTemplate.DefaultCellStyle.ForeColor = [System.Drawing.Color]::FromArgb(255,0,128,0)
    $DatastoreDataGridView.Name = 'dataGridView'
    $DatastoreDataGridView.DataBindings.DefaultDataSourceUpdateMode = 0
    $DatastoreDataGridView.ReadOnly = $True
    $DatastoreDataGridView.AllowUserToDeleteRows = $False
    $DatastoreDataGridView.RowHeadersVisible = $False
    $System_Drawing_Size = New-Object System.Drawing.Size
        $System_Drawing_Size.Width = 350
        $System_Drawing_Size.Height = 200
    $DatastoreDataGridView.Size = $System_Drawing_Size
    $DatastoreDataGridView.TabIndex = 8
    $DatastoreDataGridView.Anchor = 15
    $DatastoreDataGridView.AutoSizeColumnsMode = 16
    $DatastoreDataGridView.AllowUserToAddRows = $False
    $DatastoreDataGridView.ColumnHeadersHeightSizeMode = 2
    $System_Drawing_Point = New-Object System.Drawing.Point
        $System_Drawing_Point.X = 650
        $System_Drawing_Point.Y = 310
    $DatastoreDataGridView.Location = $System_Drawing_Point
    $DatastoreDataGridView.AllowUserToOrderColumns = $True
    $DatastoreDataGridView.SelectionMode = 'FullRowSelect'
    $form.Controls.Add($DatastoreDataGridView)
	
	#endregion

    #region Datastore DGV Submit Button
    
    $DatastoreDGVSubmitButton.UseVisualStyleBackColor = $True
    $DatastoreDGVSubmitButton.Text = 'Submit'
    $DatastoreDGVSubmitButton.DataBindings.DefaultDataSourceUpdateMode = 0
    $DatastoreDGVSubmitButton.Name = 'DGVSubmit'
    $System_Drawing_Size = New-Object System.Drawing.Size
        $System_Drawing_Size.Width = 75
        $System_Drawing_Size.Height = 23
    $DatastoreDGVSubmitButton.Size = $System_Drawing_Size
    $System_Drawing_Point = New-Object System.Drawing.Point
        $System_Drawing_Point.X = 925
        $System_Drawing_Point.Y = 285
    $DatastoreDGVSubmitButton.Location = $System_Drawing_Point
    $DatastoreDGVSubmitButton.add_Click($Datastore_DGV_Submit_Button_Click)
    $form.Controls.Add($DatastoreDGVSubmitButton)

    #endregion

    #region Customization Selection Label
	
	$CustomizationSelectionLabel.Location = '350, 25' #L/R, U/D
	$CustomizationSelectionLabel.Name = 'VCenter Selection Label'
	$CustomizationSelectionLabel.Size = '210, 20' #L/R, U/D
	$CustomizationSelectionLabel.TabIndex = 0
	$CustomizationSelectionLabel.Text = 'Please select the Customization'
    $CustomizationSelectionLabel.Enabled = $true
    $form.Controls.Add($CustomizationSelectionLabel)
	
	#endregion

	#region Customization ComboBox

	$CustomizationSelectioncomboBox.FormattingEnabled = $True
	$CustomizationSelectioncomboBox.Location = '350, 50'
	$CustomizationSelectioncomboBox.Name = 'VCenterComboBox'
	$CustomizationSelectioncomboBox.Size = '300, 50'
	$CustomizationSelectioncomboBox.TabIndex = 0
	$CustomizationSelectioncomboBox.add_SelectedIndexChanged($CustomizationSelectionMade)
    $CustomizationSelectioncomboBox.Enabled = $False
    $CustomizationSelectionComboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
	$form.Controls.Add($CustomizationSelectioncomboBox)
	
	#endregion

    
    #region Create VM Button
    
    $CreateVMButton.UseVisualStyleBackColor = $True
    $CreateVMButton.Text = 'Create VM'
    $CreateVMButton.DataBindings.DefaultDataSourceUpdateMode = 0
    $CreateVMButton.Name = 'DGVSubmit'
    $System_Drawing_Size = New-Object System.Drawing.Size
        $System_Drawing_Size.Width = 100
        $System_Drawing_Size.Height = 50
    $CreateVMButton.Size = $System_Drawing_Size
    $System_Drawing_Point = New-Object System.Drawing.Point
        $System_Drawing_Point.X = 900
        $System_Drawing_Point.Y = 25
    $CreateVMButton.Location = $System_Drawing_Point
    $CreateVMButton.Enabled = $False
    $CreateVMButton.add_Click($CreateVMButton_Click)
    $form.Controls.Add($CreateVMButton)

    #endregion

    #region VM name Input Box
    $VMnameInputBox = New-Object System.Windows.Forms.TextBox 
    $VMnameInputBox.Location = New-Object System.Drawing.Size(350,130) 
    $VMnameInputBox.Size = New-Object System.Drawing.Size(300,50) 
    $Form.Controls.Add($VMnameInputBox) 
	
    $Form.Add_Shown({$Form.Activate()})
    return $form.ShowDialog()

}

Build-Form | Out-Null