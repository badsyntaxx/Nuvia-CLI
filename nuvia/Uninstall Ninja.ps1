function uninstallNinjaRMM {
    try {
        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $p = New-Object System.Security.Principal.WindowsPrincipal($id)
        if (-not $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) { 
            throw "This script requires administrator privileges."
        }

        $ninjaExe = findAgent
        if ($ninjaExe -eq "") {
            throw "Couldn't Find the Ninja Agent."
        }

        disableUninstallPrevention -ninjaExePath $ninjaExe
        
        $NinjaDir = Split-Path -Parent $ninjaExe
        $uninstaller = Join-Path $NinjaDir "uninstall.exe"

        if (Test-Path -Path $uninstaller) {
            runUninstaller -uninstallerPath $uninstaller
            deleteDirs -ninjaExePath $ninjaExe
            deleteRegKeys

            writeText -type "success" -text "NinjaRMM uninstalled." 
        } else {
            writeText -type "error" -text "Can't find uninstaller at $uninstaller"
        }
    } catch {
        writeText -type "error" -text "uninstall-ninja-$($_.InvocationInfo.ScriptLineNumber) | $($_.Exception.Message)" -lineAfter
    }    
}

function findAgent {
    $searchPaths = @("$env:ProgramFiles", ${env:ProgramFiles(x86)})
    
    foreach ($path in $searchPaths) {
        $ninjaExe = Get-ChildItem -Path $path -Filter "NinjaRMMAgent.exe" -Recurse -ErrorAction SilentlyContinue |
        Select-Object -First 1 -ExpandProperty FullName
        
        if ($ninjaExe) {
            writeText -type "plain" -text "NinjaRMMAgent found at $ninjaExe"
            return $ninjaExe
        }
    }
    
    return ""
}

function disableUninstallPrevention {
    param (
        [parameter(Mandatory = $true)]
        [string]$ninjaExePath
    )

    writeText -type "plain" -text "Attempting to disable uninstall prevention." -lineAfter

    try {
        $process = Start-Process -FilePath "$ninjaExePath" -ArgumentList "-disableUninstallPrevention" -Wait -PassThru -NoNewWindow | Out-Null
        # writeText -type "plain" -text "Disable process exited with Exit Code: $($process.ExitCode)" -lineBefore

        # This process is output something other than the normal exit code 0. This needs work probably $lastexitcode.
        <# if ($process.ExitCode -ne 0 -and $process.ExitCode -ne 1) {
            throw "Couldn't disable Uninstall Prevention. Make sure the service actually stopped running."
        } #>
    
        writeText -type "notice" -text "Uninstall prevention disabled." -lineAfter -lineBefore
    } catch {
        writeText -type "error" -text "disableUninstallPrevention-$($_.InvocationInfo.ScriptLineNumber) | $($_.Exception.Message)" -lineAfter
    }
}

function runUninstaller {
    param (
        [parameter(Mandatory = $true)]
        [string]$uninstallerPath
    )

    writeText -type "plain" -text "Uninstalling NinjaRMMAgent."

    try {
        $process = Start-Process -FilePath $uninstallerPath -ArgumentList "--mode unattended" -Wait -PassThru -NoNewWindow
        # writeText -type "plain" -text "Uninstaller Exited with Code: $($process.ExitCode)"
        if ($process.ExitCode -ne 0) {
            throw "Uninstall failed. Exit code $($process.ExitCode)"
        }

        writeText -type "plain" -text "Uninstaller successful. Performing Cleanup."
    } catch {
        writeText -type "error" -text "runUninstaller-$($_.InvocationInfo.ScriptLineNumber) | $($_.Exception.Message)" -lineAfter
    }
}

function deleteDirs {
    param (
        [parameter(Mandatory = $true)]
        [string]$ninjaExePath
    )

    $NinjaDirectory = Split-Path -Parent $ninjaExePath
    writeText -type "plain" -text "Removing $($NinjaDirectory)"

    try {
        Remove-Item $NinjaDirectory -Force -Recurse -ErrorAction SilentlyContinue
        writeText -type "plain" -text "Removing $($env:ProgramData)\NinjaRMMAgent\"
        Remove-Item "$($env:ProgramData)\NinjaRMMAgent\" -Force -Recurse -ErrorAction SilentlyContinue
    } catch {
        writeText -type "error" -text "deleteDirs-$($_.InvocationInfo.ScriptLineNumber) | $($_.Exception.Message)" -lineAfter
    }
    
}

function deleteRegKeys {
    writeText -type "plain" -text "Deleting registry keys."
    $registryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\NinjaRMMAgent"
    try {
        Remove-Item -Path $registryPath -Force -ErrorAction SilentlyContinue
        writeText -type "plain" -text "Registry keys removed."
    } catch {
        writeText -type "error" -text "deleteRegKeys-$($_.InvocationInfo.ScriptLineNumber) | $($_.Exception.Message)" -lineAfter
    }
}