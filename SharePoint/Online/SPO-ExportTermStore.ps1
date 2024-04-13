<# SPO-ExportTermStore
 The Purpose of this script is to export a termset and all of it's sub terms into a format that is re-importable into 
the Term Store.
 -----------------------
 Nick Ortiz
 2019-03-12: 	Initial Version
 2019-04-30:    Updated to Include GUID in CSV Export.
 ------------
 This script requires SharePoint Online Client Components:
  https://www.microsoft.com/en-us/download/details.aspx?id=42038

#>

# Provide Admin Credentials.
$adminAccount = ""
$adminPassword = "" | ConvertTo-SecureString -AsPlainText -Force -ErrorAction SilentlyContinue


# Configuration Settings
$url = ""
$TermGroupName = ""
$TermSetName = ""
$CSVFile = $TermGroupName+"_"+$TermSetName+".csv"

# Update Pathes to files if needed.
# Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.dll"
# Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.Runtime.dll"
# Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.Taxonomy.dll"
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.dll"
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Runtime.dll"
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Taxonomy.dll"


# Start the CSV File
"Term Set Name,Term Set Description,LCID,Available for Tagging,Term Description,Level 1 Term,Level 2 Term,Level 3 Term,Level 4 Term,Level 5 Term,Level 6 Term,Level 7 Term,GUID" > $CSVFile

# Connect to SPO
$clientContext = New-Object Microsoft.SharePoint.Client.ClientContext($url)
$credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($adminAccount, $adminPassword) 
$clientContext.Credentials = $credentials
# Get your tenant Taxonomy details 
$MMS = [Microsoft.SharePoint.Client.Taxonomy.TaxonomySession]::GetTaxonomySession($clientcontext)
$clientContext.Load($MMS)
$clientContext.ExecuteQuery()
$TermStores = $MMS.TermStores
$clientContext.Load($TermStores)
$clientContext.ExecuteQuery()
#Bind to Term Store
$TermStore = $TermStores[0]
Write-Host "#################################      Taxonomy on tenant which contain the Site collection   #################################"
Write-Host "#################################      $url    #################################"
$clientContext.Load($TermStore)
$clientContext.ExecuteQuery()
""
$Groups = $TermStore.Groups.GetByName($TermGroupName)
$clientContext.Load($groups)
$clientContext.ExecuteQuery()

