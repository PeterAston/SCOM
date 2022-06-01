$DaysInactive = 90
$time = (Get-Date).Adddays( -($DaysInactive))
Get-ADComputer -Filter{Name -Like "ITS-*-*" -and LastLogonDate -lt $time} -Properties * | select Name, LastLogonDate | Export-CSV C:\users\***\its-*-*_vms.csv -NoTypeInformation