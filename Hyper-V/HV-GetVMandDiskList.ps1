get-vm | % { write-host "$($_.VMName)"; foreach($hd in $_.HardDrives) { Write-Host " - $($hd.Path)" } }