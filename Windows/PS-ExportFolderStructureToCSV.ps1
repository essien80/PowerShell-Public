<# PS-ExportFolderStructureToCSV.ps1
 The purpose of this script is create a csv of a folder and it's sub folders.
 -----------------------
 Nick Ortiz
 2019-03-01: Initial version.

 Usuage example:
 .\PS-ExportFolderStructureToCSV.ps1 -path "\\server\share\folder" -count -verb
 .\PS-ExportFolderStructureToCSV.ps1 -path "c:\folder" -count
#>

Param (
    [parameter(Mandatory=$true)][string]$path,
    [parameter(Mandatory=$false)][switch]$count,
    [parameter(Mandatory=$false)][switch]$verb
)

Write-host "Processing '$path', this may take a while ..." -ForegroundColor "Green"
if($count) {
    Write-host "Item count enabled" -ForegroundColor "Green"
}
if($verb) {
    Write-host "Verbose enabled" -ForegroundColor "Yellow"
}

# Load folders
$folders = Get-ChildItem $path -Recurse | Where-Object { $_.PSIsContainer -eq $true}

# Set up variables for output
$timeStamp = (Get-Date).ToString('_yyyyMMdd-HHmm')
$ScriptPath = $MyInvocation.MyCommand.Path
$ScriptDir  = Split-Path -Parent $ScriptPath
$outputFile = "PS-ExportFolderStructureToCSV"+$timeStamp+".csv"

# Array for export
$outputArray = @()

# Process folders
foreach($f in $folders) {

    # Process folders
    if($f.PSIsContainer) {
        $folderPath = $f.FullName

        # Count the items if needed
        if($count) {
            $itemCount = Get-ChildItem $f.FullName | Measure-Object | %{$_.Count}
        }
    
       # Give the user something to watch
       if($verb) {
            write-host "Verbose: "$folderPath" - "$itemCount -ForegroundColor "Yellow"
       }
    }
    
    # Add data to array for export
    $tempOBJ = New-Object system.object
    $tempOBJ | add-member -type Noteproperty -name folderPath -value $f.FullName
    if($count) {
        $tempOBJ | add-member -type Noteproperty -name itemCount -value $itemCount
    }
    $tempOBJ | add-member -type Noteproperty -name lastWriteTime -value $f.LastWriteTime
    $tempOBJ | add-member -type Noteproperty -name lastAccessTime -value $f.LastAccessTime
    $outputArray += $tempobj

}

# Create the CSV
$outputArray | Export-Csv $ScriptDir\$outputFile -NoTypeInformation