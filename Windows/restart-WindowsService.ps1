<# 
Restart-windowsService
Real Simple script to restart an array of services.

-----------------------
Nick Ortiz
2019-04-10: Initial version.
-----------------------

 #>

$services = @("SharePoint Timer Service")

foreach($service in $services) {
    write-host "Restarting: "$service
    Restart-Service -Name $service
}
