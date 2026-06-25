function installBGInfo {
    try {
        $url = "https://drive.google.com/uc?export=download&id=1o5NcW5rmhPujNH0AboGwpdvKP5Tcir7o"

        $download = getDownload -url $url -target "$env:SystemRoot\Temp\BGInfo.zip" -lineBefore

        if ($download -eq $true) { 
            # Set the wallpaper property
            # Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name WallPaper -Value "" 

            # Set the background color property
            # Set-ItemProperty -Path "HKCU:\Control Panel\Colors" -Name Background -Value "0 0 0" 

            # I don't know of a good way to check that this value has actually changed
            # writeText -type "plain" -text "Wallpaper cleared." -lineBefore

            Expand-Archive -LiteralPath "$env:SystemRoot\Temp\BGInfo.zip" -DestinationPath "$env:SystemRoot\Temp\"

            # Test if the extracted folder exists
            if (Test-Path "$env:SystemRoot\Temp\BGInfo") {
                writeText -type "plain" -text "BGInfo unpacked."
            } else {
                writeText -type "error" -text "Failed to unpack BGInfo."
            }

            ROBOCOPY "$env:SystemRoot\Temp\BGInfo" "C:\Program Files\BGInfo" /E /NFL /NDL /NJH /NJS /nc /ns | Out-Null
            ROBOCOPY "$env:SystemRoot\Temp\BGInfo" "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup" "Start BGInfo.bat" /NFL /NDL /NJH /NJS /nc /ns | Out-Null

            if (Test-Path "C:\Program Files\BGInfo") {
                writeText -type "plain" -text "BGInfo installed."
            } else {
                writeText -type "error" -text "Failed to install BGInfo."
            }

            Remove-Item -Path "$env:SystemRoot\Temp\BGInfo.zip" -Recurse
            Remove-Item -Path "$env:SystemRoot\Temp\BGInfo" -Recurse 

            $filesDeleted = $true
            if (Test-Path "$env:SystemRoot\Temp\BGInfo.zip") { 
                $filesDeleted = $false 
            }
            if (Test-Path "$env:SystemRoot\Temp\BGInfo") { 
                $filesDeleted = $false 
            } 
            if (!$filesDeleted) {
                writeText -type "error" -text "Some temp files were not deleted. This is harmless."
            }

            Start-Process -FilePath "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\Start BGInfo.bat" -WindowStyle Hidden

            writeText -type "success" -text "BGInfo installed and applied."
        }
    } catch {
        writeText -type "error" -text "installBGInfo-$($_.InvocationInfo.ScriptLineNumber) | $($_.Exception.Message)"
    }
}
