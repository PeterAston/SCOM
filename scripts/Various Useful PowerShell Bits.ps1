#Get free disk space
Get-WmiObject -Class Win32_volume -computer $env:computername | Select-Object @{Name='Computer';Expression={$env:computername}},Driveletter, ` Label,@{Name='GB Free Space';Expression={"{0:N1}" -f ($_.freespace/1GB)}}, @{Name='GB Disk Size';Expression={"{0:N1}" -f ($_.capacity/1GB)}} | Format-Table

#Get Computer Uptime
Get-WMIObject Win32_OperatingSystem -computername $env:computername| Select-Object @{Name="Computername";Expression={$_.CSName}}, `
@{Name="LastBoot";Expression={$_.ConvertToDateTime($_.LastBootUpTime)}}, `
@{Name="Uptime";Expression={(Get-Date)- $_.ConvertToDateTime($_.LastBootUpTime)}}

#Get logged on user
$sessions = query session | Where-Object{ $_ -notmatch '^ SESSIONNAME' } | ForEach-Object{
    $item = "" | Select-Object "Active", "SessionName", "Username", "Id", "State"
    $item.Active = $_.Substring(0,1) -match '&gt;'
    $item.SessionName = $_.Substring(1,18).Trim()
    $item.Username = $_.Substring(19,20).Trim()
    $item.Id = $_.Substring(39,9).Trim()
    $item.State = $_.Substring(48,8).Trim()
    $item
    } 
    $sessions | Format-Table

#Set firewall off - run elevated
netsh advfirewall set allprofiles state off
netsh advfirewall show allprofile

#Set firewall on - run elevated
netsh advfirewall set allprofiles state on
netsh advfirewall show allprofile

#Get pending reboot
$key = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey("LocalMachine", $env:computername)
$subkey = $key.OpenSubKey("Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\")
$subkeys = $subkey.GetSubKeyNames()
$subkey.Close()
$key.Close()

If ($subkeys | Where-Object {$_ -eq "RebootPending"}) 
{
Write-Host "There is a pending reboot for "  $env:computername
Write-Host "You need to restart "  $env:computername
}
Else 
{
Write-Host "No reboot is pending for"  $env:computername
}

#Get SMB1 Status
$smb = Get-WindowsOptionalFeature -Online -FeatureName smb1protocol

#SMB1 on Server 2008
Get-Item HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters | ForEach-Object {Get-ItemProperty $_.pspath}

#ADLocked and Expired Users

Import-module ActiveDirectory
$jsonFilePath = 'D:\ScheduledTasks\SquaredUpExports\ADLockedAndExpiredUsers.json'
# storing raw active directory information in ArrayList
$rawLockedUersList = New-Object -TypeName System.Collections.ArrayList
Search-ADAccount -LockedOut | Select-Object -Property Name,SamAccountName,Enabled,PasswordNeverExpires,LockedOut,`
                                    LastLogonDate,PasswordExpired,DistinguishedName | ForEach-Object {
                                        if ($_.Enabled) {
                                            $null = $rawLockedUersList.Add($_)
                                        }
}
# helper function to get account lock out time
Function Get-ADUserLockedOutTime {
    param(
        [Parameter(Mandatory=$true)]
        [string]$userID
    )
    $time = Get-ADUser -Identity $_.SamAccountName -Properties AccountLockoutTime `
        | Select-Object @{Name = 'AccountLockoutTime'; Expression = {$_.AccountLockoutTime | Get-Date -Format "yyyy-MM-dd HH:mm"}}
    $rtnValue = $time | Select-Object -ExpandProperty AccountLockoutTime
    $rtnValue
} #End Function Get-ADUserLockedOutTime

# main function that sorts and formats the output to fit better in the dashboard
Function Get-ADUsersRecentLocked {
    param(
        [Parameter(Mandatory=$true)]
        [System.Collections.ArrayList]$userList
    )
    $tmpList = New-Object -TypeName System.Collections.ArrayList
    
    $tmpList = $userList | Sort-Object -Property LastLogonDate -Descending
    $tmpList = $tmpList  | Select-Object -Property Name,`
                    @{Name = 'UserId' ; Expression = { $_.SamAccountName }}, `
                    @{Name = 'OrgaUnit' ; Expression = { ($_.DistinguishedName -replace('(?i),DC=\w{1,}|CN=|\\','')) -replace(',OU=',' / ')} }, `
                    Enabled,PasswordExpired,PasswordNeverExpires, `
                    @{Name = 'LastLogonDate'; Expression = { $_.LastLogonDate | Get-Date -Format "yyyy-MM-dd HH:mm" }}, `
                    @{Name = 'AccountLockoutTime'; Expression = { (Get-ADUserLockedOutTime -userID $_.SamAccountName) }}
    $tmpList = $tmpList | Sort-Object -Property AccountLockoutTime -Descending                    
    
    # adding a flag character for improved visualization (alternating)
    $rtnList   = New-Object -TypeName System.Collections.ArrayList    
    $itmNumber = $tmpList.Count
    
    for ($counter = 0; $counter -lt $itmNumber; $counter ++) {
        $flack = ''
        if ($counter % 2) { 
            $flack = ''
        } else {
            $flack = '--'
        }
        $userProps = @{
            UserId               = $($flack + $tmpList[$counter].UserId)
            OrgaUnit             = $($flack + $tmpList[$counter].OrgaUnit)
            Enabled              = $($flack + $tmpList[$counter].Enabled)
            PasswordExpired      = $($flack + $tmpList[$counter].PasswordExpired)
            PasswordNeverExpires = $($flack + $tmpList[$counter].PasswordNeverExpires)
            LastLogonDate        = $($flack + $tmpList[$counter].LastLogonDate)
            AccountLockoutTime   = $($flack + $tmpList[$counter].AccountLockoutTime)
        }
        $userObject = New-Object -TypeName psobject -Property $userProps
        
        $null = $rtnList.Add($userObject)        
        Write-Host $userObject
    } #end for ()          
    $rtnList
} #End Function Get-ADUsersRecentLocked
if (Test-Path -Path $jsonFilePath) {
    Remove-Item -Path $jsonFilePath -Force
}
# exporting result to a JSON file and storing it on $jsonFilePath
Get-ADUsersRecentLocked -userList $rawLockedUersList  | ConvertTo-Json | Out-File $jsonFilePath -Encoding utf8 

#Install AD UAC
Add-WindowsFeature RSAT-ADDS-Tools


#Last logged on user
$profilesDir          = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList' | Select-Object -ExpandProperty ProfilesDirectory
Get-ChildItem -Path $profilesDir | Select-Object Name, LastWriteTime | Sort-Object -Property LastwriteTime -Descending | Select-Object -First 1
