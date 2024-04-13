<# AD-FindUsersWithoutManager
The purpose of this script is generate a list of all user in Active Directory
that do not have a photo.

-----------------------
Nick Ortiz
2017-01-12: Initial version.
-----------------------

#>

if (!(Get-Module -ListAvailable -Name activeDirectory))
{
	Write-Host "Loading AD Module"
    import-module activeDirectory
}

# CSV output file
$ScriptPath = $MyInvocation.MyCommand.Path
$ScriptDir  = Split-Path -Parent $ScriptPath
$outPutFile = "AD_Users_With_No_Photo.CSV"

# Create empty Arrays
$missingPhotoArray = @()
$users = @()

# Load All users into Array
$users = Get-ADUser -filter * 
clear
Write-Host "Looking for Users without managers, this may take a while ..."
# Process each user
foreach($user in $users) {
	
	$userDetails = Get-ADUser $user -properties displayName, thumbnailPhoto
	
	# Photo not found, Add user to MissingManagerArray
    if(!$userDetails.thumbnailPhoto) {
		$tempOBJ = New-Object system.object
		$tempOBJ | add-member -type Noteproperty -name DisplayName -value $userDetails.DisplayName
		$tempOBJ | add-member -type Noteproperty -name AccountName -value $userDetails.SamAccountName
		$missingPhotoArray += $tempobj
	}    
}

$missingPhotoArray | export-csv $ScriptDir\$outPutFile -NoTypeInformation
Write-Host "User List Created at $outPutFile"
