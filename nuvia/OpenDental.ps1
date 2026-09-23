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
        writeText -type "error" -text "$($MyInvocation.MyCommand.Name)-$($_.InvocationInfo.ScriptLineNumber)"
        log -msg "$($MyInvocation.MyCommand.Name)-$($_.InvocationInfo.ScriptLineNumber):$($_.Exception.Message)" -lvl "ERROR"
    }
}

function getODVersion {
    try {
        $odVersion = (Get-Command "C:\Program Files (x86)\Open Dental\OpenDental.exe" -ErrorAction SilentlyContinue).FileVersionInfo.ProductVersion

        if ($odVersion) {
            writeText -type "plain" -text "OpenDental Version: $odVersion" -lineAfter
        } else {
            writeText -type "plain" -text "Could not find an installation of OD" -lineAfter
            readCommand
        }

        # Define the paths to check
        $dtxPaths = @(
            "C:\Program Files\DTX Studio Clinic\DTXsync.exe",
            "C:\Program Files\DTX Studio\DTXStudio.exe", # Common name
            "C:\Program Files\DTX Studio Implant\DTXStudioImplant.exe", # Alternative
            "C:\Program Files\DTX Studio Lab\DTXStudioLab.exe" # Alternative
        )

        $found = $false
        foreach ($path in $dtxPaths) {
            if (Test-Path $path) {
                try {
                    $versionInfo = Get-ItemProperty -Path $path -ErrorAction Stop
                    $version = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($path).FileVersion
                    writeText -type "plain" -text "DTX Studio Version: $version" -lineAfter
                    $found = $true
                    break
                } catch {
                    writeText -type "notice" -text "Could not read version information from $path" -lineAfter
                }
            }
        }

        if (-not $found) {
            writeText -type "notice" -text "Could not find the DTX Studio executable in the default paths." -lineAfter
        }

        getODConfig
    } catch {
        writeText -type "error" -text "$($MyInvocation.MyCommand.Name)-$($_.InvocationInfo.ScriptLineNumber)"
        log -msg "$($MyInvocation.MyCommand.Name)-$($_.InvocationInfo.ScriptLineNumber):$($_.Exception.Message)" -lvl "ERROR"
    }
    
}

function getODConfig {
    getODVersion
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
                        installApp -url $url -AppName $appName -Args "/silent"
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
        writeText -type "error" -text "$($MyInvocation.MyCommand.Name)-$($_.InvocationInfo.ScriptLineNumber)"
        log -msg "$($MyInvocation.MyCommand.Name)-$($_.InvocationInfo.ScriptLineNumber):$($_.Exception.Message)" -lvl "ERROR"
    }
}

function findODConfig {
    $driveName = "ODTarget"
    $targetComputer = $null

    try {
        # --- Input ---
        $targetComputer = readInput -prompt "Target Computer:"
        $password = readInput -prompt "Target Computer Password:" -isSecure

        # --- Connectivity ---
        writeText -type "plain" -text "Testing connectivity to $targetComputer..."
        if (-not (Test-Connection -ComputerName $targetComputer -Count 2 -Quiet)) {
            throw "$targetComputer did not respond to ping. Check the name, that it's powered on, and on the network."
        }

        writeText -type "plain" -text "Testing SMB (port 445)..."
        $smb = Test-NetConnection -ComputerName $targetComputer -Port 445 -WarningAction SilentlyContinue
        if (-not $smb.TcpTestSucceeded) {
            throw "Port 445 is not reachable on $targetComputer. File sharing may be off or a firewall is blocking it."
        }

        # --- Authenticate and map ---
        writeText -type "plain" -text "Connecting to \\$targetComputer\C$ ..."
        $cred = New-Object System.Management.Automation.PSCredential("$targetComputer\Administrator", $password)
        try {
            New-PSDrive -Name $driveName -PSProvider FileSystem -Root "\\$targetComputer\C$" -Credential $cred -Scope Global -ErrorAction Stop | Out-Null
        } catch {
            throw ("Could not connect to the admin share: $($_.Exception.Message) " +
                "Common causes: Administrator account disabled, wrong password, " +
                "or remote UAC filtering (LocalAccountTokenFilterPolicy).")
        }

        # --- Paths ---
        $source = "${driveName}:\Program Files (x86)\Open Dental\FreeDentalConfig.xml"
        $destDir = "C:\Program Files (x86)\Open Dental"
        $dest = Join-Path $destDir "FreeDentalConfig.xml"

        # --- Source check ---
        writeText -type "plain" -text "Checking source file..."
        if (-not (Test-Path -LiteralPath $source)) {
            throw "Source not found: $source (is Open Dental installed on $targetComputer?)"
        }
        $srcInfo = Get-Item -LiteralPath $source
        writeText -type "plain" -text "Source OK ($($srcInfo.Length) bytes)"

        # --- Destination prep ---
        if (-not (Test-Path -LiteralPath $destDir)) {
            writeText -type "plain" -text "Creating destination folder $destDir"
            New-Item -ItemType Directory -Path $destDir -Force -ErrorAction Stop | Out-Null
        }

        if (Test-Path -LiteralPath $dest) {
            $backup = "$dest.bak_$(Get-Date -Format yyyyMMdd_HHmmss)"
            writeText -type "plain" -text "Existing config found; backing it up to $backup"
            Copy-Item -LiteralPath $dest -Destination $backup -Force -ErrorAction Stop
        }

        # --- Copy ---
        writeText -type "plain" -text "Copying..."
        Copy-Item -LiteralPath $source -Destination $dest -Force -ErrorAction Stop

        # --- Verify ---
        writeText -type "plain" -text "Verifying copy..."
        $dstInfo = Get-Item -LiteralPath $dest
        $srcHash = (Get-FileHash -LiteralPath $source -Algorithm SHA256 -ErrorAction Stop).Hash
        $dstHash = (Get-FileHash -LiteralPath $dest   -Algorithm SHA256 -ErrorAction Stop).Hash
        if ($srcInfo.Length -ne $dstInfo.Length -or $srcHash -ne $dstHash) {
            throw "Verification failed: the copied file does not match the source."
        }

        writeText -type "success" -text "Success. Config copied from $targetComputer and verified (SHA256 match)."
    } catch {
        $where = "$($MyInvocation.MyCommand.Name)-$($_.InvocationInfo.ScriptLineNumber)"
        writeText -type "error" -text "$($_.Exception.Message) [$where]"
        log -msg "${where}: $($_.Exception.Message)" -lvl "ERROR"
    } finally {
        if (Get-PSDrive -Name $driveName -ErrorAction SilentlyContinue) {
            Remove-PSDrive -Name $driveName -ErrorAction SilentlyContinue
            writeText -type "plain" -text "Disconnected from $targetComputer."
        }
        if ($targetComputer) {
            writeText -type "plain" -text "DON'T FORGET TO DISABLE THE ADMIN ACCOUNT ON $targetComputer."
        }
    }
}