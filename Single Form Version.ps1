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
		[String]$LogMsg,
		[Parameter(Mandatory = $true, Position = 2, ValueFromPipeline, ValueFromPipelineByPropertyName)]
		[System.Windows.Forms.RichTextBox]$RTB
	)
	
	switch ($logtype)
	{
		Error {
			$RTB.SelectionColor = 'Red'
			$RTB.AppendText("`n $logtype : $logmsg")
			
		}
		Success {
			$RTB.SelectionColor = 'Green'
			$RTB.AppendText("`n $logmsg")
			
		}
		Informational {
			$RTB.SelectionColor = 'Blue'
			$RTB.AppendText("`n $logmsg")
			
		}
		
	}
	
}

Function Validate-WizardPage{
	
	[OutputType([boolean])]
	param
	(
		[System.Windows.Forms.TabPage]$tabPage
	)
	
	switch ($tabPage)
	{
		#If its the welcome page it should always enable the next button.
		$WelcomeStep
		{
			$Buttonsettings = New-Object PSObject -Property @{
				back = $False
				next = $True
				cancel = $true
				finish = $False
			}
			
			return $Buttonsettings
		}
		
		$VCenterStep
		{
			if ($VCenterComboBox.SelectedItem)
			{
				write-richtext -LogType 'informational' `
							   -logmsg "Attempting to connect to $($VCenterComboBox.SelectedItem)" `
							   -RTB $VcenterLoggingbox
				
				$Connection = (Connect-VIServer -Server $VCenterComboBox.SelectedItem | Out-Null)
				
				if ($Connection)
				{
					$Buttonsettings = New-Object PSObject -Property @{
						back = $True
						next = $True
						cancel = $true
						finish = $False
					}
					write-richtext -LogType 'success' `
								   -logmsg "A connection has been made to $($VCenterComboBox.SelectedItem)" `
								   -RTB $VcenterLoggingbox
					
					Update-TemplateDGV
					return $Buttonsettings
				}
				
				else
				{
					$Buttonsettings = New-Object PSObject -Property @{
						back = $True
						next = $False
						cancel = $true
						finish = $False
					}
					write-richtext -LogType 'success' `
								   -logmsg "A connection has been made to $($VCenterComboBox.SelectedItem)" `
								   -RTB $VcenterLoggingbox
					
					return $Buttonsettings
				}
			}
			else
			{
				write-richtext -LogType 'informational' `
							   -logmsg "Please select a VCenter Server from the Dropdown" `
							   -RTB $VcenterLoggingbox
				
				$Buttonsettings = New-Object PSObject -Property @{
					back = $True
					next = $False
					cancel = $true
					finish = $False
				}
				
				return $Buttonsettings
			}
		}
		
		$TemplateStep
		{
			'do stuff'
		}
		
		default
		{
			return $false
		}
		
	}
}

function Update-NavButtons{
	$ButtonSettings = Validate-WizardPage $tabcontrolWizard.SelectedTab
	
	$buttonNext.Enabled = $($ButtonSettings.next)
	$buttonBack.Enabled = $($ButtonSettings.back)
	$buttonFinish.Enabled = $($ButtonSettings.finish)
	$buttonCancel.Enabled = $($ButtonSettings.cancel)
}

function Update-TemplateDGV{
	[Array]$griddata = Get-Template -Server $($VCenterComboBox.SelectedItem)
	$Table = ConvertTo-DataTable -InputObject $griddata
	Load-DataGridView -DataGridView $TemplateDGV -Item $Table -DataMember 'Templates'
}

