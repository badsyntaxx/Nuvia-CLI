function installTscan {
    try {
        writeText "Creating TScan folder..."
        writeText "$env:SystemRoot\Temp\tscan"

        if (-not (Test-Path -PathType Container "$env:SystemRoot\Temp\tscan")) {
            New-Item -Path "$env:SystemRoot\Temp" -Name "tscan" -ItemType Directory | Out-Null
        }

        if (-not (Test-Path -PathType Container "$env:SystemRoot\Temp\tscan")) {
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

        $networkPath = readInput -prompt "Enter network path for T-Scan"
        
        # Authenticate to network share using net use (no drive letter)
        writeText "Authenticating to network share..."
        $credentials = Get-Credential -Message "Enter credentials for network share: $networkPath"
        
        # Use net use with the UNC path (no drive letter)
        $netUseResult = net use $networkPath /user:$($credentials.UserName) $($credentials.GetNetworkCredential().Password)
        
        # Check if authentication was successful
        if ($LASTEXITCODE -eq 0) {
            writeText "Authentication successful."
            
            # Verify the path is accessible
            if (Test-Path $networkPath) {
                writeText "Network share is accessible."
                
                Set-Service -Name "SSDPSRV" -StartupType Automatic
                Start-Service -Name "SSDP Discovery"
                Set-Service -Name "upnphost" -StartupType Automatic
                Start-Service -Name "UPnP Device Host"
                Set-NetFirewallRule -DisplayGroup "Network Discovery" -Enabled True
                Set-NetFirewallRule -DisplayGroup "File and Printer Sharing" -Enabled True

                robocopy $networkPath "$env:SystemRoot\Temp\tscan" /E /IS /COPYALL
                
                if ($LASTEXITCODE -le 7) {
                    writeText -type "plain" -text "Installing T-Scan..."
                    Start-Process -FilePath "$env:SystemRoot\Temp\tscan\tekscan\setup.exe" -ArgumentList "/quiet" -Wait
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
        Get-Item -ErrorAction SilentlyContinue "$env:SystemRoot\Temp\tscan" | Remove-Item -ErrorAction SilentlyContinue -Confirm $false
        
        # Remove the network connection (optional)
        readCommand
        
    } catch {
        # Cleanup on error
        net use $networkPath /delete 2>$null
        # writeText -type "error" -text "$($MyInvocation.MyCommand.Name): $($_.InvocationInfo.ScriptLineNumber)"
        writeText -type "error" -text "$($MyInvocation.MyCommand.Name): $($_.InvocationInfo.ScriptLineNumber)-$($_.Exception.Message)"
    }
}