<# SPO-GetBirthdayReport.ps1
This script will pull a list of Users from UPS for a date range using a managed search
property. You can pull a list of users using any managed date property.

Nick Ortiz
------------------------
2022-12-21 : Initial version

If FilterStart and FilterEnd are not defined it will default to the current month.

This script requires PNP ONline:

## Required Modules:

## SharePoint PNP
# Install-Module -Name PnP.PowerShell

#####
## Create App Registration and Certificate
# Initialize-PnPPowerShellAuthentication -ApplicationName "PNP" -Tenant "contoso.onmicrosoft.com" -OutPath c:\temp

## Add API Permissions:
# - SharePoint: Sites.FullControl.All

## Parameters
	-tenantName (string)[required]:         azure tenant name i.e contoso.onmicrosoft.com
	-AuthMethod (string)[optional]:         defaults to Web, Options: file, web, auth, cert, secret. This can be hardcoded in the configuration parameters below.
    -filterStart (string)[optional]:        Start date of your search i.e. 01/01/2022, if not provided the current month will be used.
    -filterEnd (string)[optional]:          End date of your search i.e. 01/01/2022, if not provided the current month will be used.
    -managedProperty (string)[optional]:    This is the manages search proeprty you're looking to query against. This can be hardcoded in the configuration parameters below.
	-AppId (string)[optional]:              Appid GUID for your app registration
	-ClientSecret (string)[optional]:       Generated azure ad cient secret
    -certThumb (string)[optional]:          Certificate thumbprint from app registrations

## Execution Examples

Basic Execution using Interactive logic
.\SPO-GetBirthdayReport.ps1 -tenantName contoso

Using Client Secret to login
.\SPO-GetBirthdayReport.ps1 -tenantName contoso -AuthMethod secret -AppId "11111111-1111-1111-1111-111111111111" -ClientSecret "xxxxxxxxxxxxxxxxxxxxx" -managedProperty UPSHIREDATE

Query using a date range
.\SPO-GetBirthdayReport.ps1 -tenantName contoso -filterStart 01/01/2022 -filterEnd 12/31/2022

#>

param(
	[Parameter(Mandatory=$true)] [string] $tenantName,
    [Parameter(Mandatory=$false)] [string] $AuthMethod,
    [Parameter(Mandatory=$false)] [string] $filterStart,
    [Parameter(Mandatory=$false)] [string] $filterEnd,
    [Parameter(Mandatory=$false)] [string] $managedProperty,
    [Parameter(Mandatory=$false)] [string] $AppId,
	[Parameter(Mandatory=$false)] [string] $certThumb,
	[Parameter(Mandatory=$false)] [string] $ClientSecret

)

###############################################
##          Configuration Settings           ##
###############################################
## Hard code your search managed property
if($managedProperty.Length -eq 0) {
    $managedProperty = "UPSBIRTHDAY"
}
## Hard code your authentication mode
## Options: file, web, auth, cert, secret
if($AuthMethod.Length -eq 0) {
    $AuthMethod = "web"
}

###############################################
##          Internal Parameters              ##
###############################################
## Define how many years back to search from
$numberOfYearsHistory = 50

## Define how many how many queries to generate. If you have a large orgnazation, it may
## be necessary to break up the queries futher as only 500 items are returned per query.
$numberOfYearsHistoryDivider = 10

## People Search Result Source for your tenant. All SPO tenants use "b09a7990-05ea-4af9-81ef-edfab16c4e31" by default
$searchDataSource = "b09a7990-05ea-4af9-81ef-edfab16c4e31"

## Build the Site Url string for your SPO Tenant
$siteUrl = "https://$tenantName.sharePoint.com"

## Set Time stamp and script paths
$timeStamp = (Get-Date).ToString('yyyyMMdd-HHmm')
$ScriptPath = $MyInvocation.MyCommand.Path
$ScriptDir  = Split-Path -Parent $ScriptPath

## Export File Name
$outPutFileItemInventory = "SPO-GetBirthdayReport" + "_$managedProperty" + "_$timeStamp.csv"


