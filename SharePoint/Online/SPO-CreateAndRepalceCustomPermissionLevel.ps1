<# SPO-CreateAndRepalceCustomPermissionLevel.ps1
The purpose of this script is to create a custom permission level based on an existing specified permission level.
The new permission level can be customized and be applied to all site collections and their sub sites or a 
defined list of sites.

-----------------------
Nick Ortiz
2022-03-25: Initial version.

Required Modules:
PNP.PowerShell or SharePointPNPPowerShellOnline

#>
param
(
    [Parameter(Mandatory=$false)] [string] $tenantName,
    [Parameter(Mandatory=$false)] [switch] $allSites
)

if($allSites) {
    if($tenantName){
        
        $admConn = Connect-PnPOnline https://$tenantName-admin.sharepoint.com -UseWebLogin -ReturnConnection

        $urls = (Get-PnPTenantSite -Connection $admConn | Select Url).Url

    } else {
        Write-Host "You must specify -tenantName when using -allSites, this is the part of your Site URL before sharepoint.com. i.e https://contoso.sharepoint.com would use -tenantName 'contoso'." -F Red
    }

} else {
    $urls = "https://contoso.sharepoint.com/sites/site1/","https://contoso.sharepoint.com/sites/site2/"
}
## Name for new custom permission level
$customLevel = "Site Owner"

## Full Control permission level
$oldLevel = "Full Control"

<# 
Permissions will be cloned from the oldLevel defined above, you can specify permissions to exlude from the cloned level

excludedPermissions accepted values:
EmptyMask, ViewListItems, AddListItems, EditListItems, DeleteListItems, ApproveItems,
OpenItems, ViewVersions, DeleteVersions, CancelCheckout, ManagePersonalViews, ManageLists, ViewFormPages, 
AnonymousSearchAccessList, Open, ViewPages, AddAndCustomizePages, ApplyThemeAndBorder, ApplyStyleSheets, 
ViewUsageData, CreateSSCSite, ManageSubwebs, CreateGroups, ManagePermissions, BrowseDirectories, BrowseUserInfo, 
AddDelPrivateWebParts, UpdatePersonalWebParts, ManageWeb, AnonymousSearchAccessWebLists, UseClientIntegration, 
UseRemoteAPIs, ManageAlerts, CreateAlerts, EditMyUserInfo, EnumeratePermissions, FullMask

#>

$excludedPermissions = ('CreateSSCSite','ManageSubwebs')

$timeStamp = (Get-Date).ToString('yyyyMMdd-HHmm')
$ScriptPath = $MyInvocation.MyCommand.Path
$ScriptDir  = Split-Path -Parent $ScriptPath

if(!(Test-Path $ScriptDir\Logs\)) {
    $logPath = New-Item -Path $ScriptDir\Logs\ -ItemType "directory"
}

$LogFile = "$logPath\SPO-UploadPathToLibrary.log"

Add-content $Logfile -value "---------------------- Script Started: $(Get-date -format 'dd/MM/yyy hh:mm:ss tt') -------------------"
Add-content $Logfile -value "  Parameters:"
Add-content $Logfile -value "    tenantName: $tenantName"
Add-content $Logfile -value "    allSites: $allSites"
Add-content $Logfile -value "    customLevel: $customLevel"
Add-content $Logfile -value "    oldLevel: $oldLevel"
Add-content $Logfile -value "------------------------------------------------------------------------------------------------------"

