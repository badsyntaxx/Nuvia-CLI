function nuvia {
    Write-Host
    Write-Host " $([char]0x250C)" -NoNewline -ForegroundColor "Gray"
    Write-Host " Try" -NoNewline
    Write-Host " n help" -ForegroundColor "Cyan" -NoNewline
    Write-Host " or" -NoNewline
    Write-Host " n menu" -NoNewline -ForegroundColor "Cyan"
    Write-Host " if you get stuck."
    Write-Host " $([char]0x2502)" -ForegroundColor "Gray"
}
function readMenu {
    try {
        $choice = readOption -options $([ordered]@{
                "ISR menu"          = "Go to the Nuvia ISR menu."
                "Install TScan"     = "Install TScan software."
                "Add NuAdmin"       = "Add the NuAdmin user to the computer."
                "Install Ninja"     = "Install Ninja for Nuvia computers."
                "Uninstall Ninja"   = "Uninstall Ninja from Nuvia computers."
                "Install JumpCloud" = "Install JumpCloud for Nuvia computers."
                "Cancel"            = "Select nothing and exit this menu."
            }) -prompt "Select a Nuvia function:"

        switch ($choice) {
            0 { $command = "nuvia isr menu" }
            1 { $command = "nuvia install-tscan" }
            2 { $command = "nuvia addnuadmin" }
            3 { $command = "nuvia install ninja" }
            4 { $command = "nuvia uninstall ninja" }
            5 { $command = "nuvia install jumpcloud" }
            6 { readCommand }
        }

        readCommand -command $command
    } catch {
        writeText -type "error" -text "$($MyInvocation.MyCommand.Name): $($_.InvocationInfo.ScriptLineNumber)-$($_.Exception.Message)" 
    }
}
function readISRMenu {
    try {
        $choice = readOption -options $([ordered]@{
                "Nuvia root menu" = "Go to the root Nuvia menu."
                "Onboard"         = "Collection of functions to onboard and ISR computer."
                "Install Apps"    = "Install all the apps an ISR needs to work."
                "Add Bookmarks"   = "Add ISR bookmarks to Chrome."
                "Cancel"          = "Select nothing and exit this menu."
            }) -prompt "Select a Nuvia function:"

        switch ($choice) {
            0 { $command = "nuvia menu" }
            1 { $command = "nuvia isr onboard" }
            2 { $command = "nuvia isr install apps" }
            3 { $command = "nuvia isr add bookmarks" }
            4 { readCommand }
        }

        Write-Host
        Write-Host ": "  -ForegroundColor "DarkCyan" -NoNewline
        Write-Host "Running command:" -NoNewline -ForegroundColor "DarkGray"
        Write-Host " $command" -ForegroundColor "Gray"

        readCommand -command $command
    } catch {
        writeText -type "error" -text "$($MyInvocation.MyCommand.Name): $($_.InvocationInfo.ScriptLineNumber)-$($_.Exception.Message)" 
        readCommand
    }
}
function writeHelp {
    writeText -type "plain" -text "STARTER COMMANDS:"
    writeText -type "plain" -text "commands  - Display a full list of commands."
    writeText -type "plain" -text "n menu    - Display a menu with some available functions."
    writeText -type "plain" -text "n help    - Display this help text."
    getWinDirStat
    getRevoUninstaller
}
function getWinDirStat {
    try {
        $url = "https://github.com/windirstat/windirstat/releases/latest/download/WinDirStat.zip"

        # Define paths
        $tempDir = "C:\Nuvia\Apps"
        $zipPath = Join-Path -Path $tempDir -ChildPath "WinDirStat.zip"  # FULL path with filename
        $exePath = Join-Path -Path $tempDir -ChildPath "WinDirStat.exe"

        # Create directory if it doesn't exist
        if (!(Test-Path $tempDir)) {
            New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
            writeText -type "notice" -text "Created directory: $tempDir"
        }          

        # Check if WinDirStat.exe already exists
        if (!(Test-Path $exePath)) {
            # Download the zip file - pass the FULL file path
            if (getDownload -url $url -target $zipPath) {
                # Verify the zip file was downloaded
                if (Test-Path $zipPath) {
                    # Extract the zip file
                    Expand-Archive -Path $zipPath -DestinationPath $tempDir -Force
                        
                    # Move WinDirStat.exe from x64 subfolder to root
                    $extractedExe = Join-Path -Path $tempDir -ChildPath "x64\WinDirStat.exe"
                    if (Test-Path $extractedExe) {
                        Move-Item -Path $extractedExe -Destination $exePath -Force
                        # Clean up the x64 folder
                        Remove-Item -Path (Join-Path -Path $tempDir -ChildPath "x64") -Recurse -Force -ErrorAction SilentlyContinue
                        Remove-Item -Path (Join-Path -Path $tempDir -ChildPath "x86") -Recurse -Force -ErrorAction SilentlyContinue
                        Remove-Item -Path (Join-Path -Path $tempDir -ChildPath "Arm64") -Recurse -Force -ErrorAction SilentlyContinue
                    } else {
                        writeText -type "notice" -text "WinDirStat.exe not found in the expected x64 subfolder"
                    }
                        
                    # Clean up the zip file
                    Remove-Item -Path $zipPath -Force -ErrorAction SilentlyContinue
                        
                    writeText -type "success" -text "WinDirStat.exe has been placed in: $tempDir"
                } else {
                    writeText -type "error" -text "Download failed or zip file not found at: $zipPath"
                }
            } else {
                writeText -type "error" -text "Failed to download WinDirStat.zip"
            }
        } else {
            writeText -type "notice" -text "WinDirStat.exe already exists in: $tempDir. Skipping download and extraction."
        }
    } catch {
        writeText -type "error" -text "getWinDirStat-$($_.InvocationInfo.ScriptLineNumber) | $($_.Exception.Message)" -lineAfter
    }
}