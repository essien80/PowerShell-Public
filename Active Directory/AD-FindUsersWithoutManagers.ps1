<# AD-FindUsersWithoutManager
The purpose of this script is generate a list of all user in Active Directory
that do not have a manager.

-----------------------
Nick Ortiz
2016-12-29: Initial version.
-----------------------
#>
if (!(Get-Module -ListAvailable -Name activeDirectory))
{
	Write-Host "Loading AD Module"
    import-module activeDirectory
}

# CSV output file
$outPutFile = "c:\AD_Users_With_No_Manager.CSV"

# Create empty Arrays
$missingManagerArray = @()
$users = @()

# Load All users into Array
$users = Get-ADUser -filter * 
clear
Write-Host "Looking for Users without managers, this may take a while ..."
# Process each user
foreach($user in $users) {
	
	$userDetails = Get-ADUser $user -properties displayName, manager
	
	# Manager not found, Add user to MissingManagerArray
    if(!$userDetails.manager) {
		$tempOBJ = New-Object system.object
		$tempOBJ | add-member -type Noteproperty -name DisplayName -value $userDetails.DisplayName
		$tempOBJ | add-member -type Noteproperty -name AccountName -value $userDetails.SamAccountName
		$missingManagerArray += $tempobj
	}    
}

$missingManagerArray | export-csv $outPutFile -NoTypeInformation
Write-Host "User List Created at $outPutFile"
