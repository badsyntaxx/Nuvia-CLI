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
    [CmdletBinding()]
    param(
        [string]$RootPath = 'C:\Nuvia',

        # By default users can READ each other's log files (but never modify/delete them).
        # Pass -PrivateLogFiles to make each file visible only to its creator + admins.
        [switch]$PrivateLogFiles
    )

    # Well-known SIDs. Hard-coding "Administrators" / "Users" breaks on non-English Windows.
    $ADMINS = '*S-1-5-32-544'   # BUILTIN\Administrators
    $SYSTEM = '*S-1-5-18'       # NT AUTHORITY\SYSTEM
    $USERS = '*S-1-5-32-545'   # BUILTIN\Users
    $CREATOR = '*S-1-3-0'        # CREATOR OWNER

    $subFolders = @('temp', 'tools', 'backups', 'logs', 'state')
    $writeFolder = 'logs'

    # icacls returns a non-zero exit code instead of throwing, so wrap it.
    function Invoke-Icacls([string[]]$IcaclsArgs) {
        $out = & icacls.exe @IcaclsArgs 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw ("icacls {0} failed ({1}): {2}" -f ($IcaclsArgs -join ' '), $LASTEXITCODE, ($out -join ' '))
        }
    }

    $principal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
        throw 'createNuviaFolders must be run from an elevated session.'
    }

    log -msg "Setting up Nuvia folders at $RootPath..."

    # ------------------------------------------------------------------
    # 1. Folders (idempotent - New-Item -Force is a no-op if it exists)
    # ------------------------------------------------------------------
    foreach ($path in @($RootPath) + ($subFolders | ForEach-Object { Join-Path $RootPath $_ })) {
        if (Test-Path -LiteralPath $path) { continue }
        New-Item -Path $path -ItemType Directory -Force -ErrorAction Stop | Out-Null
        log -msg "Created $path"
    }

    # ------------------------------------------------------------------
    # 2. Hide the root (cosmetic only - this is not a security control)
    # ------------------------------------------------------------------
    $item = Get-Item -LiteralPath $RootPath -Force
    $item.Attributes = $item.Attributes -bor [System.IO.FileAttributes]::Hidden

    # ------------------------------------------------------------------
    # 3. Root ACL: Administrators + SYSTEM own everything.
    #    Users get traverse on the root ITSELF only (no (OI)/(CI) flags = "this folder only"),
    #    so they can reach C:\Nuvia\logs without being able to open temp/tools/backups/state.
    #    Without this you're relying on the "Bypass traverse checking" privilege, which is
    #    granted to Everyone by default but can be revoked by policy.
    # ------------------------------------------------------------------
    Invoke-Icacls @($RootPath, '/inheritance:r')
    Invoke-Icacls @($RootPath, '/grant:r',
        "${ADMINS}:(OI)(CI)F",
        "${SYSTEM}:(OI)(CI)F",
        "${USERS}:(X,RA)")

    log -msg "Locked $RootPath to Administrators/SYSTEM (Users: traverse only)."

    # ------------------------------------------------------------------
    # 4. logs ACL: the "sticky bit" pattern.
    #
    #    (CI)(RX,WD,AD)  -> folder + subfolders: list, traverse, create files (WD),
    #                       create subfolders (AD). No DE (delete self), no DC (delete child).
    #                       (CI) with NO (OI) is the crux: this ACE never inherits onto a file,
    #                       so a user has no rights at all on files someone else created.
    #
    #    CREATOR OWNER (OI)(CI)(IO)F -> inherit-only, so it does nothing to the folder itself
    #                       but stamps full control onto each NEW item for whoever made it.
    #                       Deleting a file needs DELETE on the file, not DC on the parent,
    #                       so people can still clean up their own logs.
    # ------------------------------------------------------------------
    $writePath = Join-Path $RootPath $writeFolder

    Invoke-Icacls @($writePath, '/grant:r', "${USERS}:(CI)(RX,WD,AD)")
    Invoke-Icacls @($writePath, '/grant', "${CREATOR}:(OI)(CI)(IO)F")

    if (-not $PrivateLogFiles) {
        # Separate ACE (files only, inherit-only) so reading other people's logs is possible
        # without giving them WD, which would let them truncate/overwrite the contents.
        Invoke-Icacls @($writePath, '/grant', "${USERS}:(OI)(CI)(IO)(R)")
    }

    log -msg "Granted Users create-only access to $writePath (creators own their own files)."

    # ------------------------------------------------------------------
    # 5. Environment variable
    # ------------------------------------------------------------------
    [Environment]::SetEnvironmentVariable('na', $RootPath, 'Machine')
    $env:na = $RootPath   # was $env:n in the original - name mismatch

    log -msg "Environment variable 'na' set to $RootPath (restart other shells to pick it up)."
}

# Invoke the root of Shell CLI
initializeShellCLI
