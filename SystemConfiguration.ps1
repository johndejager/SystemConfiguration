### Variables
$TimeStamp = Get-Date
$ScriptDir = "C:\SystemConfiguration\"
$GPODir = $ScriptDir + "\Extracted\SystemConfiguration\GPO_Backup"
$ZIPFileName = 'SystemConfiguration.ZIP'
# Create script Folder
New-Item -Path $ScriptDir -ItemType Directory -ErrorAction SilentlyContinue
# Create Folder for logging
$LogDir = $ScriptDir + "\Log\"
$LogFile = $LogDir +  "Script.log"
New-Item -Path $LogDir -ItemType Directory -ErrorAction SilentlyContinue

# Functions
Function LogWrite {
    Param ([string]$logstring)
    Add-content $Logfile -value $logstring 
}

# Starting script
$TimeStamp = Get-Date
LogWrite "$TimeStamp - Script started"

# Search for the latest ZIP File
$customScriptPath = 'C:\Packages\Plugins\Microsoft.Compute.CustomScriptExtension\1.9\Downloads' 
$ZIPFile = Get-Childitem –Path $customScriptPath -Include $ZIPFileName -Recurse | Select-Object -Last 1
Copy-Item $ZIPFile $ScriptDir

### Proces the ZIP file
$ZIPSrc = $ScriptDir + $ZIPFileName
$ZIPDst = $ScriptDir + 'Extracted\'
New-Item -Path $ZIPDst -ItemType Directory -ErrorAction SilentlyContinue
$TimeStamp = Get-Date
LogWrite "$timeStamp - Zip file = $ZIPFile"
LogWrite "$TimeStamp - ZIP Source is:$ZIPSrc"
LogWrite "$TimeStamp - ZIP Destination is:$ZIPDst"
# Unzip the file 
Add-Type -AssemblyName System.IO.Compression.FileSystem
function Unzip {
    param([string]$zipfile, [string]$outpath)

    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
}
Unzip "$ZIPSrc" "$ZIPDst"

### Get OS Version
$OSVersion = (gwmi win32_operatingsystem).caption

