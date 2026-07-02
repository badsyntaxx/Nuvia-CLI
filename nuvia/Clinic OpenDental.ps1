function odMenu {
    try {
        $installChoice = readOption -options $([ordered]@{
                "get version"     = "Get the version of Open Dental."
                "get config"      = "Get the Open Dental config."
                "install 22_3_61" = "Install Open Dental version 22.3.61."
                "install 23_2_30" = "Install Open Dental version 23.2.30."
                "install 23_3_66" = "Install Open Dental version 23.3.66."
                "install 24_2_46" = "Install Open Dental version 24.2.46."
                "install 24_3_41" = "Install Open Dental version 24.3.41."
                "install 25_3_59" = "Install Open Dental version 25.3.59"
                "Exit"            = "Exit this script and go back to main command line."
            }) -prompt "Select which apps to install." -lineAfter

        switch ($installChoice) {
            0 { getODVersion }
            1 { getODConfig }
            2 { install22361 }
            6 { install24341 }
            Default { readCommand }
        }
    } catch {
        # Display error message and end the script
        writeText -type "error" -text "$($MyInvocation.MyCommand.Name): $($_.InvocationInfo.ScriptLineNumber)-$($_.Exception.Message)" -lineAfter
    }
}

function getODVersion {
    $odVersion = (Get-Command "C:\Program Files (x86)\Open Dental\OpenDental.exe").FileVersionInfo.ProductVersion
    writeText -type "plain" -text "OpenDental Version:$odVersion" -lineAfter
    writeText -type "plain" -text "Also attempting to get DTX Studio version..." -lineAfter
    # Define the paths to check
    $pathsToCheck = @(
        "C:\Program Files\DTX Studio Clinic\DTXsync.exe",
        "C:\Program Files\DTX Studio\DTXStudio.exe", # Common name
        "C:\Program Files\DTX Studio Implant\DTXStudioImplant.exe", # Alternative
        "C:\Program Files\DTX Studio Lab\DTXStudioLab.exe" # Alternative
    )

    $found = $false
    foreach ($path in $pathsToCheck) {
        if (Test-Path $path) {
            try {
                $versionInfo = Get-ItemProperty -Path $path -ErrorAction Stop
                $version = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($path).FileVersion
                writeText -type "plain" -text "DTX Studio Version: $version" -lineAfter
                writeText -type "plain" -text "File path: $path" -lineAfter
                $found = $true
                break
            } catch {
                writeText -type "warning" -text "Could not read version information from $path" -lineAfter
            }
        }
    }

    if (-not $found) {
        writeText -type "warning" -text "Could not find the DTX Studio executable in the default paths." -lineAfter
    }
}

function getODConfig {
    Get-Content "C:\Program Files (x86)\Open Dental\FreeDentalConfig.xml"
}

function install22361 {

}

function install24341 {
    try {
        $url = "https://drive.google.com/uc?export=download&id=1P65zB-9kwZ3_LnZMMt90rwgRuKp7dJoG"

        # Define paths
        $tempDir = "C:\Temp"
        $zipPath = Join-Path -Path $tempDir -ChildPath "Setup_24_3_41.zip"  # FULL path with filename
        $exePath = Join-Path -Path $tempDir -ChildPath "Setup_24_3_41.exe"

        # Create directory if it doesn't exist
        if (!(Test-Path $tempDir)) {
            New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
            writeText -type "notice" -text "Created directory: $tempDir"
        }          

        # Check if OpenDental.exe already exists
        if (!(Test-Path $exePath)) {
            # Download the zip file - pass the FULL file path
            if (getDownload -url $url -target $zipPath) {
                # Verify the zip file was downloaded
                if (Test-Path $zipPath) {
                    # Extract the zip file
                    Expand-Archive -Path $zipPath -DestinationPath $tempDir -Force
                        
                    $appName = "OpenDental"
                    $paths = @(
                        "C:\Program Files (x86)\OpenDental\OpenDental.exe"
                    )
                    $installed = findExisting -Paths $paths -App $appName
                    if (!$installed) { 
                        installProgram -url $url -AppName $appName -Args "/silent"
                    }
                        
                    writeText -type "success" -text "OpenDental.exe has been placed in: $tempDir"
                } else {
                    writeText -type "error" -text "Download failed or zip file not found at: $zipPath"
                }
            } else {
                writeText -type "error" -text "Failed to download OpenDental.zip"
            }
        } else {
            writeText -type "notice" -text "OpenDental.exe already exists in: $tempDir. Skipping download and extraction."
        }
    } catch {
        writeText -type "error" -text "$($MyInvocation.MyCommand.Name): $($_.InvocationInfo.ScriptLineNumber)-$($_.Exception.Message)" -lineAfter
    }
    
}