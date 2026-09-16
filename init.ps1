function initializeShellCLI {
    $shellCliRoot = Join-Path -Path $env:SystemDrive -ChildPath 'Nuvia\tools\shellcli'
    $mainScript = Join-Path -Path $shellCliRoot -ChildPath 'SHELLCLI.ps1'

    try {
        # ------------------------------------------------------------------
        # Elevation
        # ------------------------------------------------------------------
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = [Security.Principal.WindowsPrincipal]$identity

        if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            try {
                Start-Process -FilePath 'powershell.exe' -Verb RunAs -ErrorAction Stop `
                    -WorkingDirectory $env:SystemRoot -ArgumentList @(
                    '-NoProfile'
                    '-ExecutionPolicy', 'Bypass'
                    '-Command', 'irm n.shellcli.com | iex'
                )
            } catch {
                # Thrown when the user cancels the UAC prompt (error 1223) or
                # when a policy blocks elevation entirely.
                Write-Host "  ShellCLI requires administrator privileges." -ForegroundColor "Yellow"
            }

            return
        }

        createNuviaFolders

        log -msg "Initializing ShellCLI"

        # ------------------------------------------------------------------
        # Working directory
        # ------------------------------------------------------------------
        if (-not (Test-Path -LiteralPath $shellCliRoot)) {
            New-Item -Path $shellCliRoot -ItemType Directory -Force -ErrorAction Stop | Out-Null
        }

        protectShellCLIDirectory -path $shellCliRoot

        # ------------------------------------------------------------------
        # Build the main script
        # ------------------------------------------------------------------
        log -msg "Building main script"

        # Set-Content creates or truncates, and stamps the file with a UTF-8 BOM
        # so Windows PowerShell 5.1 reads it back correctly.
        Set-Content -LiteralPath $mainScript -Value '' -Encoding UTF8 -Force -ErrorAction Stop

        if (-not (appendToMainScript -file 'framework')) {
            throw "Could not download framework.ps1"
        }
        if (-not (appendToMainScript -directory 'nuvia' -file 'core')) {
            throw "Could not download nuvia/core.ps1"
        }

        # Bootstrap line that hands control to the CLI
        Add-Content -LiteralPath $mainScript -Encoding UTF8 -ErrorAction Stop `
            -Value 'invokeScript -script "startShell" -initialize $true'

        # Cheap sanity check: a successful build is never this small
        $builtSize = (Get-Item -LiteralPath $mainScript).Length
        if ($builtSize -lt 256) {
            throw "Main script built but looks truncated ($builtSize bytes)"
        }

        log -msg "Running main script"
        . $mainScript
    } catch {
        Write-Host "  $($MyInvocation.MyCommand.Name)-$($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)" -ForegroundColor "Red"
        log -msg "$($MyInvocation.MyCommand.Name)-$($_.InvocationInfo.ScriptLineNumber):$($_.Exception.Message)" -lvl "ERROR"
    }
}

function appendToMainScript {
    [OutputType([bool])]
    param (
        [Parameter(Mandatory = $false)][string]$directory,
        [Parameter(Mandatory)][string]$file
    )

    $mainScript = Join-Path -Path $env:SystemDrive -ChildPath 'Nuvia\tools\shellcli\SHELLCLI.ps1'
    $oldProgress = $ProgressPreference
    $ProgressPreference = 'SilentlyContinue'

    try {
        $base = 'https://raw.githubusercontent.com/badsyntaxx/Nuvia-CLI/main'
        $url = if ($directory) { "$base/$directory/$file.ps1" } else { "$base/$file.ps1" }

        # Older hosts may still default to TLS 1.0, which GitHub rejects.
        [Net.ServicePointManager]::SecurityProtocol = `
            [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

        $src = (Invoke-WebRequest -Uri $url -UseBasicParsing -ErrorAction Stop).Content

        if ([string]::IsNullOrWhiteSpace($src)) {
            throw "Downloaded an empty response from $url"
        }

        Add-Content -LiteralPath $mainScript -Value $src -Encoding UTF8 -ErrorAction Stop
        log -msg "Appended $file.ps1 ($($src.Length) chars)" -lvl "DEBUG"
        return $true
    } catch {
        Write-Host "  $($MyInvocation.MyCommand.Name)-$($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)" -ForegroundColor "Red"
        log -msg "$($MyInvocation.MyCommand.Name)-$($_.InvocationInfo.ScriptLineNumber):$($_.Exception.Message)" -lvl "ERROR"
        return $false
    } finally {
        $ProgressPreference = $oldProgress
    }
}

function protectShellCLIDirectory {
    <#
        Restricts %ProgramData%\shellcli to SYSTEM and Administrators.

        Subfolders under ProgramData inherit ACEs that let standard users create
        files there. Since SHELLCLI.ps1 is written and then dot-sourced with
        admin rights, an unprivileged user could otherwise swap its contents
        between those two steps.
    #>
    param (
        [Parameter(Mandatory)][string]$path
    )

    try {
        $acl = Get-Acl -LiteralPath $path
        $acl.SetAccessRuleProtection($true, $false)   # disable inheritance, drop inherited ACEs

        foreach ($sid in @('S-1-5-18', 'S-1-5-32-544')) {
            # SYSTEM, BUILTIN\Administrators
            $account = (New-Object Security.Principal.SecurityIdentifier($sid))
            $acl.AddAccessRule((New-Object Security.AccessControl.FileSystemAccessRule(
                        $account,
                        'FullControl',
                        'ContainerInherit, ObjectInherit',
                        'None',
                        'Allow'
                    )))
        }

        Set-Acl -LiteralPath $path -AclObject $acl -ErrorAction Stop
        log -msg "Secured $path" -lvl "DEBUG"
    } catch {
        # Non-fatal: log it and continue rather than blocking startup.
        log -msg "Could not harden ${path}: $($_.Exception.Message)" -lvl "WARNING"
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
        $logDirectory = "$env:SystemDrive\Nuvia\logs\shellcli"
        
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
    $rootPath = "C:\Nuvia"

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