if ($OSVersion -eq "Microsoft Windows Server 2012 R2 Datacenter") {
    $TimeStamp = Get-Date
    Write-Host "$TimeStamp OS Version is Microsoft Windows Server 2012 R2 Datacenter"
    LogWrite "$TimeStamp OS Version is Microsoft Windows Server 2012 R2 Datacenter"

    ### MSS Settings - Disable AutoAdminLogon - CCE-ID - CCE-37067-6
    $TimeStamp = Get-Date
    LogWrite "$TimeStamp Set MSS Settings - Disable AutoAdminLogon - CCE-ID - CCE-37067-6"
    $RegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\"
    $RegName = "AutoAdminLogon"
    $RegValue = "0"
    New-ItemProperty -Path $RegPath -Name $RegName -Value $RegValue


    ### MSS Settings - SafeDllSearchMode - CCE-ID - CCE-36351-5
    $TimeStamp = Get-Date
    LogWrite "$TimeStamp Set MSS Settings - SafeDllSearchMode - CCE-ID - CCE-36351-5"
    $RegPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\"
    $RegName = "SafeDllSearchMode"
    $RegValue = "1"
    New-ItemProperty -Path $RegPath -Name $RegName -Value $RegValue -PropertyType "DWord"


    ### MSS Settings - Screen Saver GracePeriod - CCE-ID - CCE-37993-3
    $TimeStamp = Get-Date
    LogWrite "$TimeStamp Set MSS Settings - Screen Saver GracePeriod - CCE-ID - CCE-37993-3"
    $RegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\"
    $RegName = "ScreenSaverGracePeriod"
    $RegValue = "5"
    New-ItemProperty -Path $RegPath -Name $RegName -Value $RegValue


    ### MSS Settings - Disable IP SourceRouting (IPv6) - CCE-ID - CCE-36871-2
    $TimeStamp = Get-Date
    LogWrite "$TimeStamp Set MSS Settings - Disable IP SourceRouting (IPv6) - CCE-ID - CCE-36871-2"
    $RegPath = "HKLM:\System\CurrentControlSet\Services\Tcpip6\Parameters"
    $RegName = "DisableIPSourceRouting"
    $RegValue = "2"
    New-ItemProperty -Path $RegPath -Name $RegName -Value $RegValue -PropertyType "DWord"


    ### MSS Settings - Disable IP SourceRouting (IPv4) - CCE-ID - CCE-36535-3
    $TimeStamp = Get-Date
    LogWrite "$TimeStamp Set MSS Settings - Disable IP SourceRouting (IPv4) - CCE-ID - CCE-36535-3"
    $RegPath = "HKLM:\System\CurrentControlSet\Services\Tcpip\Parameters"
    $RegName = "DisableIPSourceRouting"
    $RegValue = "2"
    New-ItemProperty -Path $RegPath -Name $RegName -Value $RegValue -PropertyType "DWord"

    ### MSS Settings - Eventlog WarningLevel - CCE-ID - CCE-36880-3
    $TimeStamp = Get-Date
    LogWrite "$TimeStamp Set MSS Settings - Eventlog WarningLevel - CCE-ID - CCE-36880-3"
    $RegPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Eventlog\Security"
    $RegName = "WarningLevel"
    $RegValue = "90"
    New-ItemProperty -Path $RegPath -Name $RegName -Value $RegValue -PropertyType "DWord"


    ### Restore GPO Backup with OS vulnerability fixes
    $TimeStamp = Get-Date
    LogWrite "$TimeStamp Started with GPO Restore"
    $LGPOCMD = $GPODir + "\LGPO\LGPO.exe"
    $GPOPath = $GPODir + "\GPO_BACKUP\WS-2012R2"
    $ARG = "/g", $GPOPath
    Start-Process -FilePath $LGPOCMD -ArgumentList $ARG

}
elseif ($OSVersion -eq "Microsoft Windows Server 2016 Datacenter") {
    $TimeStamp = Get-Date
    Write-Host "$TimeStamp OS Version is Microsoft Windows Server 2016 Datacenter"
    LogWrite "$TimeStamp OS Version is Microsoft Windows Server 2016 Datacenter"

    ### Disable SMBv1
    $TimeStamp = Get-Date
    LogWrite "$TimeStamp Disable SMBv10"
    Set-SmbServerConfiguration -EnableSMB1Protocol $false -Force

    ### Disable Windows Search Service
    $TimeStamp = Get-Date
    LogWrite "$TimeStamp Disable Windows Search Service"
    $Service = Get-Service -Name 'WSearch'
    if ($Service.Status -eq 'Running') {
        $Service | Stop-Service -Force
        $Service | Set-Service -StartupType Disable
        LogWrite "$TimeStamp Disabled Windows Search Service and set StartupType Disable"
    }
    else {
        LogWrite "$TimeStamp Windows Search Service was not running"   
    }
  
    ### Enable Windows Error Reporting
    $TimeStamp = Get-Date
    LogWrite "$TimeStamp Enable Windows Error Reporting"
    $ErrorReport = Get-WindowsErrorReporting
    if ($ErrorReport -eq 'Enabled') {
        LogWrite "$TimeStamp Windows Error Reporting is already enabled"
    }
    else {
        Enable-WindowsErrorReporting
        LogWrite "$TimeStamp Windows Error Reporting will be enabled"   
    }
    ### Restore GPO Backup with OS vulnerability fixes
    $TimeStamp = Get-Date
    LogWrite "$TimeStamp Started with GPO Restore"
    $LGPOCMD = $GPODir + "\LGPO\LGPO.exe"
    $GPOPath = $GPODir + "\GPO_BACKUP\WS-2016"
    $ARG = "/g", $GPOPath
    Start-Process -FilePath $LGPOCMD -ArgumentList $ARG
}