## Log file Settings
$LogFile = "$ScriptDir\Logs\SPO-GetBirthdayReport.log"

## Create Log Directory
if(!(Test-Path $ScriptDir\Logs\)) {
    $newLogsDir = New-Item -Path $ScriptDir\Logs\ -ItemType "directory"
}

## Check Log file size and start a new one if its larger than 20 MB
if((Test-Path $LogFile)) {
    $curLog = Get-ChildItem -Path $LogFile
    $curSize = ($curLog.Length)/1024/1024
    $curLogNewName = $($LogFile.Split('.')[0]) + "$timeStamp." + $($LogFile.Split('.')[1])

    ## Create new log is the current one is greater that 20 MB
    if($curSize -ge "20"){

        Add-content $Logfile -value "--- Birthday Report log has grown too large, creating a new file: $(Get-date -format 'MM/dd/yyy hh:mm:ss tt') ---"
        Move-Item -Path $LogFile -Destination $curLogNewName

    }
}


###############################################
##     Authenticate to SharePoint Online     ##
###############################################
Write-host "--- Starting Export: $(Get-date -format 'MM/dd/yyy hh:mm:ss tt') ---" -F Green
Add-content $Logfile -value "--- Starting Export: $(Get-date -format 'MM/dd/yyy hh:mm:ss tt') ---"

Write-host "--- Connect to SPO ---" -F Green
Add-Content $Logfile -value "--- Connect to SPO ---"

if($AuthMethod -eq "file") {
	   
    $AESKeyFileName = "SPO-GetBirthdayReport.aes"
    $PWFileName = "SPO-GetBirthdayReport.pw"
   
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
        Write-Host "Password File found ..." -F Yellow
        Add-content $Logfile -value "Password File found ..."
    }
    Add-content $Logfile -value "Loading Password File and Generating Credential."
    ## Credential using Password file
    $AESKeyFile = Get-Content $PWFilePath\$AESKeyFileName
    $SPOPass = Get-Content $PWFilePath\$PWFileName | ConvertTo-SecureString -Key $AESKeyFile

    $credential = new-object System.Management.Automation.PSCredential ($username,$SPOPass)
    
    # Connect to PnP Online
    Write-Host "- AuthMethod: $AuthMethod" -F Green
    Write-Host "- Connecting to '$siteUrl' ... " -F Green -NoNewline
    Add-content $Logfile -value "- AuthMethod: $AuthMethod`nConnecting to '$siteUrl'"
    $connSP = Connect-PnPOnline -Url $siteUrl -Credentials $credential -ReturnConnection -WarningAction ignore
    Write-host "done" -F Cyan
    
} elseif($AuthMethod -eq "cert") {
    #Connect to PnP Online
    Write-Host "- AuthMethod: $AuthMethod" -F Green
    Write-Host "- Connecting to '$siteUrl' ... " -F Green -NoNewline
    Add-content $Logfile -value "- AuthMethod: $AuthMethod`nConnecting to '$siteUrl'"
    $connSP = Connect-PnPOnline -Url $siteUrl -ClientID $AppId -Tenant "$tenantName.onmicrosoft.com" -Thumbprint $certThumb -WarningAction ignore -ReturnConnection 
    Write-host "done" -F Cyan
    
} elseif($AuthMethod -eq "web") {
    #Connect to PnP Online
    Write-Host "- AuthMethod: $AuthMethod" -F Green
    Write-Host "- Connecting to '$siteUrl' ... " -F Green -NoNewline
    Add-content $Logfile -value "- AuthMethod: $AuthMethod`nConnecting to '$siteUrl'"
    $connSP = Connect-PnPOnline -Url $siteUrl -UseWebLogin -ReturnConnection -WarningAction ignore
    Write-host "done" -F Cyan
    
} elseif($AuthMethod -eq "secret") {
    #Connect to PnP Online
    Write-Host "- AuthMethod: $AuthMethod" -F Green
    Write-Host "- Connecting to '$siteUrl' ... " -F Green -NoNewline
    Add-content $Logfile -value "- AuthMethod: $AuthMethod`nConnecting to '$siteUrl'"

    ## Credential Client Secret Credntial
    $connSP = Connect-PnPOnline -Url $siteUrl -ClientID $AppId -ClientSecret $ClientSecret -WarningAction ignore  -ReturnConnection 
    Write-host "done" -F Cyan
    
} else  {

    ## Credential User Prompted
    $credential = (Get-Credential)
        
    #Connect to PnP Online
    Write-Host "- AuthMethod: $AuthMethod" -F Green
    Write-Host "- Connecting to '$siteUrl' ... " -F Green -NoNewline
    Add-content $Logfile -value "- AuthMethod: $AuthMethod`nConnecting to '$siteUrl'"
    
    if($MFA) {
        Connect-PnPOnline -Url $siteUrl -UseWebLogin
    } else {
        Connect-PnPOnline -Url $siteUrl -Credentials $Credential
    }
    Write-host "done" -F Cyan
}

