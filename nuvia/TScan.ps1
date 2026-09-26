function installTscan {
    # Silent-install switch for Tekscan's setup.exe. Confirm against the vendor docs:
    # InstallShield bootstrappers usually take /s, MSI wrappers usually take /quiet.
    $installerArgs = "/quiet"
    $driveName = "TScanSrc"

    # Function-scoped: makes cmdlet errors (Set-Service, New-Item, etc.) terminating so catch sees them.
    $ErrorActionPreference = 'Stop'

    $nuviaPath = "$env:SystemDrive\Nuvia"
    $tempPath = "$nuviaPath\Temp\tscan"
    $logPath = "$nuviaPath\Logs"
    $robocopyLog = "$logPath\shellcli_tscan_robocopy.txt"
    $driveMapped = $false

    try {
        # --- Elevation check -------------------------------------------------------------
        $principal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
        if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            throw "This must be run as Administrator."
        }

        # --- Local folders ---------------------------------------------------------------
        writeText -type "plain" -text "Preparing TScan folder..."
        writeText -type "plain" -text $tempPath

        foreach ($dir in $tempPath, $logPath) {
            if (-not (Test-Path -PathType Container $dir)) {
                New-Item -Path $dir -ItemType Directory -Force | Out-Null
            }
        }
        if (-not (Test-Path -PathType Container $tempPath)) {
            throw "Failed to create TScan folder."
        }
        writeText -type "plain" -text "Folder ready." -lineAfter

        # --- Guide -----------------------------------------------------------------------
        writeText -type "plain" -text "T-Scan Installation Guide:"
        writeText -type "plain" -text "Example path for T-Scan installation files. You'll be prompted for the actual path:"
        writeText -type "plain" -text "\\SERVER\InTech\58550_T-Scan_v10_KALLIE_KEE_NUVIA_DENTAL_IMPLANT_CENTER" -lineAfter
        writeText -type "plain" -text "Example of the expected pathing for T-Scan network share:"
        writeText -type "plain" -text "T-Scan SQL Server:   SERVER\TSCAN10"
        writeText -type "plain" -text "Scans shared path:   \\SERVER\Scans" -lineAfter

        # --- Installer path --------------------------------------------------------------
        writeText -type "prompt" -text "What is the installer path?"
        $networkPath = [string](readInput -prompt "Path:")
        if ([string]::IsNullOrWhiteSpace($networkPath)) {
            throw "No installer path entered."
        }
        # Strip quotes from "Copy as path" pastes and any trailing backslash
        $networkPath = $networkPath.Trim().Trim('"').TrimEnd('\')

        if ($networkPath -notmatch '^\\\\[^\\]+\\[^\\]+') {
            throw "Path must be a UNC path like \\SERVER\Share\Folder"
        }
        $shareRoot = $Matches[0]   # e.g. \\SERVER\InTech - authenticate against the share root

        # --- Authenticate (no plain-text password on the command line) -------------------
        writeText -type "plain" -text "Authenticating to $shareRoot..."
        $credentials = Get-Credential -Message "Enter credentials for network share: $shareRoot"
        if (-not $credentials) {
            throw "Credential prompt was cancelled."
        }

        if (Get-PSDrive -Name $driveName -ErrorAction SilentlyContinue) {
            Remove-PSDrive -Name $driveName -Force -ErrorAction SilentlyContinue
        }
        try {
            New-PSDrive -Name $driveName -PSProvider FileSystem -Root $shareRoot -Credential $credentials | Out-Null
            $driveMapped = $true
        } catch {
            throw ("Authentication to $shareRoot failed: $($_.Exception.Message) " +
                "If this PC already has a connection to that server under different credentials, " +
                "disconnect it (net use $shareRoot /delete) and try again.")
        }
        writeText -type "plain" -text "Authentication successful"

        if (-not (Test-Path -LiteralPath $networkPath)) {
            throw "Network path is not accessible after authentication: $networkPath"
        }
        writeText -type "plain" -text "Network share is accessible"

        # --- Services (service names, not display names) ---------------------------------
        foreach ($svc in 'SSDPSRV', 'upnphost') {
            # upnphost depends on SSDPSRV, so order matters
            Set-Service   -Name $svc -StartupType Automatic
            Start-Service -Name $svc
        }

        # --- Firewall: language-independent group IDs, Domain/Private rules only ---------
        #   @FirewallAPI.dll,-32752 = Network Discovery
        #   @FirewallAPI.dll,-28502 = File and Printer Sharing
        foreach ($group in '@FirewallAPI.dll,-32752', '@FirewallAPI.dll,-28502') {
            Get-NetFirewallRule -Group $group |
            Where-Object { $_.Profile.ToString() -notmatch 'Public|Any' } |
            Enable-NetFirewallRule
        }

        # --- Copy installer --------------------------------------------------------------
        writeText -type "plain" -text "Copying installer files..."
        # /R:2 /W:5 prevents robocopy's default of 1,000,000 retries x 30s on a locked file
        robocopy $networkPath $tempPath /E /IS /COPY:DAT /R:2 /W:5 /NP "/LOG:$robocopyLog" | Out-Null
        $rc = $LASTEXITCODE
        if ($rc -ge 8) {
            throw "Robocopy failed with exit code $rc. See $robocopyLog"
        }

        # --- Install ---------------------------------------------------------------------
        # Search every subfolder for setup.exe, shallowest match first
        $setupMatches = @(
            Get-ChildItem -LiteralPath $tempPath -Filter "setup.exe" -File -Recurse -ErrorAction SilentlyContinue |
            Sort-Object { ($_.FullName -split '\\').Count }, FullName
        )

        if ($setupMatches.Count -eq 0) {
            throw "No setup.exe found anywhere under $tempPath. Check that the installer path was correct."
        } elseif ($setupMatches.Count -eq 1) {
            $setup = $setupMatches[0].FullName
        } else {
            writeText -type "plain" -text "Multiple setup.exe files found:"
            for ($i = 0; $i -lt $setupMatches.Count; $i++) {
                $relative = $setupMatches[$i].FullName.Substring($tempPath.Length + 1)
                writeText -type "plain" -text "  [$($i + 1)] $relative"
            }
            writeText -type "prompt" -text "Which one is the T-Scan installer? (Enter for 1)"
            $choice = ([string](readInput -prompt "Number:")).Trim()

            $index = 1
            if ($choice -and (-not [int]::TryParse($choice, [ref]$index) -or $index -lt 1 -or $index -gt $setupMatches.Count)) {
                throw "Invalid selection: $choice"
            }
            $setup = $setupMatches[$index - 1].FullName
        }
        writeText -type "plain" -text "Using installer: $setup"

        writeText -type "plain" -text "Installing T-Scan..."
        # Run from the installer's own folder; many setups look for their files relative to the working directory
        $proc = Start-Process -FilePath $setup -ArgumentList $installerArgs `
            -WorkingDirectory (Split-Path -Parent $setup) -Wait -PassThru

        switch ($proc.ExitCode) {
            0 { writeText -type "plain" -text "T-Scan installed." -lineAfter }
            3010 { writeText -type "plain" -text "T-Scan installed. A reboot is required to finish." -lineAfter }
            default { throw "Installer exited with code $($proc.ExitCode)." }
        }
    } catch {
        writeText -type "error" -text "$($_.Exception.Message) ($($MyInvocation.MyCommand.Name)-$($_.InvocationInfo.ScriptLineNumber))" -lineAfter
    } finally {
        # Runs on success AND failure
        if ($driveMapped) {
            Remove-PSDrive -Name $driveName -Force -ErrorAction SilentlyContinue
        }
        if (Test-Path -LiteralPath $tempPath) {
            Remove-Item -LiteralPath $tempPath -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    # Called once, on every path. If your main menu already loops, delete this line
    # and just let the function return, which avoids growing the call stack.
    readCommand
}