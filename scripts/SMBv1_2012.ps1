#Server 2012 and higher SMBv1 Monitor
param([string]$Arguments)

$ScomAPI = New-Object -comObject "MOM.ScriptAPI"
$PropertyBag = $ScomAPI.CreatePropertyBag()


$smb = Get-WindowsOptionalFeature -Online -FeatureName smb1protocol
#$smbstatus = $smb.state
If ($smb.state -eq "Disabled")
{
Write-Host "SMB1 not detected"
    $PropertyBag.AddValue("State","OK")
   
}
else 
{

Write-Host "SMB1 Feature detected"
 $PropertyBag.AddValue("State","Error!")

}

# Send output to SCOM
$PropertyBag