function odMenu {
    try {
        $installChoice = readOption -options $([ordered]@{
                "get od version"     = "Get the version of Open Dental."
                "install od 22_3_61" = "Install Open Dental version 22.3.61."
                "install od 23_2_30" = "Install Open Dental version 23.2.30."
                "install od 23_3_66" = "Install Open Dental version 23.3.66."
                "install od 24_2_46" = "Install Open Dental version 24.2.46."
                "install od 24_3_41" = "Install Open Dental version 24.3.41."
                "install od 25_3_59" = "Install Open Dental version 25.3.59"
                "Exit"               = "Exit this script and go back to main command line."
            }) -prompt "Select which apps to install." -lineAfter

        switch ($installChoice) {
            0 { getODVersion }
            1 { installOD22361 }
            4 { installOD24341 }
            Default { readCommand }
        }
    } catch {
        # Display error message and end the script
        writeText -type "error" -text "isrInstallApps-$($_.InvocationInfo.ScriptLineNumber) | $($_.Exception.Message)" -lineAfter
    }
}

function getODVersion {
    (Get-Command "C:\Program Files (x86)\Open Dental\OpenDental.exe").FileVersionInfo.ProductVersion
}

function installOD22361 {

}

function installOD24341 {
    $url = "https://revouninstaller.b-cdn.net/ruf270/revosetup.exe"
    $appName = "OpenDental"
    $paths = @(
        "C:\Program Files (x86)\OpenDental\OpenDental.exe"
    )
    $installed = findExisting -Paths $paths -App $appName
    if (!$installed) { 
        installProgram -url $url -AppName $appName -Args "/VERYSILENT /NORESTART"
    }
}