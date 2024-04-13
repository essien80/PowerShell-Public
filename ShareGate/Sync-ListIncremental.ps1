Import-Module Sharegate

$spoUser = "someuser@contoso.com"
$spoPass = "SomePassword!" | ConvertTo-SecureString -AsPlainText -Force -ErrorAction SilentlyContinue

$onPremUser = "contoso\someuser"
$onPremPass = "SomePassword!" | ConvertTo-SecureString -AsPlainText -Force -ErrorAction SilentlyContinue

$copysettings = New-CopySettings -OnContentItemExists IncrementalUpdate
$dstSite = Connect-Site -Url "https://contoso.sharepoint.com/sites/somesite"  -UserName $spoUser -Password $spoPass
$srcSite = Connect-Site -Url "http://intranet.contoso.com/sites/somesite" -UserName $onPremUser -Password $onPremPass

$lists = @("Library 1", "Library 2", "List 1", "List 1")

foreach($list in $lists) {
    $srcList = Get-List -Name $list -Site $srcSite
    $dstList = Get-List -Name $list -Site $dstSite

    Copy-Content -SourceList $srcList -DestinationList $dstList -CopySettings $copysettings | Out-Null
}