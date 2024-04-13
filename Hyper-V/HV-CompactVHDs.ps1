<# 
HV-CompactVHDs
The purpose of this script is to compact all of the Hyper-V Disks
-----------------------
Nick Ortiz 
2017-10-06: Initial version.
-----------------------

 #>
 
 $vms = Get-VM 

 foreach($vm in $vms) {
     
     $sn = $vm.Name
     $vmState = $vm.State
     
     # Shutdown server if it's running.
     if($vmState -eq "Running") {
         stop-vm $vm
     }
     
     # Load disk information
     $disks = Get-VMHardDiskDrive $sn
     
     # Compact each disk
     foreach($disk in $disks) {
         $diskPath = $disk.Path
         
         Optimize-VHD -path $diskPath
     }
     
     # Resume VM
     if($vmState -eq "Running" ) {
         start-vm $vm
     }
 }
 
 