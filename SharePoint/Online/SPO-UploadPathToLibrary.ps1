<# SPO-UploadPathToLibrary.ps1
The purpose of this script is upload the contents of a desired path into a SharePoint library.

-----------------------
Nick Ortiz
2019-09-03: Initial version.
2020-11-13: Convert from CSOM to PNP
            Updated script to use credential file instead of prompting for login.
            Flushed out documentation and logging.
            Added the ability to remove files after uploading.
2021-08-12: Updated to support multiple authentication methods.
			Added verbose output.
			Flushed out documentation
2022-01-13: Adjust documentation for app registration
            Adjust folder logic
			Add support for subfolders destinations

#####
## Required Modules:
Install-Module PNP.PowerShell

########### Start For App Authentication ###########
## All Legacy login methods have been depreciated and will eventually be removed.
##  - File
##  - Secret

## Create App Registration and Certificate
Register-PnPAzureADApp -ApplicationName "PNP-SharePoint" -Tenant "contoso.onmicrosoft.com" -GraphApplicationPermissions "User.ReadWrite.All" -SharePointApplicationPermissions "Sites.ReadWrite.All" -OutPath c:\temp -devicelogin

#####
## Add App Permissions required for certficate / app auth to the site (This does not work when using Certificate Auth, only supports Client Secret)

Open this URL and enter the AppID
https://contoso.sharepoint.com/sites/YourTargetSite/_layouts/15/appinv.aspx

Enter the appid and click lookup
Enter your domain name in the app domain field

Paste the following XML in the Permissions XML field:

<AppPermissionRequests AllowAppOnlyPolicy="true">
   <AppPermissionRequest Scope="http://sharepoint/content/sitecollection/" Right="Read"/>
   <AppPermissionRequest Scope="http://sharepoint/content/sitecollection/web" Right="FullControl"/>
</AppPermissionRequests>

########### End For App Authentication ###########

Examples: 

	App Secret Login:
    .\SPO-UploadPathToLibrary.ps1 -url "https://contoso.sharepoint.com/sites/somesite" -SourcePath "\\servername\sharename\subfolder" -LibraryName "Documents" -authMethod "secret" -tenantName contoso -appId "xxxx-xxx-xxxx-xxxxx-xxx" -ClientSecret "xxxXXXxxxXXxxx" -singlelog -verbose 
   
	Web Login:
	.\SPO-UploadPathToLibrary.ps1 -url "https://contoso.sharepoint.com/sites/somesite" -SourcePath "\\servername\sharename\subfolder" -LibraryName "Documents" -authMethod "web" -tenantName contoso -singlelog -verbose 

