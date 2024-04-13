<# EXO-RemoveEventsFromAllCalendars.ps1
The purpose of this script is to search all user calendars for specific events and remove them.

-----------------------
Nick Ortiz, Quisitive. 
2024-02-07: Initial version

By default the script will run in scan mode but you can change  removal by updateding:
$removeItems = $false

to 

$removeItems = $true

#########
Required Modules:

	Install-Module Microsft.Graph

* When logging in you'll be prompted to approve permissions to ReadWrite Calendars.
#>

######## Parameters
$eventFilter = "subject eq 'Special Event' or subject eq 'Super Secret Event'"
$removeItems = $false

######## Start Logic

## Set up transcript log.
## i.e. RemoveEventsFromAllCalendars_transcript_020724_130550.txt
$transcriptFile = "RemoveEventsFromAllCalendars_transcript_{0:MMddyy}_{0:HHmmss}.txt" -f (Get-Date)
Start-Transcript -path $transcriptFile

## Connect to Microsoft Graph with ReadWrite access
Connect-MgGraph -Scopes Calendars.ReadWrite -NoWelcome

## Load all the users in the Org
$users = Get-MGUser -All

## Process each user
foreach($user in $users) {
	
	## Store the UPN
	$uid = $user.UserPrincipalName
	
	## Load calendars for the current user, supress errors for accounts without an Exchange license.
	$userCalendars = Get-MGUserCalendar -UserId $uid -All -ErrorAction SilentlyContinue 
	
	## Proceed if calendars found
	if($userCalendars){
		
		Write-Host "Calendars found for: $($uid)"
	
		## Process each of the user's calendars
		foreach($userCalendar in $userCalendars) {
			
			## Store current calendar name and ID
			$calId = $userCalendar.Id
			$calName = $userCalendar.Name

			# Write-Host " - Checking Calendar: $($calName) - ($($calId))"
			Write-Host " - Checking Calendar: $($calName)"
			
			## Check for events based on configured filter
			$calendarEvents = Get-MgUserCalendarEvent -userid $uid -CalendarId $calId -Filter "$eventFilter"
			
			## Proceed if events meeting the criteria were found
			if($calendarEvents) {
				
				## Process each event
				foreach($calendarEvent in $calendarEvents) {
					
					## Store current event subject and id
					$eventName = $calendarEvent.Subject
					$eventId = $calendarEvent.Id
					
					Write-Host " -- Found Event: $($eventName)"
					
					## Remove event if enable.
					if($removeItems -eq $true){
						
						Write-Host " --- Event Removed" -F Yellow

						## Revove event
						Remove-MgUserEvent -UserId $uid -EventId $eventId
						
					}
				}
			}
		}
	}
}

## Disconnect from Graph
$disconnect = Disconnect-MgGraph

## Stop logging
Stop-Transcript