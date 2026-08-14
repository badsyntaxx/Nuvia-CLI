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
        writeText -type "error" -text "$($MyInvocation.MyCommand.Name)-$($_.InvocationInfo.ScriptLineNumber)"
        log -msg "$($MyInvocation.MyCommand.Name)-$($_.InvocationInfo.ScriptLineNumber):$($_.Exception.Message)" -lvl "ERROR" 
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
        writeText -type "error" -text "$($MyInvocation.MyCommand.Name)-$($_.InvocationInfo.ScriptLineNumber)"
        log -msg "$($MyInvocation.MyCommand.Name)-$($_.InvocationInfo.ScriptLineNumber):$($_.Exception.Message)" -lvl "ERROR"
    }
}
function writeHelp {
    writeText -type "plain" -text "STARTER COMMANDS:"
    writeText -type "plain" -text "commands  - Display a full list of commands."
    writeText -type "plain" -text "n menu    - Display a menu with some available functions."
    writeText -type "plain" -text "n help    - Display this help text."
}
function readLog {
    param (
        [Parameter(Mandatory = $false)]
        [int]$lines = 50,  # Show last 50 lines by default
        [Parameter(Mandatory = $false)]
        [switch]$tail   # Follow mode (like Linux tail -f)
    )

    try {
        $logDirectory = "C:\Nuvia\Logs\ShellCLI"
        
        if ($date) {
            $logFileName = "${date}.log"
            $logFilePath = Join-Path -Path $logDirectory -ChildPath $logFileName
            if (-not (Test-Path -Path $logFilePath)) {
                writeText -type "plain" -text "No log file found for date: $date"
                readCommand
            }
        } else {
            $logFiles = Get-ChildItem -Path $logDirectory -Filter "*.log" | 
            Sort-Object -Property LastWriteTime -Descending
            if ($logFiles.Count -eq 0) {
                writeText -type "plain" -text "No log files found in $logDirectory"
                readCommand
            }
            $logFilePath = $logFiles[0].FullName
            writeText -type "header" -text "Reading Log: $($logFiles[0].Name)"
        }
        
        # Read last N lines (most useful for logs)
        Get-Content -Path $logFilePath -Tail $lines
        
        # If tail switch is used, follow the log
        if ($tail) {
            writeText -type "plain" -text "`nFollowing log (Ctrl+C to stop)..."
            Get-Content -Path $logFilePath -Wait
        }
    } catch {
        writeText -type "error" -text "$($MyInvocation.MyCommand.Name)-$($_.InvocationInfo.ScriptLineNumber)"
        log -msg "$($MyInvocation.MyCommand.Name)-$($_.InvocationInfo.ScriptLineNumber):$($_.Exception.Message)" -lvl "ERROR"
    }
}