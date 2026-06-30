function isrOnboard {
    $funcs = @(
        "edit hostname" 
        "nuvia install ninja"
        "nuvia install jumpcloud"
        "nuvia isr install apps"
        "intech add admin"
        "nuvia install bginfo"
        "disable context menu"
        "plugins reclaim"
    )

    # Create the main script file
    New-Item -Path "$env:SystemRoot\Temp\ShellCLI.ps1" -ItemType File -Force | Out-Null

    foreach ($func in $funcs) {
        addFunc -command $func
    }

    addScript -directory "core" -file "Framework"

    Add-Content -Path "$env:SystemRoot\Temp\ShellCLI.ps1" -Value @"
function runAll {
    writeText -type "header" -text "Editing hostname" -lineBefore
    editHostname
    writeText -type "header" -text "Installing NinjaRMM" -lineBefore
    installNinja
    Write-Host
    writeText -type "header" -text "Installing JumpCloud" -lineBefore
    installJumpCloud
    writeText -type "header" -text "Installing ISR apps" -lineBefore
    isrInstallApps
    writeText -type "header" -text "Adding InTech admin" -lineBefore
    addInTechAdmin
    writeText -type "header" -text "Installing BGInfo" -lineBefore
    installBGInfo
    writeText -type "header" -text "Disabling context menu" -lineBefore
    disableContextMenu
    Write-Host
    Write-Host
    writeText -type "header" -text "Debloating Windows" -lineBefore
    reclaim
}
"@
    # Add a final line that will invoke the desired function
    Add-Content -Path "$env:SystemRoot\Temp\ShellCLI.ps1" -Value "invokeScript 'runAll'"

    # Execute the combined script
    $shellCLI = Get-Content -Path "$env:SystemRoot\Temp\ShellCLI.ps1" -Raw
    Invoke-Expression $shellCLI
}

function addFunc {
    param (
        [parameter(Mandatory = $false)]
        [string]$command = ""
    )

    try {
        $filteredCommand = filterCommands -command $command
        $commandDirectory = $filteredCommand[0]
        $commandFile = $filteredCommand[1]

        addScript -directory $commandDirectory -file $commandFile
    } catch {
        writeText -type "error" -text "addFunc-$($_.InvocationInfo.ScriptLineNumber) | $($_.Exception.Message)"
    }
}