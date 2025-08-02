function installNinja {
    try {
        $url = "https://app.ninjarmm.com/agent/installer/6a496c78-c8ef-4ace-9c88-cd0a7aa5415c/8.0.2891/NinjaOne-Agent-Nuvia-Unassigned-Auto.msi"
        $service = Get-Service -Name "NinjaRMMAgent" -ErrorAction SilentlyContinue

        writeText -type "notice" -text "This computer will be in -Unassigned after install."
        
        if ($null -ne $service -and $service.Status -eq "Running") {
            writeText -type "success" -text "NinjaRMMAgent is already installed and running."
        } else {
            $download = getDownload -url $url -target "$env:SystemRoot\Temp\NinjaOne-Agent-Nuvia-Unassigned-Auto.msi" -lineBefore
            if ($download) { 
                Start-Process -FilePath "msiexec" -ArgumentList "/i `"$env:SystemRoot\Temp\NinjaOne-Agent-Nuvia-Unassigned-Auto.msi`" /qn" -Wait

                # Initialize variables for service check
                $maxAttempts = 10  # Number of attempts to check service
                $waitSeconds = 5   # Time to wait between attempts
                $serviceRunning = $false

                writeText -type "notice" -text "Waiting for NinjaRMMAgent service to start..."

                # Loop to check service status
                for ($i = 1; $i -le $maxAttempts; $i++) {
                    $service = Get-Service -Name "NinjaRMMAgent" -ErrorAction SilentlyContinue
                        
                    if ($null -ne $service) {
                        if ($service.Status -eq "Running") {
                            $serviceRunning = $true
                            break
                        } elseif ($service.Status -ne "Running") {
                            writeText -type "notice" -text "Attempt $i of $maxAttempts`: Service found but not running. Starting service..."
                            Start-Service -Name "NinjaRMMAgent" -ErrorAction SilentlyContinue
                        }
                    } else {
                        writeText -type "notice" -text "Service not found yet. Attempting to find service $i of $maxAttempts."
                    }

                    if ($i -lt $maxAttempts) {
                        Start-Sleep -Seconds $waitSeconds
                    }
                }

                # Cleanup
                Get-Item -ErrorAction SilentlyContinue "$env:SystemRoot\Temp\NinjaOne-Agent-Nuvia-Unassigned-Auto.msi" | Remove-Item -ErrorAction SilentlyContinue

                # Final status check
                if ($serviceRunning) {
                    writeText -type "success" -text "NinjaOne successfully installed and service is running." -lineAfter
                } else {
                    throw "NinjaOne installation completed but service failed to start after $($maxAttempts * $waitSeconds) seconds."
                }
            }
        }
    } catch {
        writeText -type "error" -text "installNinja-$($_.InvocationInfo.ScriptLineNumber) - $($_.Exception.Message)"
    }
}