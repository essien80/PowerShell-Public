<# SPO-UserActivityReport.ps1
The purpose of this script is to pull a list of users from 1 or more site collections 
and pull their last log in info from AzureAd.

Install-Module -Name AzureADPreview -allowclobber

#>

Import-Module AzureADPreview
Import-Module PnP.PowerShell

$siteListFile = "./data/sitelist.csv"
$siteList = Import-Csv -Path $siteListFile

$aad = Connect-AzureAD

foreach($site in $siteList) {
    write-host "Checking site  $($site.Url)"
    $curSite = Connect-PNPOnline -Url $site.Url -Interactive -ReturnConnection

    $users = Get-PNPUser -Includes "Email"

    foreach($user in $users) {
        
        $uem = $user.Email
 
        if($uem) {
            
            write-host "  Checking login data for $uem"

            $userDetails = Get-AzureADUser -filter "mail eq '$uem'"
            if($userDetails) {
                $UPN = $userDetails.UserPrincipalName
                $UPN = $UPN.toLower()

                # if($userDetails.UserType -eq "Members"){
                    $LoginTime = Get-AzureAdAuditSigninLogs -top 1 -filter "userprincipalname eq '$UPN'" | select CreatedDateTime
                    # Get-AzureAdAuditSigninLogs -top 1 -filter "UserPrincipalName eq '$UPN'" | select CreatedDateTime
                    # $LoginTime = Get-AzureAdAuditSigninLogs -filter "userprincipalname eq '$UPN'" | select CreatedDateTime
                    if($LoginTime) {
                        $lt = $LoginTime.CreatedDateTime
                    } else {
                        $lt = "No log in activity found"
                    }
                    Write-Host "  "$UPN" - "$lt
                # }
            } else {
                Write-Host "   No details found for '$uem'"
            }
        }
    }

}