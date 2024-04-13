if ((Get-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue) -eq $null) 
{
    Add-PSSnapin "Microsoft.SharePoint.PowerShell"
}
 

$u = ''
$spoUrl = ""
$w = Get-SPWeb $u
$l = $w.lists["Web Analytics Workflow History"]
$lists = $w.Lists | Where-Object { $_.BaseTemplate -eq "WorkflowHistory" }

$creds = (Get-Credential)

function createSPOList($nUrl, $nTitle, $con) {

    #$con = Connect-PNPOnline -Url $nUrl –Credentials $creds
    New-PnPList -Title $nTitle -Template GenericList -Connection $con
    Add-PnPField -List $nTitle -DisplayName "List Name" -InternalName "ExportListName" -Type Text -AddToDefaultView -Connection $con | Out-Null
    Add-PnPField -List $nTitle -DisplayName "Item Name" -InternalName "ExportItemName" -Type Text -AddToDefaultView -Connection $con | Out-Null
    Add-PnPField -List $nTitle -DisplayName "User Id" -InternalName "ExportUserId" -Type Text -AddToDefaultView -Connection $con | Out-Null
    Add-PnPField -List $nTitle -DisplayName "Date Occured" -InternalName "ExportDateOccured" -Type DateTime -AddToDefaultView -Connection $con | Out-Null
    Add-PnPField -List $nTitle -DisplayName "Event Type" -InternalName "ExportEventType" -Type Text -AddToDefaultView -Connection $con | Out-Null
    Add-PnPField -List $nTitle -DisplayName "Outcome" -InternalName "ExportOutcome" -Type Text -AddToDefaultView -Connection $con | Out-Null
    Add-PnPField -List $nTitle -DisplayName "Duration" -InternalName "ExportDuration" -Type Number -AddToDefaultView -Connection $con | Out-Null
    Add-PnPField -List $nTitle -DisplayName "Description" -InternalName "ExportDescription" -Type Note -AddToDefaultView -Connection $con | Out-Null
    #Disconnect-PnPOnline
}

# function createSPOItems($nTitle, $itemValues, $con) {

#     Add-PnPListItem -List $nTitle -Values $itemValues -Connection $con | Out-Null

# }

foreach($l in $lists) {
    $wUrl = $w.ServerRelativeUrl
    $nUrl = $spoUrl + $wUrl
    $lTitle = $l.lTitle
    $nTitle = $lTitle + " Export"

    $con = Connect-PNPOnline -Url $nUrl –Credentials $creds

    #createSPOList $nUrl $nTitle $con

    $items = $l.Items

    foreach($i in $items) {
        $pList = $w.Lists | Where-Object { $_.Guid -eq $i["List Id"]}
        $pListTitle = $pList.Title
        
        $pItem = $w.Lists | Where-Object { $_.Guid -eq $i["List Id"]} |  Where-Object  {$_.GetItemById($i["Primary Item ID"])}
        $pItemTitle = $pItem["Title"]

        $itemValues = @{"Title" = $pItemTitle; "List Name" = $pListTitle; "Item Name" = $pItemTitle;"User Id" = $i["User ID"].DisplayName;"Date Occured" = $i["Date Occured"];"Event Type" = $i["Event Type"];"Outcome" = $i["Outcome"];"Duration" = $i["Duration"];"Description" = $i["Description"]}
        
        Add-PnPListItem -List $nTitle -Values $itemValues -Connection $con | Out-Null

        #createSPOItems $nTitle $itemValues $con
    }
    Disconnect-PnPOnline

}