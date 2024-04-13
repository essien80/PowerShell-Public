<# AAD-GetUsersPasswordChangeDate.ps1
The purpose of this script is to pull a list of the LastPasswordChange
time stamp for all users in Active Directory.

-----------------------
Nick Ortiz
2023-02-10: Initial version.

#>

$timeStamp = (Get-Date).ToString('yyyyMMdd-HHmm')
$ScriptPath = $MyInvocation.MyCommand.Path
$ScriptDir  = Split-Path -Parent $ScriptPath

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

Try { 
    Write-Host "Connecting ... " -F Blue -NoNewline
    Connect-MsolService | Out-Null
    Write-Host "done" -F Green
}
Catch {
    Write-Host "failed: $($_.exception.message)" -F Red
}

Try {
    $userData = @()
    $outPutFile = "$ScriptDir\AAD-GetUsersPasswordChangeDate_$timeStamp.csv"

    $domains = Get-MsolDomain

    foreach($domain in $domains) {

        $domainName = $domain.Name

        Write-Host "Loading Domain '$domainName'" -F Blue 
        # $userData = @()
        # $outPutFile = "$ScriptDir\AAD-GetUsersPasswordChangeDate_" + $domainName + "_" + "$timeStamp.csv"

        Write-Host "Loading Users ... " -F Blue -NoNewline
        $users = Get-MSOLUser -DomainName $domainName -All
        Write-Host "done" -F Green

        If($users) {
            Write-Host " - ($($users.Length)) users Found" -F green
       
            foreach($user in $users) {
        
                $upn = $($user.UserPrincipalName)
                $dn = $($user.DisplayName)
                $ut = $($user.UserType)
                $passChange = $($user.LastPasswordChangeTimestamp)
        
                # Write-host "$upn - $dn - $passChange"
        
                $tempOBJ = New-Object system.object
                $tempOBJ | add-member -type Noteproperty -name UPN -value $upn
                $tempOBJ | add-member -type Noteproperty -name DisplayName -value $dn
                $tempOBJ | add-member -type Noteproperty -name UserType -value $ut
                $tempOBJ | add-member -type Noteproperty -name DomainName -value $domainName 
                $tempOBJ | add-member -type Noteproperty -name LastPasswordChangeTimestamp -value $passChange
                $userData += $tempobj
        
            }
  

        } else {
            Write-Host " - No users Found" -F Red
        }
    }
    Try {
        Write-Host "Exporting Data ... " -F Blue -NoNewline
        $userData | Export-Csv $outPutFile -NoTypeInformation
        Write-Host "done" -F Green
    }
    Catch {
        Write-Host "failed: $($_.exception.message)" -F Red
    }
}
Catch {
    Write-Host "failed: $($_.exception.message)" -F Red
}

Write-Host "Disconnecting ... " -F Blue -NoNewline
[Microsoft.Online.Administration.Automation.ConnectMsolService]::ClearUserSessionState()
Write-Host "done" -F Green