<# 
checkServiceStatus
The purpose of this script is to check the status of a service, start it if has stopped and send
an alert.
-----------------------
Nick Ortiz
2017-09-01: Initial version.
2019-06-03: Updated to create log file in execution directory.
-----------------------

Command line paramter example:
checkServiceStatus "ServiceName"
 #>
Param(
	[Parameter(Mandatory=$True)][string[]]$serviceName
)

$TimeStamp = (Get-Date).ToString('yyyy-MM-dd HH:mm')

$ScriptPath = $MyInvocation.MyCommand.Path
$ScriptDir  = Split-Path -Parent $ScriptPath

# Email Alert Function
 function sentAlert {
	param($serviceName)
	
	# Set up the email variables
	$mailServer = ""
	$mailFrom = ""
	$mailTo = ""
	$mailSubject = "ALERT: The service '$serviceName' was not running and has been automatically restarted."
	$mailBody = "Please review the servers for crash data and validate services have been restored." | Out-String
			
	# Send the Email
	Send-MailMessage -SmtpServer $mailServer -Subject $mailSubject -From $mailFrom -To $mailTo -Priority "High" -Body $mailBody -BodyAsHtml
	"$TimeStamp - '$serviceName' started because it was not running." >> $ScriptDir\checkServiceStatus.log
}

# Check status of service, restart service and sent alert if not running.
function checkService {
	param($serviceName)
	
	$arrService = Get-Service -Name $serviceName
	
	if($arrService.Status -ne "Running") {
		#write-host "Not Running"
		sentAlert($serviceName)
		Start-Service $serviceName
	}

}

if($serviceName.Length -gt 1) {
	foreach($service in $serviceName) {
		checkService($service)
	}

} else {
	checkService($serviceName)
}