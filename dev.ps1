$global:commandMap = @{
    "n?" = @("nuvia", "Core", "writeHelp", "List some help info.")
}
function initializeShellCLI {
    try {
        if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
                [Security.Principal.WindowsBuiltInRole]::Administrator)) {
            Start-Process powershell.exe -Verb RunAs -WorkingDirectory $PSScriptRoot -ArgumentList @(
                '-NoProfile', '-ExecutionPolicy', 'Bypass', '-NoExit', '-File', "`"$PSCommandPath`"")
            return
        }

        $global:shellcliDevRoot = $PSScriptRoot
        $global:moduleCache = @{}

        foreach ($f in 'framework.ps1', 'nuvia\core.ps1') {
            . ([scriptblock]::Create([System.IO.File]::ReadAllText((Join-Path $PSScriptRoot $f))))
        }

        writeText -type "notice" -text "DEV MODE - loading modules from $PSScriptRoot"
        invokeScript -script "startShell" -initialize $true
    } catch {
        Write-Host "  $($MyInvocation.MyCommand.Name)-$($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor "Red"
        log -msg "$($MyInvocation.MyCommand.Name)-$($_.InvocationInfo.ScriptLineNumber):$($_.Exception.Message)"
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

initializeShellCLI