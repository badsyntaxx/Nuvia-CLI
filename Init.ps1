function initializeShellCLI {
    try {
        log -msg "Initializing ShellCLI..."
        # Check if user has administrator privileges
        if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
            log -msg "Terminal is not admin. Self elevating."
            # If not, elevate privileges and restart function with current arguments
            Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" $PSCommandArgs" -WorkingDirectory $pwd -Verb RunAs
            Exit
        }

        createNuviaFolders
        
        # Create the main script file
        New-Item -Path "C:\Nuvia\tools\shellcli\SHELLCLI.ps1" -ItemType File -Force | Out-Null
        log -msg "Main script file created at C:\Nuvia\tools\shellcli\SHELLCLI.ps1."

        $url = "https://raw.githubusercontent.com/badsyntaxx/Nuvia-CLI/main"

        # Download the script
        $download = getScript -Url "$url/Framework.ps1" -Target "C:\Nuvia\tools\shellcli\Framework.ps1"
        if ($download) { 
            log -msg "Download done. Building framework..."
            # Append the script to the main script
            $rawScript = Get-Content -Path "C:\Nuvia\tools\shellcli\Framework.ps1" -Raw -ErrorAction SilentlyContinue
            Add-Content -Path "C:\Nuvia\tools\shellcli\SHELLCLI.ps1" -Value $rawScript

            # Remove the script file
            Get-Item -ErrorAction SilentlyContinue "C:\Nuvia\tools\shellcli\Framework.ps1" | Remove-Item -ErrorAction SilentlyContinue

            # Add a final line that will invoke the desired function
            Add-Content -Path "C:\Nuvia\tools\shellcli\SHELLCLI.ps1" -Value 'invokeScript -script "readCommand -command `"n?`"" -initialize $true'

            log -msg "Starting..."
            # Execute the combined script
            . "C:\Nuvia\tools\shellcli\SHELLCLI.ps1"
        }
    } catch {
        Write-Host "  $($MyInvocation.MyCommand.Name): $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor "Red"
        log -msg "$($MyInvocation.MyCommand.Name): $($_.InvocationInfo.ScriptLineNumber)-$($_.Exception.Message)"
    }
}
function getScript {
    param (
        [Parameter(Mandatory)]
        [string]$url,
        [Parameter(Mandatory)]
        [string]$target
    )
  
    Process {
        $downloadComplete = $true 
        try {
            # Create web request and get response
            $request = [System.Net.HttpWebRequest]::Create($url)
            $response = $request.GetResponse()
            
            # Check for unauthorized or non-existent file
            if ($response.StatusCode -eq 401 -or $response.StatusCode -eq 403 -or $response.StatusCode -eq 404) {
                throw "Remote file error: $($response.StatusCode) - '$url'"
            }
  
            # Handle relative target path
            if ($target -match '^\.\\') { 
                $target = Join-Path (Get-Location) ($target -Split '^\.')[1] 
            }
  
            # Open streams for reading and writing
            $reader = $response.GetResponseStream()
            $writer = New-Object System.IO.FileStream $target, "Create"
            $buffer = new-object byte[] 1048576
  
            # Read data in chunks and write to target file
            do {
                $count = $reader.Read($buffer, 0, $buffer.Length)
                $writer.Write($buffer, 0, $count)
            } while ($count -gt 0)
  
            # Close streams silently (assuming success)
            if ($downloadComplete) { 
                return $true 
            } else { 
                return $false 
            }
        } catch {
            write-host $($_.Exception.Message)
            read-host
            return $false
        } finally {
            $reader.Close()
            $writer.Close()
        }
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
        $logDirectory = "C:\Nuvia\logs\ShellCLI"
        
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
    [Environment]::SetEnvironmentVariable("n", $rootPath, "Machine")
    $env:n = $rootPath  # make it available in current session too

    log -msg "Environment variable 'n' set to $rootPath (restart other shells to pick it up)."
}

# Invoke the root of Shell CLI
initializeShellCLI
