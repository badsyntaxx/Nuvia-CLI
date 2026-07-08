function installTscan {
    try {
        addTscanFolder
        
        $networkPath = "\\NUVTAMSVR\InTech\58550_T-Scan_v10_KALLIE_KEE_NUVIA_DENTAL_IMPLANT_CENTER"
        
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
                    writeText "Installing T-Scan..."
                    Start-Process -FilePath "$env:SystemRoot\Temp\tscan\tekscan\setup.exe" -ArgumentList "/quiet" -Wait
                    writeText "T-Scan installed."
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
        net use $networkPath /delete
        readCommand
        
    } catch {
        writeText -type "error" -text "$($MyInvocation.MyCommand.Name): $($_.InvocationInfo.ScriptLineNumber)-$($_.Exception.Message)"
        # Cleanup on error
        net use $networkPath /delete 2>$null
    }
}

function addTscanFolder {
    try {
        writeText "Creating TScan folder..."
        writeText "$env:SystemRoot\Temp\tscan"

        if (-not (Test-Path -PathType Container "$env:SystemRoot\Temp\tscan")) {
            New-Item -Path "$env:SystemRoot\Temp" -Name "tscan" -ItemType Directory | Out-Null
        }
        
        writeText -type "plain" -text "Folder created." -lineAfter
    } catch {
        writeText "Error creating temp folder: $($_.Exception.Message)" -type "error"
    }
}