function Load-DataGridView{
		<#
		.SYNOPSIS
			This functions helps you load items into a DataGridView.
	
		.DESCRIPTION
			Use this function to dynamically load items into the DataGridView control.
	
		.PARAMETER  DataGridView
			The DataGridView control you want to add items to.
	
		.PARAMETER  Item
			The object or objects you wish to load into the DataGridView's items collection.
		
		.PARAMETER  DataMember
			Sets the name of the list or table in the data source for which the DataGridView is displaying data.
	
		#>
	Param (
		[ValidateNotNull()]
		[Parameter(Mandatory = $true)]
		[System.Windows.Forms.DataGridView]$DataGridView,
		[ValidateNotNull()]
		[Parameter(Mandatory = $true)]
		$Item,
		[Parameter(Mandatory = $false)]
		[string]$DataMember
	)
	$DataGridView.SuspendLayout()
	$DataGridView.DataMember = $DataMember
	
	if ($Item -is [System.ComponentModel.IListSource]`
	-or $Item -is [System.ComponentModel.IBindingList] -or $Item -is [System.ComponentModel.IBindingListView])
	{
		$DataGridView.DataSource = $Item
	}
	else
	{
		$array = New-Object System.Collections.ArrayList
		
		if ($Item -is [System.Collections.IList])
		{
			$array.AddRange($Item)
		}
		else
		{
			$array.Add($Item)
		}
		$DataGridView.DataSource = $array
	}
	
	$DataGridView.ResumeLayout()
}

function ConvertTo-DataTable{
		<#
			.SYNOPSIS
				Converts objects into a DataTable.
		
			.DESCRIPTION
				Converts objects into a DataTable, which are used for DataBinding.
		
			.PARAMETER  InputObject
				The input to convert into a DataTable.
		
			.PARAMETER  Table
				The DataTable you wish to load the input into.
		
			.PARAMETER RetainColumns
				This switch tells the function to keep the DataTable's existing columns.
			
			.PARAMETER FilterWMIProperties
				This switch removes WMI properties that start with an underline.
		
			.EXAMPLE
				$DataTable = ConvertTo-DataTable -InputObject (Get-Process)
		#>
	[OutputType([System.Data.DataTable])]
	param (
		[ValidateNotNull()]
		$InputObject,
		[ValidateNotNull()]
		[System.Data.DataTable]$Table,
		[switch]$RetainColumns,
		[switch]$FilterWMIProperties)
	
	if ($Table -eq $null)
	{
		$Table = New-Object System.Data.DataTable
	}
	
	if ($InputObject -is [System.Data.DataTable])
	{
		$Table = $InputObject
	}
	else
	{
		if (-not $RetainColumns -or $Table.Columns.Count -eq 0)
		{
			#Clear out the Table Contents
			$Table.Clear()
			
			if ($InputObject -eq $null) { return } #Empty Data
			
			$object = $null
			#find the first non null value
			foreach ($item in $InputObject)
			{
				if ($item -ne $null)
				{
					$object = $item
					break
				}
			}
			
			if ($object -eq $null) { return } #All null then empty
			
			#Get all the properties in order to create the columns
			foreach ($prop in $object.PSObject.Get_Properties())
			{
				if (-not $FilterWMIProperties -or -not $prop.Name.StartsWith('__')) #filter out WMI properties

				{
					#Get the type from the Definition string
					$type = $null
					
					if ($prop.Value -ne $null)
					{
						try { $type = $prop.Value.GetType() }
						catch { }
					}
					
					if ($type -ne $null) # -and [System.Type]::GetTypeCode($type) -ne 'Object')

					{
						[void]$table.Columns.Add($prop.Name, $type)
					}
					else #Type info not found

					{
						[void]$table.Columns.Add($prop.Name)
					}
				}
			}
			
			if ($object -is [System.Data.DataRow])
			{
				foreach ($item in $InputObject)
				{
					$Table.Rows.Add($item)
				}
				return @( ,$Table)
			}
		}
		else
		{
			$Table.Rows.Clear()
		}
		
		foreach ($item in $InputObject)
		{
			$row = $table.NewRow()
			
			if ($item)
			{
				foreach ($prop in $item.PSObject.Get_Properties())
				{
					if ($table.Columns.Contains($prop.Name))
					{
						$row.Item($prop.Name) = $prop.Value
					}
				}
			}
			[void]$table.Rows.Add($row)
		}
	}
	
	return @( ,$Table)
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
    $buttonFinish = New-Object 'System.Windows.Forms.Button'
	$VCenterComboBox = New-Object 'System.Windows.Forms.ComboBox'
	$VCenterLabel = New-Object 'System.Windows.Forms.Label'
	$richtextbox1 = New-Object 'System.Windows.Forms.RichTextBox'
	$TemplateDGV = New-Object 'System.Windows.Forms.DataGridView'
	$TemplateLabel = New-Object 'System.Windows.Forms.Label'
	
	
	#$Step4 = New-Object 'System.Windows.Forms.TabPage'
	#$datagridview2 = New-Object 'System.Windows.Forms.DataGridView'
	#$labelPleaseSelectTheInven = New-Object 'System.Windows.Forms.Label'
	#$Step5 = New-Object 'System.Windows.Forms.TabPage'
	#$combobox2 = New-Object 'System.Windows.Forms.ComboBox'
	#$labelPleaseSelectTheDesir = New-Object 'System.Windows.Forms.Label'
	#$Step6 = New-Object 'System.Windows.Forms.TabPage'
	#$datagridview3 = New-Object 'System.Windows.Forms.DataGridView'
	#$label1 = New-Object 'System.Windows.Forms.Label'
	#$Step7 = New-Object 'System.Windows.Forms.TabPage'
	#$datagridview4 = New-Object 'System.Windows.Forms.DataGridView'
	#$label2 = New-Object 'System.Windows.Forms.Label'

	$InitialFormWindowState = New-Object 'System.Windows.Forms.FormWindowState'
	
	#endregion

	#region Form Events
	
	$TemplateDGV_RowStateChanged = [System.Windows.Forms.DataGridViewRowStateChangedEventHandler]{
		#Event Argument: $_ = [System.Windows.Forms.DataGridViewRowStateChangedEventArgs]
		#TODO: Place custom script here
		
	}

	$VCenterComboBox_SelectedIndexChanged = {
		#Once the user has selected a VCenter server this will force the form to update.
		$buttonNext.Enabled = $true
	}
	
	$buttonFinish_Click = {

	}
	
	$Form_Cleanup_FormClosed ={
		#Remove all event handlers from the controls
		try
		{
			$buttonBack.remove_Click($buttonBack_Click)
			$buttonFinish.remove_Click($buttonFinish_Click)
			$VCenterComboBox.remove_SelectedIndexChanged($VCenterComboBox_SelectedIndexChanged)
			$VCenterLabel.remove_Click($VCenterLabel_Click)
			$TemplateDGV.remove_RowStateChanged($TemplateDGV_RowStateChanged)
			$TemplateLabel.remove_Click($TemplateLabel_Click)
			$labelPleaseSelectTheInven.remove_Click($labelPleaseSelectTheInven_Click)
			$tabcontrolWizard.remove_Selecting($tabcontrolWizard_Selecting)
			$tabcontrolWizard.remove_Deselecting($tabcontrolWizard_Deselecting)
			$buttonNext.remove_Click($buttonNext_Click)
			$formWizard.remove_Load($formWizard_Load)
			$formWizard.remove_Load($Form_StateCorrection_Load)
			$formWizard.remove_FormClosed($Form_Cleanup_FormClosed)
		}
		catch [Exception]
		{ }
	}
	
	#endregion
	
	#region FormWizard properties

	$form.Controls.Add($buttonFinish)
	$form.ClientSize = '1024, 768'
	$form.FormBorderStyle = 'FixedDialog'
	$form.MaximizeBox = $False
	$form.Name = 'formWizard'
	$form.StartPosition = 'CenterScreen'
	$form.Text = 'White & Case Server Build Tool'
	
	#endregion
	
	#region Form Buttons
	
	$buttonFinish.Anchor = 'Bottom, Right'
	$buttonFinish.DialogResult = 'OK'
	$buttonFinish.Location = '619, 359'
	$buttonFinish.Name = 'FinishButton'
	$buttonFinish.Size = '75, 23'
	$buttonFinish.TabIndex = 3
	$buttonFinish.Text = 'Finish'
	$buttonFinish.UseVisualStyleBackColor = $True
	$buttonFinish.add_Click($buttonFinish_Click)
	
	#endregion
	
	#region Welcome TextBox
	
    $Welcomemessage = @"
Welcome to the White & Case Server build Tool.

The following Wizard will guide you through making the selections needed
to create a new VM from a template.

If you have any questions or feedback please contact :

phillip.marshall@whitecase.com
"@
    Write-RichText -LogType informational -LogMsg $WelcomeMessage -RTB $richtextbox1
	$form.Controls.Add($WelcomeTextBox)
	
	#endregion
	
	#region VCenter Server Selection (Tab2)
	
	$VCenterStep.Controls.Add($VCenterLabel)
	$VCenterStep.Location = '5, 26'
	$VCenterStep.Name = 'Step2'
	$VCenterStep.Padding = '3, 3, 3, 3'
	$VCenterStep.Size = '673, 311'
	$VCenterStep.TabIndex = 0
	$VCenterStep.Text = 'Select VCenter'
	$VCenterStep.UseVisualStyleBackColor = $True
	
	#endregion

	#region VCenter ComboBox (Tab2)

	$VCenterComboBox.FormattingEnabled = $True
	[void]$VCenterComboBox.Items.Add('AM1-Vcenter')
	[void]$VCenterComboBox.Items.Add('EM1-Vcenter')
	[void]$VCenterComboBox.Items.Add('AP1-VCenter')
	$VCenterComboBox.Location = '5, 33'
	$VCenterComboBox.Name = 'VCenterComboBox'
	$VCenterComboBox.Size = '169, 25'
	$VCenterComboBox.TabIndex = 0
	$VCenterComboBox.add_SelectedIndexChanged($VCenterComboBox_SelectedIndexChanged)
	$VCenterStep.Controls.Add($VCenterComboBox)
	
	#endregion
	
	#region VCenter ComboxBox Label (Tab2)

	$VCenterLabel.Location = '5, 7'
	$VCenterLabel.Name = 'Vcenter ComboBox Label'
	$VCenterLabel.Size = '250, 23'
	$VCenterLabel.TabIndex = 0
	$VCenterLabel.Text = 'Please select the VCenter Region.'
	
	#endregion
	
	#region VCenter LoggingBox (Tab2)
	
	$VcenterLoggingbox = New-Object 'System.Windows.Forms.RichTextBox'
	$VcenterLoggingbox.Location = New-Object System.Drawing.Size(0, 100)
	$VcenterLoggingbox.Size = New-Object System.Drawing.Point(650, 200)
	$VcenterLoggingbox.Name = "VCenter Box"
	$VcenterLoggingbox.TabIndex = 0
	$VcenterLoggingbox.Text = ""
	$VcenterLoggingbox.font = "Arial"
	$VcenterLoggingbox.BackColor = 'Gainsboro'
	$VCenterStep.Controls.Add($VcenterLoggingbox)
	
	#endregion
	
	#region Template Selection Step (Tab3)
	
	$TemplateStep.Location = '4, 26'
	$TemplateStep.Name = 'Step3'
	$TemplateStep.Size = '673, 311'
	$TemplateStep.TabIndex = 0
	$TemplateStep.Text = 'Select Template'
	$TemplateStep.UseVisualStyleBackColor = $True
	
	#endregion
	
	#region Template DataGridView (Tab3)
	
	$TemplateDGV.AllowUserToDeleteRows = $False
	$TemplateDGV.ColumnHeadersHeightSizeMode = 'AutoSize'
	$TemplateDGV.Location = '4, 68'
	$TemplateDGV.Name = 'TemplateDGV'
	$TemplateDGV.ReadOnly = $True
	$TemplateDGV.RowTemplate.Height = 24
	$TemplateDGV.Size = '650, 200'
	$TemplateDGV.TabIndex = 0
	$TemplateDGV.add_RowStateChanged($TemplateDGV_RowStateChanged)
	$TemplateStep.Controls.Add($TemplateDGV)
	
	#endregion
	
	#region Template DGV Label (Tab3)
	
	$TemplateLabel.Location = '3, 9'
	$TemplateLabel.Name = 'TemplateLabel'
	$TemplateLabel.Size = '414, 23'
	$TemplateLabel.TabIndex = 0
	$TemplateLabel.Text = 'Please select the template to deploy to the server.'
	$TemplateStep.Controls.Add($TemplateLabel)
	
	#endregion
	
	<#
	#################################################################
	$Step4.Controls.Add($datagridview2)
	$Step4.Controls.Add($labelPleaseSelectTheInven)
	$Step4.Location = '4, 26'
	$Step4.Name = 'Step4'
	$Step4.Padding = '3, 3, 3, 3'
	$Step4.Size = '673, 311'
	$Step4.TabIndex = 3
	$Step4.Text = 'Select Location'
	$Step4.UseVisualStyleBackColor = $True
	#######################################################
	$datagridview2.AllowUserToDeleteRows = $False
	$datagridview2.ColumnHeadersHeightSizeMode = 'AutoSize'
	$datagridview2.Location = '7, 60'
	$datagridview2.Name = 'datagridview2'
	$datagridview2.ReadOnly = $True
	$datagridview2.RowTemplate.Height = 24
	$datagridview2.Size = '240, 150'
	$datagridview2.TabIndex = 3
	#############################################################
	$labelPleaseSelectTheInven.Location = '7, 19'
	$labelPleaseSelectTheInven.Name = 'labelPleaseSelectTheInven'
	$labelPleaseSelectTheInven.Size = '396, 23'
	$labelPleaseSelectTheInven.TabIndex = 0
	$labelPleaseSelectTheInven.Text = 'Please select the Inventory Location from the options below.'
	$labelPleaseSelectTheInven.add_Click($labelPleaseSelectTheInven_Click)
	#############################################################
	$Step5.Controls.Add($combobox2)
	$Step5.Controls.Add($labelPleaseSelectTheDesir)
	$Step5.Location = '4, 26'
	$Step5.Name = 'Step5'
	$Step5.Padding = '3, 3, 3, 3'
	$Step5.Size = '673, 311'
	$Step5.TabIndex = 4
	$Step5.Text = 'Select ESX Host'
	$Step5.UseVisualStyleBackColor = $True
	##############################################################
	$combobox2.FormattingEnabled = $True
	$combobox2.Location = '6, 55'
	$combobox2.Name = 'combobox2'
	$combobox2.Size = '121, 25'
	$combobox2.TabIndex = 2
	###############################################################
	$labelPleaseSelectTheDesir.Location = '6, 18'
	$labelPleaseSelectTheDesir.Name = 'labelPleaseSelectTheDesir'
	$labelPleaseSelectTheDesir.Size = '396, 23'
	$labelPleaseSelectTheDesir.TabIndex = 1
	$labelPleaseSelectTheDesir.Text = 'Please select the Desired ESX host from the dropdown.'
	##############################################################
	$Step6.Controls.Add($datagridview3)
	$Step6.Controls.Add($label1)
	$Step6.Location = '4, 26'
	$Step6.Name = 'Step6'
	$Step6.Padding = '3, 3, 3, 3'
	$Step6.Size = '673, 311'
	$Step6.TabIndex = 5
	$Step6.Text = 'Select Storage Location'
	$Step6.UseVisualStyleBackColor = $True
	###############################################################
	$datagridview3.AllowUserToDeleteRows = $False
	$datagridview3.ColumnHeadersHeightSizeMode = 'AutoSize'
	$datagridview3.Location = '16, 73'
	$datagridview3.Name = 'datagridview3'
	$datagridview3.ReadOnly = $True
	$datagridview3.RowTemplate.Height = 24
	$datagridview3.Size = '240, 150'
	$datagridview3.TabIndex = 3
	################################################################
	$label1.Location = '3, 13'
	$label1.Name = 'label1'
	$label1.Size = '396, 23'
	$label1.TabIndex = 2
	$label1.Text = 'Please select the Desired storage location'
	################################################################
	$Step7.Controls.Add($datagridview4)
	$Step7.Controls.Add($label2)
	$Step7.Location = '4, 26'
	$Step7.Name = 'Step7'
	$Step7.Padding = '3, 3, 3, 3'
	$Step7.Size = '673, 311'
	$Step7.TabIndex = 6
	$Step7.Text = 'Select Customization'
	$Step7.UseVisualStyleBackColor = $True
	#################################################################
	$datagridview4.AllowUserToDeleteRows = $False
	$datagridview4.ColumnHeadersHeightSizeMode = 'AutoSize'
	$datagridview4.Location = '7, 59'
	$datagridview4.Name = 'datagridview4'
	$datagridview4.ReadOnly = $True
	$datagridview4.RowTemplate.Height = 24
	$datagridview4.Size = '240, 150'
	$datagridview4.TabIndex = 4
	##################################################################
	$label2.Location = '3, 12'
	$label2.Name = 'label2'
	$label2.Size = '396, 23'
	$label2.TabIndex = 3
	$label2.Text = 'Please select the Desired Customization.'
	##################################################################
	#>

	#Save the initial state of the form
	$InitialFormWindowState = $formWizard.WindowState
	#Init the OnLoad event to correct the initial state of the form
	$formWizard.add_Load($Form_StateCorrection_Load)
	#Clean up the control events
	$formWizard.add_FormClosed($Form_Cleanup_FormClosed)
	#Show the Form
	return $formWizard.ShowDialog()
	
}

Build-Form | Out-Null