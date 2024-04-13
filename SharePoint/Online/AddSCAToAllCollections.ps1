# Jack Fruh - sharepointjack.com
# add a user or users to the site collection admin role on every site collection in Office 365 sites (SharePoint Online)
 
#setup a log path
$path = "$($(get-location).path)\LogFile.txt"
#note we're using start-transcript, this does not work from inside the powershell ISE, only the command prompt
 
start-transcript -path $Path
write-host "This will connect to SharePoint Online"
 
#Admin Variables:
$Adminurl = "https://contoso-admin.sharepoint.com"
$username = ""
 
#Tenant Variables:
$TenantURL = "https://contoso.sharepoint.com"
 
$SiteCollectionAdmins = @("admin1@contoso.com", "admin1@contoso.com")
 
#Connect to SPO
$SecurePWD = read-host -assecurestring "Enter Password for $username"
$credential = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $SecurePWD
 
Connect-SPOService -url $Adminurl -credential $credential
write-host "Connected" -foregroundcolor green
 
 
$sites = get-sposite
Foreach ($site in $sites)
{
    Write-host "Adding users to $($site.URL)" -foregroundcolor yellow
	#get the owner group name
	$ownerGroup = get-spoSitegroup -site $site.url | where {$_.title -like "*Owners"}
	$ownertitle = $ownerGroup.title
	Write-host "Owner Group is named > $ownertitle > " -foregroundcolor cyan
	
	#add the Site Collection Admin to the site in the owners group
	foreach ($user in $SiteCollectionAdmins)
	{
		#Write-host "Adding $user to $($site.URL) as a user..."
		#add-SPOuser  -site $site.url -LoginName $user -group $ownerTitle
		#write-host "Done"
		
		#Set the site collection admin flag for the Site collection admin
		write-host "Setting up $user as a site collection admin on $($site.url)..."
		set-spouser -site $site.url -loginname $user -IsSiteCollectionAdmin $true
		write-host "Done"	-foregroundcolor green
	}
}
Write-host "Done with everything" -foregroundcolor green 
stop-transcript