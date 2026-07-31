function getEZDentVersion {
    writeText -type "plain" -text "Searching for EZDent client version"

    $ezDentVersion = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*, HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object { $_.DisplayName -like "*EzDent*" } | Select-Object DisplayName, DisplayVersion

    if ($ezDentVersion) {
        writeText -type "plain" -text "EZDent Version: $ezDentVersion" -lineAfter
    } else {
        writeText -type "plain" -text "Could not find an installation of EZDent" -lineAfter
        readCommand
    }

    getVTServerConfig
}

function getEZServerVersion {
    $ezServerVersion = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*, 
    HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | 
    Where-Object { $_.DisplayName -like "*EzServer*" } | 
    Select-Object DisplayName, DisplayVersion

    if ($ezServerVersion) {
        writeText -type "plain" -text "EZDent Version: $ezServerVersion" -lineAfter
    } else {
        writeText -type "plain" -text "Could not find an installation of EZDent" -lineAfter
        readCommand
    }
}

function getVTServerConfig {
    $filePath = "C:\Program Files (x86)\VATECH\EzDent-i\Setting\VTServerConfig.ini"
    
    if (Test-Path $filePath) {
        writeText -type "plain" -text "VTServerConfig found:" -lineAfter
        Get-Content $filePath
    } else {
        writeText -type "plain" -text "VTServerConfig not found at: $filePath" -lineAfter
    }
}