function Update-UsersAndGroups {
    param (
        $currentConn,
        $currentWeb,
        $customLevel,
        $oldLevel 
    )


    ForEach ($RoleAssignment in $currentWeb.RoleAssignments)
    {
        ## Get the Permission Levels assigned and Member
        Get-PnPProperty -ClientObject $RoleAssignment -Property RoleDefinitionBindings, Member -Connection $currentConn

        $PermissionType = $RoleAssignment.Member.PrincipalType
        $currentLevel = $($RoleAssignment.RoleDefinitionBindings | Select -ExpandProperty Name)

        If($PermissionType -eq "User") {
            
            ## Get the User
            $User = Get-PnPUser -Identity $RoleAssignment.Member.LoginName -Connection $currentConn

            Write-Host " -- Checking user  '$($User.Title)' ... " -F Green -NoNewline
            Add-content $Logfile -value " -- Checking user  '$($User.Title)' ..."

            ## Check if "Full Control" Permission Level is assigned to the user

            If($currentLevel -eq $oldLevel) {
                ## Get the User
                $User = Get-PnPUser -Identity $RoleAssignment.Member.LoginName -Connection $currentConn

                Write-Host "Updating user '$($User.Title)' from '$currentLevel' to '$customLevel' ... " -F Yellow -NoNewline
                
                Add-content $Logfile -value " --- Updating user  '$($User.Title)' from '$currentLevel' to '$customLevel' ... "

                ## Update user permission level.
                $updatedUserLevel = Set-PnPWebPermission -user $($RoleAssignment.Member.LoginName) -RemoveRole $oldLevel -AddRole $customLevel -Connection $currentConn

                Write-Host "Done" -F Green
                
                Add-content $Logfile -value " --- Done"

            }
            else {
                Write-Host "Update not needed." -F Green
                Add-content $Logfile -value " --- Update not needed."
            }
        } else {

            Write-Host " -- Checking group '$($RoleAssignment.Member.Title)' ... " -F Green -NoNewline
            Add-content $Logfile -value " -- Checking group '$($RoleAssignment.Member.Title)' ... "

            If($currentLevel -eq $oldLevel) {

                Write-Host "Updating group '$($RoleAssignment.Member.Title)' from '$currentLevel' to '$customLevel' ... " -F Yellow -NoNewline
                Add-content $Logfile -value " --- Updating group '$($RoleAssignment.Member.Title)' from '$currentLevel' to '$customLevel' ... "
                ## Add custom role and remove Full control role
                $updatedLevel = Set-PnPGroupPermissions $RoleAssignment.Member.Title -RemoveRole $oldLevel -AddRole $customLevel -Connection $currentConn
    
                Write-Host "Done" -F Green
                Add-content $Logfile -value " --- Done"
            } else {
                Write-Host "Update not needed." -F Green
                Add-content $Logfile -value " --- Update not needed."
            } 
        }
    }

}

## Process each site
foreach($url in $urls){

    ## Connect to root site
    $rootConn = Connect-PnPOnline $url -UseWebLogin -ReturnConnection

    ## Process Root Web
    $rootWeb = Get-PNPWeb -Includes RoleAssignments -Connection $rootConn

    Write-Host "Checking Rootsite '$($rootWeb.Title)' at '$($rootWeb.Url)'" -F CYAN
    Add-content $Logfile -value "Checking Rootsite '$($rootWeb.Title)' at '$($rootWeb.Url)'"
    
    ## Load current permission levels
    $levels = Get-PnPRoleDefinition -Connection $rootConn

    ## Check for custom permission level
    Write-Host " - Checking for Custom level '$customLevel' ... " -F Cyan -NoNewline
    Add-content $Logfile -value " - Checking for Custom level '$customLevel' ... "

    If(!($levels | ? { $_.Name -eq $customLevel })) {

        ## Create custom permission level
        Write-Host " -- not found" -F Yellow

        Write-Host " -- Creating Permission level '$customLevel' without '$excludedPermissions' ... " -NoNewline -F Yellow
        Add-content $Logfile -value " - Creating Permission level '$customLevel' without '$excludedPermissions' ... "

        ## Add custom role and remove Full control role
        $newRole = Add-PnPRoleDefinition -RoleName $customLevel -Clone $oldLevel -Exclude $excludedPermissions  -Description "This is a custom permission level based on Full Control but does not have access to create Subsites." -Connection $conn

        Write-Host "Done" -F Green
        Add-content $Logfile -value " --- Done"

    } else {

        Write-Host "found!" -F Green
        Add-content $Logfile -value " --- found!"

        ## Load existing custom permission level
        $newRole = $levels | ? { $_.Name -eq $customLevel }

    }

    ## Process groups on root site
    # Update-GroupsOnSite $rootConn $rootWeb
    # Update-StandAloneUsers $rootConn $rootWeb
    Update-UsersAndGroups $rootConn $rootWeb $customLevel $oldLevel 

    ## Load Sub sites
    $subWebs = Get-PNPSubWebs -Connection $rootConn

    ## Process Each Sub Site
    foreach($subWeb in $subWebs) {

        Write-Host "Checking Sub-web '$($subWeb.Title)' at '$($subWeb.Url)'" -F CYAN
        Add-content $Logfile -value "Checking Sub-web '$($subWeb.Title)' at '$($subWeb.Url)'"

        ## Connect to sub site
        $subConn = Connect-PnPOnline -Url $subWeb.Url -UseWebLogin -ReturnConnection
        $subWeb = Get-PNPWeb -Includes RoleAssignments -Connection $subConn
    
        ## Process groups on sub site
        # Update-GroupsOnSite $subConn $subWeb
        # Update-StandAloneUsers $subConn $subWeb
        Update-UsersAndGroups $subConn $subWeb $customLevel $oldLevel 
    
        ## Disconnect from sub site
        Disconnect-PnPOnline -Connection $subConn

    }

    ## Disconnect from Root Web
    Disconnect-PnPOnline -Connection $rootConn
}
Add-content $Logfile -value "---------------------- Script Completed: $(Get-date -format 'dd/MM/yyy hh:mm:ss tt') -----------------"
Write-Host "All Done, Exiting ..." -F Green