###############################################
##                Functions                  ##
###############################################
function util_Numeric_ReturnArrayOfIntegersByDivider {
    param (
        $NumericInteger, 
        $DividerInteger
    )
    ## This function will divide the NumericInteger by the DividerInteger.
    ## From that division, we will only take the whole numbers, then use the modulus (%) operator to return the
    ## remainder. The return value will be an array of the result of the division and the remainder.
    ## (Example: 	NumericInteger of 50 / DividerInteger of 4 = 12.5. Since we are only taking the whole number,
    ## 				we only have 12, 4 times with a remainder of 2. SO: 50/4 = 12 + remainder of 2.
    ##				The Array will then look like [12,12,12,12,2] = 12+12+12+12+2 = 50.)
    $wholeDivisionValue = [math]::floor($NumericInteger / $DividerInteger);
    $remainderDivisionValue = $NumericInteger % $DividerInteger;
    $returnArray = @();
    for ($i = 0; $i -lt $DividerInteger; $i++) {
        $returnArray += ($wholeDivisionValue);
    }
    if ($remainderDivisionValue -ne 0) {
        $returnArray += ($remainderDivisionValue);
    }
    return $returnArray;
}

function util_Build_Query_Strings{
    param (
        $filterStart,
        $filterEnd,
        $arrayNumberOfYears,
        $ManagedProperty
    ) 

    $startDate = Get-Date($filterStart)
    $endDate = Get-Date($filterEnd)

    ## Create the return array that will be passed at the end of the function.
    $returnArray = @();
    ## Create a variable to track the current year.
    ## This variable is used to ensure that as we loop through the arrayNumberOfYears, we ensure we are subtracting
    ## from the correct year.
    ## Example:	If the startDate year is 2050 and our arrayNumberOfYears is [25,25], when we loop through the second array item
    ##			we are technically starting at 2025, not 2050, which is the startDate Year.
    ##			OTHERWISE, as we progress through the second and on array item, we would have to know what the previous array
    ##			item values were. If we KNOW that every item in the array is the same value, we could programmatically calculate
    ##			which year we are on inside the for loop, BUT if the numbers per array item vary, it makes it virtually impossible.
    ## NOTE:	We create a variable for both the startDate and endDate BECAUSE they technically could be two different years.
    ## Example:	If the startDate is in December and the endDate is in Jan, they would have different years and must be tracked individually.
    $tempStartDateCurrentYear = $null;
    $tempEndDateCurrentYear = $null;
    if ($ManagedProperty -eq $hireDateColumn) {
        $tempStartDateCurrentYear = $endDate.Year - 1;
        $tempEndDateCurrentYear = (Get-Date).Year - 1;
    } else {
        $tempStartDateCurrentYear = $startDate.Year 
        $tempEndDateCurrentYear = $endDate.Year 
    }
    ## Because the start and end month/day's will never differ from year to year, we can calculate the month/day values
    ## outside of the loops. This will require less processing to occur within the loops.

    $startDateDay = $startDate.Day;
    $startDateMonth = $startDate.Month

    $endDateDay = $endDate.Day;
    $endDateMonth = $endDate.Month

    ## Now loop through each array item on the arrayNumberOfYears array. This essentially identifies how many years to include
    ## in each request for data. The value of each array item identifies how many years to include in each request. The number
    ## of array items represents how many separate requests we will make.
    for ($i = 0; $i -lt $arrayNumberOfYears.length; $i++) {
        ## Create the queryText variable. This variable will be rest on the outer for loop.
        ## The queryText will be added to the returnArray array after the inner loop.
        $queryText = '';
        ## Create another for loop that will loop through the current arrayNumberOfYears item value and build the query text.
        ## This value inside the individual arrayNumberOfYears[i] item represents how many years to include in the individual request.
        # $endDateMonth

        for ($ai = 0; $ai -lt $arrayNumberOfYears[$i]; $ai++) {
            ## Because the Month/Day values were already configured outside of the loops, we are simply just creating the queryText
            ## values inside the loop. The year value is calculated using the tempStartDateCurrentYear/tempEndDateCurrentYear variables.
            $startDateQuery = $tempStartDateCurrentYear.toString() + '-' + $startDateMonth.toString() + '-' + $startDateDay.toString();
            $endDateQuery = $tempEndDateCurrentYear.toString() + '-' + $endDateMonth.toString() + '-' + $endDateDay.toString();
            $queryText = $queryText + $ManagedProperty + ':' + $startDateQuery + '..' + $endDateQuery;

            ## We are using an if statement here to ensure that there is no trailing "+OR+" at the end of the queryText in the REST API
            ## request. If there was a trailing " OR ', then it would be like saying to search to bring back everything.
            if ($ai -ne $arrayNumberOfYears[$i] - 1) {
                $queryText = $queryText + ' OR ';
            }

            ## Decrease the current year for the startDate and endDate values. Reasoning behind why we are decreasing the years in this way
            ## is described in the notes and examples above when the variables were created.
            $tempStartDateCurrentYear = $tempStartDateCurrentYear - 1;
            $tempEndDateCurrentYear = $tempEndDateCurrentYear - 1;
        }
        $returnArray += ($queryText);
    }
    return $returnArray;
}

