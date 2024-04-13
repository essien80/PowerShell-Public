$creds = (Get-Credential)

$azureAD = Connect-AzureAD -Credential $creds

$groupId = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

$group = Get-AzureADGroup -ObjectId $groupId

$members = $group | Get-AzureADGroupMember -All $true

## Date and Filter Settings
$dateFormat = "yyyy-MM-dd HH:mm:ss"
$filterDate = $(get-date).addDays(-30).toString('yyyy-MM-dd')
# $filterDate = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId((get-date), "Mountain Standard Time").addDays(-14).toString('yyyy-MM-dd')
##

## Invite Settings
$resendInvites = $false
$inviteRedirectUrl = "https://contoso.sharepoint.com/sites/SomeSite"
$invitationMessageBody = @"
This is an invitation to the Test Portal.

When accepting the invitation, please log in with your current email address and password.

Please note that we can not manage your account password; if you're unsure what you're current password is, please check with your local IT or use the Password Recovery link on the login page.
"@
##

$includeAuditInfo = $false
$outPutFileUserLoginDetails = "AAD-UserLoginDetails.csv"

$audiInformation = @()

foreach($u in $members) {
    $creationType = $u.CreationType
    $createdDate = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId($([datetime]$($u.ExtensionProperty.createdDateTime)), "Mountain Standard Time").toString($dateFormat)
    if($($u.UserStateChangedOn)) {
        $inviteStatusChangedOn = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId($([datetime]$($u.UserStateChangedOn)), "Mountain Standard Time").toString($dateFormat)
    } else  {
        $inviteStatusChangedOn = $null
    }
    $inviteStatus = $u.UserState
    $type = $u.UserType
    $upn = $u.UserPrincipalName
    $email = $u.Mail
    $userID = $u.ObjectId
    $displayName = $u.DisplayName

    if($includeAuditInfo) {
        # $auditInfo = Get-AzureADAuditSignInLogs -Filter "UserPrincipalName eq '$upn' and CreatedDateTime ge $filterDate and status/ErrorCode ne 0"
        $auditInfo = Get-AzureADAuditSignInLogs -Filter "userID eq '$userID' and CreatedDateTime ge $filterDate"
        # $auditInfo = Get-AzureADAuditSignInLogs -Filter "UserPrincipalName eq '$upn' and CreatedDateTime ge $filterDate"
        # $auditInfo = Get-AzureADAuditSignInLogs -Filter "UserPrincipalName eq '$upn'"
    }

    Write-Host "$upn - $inviteStatus - $inviteStatusChangedOn - $creationType"

    if($auditInfo -and $includeAuditInfo -eq $true){
        foreach($login in $auditInfo) {

            $status = $login.Status
            $errorCode = $login.Status.ErrorCode
            $reason = $login.Status.FailureReason
            $details = $login.Status.AdditionalDetails

            $tempOBJ = New-Object system.object
            $tempOBJ | add-member -type Noteproperty -name displayName -value $displayName
            $tempOBJ | add-member -type Noteproperty -name email -value $email
            $tempOBJ | add-member -type Noteproperty -name upn -value $upn
            $tempOBJ | add-member -type Noteproperty -name type -value $type
            $tempOBJ | add-member -type Noteproperty -name createdDate -value $createdDate
            $tempOBJ | add-member -type Noteproperty -name creationType -value $creationType
            $tempOBJ | add-member -type Noteproperty -name inviteStatus -value $inviteStatus
            $tempOBJ | add-member -type Noteproperty -name inviteStatusChangedOn -value $inviteStatusChangedOn
            $tempOBJ | add-member -type Noteproperty -name errorCode -value $errorCode
            $tempOBJ | add-member -type Noteproperty -name reason -value $reason
            $tempOBJ | add-member -type Noteproperty -name details -value $details
            $audiInformation += $tempobj
        }
    } else {

        $tempOBJ = New-Object system.object
        $tempOBJ | add-member -type Noteproperty -name displayName -value $displayName
        $tempOBJ | add-member -type Noteproperty -name email -value $email
        $tempOBJ | add-member -type Noteproperty -name upn -value $upn
        $tempOBJ | add-member -type Noteproperty -name type -value $type
        $tempOBJ | add-member -type Noteproperty -name createdDate -value $createdDate
        $tempOBJ | add-member -type Noteproperty -name creationType -value $creationType
        $tempOBJ | add-member -type Noteproperty -name inviteStatus -value $inviteStatus
        $tempOBJ | add-member -type Noteproperty -name inviteStatusChangedOn -value $inviteStatusChangedOn
        $tempOBJ | add-member -type Noteproperty -name errorCode -value "n/a"
        $tempOBJ | add-member -type Noteproperty -name reason -value "n/a"
        $tempOBJ | add-member -type Noteproperty -name details -value "n/a"
        $audiInformation += $tempobj
    }

    # Resend Site invite
    if($resendInvites -eq $true -and $inviteStatus -eq "PendingAcceptance") {

        $invitation = @{ customizedMessageBody = $invitationMessageBody }

        New-AzureADMSInvitation -InvitedUserDisplayName $displayNam -InvitedUserEmailAddress $email -SendInvitationMessage $true -InviteRedirectUrl $inviteRedirectUrl -InvitedUserMessageInfo $invitation
    }

}

$audiInformation | Export-Csv $outPutFileUserLoginDetails -NoTypeInformation