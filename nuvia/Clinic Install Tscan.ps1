function installTscan {
    try {
        $nuviaPath = "C:\Nuvia"
        writeText -type "plain" -text "Creating TScan folder..."
        writeText -type "plain" -text "$nuviaPath\Temp\tscan"

        if (-not (Test-Path -PathType Container "$nuviaPath\Temp\tscan")) {
            New-Item -Path "$nuviaPath\Temp" -Name "tscan" -ItemType Directory | Out-Null
        }

        if (-not (Test-Path -PathType Container "$nuviaPath\Temp\tscan")) {
            writeText -type "error" -text "Failed to create TScan folder." -lineAfter
            readCommand
        } else {
            writeText -type "plain" -text "Folder created." -lineAfter
        }
        
        writeText -type "plain" -text "T-Scan Installation Guide:"
        writeText -type "plain" -text "Example path for T-Scan installation files. You'll be prompted for the actual path:"
        writeText -type "plain" -text "\\SERVER\InTech\58550_T-Scan_v10_KALLIE_KEE_NUVIA_DENTAL_IMPLANT_CENTER" -lineAfter
        writeText -type "plain" -text "Example of the expected pathing for T-Scan network share:"
        writeText -type "plain" -text "T-Scan SQL Server:	SERVER\TSCAN10"
        writeText -type "plain" -text "Scans shared path:   \\SERVER\Scans" -lineAfter

        writeText -type "prompt" -text "What is the install path?"
        $networkPath = readInput -prompt "Path:"
        
        # Authenticate to network share using net use (no drive letter)
        writeText -type "plain" -text "Authenticating to network share..."
        $credentials = Get-Credential -Message "Enter credentials for network share: $networkPath"
        
        # Use net use with the UNC path (no drive letter)
        $netUseResult = net use $networkPath /user:$($credentials.UserName) $($credentials.GetNetworkCredential().Password)
        
        # Check if authentication was successful
        if ($LASTEXITCODE -eq 0) {
            writeText -type "plain" -text "Authentication successful"
            
            # Verify the path is accessible
            if (Test-Path $networkPath) {
                writeText -type "plain" -text "Network share is accessible"
                
                Set-Service -Name "SSDPSRV" -StartupType Automatic
                Start-Service -Name "SSDP Discovery"
                Set-Service -Name "upnphost" -StartupType Automatic
                Start-Service -Name "UPnP Device Host"
                Set-NetFirewallRule -DisplayGroup "Network Discovery" -Enabled True
                Set-NetFirewallRule -DisplayGroup "File and Printer Sharing" -Enabled True

                robocopy "$networkPath" "$nuviaPath\Temp\tscan" /E /IS /COPY:DAT > "$nuviaPath\Logs\shellcli_tscan_robocopy.txt" 2>&1
                
                if ($LASTEXITCODE -le 7) {
                    writeText -type "plain" -text "Installing T-Scan..."
                    Start-Process -FilePath "$nuviaPath\Temp\tscan\tekscan\setup.exe" -ArgumentList "/quiet" -Wait
                    writeText -type "plain" -text "T-Scan installed."
                } else {
                    throw "Robocopy failed with exit code: $LASTEXITCODE"
                }
            } else {
                throw "Network path is not accessible after authentication"
            }
        } else {
            throw "Authentication failed with exit code: $LASTEXITCODE"
        }
        
        # Cleanup
        Get-Item -ErrorAction SilentlyContinue "$nuviaPath\Temp\tscan" | Remove-Item -ErrorAction SilentlyContinue -Confirm $false
        
        # Remove the network connection (optional)
        net use $networkPath /delete 2>$null
        readCommand
    } catch {
        # Cleanup on error
        net use $networkPath /delete 2>$null
        writeText -type "error" -text "$($MyInvocation.MyCommand.Name)-$($_.InvocationInfo.ScriptLineNumber)"
        log -msg "$($MyInvocation.MyCommand.Name)-$($_.InvocationInfo.ScriptLineNumber):$($_.Exception.Message)" -lvl "ERROR"
    }
}