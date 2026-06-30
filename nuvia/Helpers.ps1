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
        writeText -type "error" -text "nuvia-menu: $($_.Exception.Message) $url/nuvia/$dependency.ps1" 
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
        writeText -type "error" -text "nuvia-menu: $($_.Exception.Message) $url/nuvia/$dependency.ps1" 
        readCommand
    }
}
function writeHelp {
    writeText -type "plain" -text "NUVIA COMMANDS:" -lineBefore
    writeText -type "plain" -text "nuvia addnuadmin         - Add the NuAdmin user to the computer." -Color "DarkGray"
    writeText -type "plain" -text "nuvia install bginfo     - Installs BGInfo." -Color "DarkGray"
    writeText -type "plain" -text "nuvia install ninja      - Installs Ninja." -Color "DarkGray"
    writeText -type "plain" -text "nuvia uninstall ninja  - Uninstalls Ninja." -Color "DarkGray"
    writeText -type "plain" -text "nuvia install jumpcloud  - Installs JumpCloud." -Color "DarkGray"
    writeText -type "plain" -text "NUVIA ISR COMMANDS:" -lineBefore
    writeText -type "plain" -text "isr onboard          - Edit the computers hostname and description." -Color "DarkGray"
    writeText -type "plain" -text "isr install apps     - Install Windows updates. All or just severe." -Color "DarkGray"
    writeText -type "plain" -text "schedule task        - Create a task in the task scheduler." -Color "DarkGray"
    writeText -type "plain" -text "toggle context menu  - Disable the Windows 11 context menu." -Color "DarkGray"
}