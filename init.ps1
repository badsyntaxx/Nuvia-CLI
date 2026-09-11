function initializeShellCLI {
    try {
        # Check if user has administrator privileges
        if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
            log -msg "Terminal is not admin. Self elevating."
            # If not, elevate privileges and restart function with current arguments
            Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" $PSCommandArgs" -WorkingDirectory $pwd -Verb RunAs
            Exit
        }
        
        log -msg "Initializing ShellCLI"

        createNuviaFolders
        
        # Create the main script file
        log -msg "Building main script"
        New-Item -Path "$env:ProgramData\Nuvia\temp\SHELLCLI.ps1" -ItemType File -Force | Out-Null

        if (-not (Test-Path -Path "$env:ProgramData\Nuvia\temp\SHELLCLI.ps1")) {
            log -msg "Failed to create main script file" -lvl "ERROR"
            throw "Failed to create main script file"
        }

        appendToMainScript -file "framework"
        appendToMainScript -directory "nuvia" -file "core"

        # Add a final line that will invoke the desired function
        Add-Content -Path "$env:ProgramData\Nuvia\temp\SHELLCLI.ps1" -Value 'invokeScript -script "readCommand -command `"n?`"" -initialize $true'

        log -msg "Running main script"
        # Execute the combined script
        . "$env:ProgramData\Nuvia\temp\SHELLCLI.ps1"
    } catch {
        Write-Host "  $($MyInvocation.MyCommand.Name)-$($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor "Red"
        log -msg "$($MyInvocation.MyCommand.Name)-$($_.InvocationInfo.ScriptLineNumber):$($_.Exception.Message)"
    }
}
function appendToMainScript {
    param (
        [Parameter(Mandatory = $false)][string]$directory,
        [Parameter(Mandatory)][string]$file
    )

    $oldProgress = $ProgressPreference
    $ProgressPreference = 'SilentlyContinue'

    try {
        $url = "https://raw.githubusercontent.com/badsyntaxx/Nuvia-CLI/main/$file.ps1"
        if ($directory) {
            $url = "https://raw.githubusercontent.com/badsyntaxx/Nuvia-CLI/main/$directory/$file.ps1"
        }

        $src = (Invoke-WebRequest -Uri $url -UseBasicParsing).Content
        Add-Content -Path "$env:ProgramData\Nuvia\temp\SHELLCLI.ps1" -Value $src
    } catch {
        Write-Host "  $($MyInvocation.MyCommand.Name)-$($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor "Red"
        log -msg "$($MyInvocation.MyCommand.Name)-$($_.InvocationInfo.ScriptLineNumber):$($_.Exception.Message)"
    } finally {
        $ProgressPreference = $oldProgress
    }
}
function log {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$msg,
        [Parameter(Position = 1)]
        [ValidateSet('INFO', 'WARNING', 'ERROR', 'DEBUG', 'SUCCESS')]
        [string]$lvl = 'INFO'
    )

    try {      
        # Define log directory
        $logDirectory = "$env:ProgramData\Nuvia\logs\shellcli"
        
        # Create log directory if it doesn't exist
        if (-not (Test-Path -Path $logDirectory)) {
            try {
                New-Item -Path $logDirectory -ItemType Directory -Force -ErrorAction Stop | Out-Null
            } catch {
                Write-Error "Failed to create log directory: $_"
                return
            }
        }
        
        # Define log file path
        $dateStamp = Get-Date -Format "yyyy-MM-dd"
        $logFileName = "${dateStamp}.log"
        $logFilePath = Join-Path -Path $logDirectory -ChildPath $logFileName

        # Format log entry
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logEntry = "[$timestamp] [$lvl] $msg"
            
        # Write to log file
        Add-Content -Path $logFilePath -Value $logEntry -ErrorAction Stop
    } catch {
        Write-Error "Failed to write log entry: $_"
    }
}
function createNuviaFolders {
    $rootPath = "$env:ProgramData\Nuvia"

    log -msg "Setting up Nuvia folders at $rootPath..."

    # Create root + subfolders
    $subFolders = @("temp", "tools", "backups", "logs", "state")

    # Check if root and all subfolders already exist
    $allExist = Test-Path $rootPath
    if ($allExist) {
        foreach ($folder in $subFolders) {
            $fullPath = Join-Path $rootPath $folder
            if (-not (Test-Path $fullPath)) {
                $allExist = $false
                break
            }
        }
    }

    if ($allExist) {
        log -msg "$rootPath and all subfolders already exist. Skipping setup."
        return
    }

    if (-not (Test-Path $rootPath)) {
        New-Item -Path $rootPath -ItemType Directory | Out-Null
        log -msg "Created $rootPath"
    }

    foreach ($folder in $subFolders) {
        $fullPath = Join-Path $rootPath $folder
        if (-not (Test-Path $fullPath)) {
            New-Item -Path $fullPath -ItemType Directory | Out-Null
            log -msg "Created $fullPath"
        }
    }

    # Hide the root folder 
    $item = Get-Item $rootPath -Force
    $item.Attributes = $item.Attributes -bor [System.IO.FileAttributes]::Hidden

    # Restrict access to Administrators only 
    # Disable inheritance and grant full control only to Administrators + SYSTEM
    icacls $rootPath /inheritance:r | Out-Null
    icacls $rootPath /grant:r "Administrators:(OI)(CI)F" | Out-Null
    icacls $rootPath /grant:r "SYSTEM:(OI)(CI)F" | Out-Null
    # Remove other default grants like Users/Authenticated Users if present
    icacls $rootPath /remove "Users" "Authenticated Users" "Everyone" 2>$null | Out-Null

    log -msg "Restricted $rootPath to Administrators/SYSTEM only."

    # Set machine-level environment variable %n% ---
    [Environment]::SetEnvironmentVariable("na", $rootPath, "Machine")
    $env:n = $rootPath  # make it available in current session too

    log -msg "Environment variable 'na' set to $rootPath (restart other shells to pick it up)."
}

# Invoke the root of Shell CLI
initializeShellCLI