###############################################
##             Start Execution               ##
###############################################
Write-host "--- Parameters ---" -F Green
Write-host "- ManagedProperty: $managedProperty" -F Green
Add-Content $Logfile -value "--- Parameters ---"
Add-Content $Logfile -value "- ManagedProperty: $managedProperty"

## Calcuate the Start Date for the current month if a value hasn't been provided
if($filterStart.Length -eq 0) {    
    $CURRENTDATE = (Get-Date -Hour 0 -Minute 0 -Second 0)
    $filterStart = (Get-Date $CURRENTDATE -Day 1) 

    Write-host "- FilterStart not defined, using current month '$filterStart'" -f Yellow
    Add-Content $Logfile -value "- FilterStart not defined, using current month [$filterStart]"
} else {
    Write-host "- FilterStart: $filterStart" -F Green
    Add-Content $Logfile -value "- FilterStart: $filterStart"
}

## Calcuate the End Date for the current month if a value hasn't been provided
if($filterEnd.Length -eq 0) {
    $filterEnd = (GET-DATE $filterStart).AddMonths(1).AddSeconds(-1)
    
    Write-host "- FilterEnd not defined, using current month '$filterEnd'" -f Yellow
    Add-Content $Logfile -value "- FilterEnd not defined, using the current month [$filterEnd]"
} else {
    Write-host "- FilterEnd: $filterEnd" -F Green
    Add-Content $Logfile -value "- FilterEnd: $filterEnd"
}

## Build Array to help calculate all the Search queries over mulitple years
$queryYearsRangeArray = util_Numeric_ReturnArrayOfIntegersByDivider -NumericInteger $numberOfYearsHistory -DividerInteger $numberOfYearsHistoryDivider

