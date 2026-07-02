function getPrinterDrivers {
    $installChoice = readOption -options $([ordered]@{
            "Epson ET-8550" = "Epson ET-8550"
            "Epson ES400II" = "Epson ES400II"
            "Exit"          = "Exit this script and go back to main command line."
        }) -prompt "Select a printer:" -lineAfter

    switch ($installChoice) {
        0 { EpsonET8550Menu }
        1 { EpsonES400IIMenu }
        2 { readCommand }
    }
}

function EpsonET8550Menu {
    $installChoice = readOption -options $([ordered]@{
            "Download" = "Just download the driver and place it in C:\Temp"
            "Install"  = "Silently download and install the driver"
            "Exit"     = "Exit this script and go back to printer menu."
        }) -prompt "Select an action:" -lineAfter

    switch ($installChoice) {
        0 { getEpsonET8550Driver }
        1 { installEpsonET8550Driver }
        2 { getPrinterDrivers }
    }
}

function getEpsonET8550Driver {
    try {
        $url = "https://ftp.epson.com/drivers/ET8550_X64_38000_NA.exe"
        if (getDownload -url $url -target "C:\Temp\ET8550_X64_38000_NA.exe") {      
            writeText -type "success" -text "ET8550_X64_38000_NA.exe has been placed in: C:\Temp"
        } else {
            writeText -type "error" -text "Download failed at: C:\Temp"
        }
        $url = "https://ftp.epson.com/drivers/ET8550_EScan2_67810_NA.exe"
        if (getDownload -url $url -target "C:\Temp\ET8550_EScan2_67810_NA.exe") {      
            writeText -type "success" -text "ET8550_EScan2_67810_NA.exe has been placed in: C:\Temp"
        } else {
            writeText -type "error" -text "Download failed at: C:\Temp"
        }
    } catch {
        writeText -type "error" -text "$($MyInvocation.MyCommand.Name): $($_.InvocationInfo.ScriptLineNumber)"
        # writeText -type "error" -text "$($MyInvocation.MyCommand.Name): $($_.InvocationInfo.ScriptLineNumber)-$($_.Exception.Message)"
    }
}

function installEpsonET8550Driver {
    try {
        $url = "https://ftp.epson.com/drivers/ET8550_X64_38000_NA.exe"
        $appName = "Epson ET8550 Printer"
        $paths = @(
            "$env:ProgramFiles\BraveSoftware\Brave-Browser\Application\brave.exe"
        )
        $installed = findExisting -Paths $paths -App $appName
        if (!$installed) { 
            installProgram -url $url -AppName $appName -Args "/silent" 
        }

        $url = "https://ftp.epson.com/drivers/ET8550_EScan2_67810_NA.exe"
        $appName = "Epson ET8550 Scanner"
        $paths = @(
            "$env:ProgramFiles\BraveSoftware\Brave-Browser\Application\brave.exe"
        )
        $installed = findExisting -Paths $paths -App $appName
        if (!$installed) { 
            installProgram -url $url -AppName $appName -Args "/silent" 
        }
    } catch {
        writeText -type "error" -text "$($MyInvocation.MyCommand.Name): $($_.InvocationInfo.ScriptLineNumber)-$($_.Exception.Message)"
    }
}