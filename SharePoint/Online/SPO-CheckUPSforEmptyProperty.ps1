<# SPO-CheckUPSforEmptyProperty.ps1
The purpose of this script is to check all users in SPO UPS to see
if they have a property field populated.

-----------------------
Nick Ortiz
2022-03-08: Initial version.

#>

$tenantName = "consto"
$siteUrl = "https://$tenantName.sharepoint.com"
$property = "MyLinks"

$timeStamp = (Get-Date).ToString('yyyyMMdd-HHmm')
$outPutFile = "SPO-CheckUPSforEmptyProperty_"+$timeStamp+".csv"

$spConn = Connect-PNPOnline -Url $siteUrl -Interactive

$users = Get-PNPUser -connection $spConn
$userArray = @()

foreach($user in $users) {

    If($user.LoginName -like "i:0#.f|membership|*") {
        $upn = $user.LoginName.Replace("i:0#.f|membership|","")
        $un = $user.Title

        Write-Host "Checking User: " $user.Title " - " $upn -F Green

        $props = Get-PnPUserProfileProperty -Account $upn

        $propertyValue = $props.UserProfileProperties.$property

        If($propertyValue.length -gt 0) {

            Write-Host " - Property ($($property)) Found: $($propertyValue)"  -F Cyan

            $tempOBJ = New-Object system.object
            $tempOBJ | add-member -type Noteproperty -name DisplayName -value $un
            $tempOBJ | add-member -type Noteproperty -name upn -value $upn
            $tempOBJ | add-member -type Noteproperty -name property -value $property
            $tempOBJ | add-member -type Noteproperty -name propertyValue -value $propertyValue
            $userArray += $tempobj
        }

    }
}
If($userArray.length -gt 0) {
    Write-Host "-- Exporting file: $($outPutFile)" -F Yellow
    $userArray | Export-Csv -Path $outPutFile -NoTypeInformation
} else {
    Write-Host "-- No users with the property '$($property)' found." -F Red
}

$spConn = $null