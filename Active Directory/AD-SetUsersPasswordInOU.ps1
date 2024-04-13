$OUpath = 'OU=Sample Users,OU=Accounts,DC=CONTOSO,DC=COM'

$users = Get-ADUser -Filter * -SearchBase $OUpath

foreach($user in $users) {

	Set-ADAccountPassword -Identity $user -NewPassword (ConvertTo-SecureString -AsPlainText "password" -Force)
	Set-ADUser -Identity $user -CannotChangePassword $True -PasswordNeverExpires $True

}