## Use the variable above to create a collection array of Query Strings.
$bQueryTextYearsRangeArray = util_Build_Query_Strings -filterStart $filterStart -filterEnd $filterEnd -arrayNumberOfYears $queryYearsRangeArray -ManagedProperty $managedProperty

## Reset Search Results to be safe
$searchAllResults = $null

## Execute Search and build result set
Write-host "--- Start Search ---" -F Green
Add-Content $Logfile -value "--- Start Search ---"

for ($i = 0; $i -lt $bQueryTextYearsRangeArray.length; $i++) {

    $query = $bQueryTextYearsRangeArray[$i] 
    $counterDisplay = $i + 1

    try{
        Write-Host "- Searching [$counterDisplay] of [$($bQueryTextYearsRangeArray.length)], stand by ... " -F Green -NoNewline
        Add-content $LogFile -value "Searching [$counterDisplay] of [$($bQueryTextYearsRangeArray.length)] "
        Add-content $LogFile -value "- Query: '$query'"
        Add-content $LogFile -value "- Results Found: $($searchResults.RowCount)"
    
        $searchResults = Submit-PnPSearchQuery -Query $bQueryTextYearsRangeArray[$i] -All -SelectProperties "Title,$managedProperty,PictureURL,Path,Department,WorkEmail" -SourceId $searchDataSource -Connection $connSP
    
        Write-Host "done" -F Cyan
    
        if($searchResults.ResultRows) {
            $searchAllResults += $searchResults.ResultRows 
        }

    }
    catch {
        Write-Host "- Search failed ... $($_.exception.message)" -F Red
    }

}
Write-host "--- Search Complete ---" -F Green
Add-Content $Logfile -value "--- Search Complete ---"
 
## Process result set and add items to an Array for export.
$resultExport = @()

$searchAllResults | ForEach-object { 

    $tempOBJ = New-Object system.object
    $tempOBJ | add-member -type Noteproperty -name PreferredName -value $_["PreferredName"]
    $tempOBJ | add-member -type Noteproperty -name JobTitle -value $_["JobTitle"]
    $tempOBJ | add-member -type Noteproperty -name $managedProperty -value (Get-Date($_["$managedProperty"])).ToShortDateString()
    $tempOBJ | add-member -type Noteproperty -name WorkEmail -value $_["WorkEmail"]
    $resultExport += $tempOBJ
}

## Export Results to a CSV
if($($resultExport.Length -gt 0)) {
    
    write-host "- Total items found: $($resultExport.Length) " -F Green
    Add-Content $LogFile -value "Total items found: $($resultExport.Length)"
    
    try{
        Write-Host "- Exporting to '$outPutFileItemInventory' ... " -F green -NoNewline
        Add-Content $LogFile -value "Exporting to '$outPutFileItemInventory'"
        $resultExport | Export-Csv $outPutFileItemInventory -NoTypeInformation
        Write-Host "done" -F Cyan
    }
    catch {
        Write-Host "- Export failed ... $($_.exception.message)" -F Red
        Add-Content $LogFile -value "Export failed ... $($_.exception.message)"
    }
} else {
    Write-Host "- No items found for '$managedProperty' filterStart: '$filterStart' filterEnd: '$filterEnd'" -F Red
    Add-Content $LogFile -value "- No items found for '$managedProperty' filterStart: '$filterStart' filterEnd: '$filterEnd'"
}

## Disconnect from SharePOint Online
write-host "- Disconnecting ... " -F Green -NoNewline
Add-Content $LogFile -value "Disconnecting ... "

$connSP = $null

Write-Host "done" -F Cyan

## Exiting
write-host "- Exiting" -F Green
Add-Content $LogFile -value "Exiting"

Write-host "--- Export Complete: $(Get-date -format 'MM/dd/yyy hh:mm:ss tt') ---" -F Green
Add-content $Logfile -value "--- Export Complete: $(Get-date -format 'MM/dd/yyy hh:mm:ss tt') ---"