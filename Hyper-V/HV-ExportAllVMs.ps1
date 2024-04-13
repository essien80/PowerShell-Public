$expDest = "d:\Export"
$moveDest = ""


$vms = Get-Vm | ? { $_.State -eq "Off" -and $_.Notes -notLike "*Exported*"  }
Write-Host "Found $($vms.Length) VM(s)" -F Green

foreach($vm in $vms) {

	Write-Host " - Processing $($vm.Name)" -F Green

    Export-Vm $vm -Path $dest -ErrorAction Stop

    Write-Host " - Moving Export: $($vm.Name) ... " -F Green	-NoNewLine
    Move-Item "$expDest\$($vm.Name)" -Destination $moveDest -ErrorAction Stop

    Write-Host "done" -F White

    Set-VM $vm -Notes "Exported"

}