# Process term set
for ($i = 0; $i -lt $Groups.Count; $i++) {
    write-host "For the Group: "$groups[$i].Name " / " $groups[$i].id
    $groupname = $groups[$i]
    $termsets = $groupname.TermSets.GetByName($TermSetName)
    #$TermSet = $TermGroup.TermSets.GetByName($TermSetName)
    $clientContext.Load($termsets)
    $clientContext.ExecuteQuery()
    foreach ($termset in $termsets ) {
        write-host "  The TermSet:"$termset.Name " / " $termset.id  -ForegroundColor DarkYellow
        $terms = $termset.Terms
        $clientContext.Load($terms)
        $clientContext.ExecuteQuery()
        $termset.Name + ",""$($termset.Description)""," + $TermStore.DefaultLanguage + "," + $TermSet.IsAvailableForTagging + "," + "," + "," + "," + "," + "," + "," + "," + "," +  $termset.id  >> $CSVFile
        foreach ($term in $terms ) {
            
            write-host  "    The Term ( level 0): "$term.Name  " / " $term.id  -ForegroundColor Gray
            $items = $term.Terms
            $clientContext.Load($Items)
            $clientContext.ExecuteQuery()
            
            ","+"," + "," + $TermSet.IsAvailableForTagging + ",""$($Terms[0].Description)""," + $term.Name + "," + "," + "," + "," + "," + "," + "," + $term.id  >> $CSVFile
            
            foreach ( $term_level1 in $items ) {
                Write-Host "      Level 1:" $term_level1.Name " / "$term_level1.ID -ForegroundColor cyan
                ","+"," + "," + $TermSet.IsAvailableForTagging + ",""$($Tetermrm.Description)""," + $term.Name + "," + $term_level1.Name + "," + "," + "," + "," + "," + "," + $term_level1.ID  >> $CSVFile
               
                #$term_level1.TermsCount
                $items2 = $term_level1.Terms
                $clientContext.Load($Items2)
                $clientContext.ExecuteQuery()
               
                foreach ( $term_level2 in $items2 ) {
                    # $term_level2.TermsCount
                    Write-Host "        Level 2:" $term_level2.Name " / "$term_level2.ID -ForegroundColor green
                    ","+"," + "," + $TermSet.IsAvailableForTagging + ",""$($term.Description)""," + $term.Name + "," + $term_level1.Name + "," + $term_level2.Name + "," + "," + "," + "," + "," + $term_level2.ID  >> $CSVFile

                    $items3 = $term_level2.Terms
                    $clientContext.Load($Items3)
                    $clientContext.ExecuteQuery()
                    
                    foreach ( $term_level3 in $items3 ) {
                        #$term_level3.TermsCount
                        Write-Host "            Level 3:" $term_level3.Name " / "$term_level3.ID -ForegroundColor yellow
                        ","+"," + "," + $TermSet.IsAvailableForTagging + ",""$($Terms[0].Description)""," + $term.Name + "," + $term_level1.Name + "," + $term_level2.Name + "," + $term_level3.Name + "," + "," + "," + "," + $term_level3.ID  >> $CSVFile
                       
                        $items4 = $term_level3.Terms
                        $clientContext.Load($Items4)
                        $clientContext.ExecuteQuery()
                        
                        foreach ( $term_level4 in $items4 ) {
                            #$term_level4.TermsCount
                            Write-Host "              Level 4:" $term_level4.Name " / "$term_level4.ID -ForegroundColor blue
                            ","+"," + "," + $TermSet.IsAvailableForTagging + ",""$($Terms[0].Description)""," + $term.Name + "," + $term_level1.Name + "," + $term_level2.Name + "," + $term_level3.Name + "," + $term_level4.Name + "," + "," + "," + $term_level4.ID  >> $CSVFile
                            
                            $items5 = $term_level4.Terms
                            $clientContext.Load($Items5)
                            $clientContext.ExecuteQuery()
                            
                            foreach ( $term_level5 in $items5 ) {
                                #$term_level5.TermsCount
                                Write-Host "                Level 5:" $term_level5.Name" / "$term_level5.ID -ForegroundColor red
                                ","+"," + "," + $TermSet.IsAvailableForTagging + ",""$($Terms[0].Description)""," + $term.Name + "," + $term_level1.Name + "," + $term_level2.Name + "," + $term_level3.Name + "," + $term_level4.Name + "," + $term_level5.Name + "," + "," + $term_level5.ID  >> $CSVFile
                               
                                $items6 = $term_level5.Terms
                                $clientContext.Load($items6)
                                $clientContext.ExecuteQuery()
                                foreach ( $term_level6 in $items6 ) {
                                    #$term_level6.TermsCount
                                    Write-Host "                Level 6:" $term_level6.Name" / "$term_level6.ID -ForegroundColor red

                                    ","+"," + "," + $TermSet.IsAvailableForTagging + ",""$($Terms[0].Description)""," + $term.Name + "," + $term_level1.Name + "," + $term_level2.Name + "," + $term_level3.Name + "," + $term_level4.Name + "," + $term_level6.Name + "," + "," + $term_level6.ID  >> $CSVFile
                                
                                    $items7 = $term_level6.Terms
                                    $clientContext.Load($items7)
                                    $clientContext.ExecuteQuery()
                                    foreach ( $term_level7 in $items7 ) {
                                        #$term_level7.TermsCount
                                        Write-Host "                Level 7:" $term_level7.Name" / "$term_level7.ID -ForegroundColor red
    
                                        ","+"," + "," + $TermSet.IsAvailableForTagging + ",""$($Terms[0].Description)""," + $term.Name + "," + $term_level1.Name + "," + $term_level2.Name + "," + $term_level3.Name + "," + $term_level4.Name + "," + $term_level6.Name + "," + $term_level7.Name + "," + $term_level7.ID >> $CSVFile
                                    }
                                }
                            }
                        } 
                    }
                }
                
  
            }
       }
    }
}
