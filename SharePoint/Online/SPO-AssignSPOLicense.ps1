Param (
[Parameter(Mandatory=$True,Position=0)][string]$ConfigFile = $(throw '- Need parameter input file (e.g. "c:\users.csv")')
)
$Host.UI.RawUI.BufferSize = New-Object System.Management.Automation.Host.Size (500, 300)
$ScriptPath = $MyInvocation.MyCommand.Path
$ScriptDir  = Split-Path -Parent $ScriptPath
$Computer = $env:computername
$TimeStamp = (Get-Date).ToString('yyyyMMdd-HHmmss')
start-transcript -path $ScriptDir\Assign-SPOLicense.$TimeStamp.txt 
####End Common Setup ####
####Import users from CSV####
$Userlist=import-csv $ConfigFile
####Connect to O365####
Import-Module MSOnline
$Pword="Password" | ConvertTo-SecureString -AsPlainText -Force

$365Account=""

$MSCred=New-Object System.Management.Automation.PSCredential -ArgumentList $365Account, $PWord
Connect-MSOLService -Credential $MSCred

####Do stuff
foreach ( $user in $Userlist ) {
	$DisplayName = $User.Name
	try { 
			$TargetUser=Get-MSOLUser -searchstring $displayname -ea SilentlyContinue
		}
		catch [System.Management.Automation.RemoteException]
		{
			####RemotePS error handling doesn't actually work, but we put it in in case someday it does####
			$err=$_.Exception
			write-error "Could not find matching user $DisplayName."
			write-output "$Err"
		}
		if ($TargetUser) { 
			write-output "`nChecking $($TargetUser.UserPrincipalName) for an active license."
				####Below gets license details and plugs them into a flat array for easy status checking####
				$Check4Lic = @()
				Get-MsolUser -UserPrincipalName $TargetUser.UserPrincipalName | ? {$_.isLicensed -eq $true} |%{
				foreach($l in $_.Licenses.ServiceStatus)
				{
				$data = New-Object psObject -Property @{
				ServiceName = $l.ServicePlan.ServiceName
				ServiceStatus = $l.ProvisioningStatus
				}
				$Check4Lic += $data
				}
				}
			####Find the type of SharePoint license available.
			$O365Plan=Get-MsolAccountSKU | ? {$_.AccountSkuId -like "*SHAREPOINT*"}
			####Make sure we have licenses available to assign
			if ($O365Plan.ConsumedUnits -lt $O365Plan.ActiveUnits) {
				write-output "There are $($O365Plan.ActiveUnits-$O365Plan.ConsumedUnits) licenses available for $($O365Plan.AccountSkuID.ToString())."
				if ($Check4Lic.ServiceName -like "*SharePointStandard*" -or $Check4Lic.ServiceName -like "*SharePointEnt*" -and $Check4Lic.ServiceStatus -eq "Success") { 
					write-output "Found existing license already assigned for $($TargetUser.UserPrincipalName)."
					}
				elseif (!$Check4Lic -and $TargetUser.isLicensed -eq $false) { 
					write-output "Could not find a license for $($TargetUser.UserPrincipalName)"
					write-output "Adding SharePoint Standard license $($O365Plan.AccountSkuID.ToString()) for $($TargetUser.UserPrincipalName)"
					####Usage location error handling
					if ($Targetuser.UsageLocation -eq $null) {
					write-output "No usage location set. Assuming location is US for $($TargetUser.UserPrincipalName)"
					Set-MsolUser -UserPrincipalName $TargetUser.UserPrincipalName -UsageLocation US
					Set-MSolUserLicense -UserPrincipalName $TargetUser.UserPrincipalName -AddLicenses $($O365Plan.AccountSkuID.ToString())
					} else {
					Set-MSolUserLicense -UserPrincipalName $TargetUser.UserPrincipalName -AddLicenses $($O365Plan.AccountSkuID.ToString())
					}
					}
			} else {
				write-output "There are no licenses available for $($O365Plan.AccountSkuID.ToString())."
			}
		} else {
		Write-output "`r`nCould not find user account for $DisplayName"
		}
	}
Stop-Transcript