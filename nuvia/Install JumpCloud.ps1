function installJumpCloud {
    try {
        & "C:\Windows\System32\cmd.exe" /c ipconfig /FlushDNS | Out-Null
        $agentPath = Join-Path ${env:ProgramFiles} "JumpCloud"
        if (-not (Test-Path -Path "$($agentPath)\jumpcloud-agent.exe")) {
            $url = "https://cdn02.jumpcloud.com/production/jcagent-msi-signed.msi"
            $installerPath = "$env:SystemRoot\Temp\jcagent-msi-signed.msi"
        
            $download = getDownload -url $url -target $installerPath -lineBefore
            if ($download) {        
                $log = "$env:SystemRoot\Temp\jcInstall.log";
                $JumpCloudConnectKey = "jcc_eyJwdWJsaWNLaWNrc3RhcnRVcmwiOiJodHRwczovL2tpY2tzdGFydC5qdW1wY2xvdWQuY29tIiwicHJpdmF0ZUtpY2tzdGFydFVybCI6Imh0dHBzOi8vcHJpdmF0ZS1raWNrc3RhcnQuanVtcGNsb3VkLmNvbSIsImNvbm5lY3RLZXkiOiIzMGYwZGJlM2NjZGM1NjNmMTQyNmY0MTM4ZjJiOTA0NmNkYzQ0ZGJkIn0g";
                
                # Correct MSIEXEC arguments - note the proper quoting
                $installArgs = @(
                    "/i",
                    "`"$installerPath`"",
                    "/quiet",
                    "/norestart",
                    "/L*V",
                    "`"$log`"",
                    "JCINSTALLERARGUMENTS=`"-k $JumpCloudConnectKey`""
                )
                
                "Starting installation with arguments: msiexec $installArgs" | Out-File -FilePath $log -Append
                
                $process = Start-Process -FilePath "msiexec" -ArgumentList $installArgs -PassThru -NoNewWindow -Wait

                writeText -type "plain" -text "Installation process started (PID: $($process.Id))"
                writeText -type "plain" -text "Waiting for agent service to start..."
                
                $startTime = Get-Date
                $timeout = New-TimeSpan -Minutes 10
                $animationChars = @('|', '/', '-', '\')
                $counter = 0

                while ((Get-Date) - $startTime -lt $timeout) {
                    $AgentService = Get-Service -Name "jumpcloud-agent" -ErrorAction SilentlyContinue
                    
                    if ($AgentService -and $AgentService.Status -eq "Running") {
                        writeText -type 'plain' -text "Installation completed in: $((Get-Date) - $startTime)"
                        writeText -type 'plain' -text "Service status: $($AgentService.Status)"
                        writeText -type 'success' -text "JumpCloud Agent installed and running successfully!"
                        break
                    }
                    
                    # Animated progress indicator
                    $animation = $animationChars[$counter % $animationChars.Length]
                    Write-Host "`rInstalling $animation (Elapsed: $((Get-Date) - $startTime))"
                    $counter++
                    Start-Sleep -Milliseconds 250
                }
                
                if (-not $AgentService -or $AgentService.Status -ne "Running") {
                    writeText -type 'notice' -text "Installation timeout reached. Checking service status..."
                    $AgentService = Get-Service -Name "jumpcloud-agent" -ErrorAction SilentlyContinue
                    if (-not $AgentService) {
                        writeText -type 'error' -text "JumpCloud service not found after installation attempt."
                    } else {
                        writeText -type 'notice' -text "JumpCloud service found but not running. Current status: $($AgentService.Status)"
                    }
                    writeText -type 'plain' -text "Please check the installation log at: $log"
                }

                $JumpCloudConnectKey = $null;
                
                <# Write-Host "[INFO] Cleaning up installer..."
                if (Test-Path $installerPath) {
                    Remove-Item $installerPath -Force
                    Write-Host "[INFO] Installer removed successfully."
                } #>
            }
        } else {
            writeText -type "success" -text "JumpCloud Agent Already Installed."
        }
    } catch {
        writeText -type "error" -text "installJumpCloud-$($_.InvocationInfo.ScriptLineNumber) - $($_.Exception.Message)"
    }
}