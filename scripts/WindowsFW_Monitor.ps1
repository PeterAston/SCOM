param([string]$Arguments)

$ScomAPI = New-Object -comObject "MOM.ScriptAPI"
$PropertyBag = $ScomAPI.CreatePropertyBag()

#get Windows Domain FW state from Registry
$FWState=(Get-Itemproperty Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\DomainProfile).EnableFirewall
$PropertyBag.AddValue("FWState",$fwstate)
#Write-Host $FWState

$fwoff = Get-WinEvent -LogName "Microsoft-Windows-Windows Firewall With Advanced Security/Firewall" | Where-Object {$_.Id -eq 2003 -and $_.Message -clike "*Enable*" -and $_.Message -clike "*No*"}
$SID = $fwoff.properties.value.value
$objSID = New-Object System.Security.Principal.SecurityIdentifier($SID)
$objUser = $objSID.Translate([System.Security.Principal.NTAccount])
$PropertyBag.AddValue("username: ", $objUser.Value)
#Write-Host $objUser.value
             
# Send output to SCOM
$PropertyBag