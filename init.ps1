function initializeShellCLI {
    $shellCliRoot = Join-Path -Path $env:SystemDrive -ChildPath 'Nuvia\tools\shellcli'

    try {
        # Elevation
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = [Security.Principal.WindowsPrincipal]$identity

        if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            try {
                Start-Process -FilePath 'powershell.exe' -Verb RunAs -ErrorAction Stop `
                    -WorkingDirectory $env:SystemRoot -ArgumentList @(
                    '-NoProfile'
                    '-ExecutionPolicy', 'Bypass'
                    '-Command', 'irm https://raw.githubusercontent.com/badsyntaxx/Nuvia-CLI/main/init.ps1 | iex'
                )
            } catch {
                # Thrown when the user cancels the UAC prompt (error 1223) or
                # when a policy blocks elevation entirely.
                Write-Host "  ShellCLI requires administrator privileges." -ForegroundColor "Yellow"
            }

            return
        }

        log -msg "Initializing ShellCLI"

        # Domain check
        $domain = getJoinedDomain
        if ($domain) {
            Write-Host "  This computer is joined to the domain '$domain'." -ForegroundColor "Yellow"
            Write-Host "  Much of ShellCLI will not work on domain-joined computers." -ForegroundColor "Yellow"
            Read-Host "  Press any key to continue..."
            log -msg "Domain-joined computer detected ($domain)" -lvl "WARNING"
        }

        # Working directory
        if (-not (Test-Path -LiteralPath $shellCliRoot)) {
            New-Item -Path $shellCliRoot -ItemType Directory -Force -ErrorAction Stop | Out-Null
        }

        # Build the main script in memory. Nothing is written to disk and then
        # executed, so execution policy never applies and there is no window in
        # which a file could be swapped between being written and being run.
        log -msg "Building main script"

        $framework = getRemoteScript -file 'framework'
        if ($null -eq $framework) {
            throw "Could not download framework.ps1"
        }

        $core = getRemoteScript -directory 'main' -file 'core'
        if ($null -eq $core) {
            throw "Could not download main/core.ps1"
        }

        # core is already defined by the build below. Seed the module cache so
        # the first core command (help) does not download it a second time.
        # framework.ps1 keeps an existing cache instead of resetting it.
        $global:moduleCache = @{ 'main/core' = $core }

        # Bootstrap line that hands control to the CLI
        $mainScript = $framework + "`n" + $core + "`n" + 'invokeScript -script "startShell" -initialize $true'

        # Cheap sanity check: a successful build is never this small
        if ($mainScript.Length -lt 256) {
            throw "Main script built but looks truncated ($($mainScript.Length) chars)"
        }

        log -msg "Running main script"
        . ([scriptblock]::Create($mainScript))
    } catch {
        Write-Host "  $($MyInvocation.MyCommand.Name)-$($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)" -ForegroundColor "Red"
        log -msg "$($MyInvocation.MyCommand.Name)-$($_.InvocationInfo.ScriptLineNumber):$($_.Exception.Message)" -lvl "ERROR"
    }
}

function getRemoteScript {
    <#
        Downloads one script from the repo and returns its source text.
        Reports the error and returns $null if it cannot be obtained.
    #>
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $false)][string]$directory,
        [Parameter(Mandatory)][string]$file
    )

    $oldProgress = $ProgressPreference
    $ProgressPreference = 'SilentlyContinue'

    try {
        $base = 'https://raw.githubusercontent.com/badsyntaxx/shellcli/main'
        $url = if ($directory) { "$base/$directory/$file.ps1" } else { "$base/$file.ps1" }

        # Older hosts may still default to TLS 1.0, which GitHub rejects.
        [Net.ServicePointManager]::SecurityProtocol = `
            [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

        # Windows PowerShell 5.1 does not ask for compression by itself. With
        # the header GitHub sends gzip (~75% smaller) and .Content is decoded.
        $src = (Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 20 -ErrorAction Stop `
                -Headers @{ 'Accept-Encoding' = 'gzip' }).Content

        if ([string]::IsNullOrWhiteSpace($src)) {
            throw "Downloaded an empty response from $url"
        }

        log -msg "Downloaded $file.ps1 ($($src.Length) chars)" -lvl "DEBUG"
        return $src
    } catch {
        Write-Host "  $($MyInvocation.MyCommand.Name)-$($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)" -ForegroundColor "Red"
        log -msg "$($MyInvocation.MyCommand.Name)-$($_.InvocationInfo.ScriptLineNumber):$($_.Exception.Message)" -lvl "ERROR"
        return $null
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
        $logDirectory = "$env:SystemDrive\Nuvia\Logs\shellcli"
        
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

function getJoinedDomain {
    <#
        Returns the AD domain name if this machine is domain joined, otherwise $null.
        Failure to query is treated as "not joined" so startup is never blocked.
    #>
    [OutputType([string])]
    param ()

    try {
        $cs = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop
        if ($cs.PartOfDomain) { return $cs.Domain }
        return $null
    } catch {
        log -msg "Could not determine domain membership: $($_.Exception.Message)" -lvl "WARNING"
        return $null
    }
}

function createNuviaFolders {
    [CmdletBinding()]
    param(
        [string]$RootPath = 'C:\Nuvia'
    )

    $subFolders = @('Temp', 'Tools', 'Backups', 'Logs', 'State')

    log -msg "Setting up Nuvia folders at $RootPath..."

    # 1. Folders (idempotent)
    foreach ($path in @($RootPath) + ($subFolders | ForEach-Object { Join-Path $RootPath $_ })) {
        if (Test-Path -LiteralPath $path) { continue }
        New-Item -Path $path -ItemType Directory -Force -ErrorAction Stop | Out-Null
        log -msg "Created $path"
    }

    # 2. Hide the root (cosmetic only)
    $item = Get-Item -LiteralPath $RootPath -Force
    $item.Attributes = $item.Attributes -bor [System.IO.FileAttributes]::Hidden

    # 3. Environment variable
    [Environment]::SetEnvironmentVariable('na', $RootPath, 'Machine')
    $env:na = $RootPath

    log -msg "Environment variable 'na' set to $RootPath (restart other shells to pick it up)."
}

# Invoke the root of Shell CLI
initializeShellCLI
