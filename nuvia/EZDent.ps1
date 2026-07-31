function vatechMenu {
    try {
        $installChoice = readOption -options $([ordered]@{
                "get ezdent ver"    = "Get the EZDent version."
                "get ezserver ver"  = "The the EZServer version."
                "get ezdent config" = "Get the EZDent VTServerConfig."
                "Exit"              = "Exit this script and go back to main command line."
            }) -prompt "Select which apps to install." -lineAfter

        switch ($installChoice) {
            0 { getEZDentVersion }
            1 { getEZServerVersion }
            2 { getVTServerConfig }
            Default { readCommand }
        }
    } catch {
        # Display error message and end the script
        writeText -type "error" -text "$($MyInvocation.MyCommand.Name): $($_.InvocationInfo.ScriptLineNumber)-$($_.Exception.Message)" -lineAfter
    }
}

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