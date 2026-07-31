function getDTXVersion {
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
                writeText -type "warning" -text "Could not read version information from $path" -lineAfter
            }
        }
    }

    if (-not $found) {
        writeText -type "warning" -text "Could not find the DTX Studio executable in the default paths." -lineAfter
    }

    getODConfig
}