Options:
    -url (string) : Site URL to upload content to
    -SourcePath (string) : Location` of data to upload
    -LibraryName (string) : library to upload files into.
	-SubFolder (string) : subfolder located within the library, you can specify multiple nested folders i.e. Projects/Reports
	-AuthMethod (string) : Options: file, web, cert, secret, azureAuth(not working)
    -username (string) : user account that will be authenticating.
	-certThumb (string) : certificate thumbprint from app registrations
	-AppId (string): appid GUID for your app registration
	-ClientSecret (string): generated azure ad cient secret
	-tenantName (string): azure tenant name i.e contoso.onmicrosoft.com
	-username (string) : user account that will be authenticating.
    -PWFilePath (string) : Path to the location you want your password file to be stored, you can alter permissions on that location to secure the file.
    -SingleLog (switch) : Create a single log instead of timestamped logs.
    -CleanUp (switch) : This option will delete the files after uploading, use with Caution!

	You should run this script atleast once in a console to verify functionality.

#>

param
(
    [Parameter(Mandatory=$true)] [string] $Url,
    [Parameter(Mandatory=$true)] [string] $SourcePath,
    [Parameter(Mandatory=$true)] [string] $LibraryName,
	[Parameter(Mandatory=$false)] [string] $SubFolder,
    [Parameter(Mandatory=$true,HelpMessage="available options: file, web, auth, cert, secret, azureAuth(not working)")] [string] $AuthMethod,
    [Parameter(Mandatory=$false)] [string] $username,
    [Parameter(Mandatory=$false)] [string] $PWFilePath,
	[Parameter(Mandatory=$false)] [string] $AppId,
	[Parameter(Mandatory=$false)] [string] $certThumb,
	[Parameter(Mandatory=$false)] [string] $ClientSecret,
	[Parameter(Mandatory=$false)] [string] $tenantName,
	[Parameter(Mandatory=$false)] [string] $LogName,
    [Parameter(Mandatory=$false)] [switch] $SingleLog,
    [Parameter(Mandatory=$false)] [switch] $CleanUp
)

$timeStamp = (Get-Date).ToString('yyyyMMdd-HHmm')
$ScriptPath = $MyInvocation.MyCommand.Path
$ScriptDir  = Split-Path -Parent $ScriptPath

## Create Log Directory and define log name
if(!(Test-Path $ScriptDir\Logs\)) {
    $newLogsDir = New-Item -Path $ScriptDir\Logs\ -ItemType "directory"
}

if($SingleLog) {
    $LogFile = "$ScriptDir\Logs\SPO-UploadPathToLibrary_" + $LogName + ".log"

	## Check Log file size and start a new one if its larger than 20 MB
	if((Test-Path $LogFile)) {
		$curLog = Get-ChildItem -Path $LogFile
		$curSize = ($curLog.Length)/1024/1024
		$oldLogNewName = $($LogFile.Split('.')[0]) + "$timeStamp_old." + $($LogFile.Split('.')[1])

		## Create new log is the current one is greater that 20 MB
		if($curSize -ge "20"){

			Add-content $Logfile -value "--- Log has grown too large, creating a new file: $(Get-date -format 'MM/dd/yyy hh:mm:ss tt') ---"
			Move-Item -Path $LogFile -Destination $oldLogNewName

		}
	}
} else {
    $LogFile = "$ScriptDir\Logs\SPO-UploadPathToLibrary_" + $LogName + "_$timeStamp.log"
}

$ErrorActionPreference = "SilentlyContinue"

Try {
	Write-Verbose "---------------------- File Upload Script Started: $(Get-date -format 'MM/dd/yyy hh:mm:ss tt') -------------------"
    Write-Verbose "  Parameters:"
    Write-Verbose "    url: $url"
    Write-Verbose "    SourcePath: $SourcePath"
    Write-Verbose "    LibraryName: $LibraryName"
	Write-Verbose "    SubFolder: $subFolder"
	Write-Verbose "    AuthMethod: $AuthMethod"
    Write-Verbose "    UserName: $username"
    Write-Verbose "    PWFilePath: $PWFilePath"
    Write-Verbose "    SingleLog: $SingleLog"
    Write-Verbose "    CleanUp: $CleanUp"
    Add-content $Logfile -value "---------------------- File Upload Script Started: $(Get-date -format 'MM/dd/yyy hh:mm:ss tt') -------------------"
    Add-content $Logfile -value "  Parameters:"
    Add-content $Logfile -value "    url: $url"
    Add-content $Logfile -value "    SourcePath: $SourcePath"
    Add-content $Logfile -value "    LibraryName: $LibraryName"
	Add-content $Logfile -value "    SubFolder: $subFolder"
	Add-content $Logfile -value "    AuthMethod: $AuthMethod"
    Add-content $Logfile -value "    UserName: $username"
    Add-content $Logfile -value "    PWFilePath: $PWFilePath"
    Add-content $Logfile -value "    ShowProgress: $ShowProgress"
    Add-content $Logfile -value "    SingleLog: $SingleLog"
    Add-content $Logfile -value "    CleanUp: $CleanUp"

    if($CleanUp) {
		Write-Verbose "CleanUp is enabled, files will be deleted after they're uploaded."
        Add-content $Logfile -value "CleanUp is enabled, files will be deleted after they're uploaded."
    }

	if($AuthMethod -eq "file") {
	   
		$AESKeyFileName = "SPO-UploadPathToLibrary.aes"
		$PWFileName = "SPO-UploadPathToLibrary.pw"
	   
		## Check for and Create password file
		if(!(Test-Path $PWFilePath)) {
			$newPWFileDir = New-Item -Path $PWFilePath -ItemType "directory"
		}

		if(!(Test-Path  "$PWFilePath\$PWFileName")) {

			## Check for and Create AES Key
			if(!(Test-Path  "$PWFilePath\$AESKeyFileName")) {
				write-host "AES Key file not found, generating ..." -ForegroundColor "Yellow"
				Add-content $Logfile -value "AES Key file not found, generating ..." -ForegroundColor "Yellow"
				$AESKeyFilePath = "$PWFilePath\$AESKeyFileName"
				$AESKey = New-Object Byte[] 32
				[Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($AESKey)
				
				Set-Content $AESKeyFilePath $AESKey

			}

			$passwordfilePath = "$PWFilePath\$PWFileName"

			Add-content $Logfile -value "Password File not found, prompting user to create"

			write-host "Password file not found, Please enter the password for '$username'" -ForegroundColor "Yellow"
			read-host -assecurestring -Prompt 'Enter Password' | convertfrom-securestring -Key $AESKey | out-file $passwordfilePath

			Add-content $Logfile -value "Password File created."
		} else {
			Write-Verbose "Password File found ..."
			Add-content $Logfile -value "Password File found ..."
		}
		Add-content $Logfile -value "Loading Password File and Generating Credential."
		## Credential using Password file
		$AESKeyFile = Get-Content $PWFilePath\$AESKeyFileName
		$SPOPass = Get-Content $PWFilePath\$PWFileName | ConvertTo-SecureString -Key $AESKeyFile

		$credential = new-object System.Management.Automation.PSCredential ($username,$SPOPass)
		
		## Connect to PnP Online
		Write-Verbose "Connecting to '$Url'"
		Add-content $Logfile -value "Connecting to '$Url'"
		$connSP = Connect-PnPOnline -Url $Url -Credentials $credential -ReturnConnection -WarningAction ignore
		
	# } elseif($AuthMethod -eq "azureAuth") {

	# 	## Credential Azure Store Credntial
	# 	$credential = Get-AutomationPSCredential -Name $azureAuthAcc
		
	} elseif($AuthMethod -eq "cert") {
		## Connect to PnP Online
		Write-Verbose "Connecting to '$Url'"
		Add-content $Logfile -value "Connecting to '$Url'"
		$connSP = Connect-PnPOnline -Url $Url -ClientID $AppId -Tenant "$tenantName.onmicrosoft.com" -Thumbprint $certThumb -WarningAction ignore -ReturnConnection 
		
	} elseif($AuthMethod -eq "web") {
		## Connect to PnP Online
		Write-Verbose "Connecting to '$Url'"
		Add-content $Logfile -value "Connecting to '$Url'"
		$connSP = Connect-PnPOnline -Url $Url -UseWebLogin -ReturnConnection -WarningAction ignore
		
	} elseif($AuthMethod -eq "secret") {
		## Connect to PnP Online
		Write-Verbose "Connecting to '$Url'"
		Add-content $Logfile -value "Connecting to '$Url'"
		## Credential Azure Store Credntial
		$connSP = Connect-PnPOnline -Url $Url -ClientID $AppId -ClientSecret $ClientSecret -WarningAction ignore  -ReturnConnection 
		
	} else  {

		## Credential User Prompteds
		$credential = (Get-Credential)
			
		## Connect to PnP Online
		Write-Verbose "Connecting to '$Url'"
		Add-content $Logfile -value "Connecting to '$Url'"
		
		Connect-PnPOnline -Url $Url -Credentials $Credential

	}

	## Get the Target Folder to Upload
	$Web = Get-PnPWeb -Connection $connSP 
	
	if($Web) {
		Write-Verbose "Connected successfully."	
		Add-content $Logfile -value "Connected successfully."
				
		# Write-Verbose "ServerRelativeUrl: $($Web.ServerRelativeUrl)"
		try{

			## Connect to SharePoint Library
			$List = Get-PnPList $LibraryName -Includes RootFolder -Connection $connSP 
		
			if($List) {
				
				Write-Verbose "Library '$LibraryName' Loaded successfully."	
				Add-content $Logfile -value "Library '$LibraryName' Loaded successfully."	
				
				$TargetFolder = $List.RootFolder
				## Write-Verbose $TargetFolder 
				
				if($subFolder){
					Write-Verbose "Subfolder '$subFolder' has been specified."	
					Add-content $Logfile -value "Subfolder '$subFolder' has been specified."	
					
					$TargetFolderSiteRelativeURL = $TargetFolder.ServerRelativeURL+"/"+$subFolder
				} else {
					$TargetFolderSiteRelativeURL = $TargetFolder.ServerRelativeURL
				}

				# Write-Verbose "TargetFolderSiteRelativeURL : $TargetFolderSiteRelativeURL"
				
				try{

					## Get All Items from the Source
					Write-Verbose "Loading Items ..."
					Add-content $Logfile -value "Loading Items ..."

					$Source = Get-ChildItem -Path $SourcePath -Recurse
					$SourceItems = $Source | Select FullName, PSIsContainer, @{Label='TargetItemURL';Expression={$_.FullName.Replace($SourcePath,$TargetFolderSiteRelativeURL).Replace("\","/")}}
				}
				catch {
					Write-Verbose "Error:$($_.Exception.Message)"
					Add-content $Logfile -value "Error:$($_.Exception.Message)"
				}
				
				Write-Verbose "Number of Items Found in the Source: $($SourceItems.Count)"
				Add-content $Logfile -value "Number of Items Found in the Source: $($SourceItems.Count)"

				## Upload Source Items to Target SharePoint Online document library
				$Counter = 0
				foreach($item in $SourceItems) {

					# write-verbose "TargetFolderURL: $TargetFolderURL"

					## Get the File Name
					$ItemName = Split-Path $item.FullName -leaf
							
					## Replace Invalid Characters 
					$ItemName = [RegEx]::Replace($ItemName, "[{0}]" -f ([RegEx]::Escape([String]'\"*:<>?/\|')), '_')

					If($item.PSIsContainer) {
						
						## Check for subfolder and create automatically
						try {

							## Build Folder paths
							$TargetFolderURL = $item.TargetItemURL.Replace($Web.ServerRelativeUrl,"")
							$stringLength = $TargetFolderURL.length

							$trimmedTargetFolderURL = $TargetFolderURL.subString(1, $stringLength-1)
		
							$Folder  = Resolve-PnPFolder -SiteRelativePath $trimmedTargetFolderURL -Connection $connSP 

							Write-Verbose "Ensure folder '$TargetFolderURL'"
							Add-content $Logfile -value "Ensure folder '$TargetFolderURL'"

						}
						catch {

							Write-Verbose "Error:$($_.Exception.Message)"
							Add-content $Logfile -value "Error:$($_.Exception.Message)"

						}

					} else {
							## Upload File
							try {
								
								## Calculate Target Folder URL
								$TargetFolderURL = (Split-Path $item.TargetItemURL -Parent).Replace("\","/")
					
								Write-Verbose "Upload file '$($item.FullName)' to folder '$TargetFolderURL'"
								Add-content $Logfile -value "Upload file '$($item.FullName)' to folder '$TargetFolderURL'"

								$File  = Add-PnPFile -Path $item.FullName -Folder "$TargetFolderURL" -Connection $connSP -verbose
								
							}
							catch {
								Write-Verbose "Error:$($_.Exception.Message)"
								Add-content $Logfile -value "Error:$($_.Exception.Message)"
							}

							## Delete source file if cleanup is configured.
							if($CleanUp) {
								try {
									Write-Verbose " - Deleting File '$($item.FullName)'"
									Add-content $Logfile -value " - Deleting File '$($item.FullName)'"
									Remove-Item -Path $($item.FullName)
								}
								catch {
									Write-Verbose "Error:$($_.Exception.Message)"
									Add-content $Logfile -value "Error:$($_.Exception.Message)"
								}
							}
					}
					$Counter++
				} 
			} else {
					
				Write-Verbose "Library failed to load."	
				Add-content $Logfile -value "Library failed to load."
			}
		}
		catch {
			Write-Verbose "Error:$($_.Exception.Message)"
			Add-content $Logfile -value "Error:$($_.Exception.Message)"
		}
	} else {
		Write-Verbose "Connection Failed!"
		Add-content $Logfile -value "Connection Failed!"
	}
}
Catch {
	
	Write-Verbose "Error:$($_.Exception.Message)"
    Add-content $Logfile -value "Error:$($_.Exception.Message)"
}
Finally {
	
   Write-Verbose "Disconnecting from '$Url'"	
   Add-content $Logfile -value "Disconnecting from '$Url'"
   
   ## Disconnect-PnPOnline -Connection $connSP
   $connSP = $null
   
   Write-Verbose "---------------------- File Upload Script Completed: $(Get-date -format 'MM/dd/yyy hh:mm:ss tt') -----------------"
   Add-content $Logfile -value "---------------------- File Upload Script Completed: $(Get-date -format 'MM/dd/yyy hh:mm:ss tt') -----------------"
}
