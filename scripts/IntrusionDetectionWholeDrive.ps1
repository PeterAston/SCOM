#PowerShell script to look for specific files in a specific path and send an email if it finds anything.
#This is run as a Rule in SCOM targeted at a custom group containing servers of interest.
#To force a scan change the sync time in Overrides.
#Created by Dave MacMagic with hinderance from Pete Aston

#Required for SCOM
$ScomAPI = New-Object -comObject "MOM.ScriptAPI"
$PropertyBag = $ScomAPI.CreatePropertyBag()

#Path and files to search for
$email = ""
$path = "C:\"
$files = "\\XXXXXXXXXXXX\script$\scom\IoCs.txt"
$array = Get-Content $files

#Search the path recursively for the files in the array
foreach ($element in $array) {
     ($emailline = Get-ChildItem -Path $path -Recurse -Filter $element -ErrorAction SilentlyContinue -Force | select-object -Property FullName)

#Clean the filenames up a bit    
$email += $emailline
} 
$email2 = $email -replace "@{FullName=", "`r"
$email3 = $email2 -replace "}", ""
$subject = "Potentially Compromised System Detected: " + $env:COMPUTERNAME

#Main recipient
$recipients = "email.address.here"

#Send email to recipients and any BCC
Send-MailMessage -From "SCOM Intrusion Detection <notifications-scom@lists.bham.ac.uk>" -To $recipients -BCC "bcc.email.addresses.here" -Subject  $subject -Body $email3 -SmtpServer "smtp.xxx.xx.xx" 

# Send output to SCOM
$PropertyBag