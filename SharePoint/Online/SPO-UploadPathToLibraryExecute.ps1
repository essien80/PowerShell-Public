<#

This is an executor script to load the file uploader script with specific parameters.

Rename this file as appropriate for different upload jobs

i.e. SPO-UploadPathToLibraryExecute_specialreports.ps1

#>

$siteUrl = ""
$tenantName = ""
$sourcePath = ""
$libName = ""
$subfolder = ""
$authMethod = ""
$logName = ""
$certThumb = ""
$ClientSecret = ""
$appId = ""

switch($authMethod) {
    secret {
        ## Secret
        .\SPO-UploadPathToLibrary.ps1 -url $siteUrl -SourcePath $sourcePath -LibraryName $libName -authMethod $authMethod -tenantName $tenantName -appId $appId -ClientSecret $ClientSecret -logName $logName -singlelog -verbose 
    }    
    cert {
        ## Cert Login
        if($subfolder) {
            ## Cert Login with sub folder
            .\SPO-UploadPathToLibrary.ps1 -url $siteUrl -SourcePath $sourcePath -LibraryName $libName -subfolder $subfolder -authMethod $authMethod -tenantName $tenantName -appId $appId -certThumb $certThumb -logName $logName -singlelog -verbose 
        } else {
            .\SPO-UploadPathToLibrary.ps1 -url $siteUrl -SourcePath $sourcePath -LibraryName $libName -authMethod $authMethod -tenantName $tenantName -appId $appId -certThumb $certThumb -logName $logName -singlelog -verbose           
        }
    }
    web {
        ## Web Login
        .\SPO-UploadPathToLibrary.ps1 -url $siteUrl -SourcePath $sourcePath -LibraryName $libName -authMethod $authMethod -logName $logName -verbose
    }
}