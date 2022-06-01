#Required for SCOM
$ScomAPI = New-Object -comObject "MOM.ScriptAPI"
$PropertyBag = $ScomAPI.CreatePropertyBag()

#Search for SolarWinds.Orion.Core.BusinessLayer.dll:
$orion = Get-ChildItem -path 'C:\Program Files\', C:\Windows -Include 'SolarWinds.Orion.Core.BusinessLayer.dll' -File -Recurse -Force -ErrorAction SilentlyContinue

#Search for netsetupsvc.dll:
$netsup = Get-ChildItem -path 'C:\windows\syswow64' -Include 'netsetupsvc.dll' -File -Recurse -Force -ErrorAction SilentlyContinue
$result +=$orion
$result +=$netsup

$message = If ($null -ne $orion -Or $netsup) {$email} Else {$orion -Or $netsup}

#Email details
$recipients = "recipient@bham.ac.uk"
$email = "No problems"
$subject = "SolarWinds vulnerabilty checker " + $env:COMPUTERNAME


#Send email to recipient
Send-MailMessage -From "SCOM Intrusion Detection <notifications-scom@lists.bham.ac.uk>" -To $recipients -Subject  $subject -Body "Result = " $message -SmtpServer "smtp.bham.ac.uk" 

# Send output to SCOM
$PropertyBag