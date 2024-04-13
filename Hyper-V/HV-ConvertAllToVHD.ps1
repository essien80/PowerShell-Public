## This Script will convert all offline Hyper-V Disk to VHD and move the converted disk to a network share.

Write-Host "Loading VMs ... " -F Green -NoNewline
try {
    $vms = Get-Vm | ? { $_.State -eq "Off" -and $_.Name -ne "ad-dc01-dev" -and $_.Notes -notLike "*Converted*" }

    Write-Host "done" -F White
}
catch {
    Write-Host "Error: $($_.exception.message)" -F Red
}

$dest = ""
$convPath = "D:\conversion"

foreach($vm in $vms) {
	
    $disks = $vm.HardDrives
    $exportResult = 0

	Write-Host "Found $($vms.Length) VM(s)" -F Green
	Write-Host " - Processing $($vm.Name)" -F Green
	Write-Host " -- Found $($disks.Length) Disks" -F Green

	if($disks){
        foreach($disk in $disks) {
            
            $sid = $disk.Path.Split("\").Length - 1
            $fileName = $disk.Path.Split("\")[$sid].Split(".")[0]
			$convertedFileName = "$($fileName).vhd"

            Write-Host " --- Converting disk: $($fileName) ... " -F Green	-NoNewLine
        
            try {
                Convert-VHD -Path "$($disk.Path)" -DestinationPath "D:\conversion\$convertedFileName" 

                Write-Host "done" -F White
                $exportResult++

                Write-Host " --- Moving Converted disk: $($convertedFileName) ... " -F Green	-NoNewLine
                try {
					Start-Sleep -Seconds 2

                    Move-Item "D:\conversion\$convertedFileName" -Destination $dest
    
                    Write-Host "done" -F White
                    $exportResult++
                }
                catch {
                    Write-Host "Error: $($_.exception.message)" -F Red
                    $exportResult--
                }
                
            }
            catch {
                Write-Host "Error: $($_.exception.message)" -F Red
                $exportResult--
            }
            
           
            
        }
    }
	
	# Write-Host "Result: $exportResult"
	
    if($exportResult -ge 2) {
        Write-Host " -- Marking VM Converted ... " -NoNewline -F Green

        try {
            Set-VM $vm -Notes "Converted"

            Write-Host "done" -F White
        }
        catch {
            Write-Host "Error: $($_.exception.message)" -F Red
        }
    }
}