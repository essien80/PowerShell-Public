##########################################################################################################
# This script requires the following modules to be installed:
# - Install-Module ActiveDirectory
##########################################################################################################

## Script Settings

$searchBaseActive = "OU=Sample Users,OU=Accounts,DC=CONTOSO,DC=COM"
$searchBaseDisabled = "OU=Disabled,OU=Accounts,DC=CONTOSO,DC=COM"
$fieldName = "extensionAttribute4"
$fieldValueActive = "Test Employee"
$fieldValueDisabled = "Terminated"

##########################################################################################################

$ScriptPath = $MyInvocation.MyCommand.Path
$ScriptDir  = Split-Path -Parent $ScriptPath


$LogFile = "$ScriptDir\Logs\AD-SetUserPropertyForActiveTermUsersInOU.log"

$LogFileItem = Get-ChildItem -path $LogFile

# Check if the log is too large and delete if needed.
If($LogFileItem.Length -gt '314572800') {

	Remove-Item $LogFileItem

	Add-content $Logfile -value "---------------------- New Log File Created: $(Get-date -format 'MM/dd/yyyy hh:mm:ss tt') -------------------"
}

# Log Parameters
Add-content $Logfile -value "---------------------- File Upload Script Started: $(Get-date -format 'MM/dd/yyyy hh:mm:ss tt') -------------------"
Add-content $Logfile -value "  Parameters:"
Add-content $Logfile -value "    searchBaseActive: $searchBaseActive"
Add-content $Logfile -value "    searchBaseDisabled: $searchBaseDisabled"
Add-content $Logfile -value "    fieldName: $fieldName"
Add-content $Logfile -value "    fieldValueActive: $fieldValueActive"
Add-content $Logfile -value "    fieldValueDisabled: $fieldValueDisabled"

# Start Active User Update
Write-Host "----------------------------------------------------------------------------" -ForegroundColor Green
Write-Host "Checking for Active users in " -NoNewline
Write-host $searchBaseActive -ForegroundColor Green
Write-Host "----------------------------------------------------------------------------" -ForegroundColor Green

Add-content $Logfile -value "----------------------------------------------------------------------------" 
Add-content $Logfile -value "Checking for Active users in $searchBaseActive"
Add-content $Logfile -value "----------------------------------------------------------------------------"

$activeUsers = Get-ADUser -filter "$fieldName  -notlike '*' -or $fieldName -ne '$fieldValueActive'" -SearchBase $searchBaseActive -Properties $fieldName
if($activeUsers) {

	$activeUserCount = $activeUsers.Length
	Write-host "Users found: "  -NoNewline
	Write-host "$activeUserCount" -ForegroundColor Green
	Add-content $Logfile -value "Users found: $activeUserCount" 

	foreach($activeUser in $activeUsers) {
		
		if($activeUser.$fieldName -ne $fieldValueActive) {
			$activeUser.$fieldName = $fieldValueActive
			$dn = $activeUser.Name

			Write-host "Updating user $dn to '$fieldValueActive' ..." -NoNewline
			Add-content $Logfile -value "Updating user $dn to '$fieldValueActive'"

			Set-ADUser -Instance $activeUser
			Write-Host "Done!" -ForegroundColor Green
		}
	}
} else {
	Write-Host "No active users need to be updated."  -ForegroundColor Yellow
	Add-content $Logfile -value "No disabled users need to be updated."
}

# Start Disabled User Update
Write-Host "----------------------------------------------------------------------------" -ForegroundColor Green
Write-Host "Checking for Disabled users in " -NoNewline
Write-host $searchBaseDisabled -ForegroundColor Green
Write-Host "----------------------------------------------------------------------------" -ForegroundColor Green

Add-content $Logfile -value "----------------------------------------------------------------------------" 
Add-content $Logfile -value "Checking for Disabled users in $searchBaseDisabled"
Add-content $Logfile -value "----------------------------------------------------------------------------"

$disabledUsers = Get-ADUser -filter "$fieldName  -notlike '*' -or $fieldName -ne '$fieldValueDisabled'" -SearchBase $searchBaseDisabled -Properties $fieldName
if($disabledUsers) {
	$disabledUserCount = $disabledUsers.Length
	Write-host "Users found: "  -NoNewline
	Write-host "$disabledUserCount" -ForegroundColor Green
	Add-content $Logfile -value "Users found: $disabledUserCount"

	foreach($disabledUser in $disabledUsers) {

		if($disabledUser.$fieldName -ne $fieldValueDisabled) {
			$disabledUser.$fieldName  = $fieldValueDisabled
			$dn = $disabledUser.Name

			Write-host "Updating user $dn to '$fieldValueDisabled'..." -NoNewline
			Add-content $Logfile -value "Updating user $dn to '$fieldValueDisabled'"

			Set-ADUser -Instance $disabledUser
			Write-Host "Done!" -ForegroundColor Green
		}		
	}
} else {
	Write-Host "No disabled users need to be updated."  -ForegroundColor Yellow
	Add-content $Logfile -value "No disabled users need to be updated."
}
Add-content $Logfile -value "---------------------- File upload Script Completed: $(Get-date -format 'MM/dd/yyyy hh:mm:ss tt') -----------------"