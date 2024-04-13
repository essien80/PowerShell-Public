##########################################################################################################
# This script requires the following modules to be installed:
# - Install-Module AzureAD
##########################################################################################################

## Script Settings

$CSVFile = "AAD-InviteGuest_multiuser.csv"
$CSVFilePath = ".\"

# $redirectURL = "https://contoso.sharepoint.com/sites/somesite"

$tenantName = "contoso"

$tenantId = ""

$serviceAccount = ""

$PWFilePath = ".\creds"
$AESKeyFileName = "AAD-InviteGuest.aes"
$PWFileName = "AAD-InviteGuest.pw"

##########################################################################################################


$dataFile = Import-CSV -Path $CSVFilePath\$CSVFile

## Load or Create Password File
if(!(Test-Path $PWFilePath)) {
    $newPWFileDir = New-Item -Path $PWFilePath -ItemType "directory"
}

if(!(Test-Path  "$PWFilePath\$PWFileName")) {

    ## Check for and Create AES Key
    if(!(Test-Path  "$PWFilePath\$AESKeyFileName")) {
        write-host "AES Key file not found, generating ..." -ForegroundColor "Yellow"
        $AESKeyFilePath = "$PWFilePath\$AESKeyFileName"
        $AESKey = New-Object Byte[] 32
        [Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($AESKey)
            
        Set-Content $AESKeyFilePath $AESKey

    }

    $passwordfilePath = "$PWFilePath\$PWFileName"
    
    write-host "Password file not found, Please enter the password for '$serviceAccount'" -ForegroundColor "Yellow"
    read-host -assecurestring -Prompt 'Enter Password' | convertfrom-securestring -Key $AESKey | out-file $passwordfilePath
} else {
    Write-Verbose "Password File found ..."
}

## Credential using Password file
$AESKeyFile = Get-Content $PWFilePath\$AESKeyFileName
$AADPass = Get-Content $PWFilePath\$PWFileName | ConvertTo-SecureString -Key $AESKeyFile

$credential = New-Object System.Management.Automation.PSCredential($serviceAccount,$AADPass)

## Connect to AzureAD
$connAAD = Connect-AzureAD -TenantId $tenantId
$ErrorActionPreference = "SilentlyContinue"
## Process Items in CSV File
foreach($item in $dataFile) {

    Write-Host "Creating account for " $item.Email "... " -NoNewline

    $destGroup = $item.Group
    $redirectURL = $item.RedirectUrl
    # $role = $item.RedirectUrl

    ## Get Requested Azure AD Group
    $group = Get-AzureADGroup -SearchString "$destGroup" | Select-Object DisplayName, ObjectId

    ## Invite User
    $inv = New-AzureADMSInvitation -InvitedUserDisplayName $item.DisplayName -InvitedUserEmailAddress $item.Email -InviteRedirectUrl $redirectURL -SendInvitationMessage $false

    ## Add user to group if Invite was successful
    if($inv -and $group) {
        
        Write-Host "Done!" -ForegroundColor Green

        $newUserID = $inv.InvitedUser.Id

        $destGroup = $item.Group

        Write-Host " - Adding to" $group.DisplayName "... " -NoNewline

        ## Adding User to group
        Add-AzureADGroupMember -ObjectId $group.ObjectId -RefObjectId $newUserID
    
            Write-Host "Done!" -ForegroundColor Green

    } else {
        Write-Host "Failed!" -ForegroundColor Red

    }

}
Disconnect-AzureAD