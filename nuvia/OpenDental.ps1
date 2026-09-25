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
            Default { return }
        }
    } catch {
        writeText -type "error" -text "$($_.Exception.Message) ($($MyInvocation.MyCommand.Name)-$($_.InvocationInfo.ScriptLineNumber))"
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
                    Get-ItemProperty -Path $path -ErrorAction Stop
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
    } catch {
        writeText -type "error" -text "$($_.Exception.Message) ($($MyInvocation.MyCommand.Name)-$($_.InvocationInfo.ScriptLineNumber))"
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
        writeText -type "error" -text "$($_.Exception.Message) ($($MyInvocation.MyCommand.Name)-$($_.InvocationInfo.ScriptLineNumber))"
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
        writeText -type "error" -text "$($_.Exception.Message) ($($MyInvocation.MyCommand.Name)-$($_.InvocationInfo.ScriptLineNumber))"
    } finally {
        if (Get-PSDrive -Name $driveName -ErrorAction SilentlyContinue) {
            Remove-PSDrive -Name $driveName -ErrorAction SilentlyContinue
            writeText -type "plain" -text "Disconnected from $targetComputer."
        }
        if ($targetComputer) {
            writeText -type "notice" -text "DON'T FORGET TO DISABLE THE ADMIN ACCOUNT ON $targetComputer."
        }
    }
}

function enableAdminNetShare {
    try {
        # --- Find the built-in Administrator (SID ends in -500, works even if renamed) ---
        $admin = Get-LocalUser | Where-Object { $_.SID.Value -like "S-1-5-21-*-500" }
        if (-not $admin) {
            throw "Could not find the built-in Administrator account."
        }
        writeText -type "plain" -text "Found built-in admin account: $($admin.Name)"

        # --- Get and confirm password ---
        $pw1 = readInput -prompt "New Administrator password:" -isSecure
        $pw2 = readInput -prompt "Confirm password:" -isSecure
        if (-not $pw1 -or $pw1.Length -eq 0) {
            throw "Password cannot be empty (blank passwords are blocked over the network)."
        }
        $plain1 = [System.Net.NetworkCredential]::new("", $pw1).Password
        $plain2 = [System.Net.NetworkCredential]::new("", $pw2).Password
        $match = $plain1 -ceq $plain2
        $plain1 = $null; $plain2 = $null
        if (-not $match) {
            throw "Passwords do not match."
        }

        # --- Set password and enable the account ---
        writeText -type "plain" -text "Setting password..."
        Set-LocalUser -SID $admin.SID -Password $pw1 -ErrorAction Stop

        writeText -type "plain" -text "Enabling account..."
        Enable-LocalUser -SID $admin.SID -ErrorAction Stop

        if (-not (Get-LocalUser -SID $admin.SID).Enabled) {
            throw "Account $($admin.Name) still shows as disabled after enabling."
        }
        writeText -type "plain" -text "Account $($admin.Name) is enabled."

        # --- Network profile check (sharing rules shouldn't be opened on Public) ---
        $profiles = Get-NetConnectionProfile
        $public = $profiles | Where-Object { $_.NetworkCategory -eq "Public" }
        if ($public) {
            writeText -type "error" -text ("Warning: network '$($public.Name -join ', ')' is set to Public. " +
                "File sharing rules are only enabled for Domain/Private, so remote access may still fail. " +
                "Change it with: Set-NetConnectionProfile -InterfaceAlias '<name>' -NetworkCategory Private")
        }

        # --- Enable File and Printer Sharing firewall rules (Domain/Private only) ---
        # Group ID is language-neutral, unlike the display name
        writeText -type "plain" -text "Enabling File and Printer Sharing firewall rules..."
        $rules = Get-NetFirewallRule -Group "@FirewallAPI.dll,-28502" -ErrorAction Stop |
        Where-Object { $_.Profile.ToString() -match "Domain|Private|Any" }
        if (-not $rules) {
            throw "No File and Printer Sharing firewall rules found."
        }
        $rules | Enable-NetFirewallRule -ErrorAction Stop

        $smbRule = Get-NetFirewallRule -Group "@FirewallAPI.dll,-28502" |
        Where-Object { $_.Enabled -eq "True" -and $_.DisplayName -like "*SMB-In*" }
        if (-not $smbRule) {
            throw "SMB-In firewall rule is not enabled after update."
        }

        # --- Make sure the Server service is running ---
        writeText -type "plain" -text "Checking Server (LanmanServer) service..."
        Set-Service -Name LanmanServer -StartupType Automatic -ErrorAction Stop
        if ((Get-Service LanmanServer).Status -ne "Running") {
            Start-Service LanmanServer -ErrorAction Stop
        }

        # --- Make sure admin shares aren't disabled ---
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters"
        $autoShare = (Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue).AutoShareWks
        if ($autoShare -eq 0) {
            writeText -type "plain" -text "Admin shares were disabled; re-enabling (restarting Server service)..."
            Set-ItemProperty -Path $regPath -Name AutoShareWks -Value 1 -ErrorAction Stop
            Restart-Service LanmanServer -Force -ErrorAction Stop
        }

        # --- Verify C$ exists ---
        if (-not (Get-SmbShare -Name 'C$' -ErrorAction SilentlyContinue)) {
            throw "The C$ admin share is not present."
        }

        writeText -type "success" -text "$env:COMPUTERNAME is ready. Connect as $env:COMPUTERNAME\$($admin.Name)."
        writeText -type "notice" -text "DON'T FORGET TO DISABLE THE ADMIN ACCOUNT WHEN DONE."
    } catch {
        writeText -type "error" -text "$($_.Exception.Message) ($($MyInvocation.MyCommand.Name)-$($_.InvocationInfo.ScriptLineNumber))"
    }
}

function disableAdminNetShare {
    try {
        # --- Find the built-in Administrator by SID ---
        $admin = Get-LocalUser | Where-Object { $_.SID.Value -like "S-1-5-21-*-500" }
        if (-not $admin) {
            throw "Could not find the built-in Administrator account."
        }

        if (-not $admin.Enabled) {
            writeText -type "success" -text "Account $($admin.Name) is already disabled. Nothing to do."
            return
        }

        # --- Lockout safety: make sure another admin account remains ---
        $otherAdmins = @(Get-LocalGroupMember -SID "S-1-5-32-544" -ErrorAction Stop |
            Where-Object { $_.SID.Value -ne $admin.SID.Value })
        $usableOthers = $otherAdmins | Where-Object {
            $_.PrincipalSource -ne "Local" -or
            (Get-LocalUser -SID $_.SID -ErrorAction SilentlyContinue).Enabled
        }
        if (-not $usableOthers) {
            throw "No other enabled administrator account exists. Disabling $($admin.Name) could lock you out of admin access."
        }

        # --- Warn if we're currently signed in as this account ---
        if ($env:USERNAME -eq $admin.Name) {
            writeText -type "error" -text ("Warning: you are signed in as $($admin.Name). " +
                "This session will keep working, but you won't be able to sign in with it again.")
        }

        # --- Disable and verify ---
        writeText -type "plain" -text "Disabling $($admin.Name)..."
        Disable-LocalUser -SID $admin.SID -ErrorAction Stop

        if ((Get-LocalUser -SID $admin.SID).Enabled) {
            throw "Account $($admin.Name) still shows as enabled after disabling."
        }

        writeText -type "success" -text "Account $($admin.Name) on $env:COMPUTERNAME is disabled."
    } catch {
        writeText -type "error" -text "$($_.Exception.Message) ($($MyInvocation.MyCommand.Name)-$($_.InvocationInfo.ScriptLineNumber))"
    }
}