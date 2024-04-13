
$timeStamp = (Get-Date).ToString('yyyyMMdd-HHmm')
$ScriptPath = $MyInvocation.MyCommand.Path
$ScriptDir  = Split-Path -Parent $ScriptPath

$outPutFile = "$ScriptDir\AAD-GetAllUsersWithDetails.csv"

#Check for MSOnline module 
$Module=Get-Module -Name MSOnline -ListAvailable  
if($Module.count -eq 0) 
{ 
 Write-Host MSOnline module is not available  -ForegroundColor yellow  
 $Confirm= Read-Host Are you sure you want to install module? [Y] Yes [N] No 
 if($Confirm -match "[yY]") 
 { 
  Install-Module MSOnline 
  Import-Module MSOnline
 } 
 else 
 { 
  Write-Host MSOnline module is required to connect AzureAD.Please install module using Install-Module MSOnline cmdlet. 
  Exit
 }
} 

$conn = Connect-MsolService


$users = Get-MSOLUser -All

$userData = @()

foreach($user in $users) {

    $upn = $($user.UserPrincipalName)
    $dn = $($user.DisplayName)
    $passChange = $($user.LastPasswordChangeTimestamp)

    Write-host "$upn - $dn - $passChange"

    $tempOBJ = New-Object system.object
    $tempOBJ | add-member -type Noteproperty -name UPN -value $upn
    $tempOBJ | add-member -type Noteproperty -name DisplayName -value $dn
    $tempOBJ | add-member -type Noteproperty -name LastPasswordChangeTimestamp -value $passChange
    $userData += $tempobj

}

$userData | Export-Csv $outPutFile -NoTypeInformation