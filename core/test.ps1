function addInTechAdmin {
    try {
        $accountName = "InTechAdmin"
        $downloads = [ordered]@{
            "$env:SystemRoot\Temp\KEY.txt"    = "https://drive.google.com/uc?export=download&id=1EGASU9cvnl5E055krXXcXUcgbr4ED4ry"
            "$env:SystemRoot\Temp\PHRASE.txt" = "https://drive.google.com/uc?export=download&id=1jbppZfGusqAUM2aU7V4IeK0uHG2OYgoY"
        }

        foreach ($d in $downloads.Keys) { 
            $download = getDownload -url $downloads[$d] -target $d  
        } 

        Write-Host $download

        Read-Host "foo"
        
        if ($download) { 
            $password = Get-Content -Path "$env:SystemRoot\Temp\PHRASE.txt" | ConvertTo-SecureString -Key (Get-Content -Path "$env:SystemRoot\Temp\KEY.txt")

            writeText -type "plain" -text "Phrase converted."

            # Check if the InTechAdmin user already exists
            $account = Get-LocalUser -Name $accountName -ErrorAction SilentlyContinue

            if ($null -eq $account) {
                # Create the InTechAdmin user with specified password and attributes
                New-LocalUser -Name $accountName -Password $password -FullName "" -Description "InTech Administrator" -AccountNeverExpires -PasswordNeverExpires -ErrorAction stop | Out-Null
                writeText -type "success" -text "The InTechAdmin account has been created."
            } else {
                # Update the existing InTechAdmin user's password
                writeText -type "notice" -text "InTechAdmin account already exists."
                $account | Set-LocalUser -Password $password
                writeText -type "success" -text "The InTechAdmin account password was updated."
            }

            # Add the InTechAdmin user to the Administrators, Remote Desktop Users, and Users groups
            Add-LocalGroupMember -Group "Administrators" -Member $accountName -ErrorAction SilentlyContinue
            writeText -type "success" -text "The InTechAdmin account has been added to the 'Administrators' group."
            Add-LocalGroupMember -Group "Remote Desktop Users" -Member $accountName -ErrorAction SilentlyContinue
            writeText -type "success" -text "The InTechAdmin account has been added to the 'Remote Desktop Users' group."
            Add-LocalGroupMember -Group "Users" -Member $accountName -ErrorAction SilentlyContinue
            writeText -type "success" -text "The InTechAdmin account has been added to the 'Users' group."

            # Remove the downloaded files for security reasons
            Remove-Item -Path "$env:SystemRoot\Temp\PHRASE.txt"
            Remove-Item -Path "$env:SystemRoot\Temp\KEY.txt"

            # Informational messages about deleting temporary files
            if (-not (Test-Path -Path "$env:SystemRoot\Temp\KEY.txt")) {
                writeText -text "Encryption key deleted."
            } else {
                writeText -text "Encryption key not deleted!"
            }
        
            if (-not (Test-Path -Path "$env:SystemRoot\Temp\PHRASE.txt")) {
                writeText -text "Encryption phrase deleted."
            } else {
                writeText -text "Encryption phrase not deleted!"
            }
        }
    } catch {
        writeText -type "error" -text "add-intechadmin-$($_.InvocationInfo.ScriptLineNumber) | $($_.Exception.Message)"
    }
}
function invokeScript {
    param (
        [parameter(Mandatory = $true)]
        [string]$script,
        [parameter(Mandatory = $false)]
        [boolean]$initialize = $false
    ) 

    try {
        if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
            Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" $PSCommandArgs" -WorkingDirectory $pwd -Verb RunAs
            Exit
        } 

        # Customize console appearance
        $console = $host.UI.RawUI
        $console.BackgroundColor = "Black"
        $console.ForegroundColor = "Gray"
        $console.WindowTitle = "InTech Scripts"

        if ($initialize) {
            Clear-Host
            Write-Host
            Write-Host "  Try" -NoNewline
            Write-Host " help" -ForegroundColor "Cyan" -NoNewline
            Write-Host " or" -NoNewline
            Write-Host " menu" -NoNewline -ForegroundColor "Cyan"
            Write-Host " if you don't know what to do."
        }

        Invoke-Expression $script
    } catch {
        writeText -type "error" -text "invokeScript-$($_.InvocationInfo.ScriptLineNumber) | $($_.Exception.Message)"
    }
}
function readCommand {
    param (
        [parameter(Mandatory = $false)]
        [string]$command = ""
    )

    try {
        Write-Host
        if ($command -eq "") { 
            Write-Host "$([char]0x203A) " -NoNewline
            $command = Read-Host 
        }

        $command = $command.ToLower()
        $command = $command.Trim()

        if ($command -ne "help" -and $command -ne "" -and $command -match "^(?-i)(\w+(-\w+)*)") {
            if (Get-command $matches[1] -ErrorAction SilentlyContinue) {
                if ($matches[1] -ne "intech" -and $matches[1] -ne "nuvia" -and $matches[1] -ne "isr") {
                    Invoke-Expression $command
                    readCommand
                }
            }
        }

        $filteredCommand = filterCommands -command $command
        $commandDirectory = $filteredCommand[0]
        $commandFile = $filteredCommand[1]
        $commandFunction = $filteredCommand[2]

        New-Item -Path "$env:SystemRoot\Temp\ShellCLI.ps1" -ItemType File -Force | Out-Null
        addScript -directory $commandDirectory -file $commandFile
        addScript -directory "core" -file "Framework"
        Add-Content -Path "$env:SystemRoot\Temp\ShellCLI.ps1" -Value "invokeScript '$commandFunction'"
        Add-Content -Path "$env:SystemRoot\Temp\ShellCLI.ps1" -Value "readCommand"

        $shellCLI = Get-Content -Path "$env:SystemRoot\Temp\ShellCLI.ps1" -Raw
        Invoke-Expression $shellCLI
    } catch {
        writeText -type "error" -text "readCommand-$($_.InvocationInfo.ScriptLineNumber) | $($_.Exception.Message)"
    }
}
function filterCommands {
    param (
        [parameter(Mandatory)]
        [string]$command
    )

    try {
        $commandArray = $()

        switch ($command) {
            "help" { $commandArray = $("windows", "Helpers", "writeHelp"); break }
            "menu" { $commandArray = $("windows", "Helpers", "readMenu"); break }
            "toggle context menu" { $commandArray = $("windows", "Toggle Context Menu", "toggleContextMenu"); break }
            "toggle admin" { $commandArray = $("windows", "Toggle Admin", "toggleAdmin"); break }
            "enable admin" { $commandArray = $("windows", "Toggle Admin", "enableAdmin"); break }
            "disable admin" { $commandArray = $("windows", "Toggle Admin", "disableAdmin"); break }
            "add user" { $commandArray = $("windows", "Add User", "addUser"); break }
            "add local user" { $commandArray = $("windows", "Add User", "addLocalUser"); break }
            "add ad user" { $commandArray = $("windows", "Add User", "addUser"); break }
            "add drive letter" { $commandArray = $("windows", "Add Drive Letter", "addDriveLetter"); break }
            "remove user" { $commandArray = $("windows", "Remove User", "removeUser"); break }
            "edit hostname" { $commandArray = $("windows", "Edit Hostname", "editHostname"); break }
            "edit user" { $commandArray = $("windows", "Edit User", "editUser"); break }
            "edit user name" { $commandArray = $("windows", "Edit User", "editUserName"); break }
            "edit user password" { $commandArray = $("windows", "Edit User", "editUserPassword"); break }
            "edit user group" { $commandArray = $("windows", "Edit User", "editUserGroup"); break }
            "edit net adapter" { $commandArray = $("windows", "Edit Net Adapter", "editNetAdapter"); break }
            "get wifi creds" { $commandArray = $("windows", "Get Wifi Creds", "getWifiCreds"); break }
            "schedule task" { $commandArray = $("windows", "Schedule Task", "scheduleTask"); break }
            "install updates" { $commandArray = $("windows", "Install Updates", "installUpdates"); break }
            "plugins" { $commandArray = $("plugins", "Helpers", "plugins"); break }
            "plugins menu" { $commandArray = $("plugins", "Helpers", "readMenu"); break }
            "plugins help" { $commandArray = $("plugins", "Helpers", "writeHelp"); break }
            "plugins reclaim" { $commandArray = $("plugins", "ReclaimW11", "reclaim"); break }
            "plugins massgravel" { $commandArray = $("plugins", "massgravel", "massgravel"); break }
            "plugins win11debloat" { $commandArray = $("plugins", "win11Debloat", "win11debloat"); break }
            "intech" { $commandArray = $("intech", "Helpers", "intech"); break }
            "intech help" { $commandArray = $("intech", "Helpers", "writeHelp"); break }
            "intech menu" { $commandArray = $("intech", "Helpers", "readMenu"); break }
            "intech add admin" { $commandArray = $("intech", "Add InTech Admin", "addInTechAdmin"); break }
            "intech schedule reboot" { $commandArray = $("intech", "Schedule Reboot", "scheduleReboot"); break }
            "nuvia help" { $commandArray = $("nuvia", "Helpers", "writeHelp"); break }
            "nuvia menu" { $commandArray = $("nuvia", "Helpers", "readMenu"); break }
            "nuvia install bginfo" { $commandArray = $("nuvia", "Install BGInfo", "installBGInfo"); break }
            "nuvia install jumpcloud" { $commandArray = $("nuvia", "Install JumpCloud", "installJumpCloud"); break }
            "nuvia install ninja" { $commandArray = $("nuvia", "Install Ninja", "installNinja"); break }
            "nuvia install tscan" { $commandArray = $("nuvia", "Install Tscan", "installTscan"); break }
            "nuvia isr install apps" { $commandArray = $("nuvia", "ISR Install Apps", "isrInstallApps"); break }
            "isr install apps" { $commandArray = $("nuvia", "ISR Install Apps", "isrInstallApps"); break }
            "nuvia isr add bookmarks" { $commandArray = $("nuvia", "ISR Add Bookmarks", "isrAddBookmarks"); break }
            "isr add bookmarks" { $commandArray = $("nuvia", "ISR Add Bookmarks", "isrAddBookmarks"); break }
            "nuvia isr onboard" { $commandArray = $("nuvia", "ISR Onboard", "isrOnboard"); break }
            "isr onboard" { $commandArray = $("nuvia", "ISR Onboard", "isrOnboard"); break }
            default { 
                Write-Host "  Unrecognized command. Try" -NoNewline
                Write-Host " help" -ForegroundColor "Cyan" -NoNewline
                Write-Host " or" -NoNewline
                Write-Host " menu" -NoNewline -ForegroundColor "Cyan"
                Write-Host " to learn more."
                readCommand 
            }
        }

        return $commandArray
    } catch {
        writeText -type "error" -text "filterCommands-$($_.InvocationInfo.ScriptLineNumber) | $($_.Exception.Message)"
    }
}
function addScript {
    param (
        [parameter(Mandatory)]
        [string]$directory,
        [parameter(Mandatory)]
        [string]$file
    )

    try {
        $url = "https://raw.githubusercontent.com/badsyntaxx/intech-scripts/main"

        if ($directory -eq 'windows' -or $directory -eq 'plugins') {
            $url = "https://raw.githubusercontent.com/badsyntaxx/shellcli/main"
        }

        getDownload -url "$url/$directory/$file.ps1" -target "$env:SystemRoot\Temp\$file.ps1"

        $rawScript = Get-Content -Path "$env:SystemRoot\Temp\$file.ps1" -Raw -ErrorAction SilentlyContinue
        Add-Content -Path "$env:SystemRoot\Temp\ShellCLI.ps1" -Value $rawScript

        Get-Item -ErrorAction SilentlyContinue "$env:SystemRoot\Temp\$file.ps1" | Remove-Item -ErrorAction SilentlyContinue
    } catch {
        writeText -type "error" -text "addScript-$($_.InvocationInfo.ScriptLineNumber) | $($_.Exception.Message)"
    }
}
function writeText {
    param (
        [parameter(Mandatory = $false)]
        [string]$label = "",
        [parameter(Mandatory = $false)]
        [string]$text = "",
        [parameter(Mandatory = $false)]
        [string]$type = "plain",
        [parameter(Mandatory = $false)]
        [string]$Color = "Gray",
        [parameter(Mandatory = $false)]
        [switch]$lineBefore = $false, # Add a new line before output if specified
        [parameter(Mandatory = $false)]
        [switch]$lineAfter = $false, # Add a new line after output if specified
        [parameter(Mandatory = $false)]
        [System.Collections.Specialized.OrderedDictionary]$List,
        [parameter(Mandatory = $false)]
        [System.Collections.Specialized.OrderedDictionary]$oldData,
        [parameter(Mandatory = $false)]
        [System.Collections.Specialized.OrderedDictionary]$newData
    )

    try {
        # Add a new line before output if specified
        if ($lineBefore) { Write-Host }

        # Format output based on the specified Type
        if ($type -eq "header") {
            Write-Host "# " -ForegroundColor "Cyan" -NoNewline
            Write-Host "$text" -ForegroundColor "White" 
        }

        if ($type -eq 'success') { 
            Write-Host
            Write-Host "    $([char]0x2713) $text"  -ForegroundColor "Green"
            Write-Host
        }

        if ($type -eq 'error') { 
            Write-Host
            Write-Host "    X $text" -ForegroundColor "Red"
            Write-Host 
        }

        if ($type -eq 'notice') { 
            Write-Host "! $text" -ForegroundColor "Yellow" 
        }

        if ($type -eq 'plain') {
            if ($label -ne "") { 
                if ($Color -eq "Gray") {
                    $Color = 'DarkCyan'
                }
                Write-Host "  $label`: " -NoNewline -ForegroundColor "Gray"
                Write-Host "$text" -ForegroundColor $Color 
            } else {
                Write-Host "  $text" -ForegroundColor $Color 
            }
        }

        if ($type -eq 'list') { 
            # Get a list of keys from the options dictionary
            $orderedKeys = $List.Keys | ForEach-Object { $_ }

            # Find the length of the longest key for padding
            $longestKeyLength = ($orderedKeys | Measure-Object -Property Length -Maximum).Maximum

            # Display single option if only one exists
            if ($orderedKeys.Count -eq 1) {
                Write-Host " $($orderedKeys) $(" " * ($longestKeyLength - $orderedKeys.Length)) - $($List[$orderedKeys])"
            } else {
                # Loop through each option and display with padding and color
                for ($i = 0; $i -lt $orderedKeys.Count; $i++) {
                    $key = $orderedKeys[$i]
                    $padding = " " * ($longestKeyLength - $key.Length)
                    Write-Host "    $($key): $padding $($List[$key])" -ForegroundColor $Color
                }
            }
        }

        # Add a new line after output if specified
        if ($lineAfter) { Write-Host }
    } catch {
        writeText -type "error" -text "writeText-$($_.InvocationInfo.ScriptLineNumber) | $($_.Exception.Message)"
    }
}
function readInput {
    param (
        [parameter(Mandatory = $false)]
        [string]$Value = "", # A pre-fill value so the user can hit enter without typing command and get the current value if there is one
        [parameter(Mandatory = $false)]
        [string]$prompt, # Provide a specific prompt in necessary
        [parameter(Mandatory = $false)]
        [regex]$Validate = $null,
        [parameter(Mandatory = $false)]
        [string]$ErrorMessage = "", # Provide an optional error message
        [parameter(Mandatory = $false)]
        [switch]$IsSecure = $false, # If prompting for a password
        [parameter(Mandatory = $false)]
        [switch]$CheckExistingUser = $false,
        [parameter(Mandatory = $false)]
        [switch]$lineBefore = $false, # Add a new line before prompt if specified
        [parameter(Mandatory = $false)]
        [switch]$lineAfter = $false # Add a new line after prompt if specified
    )

    try {
        # Add a new line before prompt if specified
        if ($lineBefore) { Write-Host }

        # Get current cursor position
        $currPos = $host.UI.RawUI.CursorPosition

        Write-Host "? " -NoNewline -ForegroundColor "Cyan"
        Write-Host "$prompt " -NoNewline

        if ($IsSecure) { $userInput = Read-Host -AsSecureString } 
        else { $userInput = Read-Host }

        # Check for existing user if requested
        if ($CheckExistingUser) {
            $account = Get-LocalUser -Name $userInput -ErrorAction SilentlyContinue
            if ($null -ne $account) { $ErrorMessage = "An account with that name already exists." }
        }

        # Validate user input against provided regular expression
        if ($userInput -notmatch $Validate) { $ErrorMessage = "Invalid input. Please try again." } 

        # Display error message if encountered
        if ($ErrorMessage -ne "") {
            writeText -type "error" -text $ErrorMessage
            # Recursively call readInput if user exists
            if ($CheckExistingUser) { return readInput -prompt $prompt -Validate $Validate -CheckExistingUser } 

            # Otherwise, simply call again without CheckExistingUser
            else { return readInput -prompt $prompt -Validate $Validate }
        }

        # Use provided default value if user enters nothing for a non-secure input
        if ($userInput.Length -eq 0 -and $Value -ne "" -and !$IsSecure) { $userInput = $Value }

        # Reset cursor position
        [Console]::SetCursorPosition($currPos.X, $currPos.Y)
        
        Write-Host "? " -ForegroundColor "Cyan" -NoNewline
        if ($IsSecure -and ($userInput.Length -eq 0)) { 
            Write-Host "$prompt                                                "
        } else { 
            Write-Host "$prompt " -NoNewline
            Write-Host "$userInput                                             " -ForegroundColor "DarkCyan"
        }

        # Add a new line after prompt if specified
        if ($lineAfter) { Write-Host }
    
        # Return the validated user input
        return $userInput
    } catch {
        writeText -type "error" -text "readInput-$($_.InvocationInfo.ScriptLineNumber) | $($_.Exception.Message)"
    }
}
function readOption {
    param (
        [parameter(Mandatory = $true)]
        [System.Collections.Specialized.OrderedDictionary]$options,
        [parameter(Mandatory = $false)]
        [string]$prompt, # Provide a specific prompt in necessary
        [parameter(Mandatory = $false)]
        [switch]$returnKey = $false,
        [parameter(Mandatory = $false)]
        [switch]$returnValue = $false,
        [parameter(Mandatory = $false)]
        [switch]$lineBefore = $false,
        [parameter(Mandatory = $false)]
        [switch]$lineAfter = $false
    )

    try {
        # Add a line break before the menu if lineBefore is specified
        if ($lineBefore) { Write-Host }

        # Get current cursor position
        $promptPos = $host.UI.RawUI.CursorPosition

        Write-Host "? " -NoNewline -ForegroundColor "Cyan"
        Write-Host "$prompt "

        # Initialize variables for user input handling
        $vkeycode = 0
        $pos = 0
        $oldPos = 0

        # Get a list of keys from the options dictionary
        $orderedKeys = $options.Keys | ForEach-Object { $_ }

        # Get an array of all values
        $values = $options.Values

        # Find the length of the longest key for padding
        $longestKeyLength = ($orderedKeys | Measure-Object -Property Length -Maximum).Maximum

        # Find the length of the longest value
        $longestValueLength = ($values | Measure-Object -Property Length -Maximum).Maximum

        # Display single option if only one exists
        if ($orderedKeys.Count -eq 1) {
            Write-Host "$([char]0x2192)" -ForegroundColor "DarkCyan" -NoNewline
            Write-Host "  $($orderedKeys) $(" " * ($longestKeyLength - $orderedKeys.Length)) - $($options[$orderedKeys])" -ForegroundColor "DarkCyan"
        } else {
            # Loop through each option and display with padding and color
            for ($i = 0; $i -lt $orderedKeys.Count; $i++) {
                $key = $orderedKeys[$i]
                $padding = " " * ($longestKeyLength - $key.Length)
                if ($i -eq $pos) { 
                    Write-Host "$([char]0x2192)" -ForegroundColor "DarkCyan" -NoNewline  
                    Write-Host " $key $padding - $($options[$key])" -ForegroundColor "DarkCyan"
                } else { 
                    Write-Host "  $key $padding - $($options[$key])" -ForegroundColor "Gray" 
                }
            }
        }

        # Get the current cursor position
        $currPos = $host.UI.RawUI.CursorPosition

        # Loop for user input to select an option
        While ($vkeycode -ne 13) {
            $press = $host.ui.rawui.readkey("NoEcho, IncludeKeyDown")
            $vkeycode = $press.virtualkeycode
            Write-host "$($press.character)" -NoNewLine
            if ($orderedKeys.Count -ne 1) { 
                $oldPos = $pos;
                if ($vkeycode -eq 38) { $pos-- }
                if ($vkeycode -eq 40) { $pos++ }
                if ($pos -lt 0) { $pos = 0 }
                if ($pos -ge $orderedKeys.Count) { $pos = $orderedKeys.Count - 1 }

                # Calculate positions for redrawing menu items
                $menuLen = $orderedKeys.Count
                $menuOldPos = New-Object System.Management.Automation.Host.Coordinates(0, ($currPos.Y - ($menuLen - $oldPos)))
                $menuNewPos = New-Object System.Management.Automation.Host.Coordinates(0, ($currPos.Y - ($menuLen - $pos)))
                $oldKey = $orderedKeys[$oldPos]
                $newKey = $orderedKeys[$pos]
            
                # Re-draw the previously selected and newly selected options
                $host.UI.RawUI.CursorPosition = $menuOldPos
                Write-Host "  $($orderedKeys[$oldPos]) $(" " * ($longestKeyLength - $oldKey.Length)) - $($options[$orderedKeys[$oldPos]])" -ForegroundColor "Gray"
                $host.UI.RawUI.CursorPosition = $menuNewPos
                Write-Host "$([char]0x2192)" -ForegroundColor "DarkCyan" -NoNewline
                Write-Host " $($orderedKeys[$pos]) $(" " * ($longestKeyLength - $newKey.Length)) - $($options[$orderedKeys[$pos]])" -ForegroundColor "DarkCyan"
                $host.UI.RawUI.CursorPosition = $currPos
            }
        }

        [Console]::SetCursorPosition($promptPos.X, $promptPos.Y)

        if ($orderedKeys.Count -ne 1) {
            Write-Host "? " -ForegroundColor "Cyan" -NoNewline
            Write-Host $prompt -NoNewline
            Write-Host " $($orderedKeys[$pos])" -ForegroundColor "DarkCyan"
        } else {
            Write-Host "? " -ForegroundColor "Cyan" -NoNewline
            Write-Host $prompt -NoNewline
            Write-Host " $($orderedKeys) $(" " * ($longestKeyLength - $orderedKeys.Length))" -ForegroundColor "DarkCyan"
        }

        for ($i = 0; $i -lt $options.Count; $i++) {
            Write-Host "       $(" " * ($longestKeyLength + $longestValueLength))"
        }
        
        [Console]::SetCursorPosition($promptPos.X, $promptPos.Y)
        Write-Host

        # Add a line break after the menu if lineAfter is specified
        if ($lineAfter) { Write-Host }

        # Handle function return values (key, value, menu position) based on parameters
        if ($returnKey) { 
            if ($orderedKeys.Count -eq 1) { 
                return $orderedKeys 
            } else { 
                return $orderedKeys[$pos] 
            } 
        } 
        if ($returnValue) { 
            if ($orderedKeys.Count -eq 1) { 
                return $options[$pos] 
            } else { 
                return $options[$orderedKeys[$pos]] 
            } 
        } else { 
            return $pos 
        }
    } catch {
        writeText -type "error" -text "readOption-$($_.InvocationInfo.ScriptLineNumber) | $($_.Exception.Message)"
    }
}
function getDownload {
    param (
        [parameter(Mandatory)]
        [string]$url,
        [parameter(Mandatory)]
        [string]$target,
        [parameter(Mandatory = $false)]
        [string]$label = 'Loading',
        [parameter(Mandatory = $false)]
        [string]$failText = 'Download failed...',
        [parameter(Mandatory = $false)]
        [int]$MaxRetries = 2,
        [parameter(Mandatory = $false)]
        [int]$Interval = 1,
        [parameter(Mandatory = $false)]
        [switch]$visible = $false
    )
    Begin {
        function Show-Progress {
            param (
                [parameter(Mandatory)]
                [Single]$totalValue,
                [parameter(Mandatory)]
                [Single]$currentValue,
                [parameter(Mandatory)]
                [string]$label,
                [parameter()]
                [string]$ValueSuffix,
                [parameter()]
                [int]$BarSize = 40,
                [parameter()]
                [switch]$Complete
            )
            
            # calc %
            $percent = $currentValue / $totalValue
            $percentComplete = $percent * 100
            if ($ValueSuffix) {
                $ValueSuffix = " $ValueSuffix" # add space in front
            }
  
            # build progressbar with string function
            $curBarSize = $BarSize * $percent
            $progbar = ""
            $progbar = $progbar.PadRight($curBarSize, [char]9608)
            $progbar = $progbar.PadRight($BarSize, [char]9617)

            if (!$Complete.IsPresent) {
                Write-Host -NoNewLine "`r    $label $progbar $($percentComplete.ToString("##0.00").PadLeft(6))%"
            } else {
                Write-Host -NoNewLine "`r    $label $progbar $($percentComplete.ToString("##0.00").PadLeft(6))%"                    
            }              
             
        }
    }
    Process {
        $downloadComplete = $true 
        for ($retryCount = 1; $retryCount -le $MaxRetries; $retryCount++) {
            try {
                $storeEAP = $ErrorActionPreference
                $ErrorActionPreference = 'Stop'
        
                # invoke request
                $request = [System.Net.HttpWebRequest]::Create($url)
                $response = $request.GetResponse()
  
                if ($response.StatusCode -eq 401 -or $response.StatusCode -eq 403 -or $response.StatusCode -eq 404) {
                    throw "Remote file either doesn't exist, is unauthorized, or is forbidden for '$url'."
                }
  
                if ($target -match '^\.\\') {
                    $target = Join-Path (Get-Location -PSProvider "FileSystem") ($target -Split '^\.')[1]
                }
            
                if ($target -and !(Split-Path $target)) {
                    $target = Join-Path (Get-Location -PSProvider "FileSystem") $target
                }

                if ($target) {
                    $fileDirectory = $([System.IO.Path]::GetDirectoryName($target))
                    if (!(Test-Path($fileDirectory))) {
                        [System.IO.Directory]::CreateDirectory($fileDirectory) | Out-Null
                    }
                }

                [long]$fullSize = $response.ContentLength
                $fullSizeMB = $fullSize / 1024 / 1024
  
                # define buffer
                [byte[]]$buffer = new-object byte[] 1048576
                [long]$total = [long]$count = 0
  
                # create reader / writer
                $reader = $response.GetResponseStream()
                $writer = new-object System.IO.FileStream $target, "Create"
  
                # start download
                $finalBarCount = 0 #show final bar only one time
                do {
                    $count = $reader.Read($buffer, 0, $buffer.Length)
          
                    $writer.Write($buffer, 0, $count)
              
                    $total += $count
                    $totalMB = $total / 1024 / 1024
          
                    if ($visible) {
                        if ($fullSize -gt 0) {
                            Show-Progress -totalValue $fullSizeMB -currentValue $totalMB -label $label -ValueSuffix "MB"
                        }

                        if ($total -eq $fullSize -and $count -eq 0 -and $finalBarCount -eq 0) {
                            Show-Progress -totalValue $fullSizeMB -currentValue $totalMB -label $label -ValueSuffix "MB" -Complete
                            $finalBarCount++
                        }
                    }
                } while ($count -gt 0)

                # Prevent the following output from appearing on the same line as the progress bar
                if ($visible) {
                    Write-Host 
                }
                
                if ($downloadComplete) { 
                    return $true 
                } else { 
                    return $false 
                }
            } catch {
                # writeText -type "fail" -text "$($_.Exception.Message)"
                writeText -type "fail" -text $failText
                
                $downloadComplete = $false
            
                if ($retryCount -lt $MaxRetries) {
                    writeText "Retrying..."
                    Start-Sleep -Seconds $Interval
                } else {
                    writeText -type "error" -text "Maximum retries reached." 
                }
            } finally {
                # cleanup
                if ($reader) { 
                    $reader.Close() 
                }
                if ($writer) { 
                    $writer.Flush() 
                    $writer.Close() 
                }
        
                $ErrorActionPreference = $storeEAP
                [GC]::Collect()
            } 
        }   
    }
}
function getUserData {
    param (
        [parameter(Mandatory = $true)]
        [string]$username
    )

    try {
        $user = Get-LocalUser -Name $username
        $groups = Get-LocalGroup | Where-Object { $user.SID -in ($_ | Get-LocalGroupMember | Select-Object -ExpandProperty "SID") } | Select-Object -ExpandProperty "Name"
        $userProfile = Get-CimInstance Win32_UserProfile -Filter "SID = '$($user.SID)'"
        $dir = $userProfile.LocalPath
        if ($null -ne $userProfile) { $dir = $userProfile.LocalPath } else { $dir = "Awaiting first sign in." }

        $source = Get-LocalUser -Name $username | Select-Object -ExpandProperty PrincipalSource

        $data = [ordered]@{
            "Name"   = "$username"
            "Groups" = "$($groups -join ';')"
            "Path"   = "$dir"
            "Source" = "$source"
        }

        return $data
    } catch {
        writeText -type "error" -text "getUserData-$($_.InvocationInfo.ScriptLineNumber) | $($_.Exception.Message)"
    }
}
function selectUser {
    param (
        [parameter(Mandatory = $false)]
        [string]$prompt = "Select a user account:",
        [parameter(Mandatory = $false)]
        [switch]$lineBefore = $false,
        [parameter(Mandatory = $false)]
        [switch]$lineAfter = $false,
        [parameter(Mandatory = $false)]
        [switch]$writeResult = $false
    )

    try {
        # Add a line break before the menu if lineBefore is specified
        if ($lineBefore) { Write-Host }
         
        # Initialize empty array to store user names
        $userNames = @()

        # Get all local users on the system
        $localUsers = Get-LocalUser

        # Define a list of accounts to exclude from selection
        $excludedAccounts = @("DefaultAccount", "WDAGUtilityAccount", "Guest", "defaultuser0")

        # Check if the "Administrator" account is disabled and add it to excluded list if so
        $adminEnabled = Get-LocalUser -Name "Administrator" | Select-Object -ExpandProperty Enabled
        if (!$adminEnabled) { $excludedAccounts += "Administrator" }

        # Filter local users to exclude predefined accounts
        foreach ($user in $localUsers) {
            if ($user.Name -notin $excludedAccounts) { $userNames += $user.Name }
        }

        # Create an ordered dictionary to store username and group information
        $accounts = [ordered]@{}
        foreach ($name in $userNames) {
            # Get details for the current username
            $username = Get-LocalUser -Name $name
            
            # Find groups the user belongs to
            $groups = Get-LocalGroup | Where-Object { $username.SID -in ($_ | Get-LocalGroupMember | Select-Object -ExpandProperty "SID") } | Select-Object -ExpandProperty "Name"
            # Convert groups to a semicolon-separated string
            $groupString = $groups -join ';'

            # Get the users source
            $source = Get-LocalUser -Name $username | Select-Object -ExpandProperty PrincipalSource

            # Add username and group string to the dictionary
            $accounts["$username"] = "$source | $groupString"
        }

        $accounts["Cancel"] = "Do not select a user and exit this function."

        # Prompt user to select a user from the list and return the key (username)
        $choice = readOption -options $accounts -prompt $prompt -returnKey

        if ($choice -eq "Cancel") {
            readCommand
        }

        # Get user data using the selected username
        $data = getUserData -Username $choice

        if ($writeResult) {
            Write-Host
            # Display user data as a list
            writeText -type "list" -List $data -Color "Green"
        }

        # Add a line break after the menu if lineAfter is specified
        if ($lineAfter) { Write-Host }

        # Return the user data dictionary
        return $data
    } catch {
        writeText -type "error" -text "selectUser-$($_.InvocationInfo.ScriptLineNumber) | $($_.Exception.Message)"
    }
}

invokeScript -script "addInTechAdmin" -initialize $true
