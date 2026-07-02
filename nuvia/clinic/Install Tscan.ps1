function installTscan {
    try {
        addTscanFolder

        Set-Service -Name "SSDPSRV" -StartupType Automatic
        Start-Service -Name "SSDP Discovery"
        Set-Service -Name "upnphost" -StartupType Automatic
        Start-Service -Name "UPnP Device Host"
        Set-NetFirewallRule -DisplayGroup "Network Discovery" -Enabled True
        Set-NetFirewallRule -DisplayGroup "File and Printer Sharing" -Enabled True

        robocopy "\\NUVFULSVR\InTech\59179_T-Scan_v10_KALLIE_NUVIA_DENTAL_IMPLANT_CENTER" "$env:SystemRoot\Temp\tscan" /E /IS /COPYALL
          
        writeText "Installing T-Scan..."
        Start-Process -FilePath "$env:SystemRoot\Temp\tscan\tekscan\setup.exe" -ArgumentList "/quiet" -Wait
        writeText "T-Scan installed."
        
        Get-Item -ErrorAction SilentlyContinue "$env:SystemRoot\Temp\tscan" | Remove-Item -ErrorAction SilentlyContinue -Confirm $false
        readCommand
    } catch {
        writeText -type "error" -text "$($MyInvocation.MyCommand.Name): $($_.InvocationInfo.ScriptLineNumber)-$($_.Exception.Message)"
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

