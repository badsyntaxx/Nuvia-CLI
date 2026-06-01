#Requires -Version 5.0
function UninstallNinja {
    removeNinjaRMM
    removeNinjaRemote
    findMissingProductKeyNames
    writeText -type "success" -text "Ninja Successfully Uninstalled" -lineAfter
}

function getNinjaRegistryPaths {
    $Paths = @{
        Main             = 'HKLM:\SOFTWARE\WOW6432Node\NinjaRMM LLC\NinjaRMMAgent'
        Uninstall        = 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
        MSIWrapper       = 'HKLM:\SOFTWARE\WOW6432Node\EXEMSI.COM\MSI Wrapper\Installed'
        ProductInstaller = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products'
        HKCRInstaller    = 'Registry::\HKEY_CLASSES_ROOT\Installer\Products'
    }
    
    if (!([System.Environment]::Is64BitOperatingSystem)) {
        $Paths.Main = 'HKLM:\SOFTWARE\NinjaRMM LLC\NinjaRMMAgent'
        $Paths.Uninstall = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
    }
    
    return $Paths
}

function removeRegistryKey {
    param (
        [Parameter(Mandatory = $true)]
        [string]$RegPath
    )
    
    if (Test-Path $RegPath) {
        try {
            writeText -type "plain" -text "Removing registry key: $RegPath"
            Remove-Item $RegPath -Recurse -Force -ErrorAction Stop
            writeText -type "success" -text "Successfully removed registry key" -lineAfter
            return $true
        } catch {
            writeText -type "error" -text "removeRegistryKey-$($_.InvocationInfo.ScriptLineNumber) | $($_.Exception.Message)" -lineAfter
            return $false
        }
    }
    return $false
}

function findNinjaInstallPaths {
    $RegPaths = getNinjaRegistryPaths
    
    try {
        $InstallLocation = (Get-ItemPropertyValue $RegPaths.Main -Name Location -ErrorAction Stop).Replace('/', '\')
        
        if (Test-Path "$InstallLocation\NinjaRMMAgent.exe") {
            return $InstallLocation
        } else {
            $ServicePath = ((Get-CimInstance Win32_Service | Where-Object { $_.Name -eq 'NinjaRMMAgent' }).PathName).Trim('"')
            if (Test-Path $ServicePath) {
                return $ServicePath | Split-Path
            }
        }
    } catch {
        writeText -type "warning" -text "Unable to locate Ninja installation path. Continuing with cleanup..." -lineAfter
    }
    
    return $null
}

function Get-NinjaUninstallString {
    $RegPaths = getNinjaRegistryPaths
    
    $UninstallString = (Get-ItemProperty $RegPaths.Uninstall | 
        Where-Object { ($_.DisplayName -eq 'NinjaRMMAgent') -and ($_.UninstallString -match 'msiexec') }).UninstallString
    
    if ($UninstallString) {
        return $UninstallString.Split('X')[1]
    }
    
    return $null
}

function invokeNinjaMSIUninstall {
    param (
        [Parameter(Mandatory = $true)]
        [string]$UninstallString
    )
    
    $Arguments = @(
        "/x$UninstallString"
        '/quiet'
        '/L*V'
        "$env:windir\temp\NinjaRMMAgent_uninstall.log"
        "WRAPPED_ARGUMENTS=`"--mode unattended`""
    )
    
    writeText -type "plain" -text "Starting MSI uninstaller..."
    Start-Process "msiexec.exe" -ArgumentList $Arguments -Wait -NoNewWindow
    writeText -type "plain" -text "Finished running uninstaller. Continuing to clean up..."
    Start-Sleep -Seconds 30
}

function stopNinjaProcess {
    $Processes = @("NinjaRMMAgent", "NinjaRMMAgentPatcher", "njbar", "NinjaRMMProxyProcess64")
    
    foreach ($ProcessName in $Processes) {
        $Process = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue
        if ($Process) {
            try {
                Stop-Process $Process -Force -ErrorAction Stop
                writeText -type "success" -text "Successfully stopped process: $ProcessName" -lineAfter
            } catch {
                writeText -type "error" -text "stopNinjaProcess-$($_.InvocationInfo.ScriptLineNumber) | $($_.Exception.Message)" -lineAfter
            }
        }
    }
}

function removeNinjaServices {
    param (
        [string]$InstallLocation
    )
    
    $Services = @('NinjaRMMAgent', 'nmsmanager', 'lockhart')
    
    foreach ($ServiceName in $Services) {
        if ($ServiceName -eq 'lockhart' -and !(Test-Path "$InstallLocation\lockhart\bin\lockhart.exe")) {
            continue
        }
        
        $Service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
        if ($Service) {
            try {
                writeText -type "plain" -text "Stopping service: $ServiceName"
                Stop-Service $ServiceName -Force -ErrorAction Stop
            } catch {
                writeText -type "error" -text "removeNinjaServices-$($_.InvocationInfo.ScriptLineNumber) | $($_.Exception.Message)" -lineAfter
            }
            
            & sc.exe DELETE $ServiceName
            Start-Sleep -Seconds 5
            
            if (Get-Service -Name $ServiceName -ErrorAction SilentlyContinue) {
                writeText -type "warning" -text "Failed to remove $ServiceName service. Continuing..." -lineAfter
            } else {
                writeText -type "success" -text "Successfully removed $ServiceName service" -lineAfter
            }
        }
    }
}

function removeNinjaDirectories {
    param (
        [string]$InstallLocation
    )
    
    $Directories = @(
        @{Path = $InstallLocation; Name = 'installation directory' },
        @{Path = "$($env:ProgramData)\NinjaRMMAgent"; Name = 'data directory' },
        @{Path = "$env:ProgramFiles\WindowsPowerShell\Modules\NJCliPSh"; Name = 'PowerShell module directory' }
    )
    
    foreach ($Dir in $Directories) {
        if ($Dir.Path -and (Test-Path $Dir.Path)) {
            writeText -type "plain" -text "Removing Ninja $($Dir.Name): $($Dir.Path)"
            try {
                Remove-Item $Dir.Path -Recurse -Force -ErrorAction Stop
                writeText -type "success" -text "Successfully removed"
            } catch {
                writeText -type "error" -text "removeNinjaDirectories-$($_.InvocationInfo.ScriptLineNumber) | $($_.Exception.Message)" -lineAfter
            }
        }
    }
}

function removeNinjaRegistryItems {
    $RegPaths = getNinjaRegistryPaths
    $KeysToRemove = [System.Collections.Generic.List[string]]::new()
    
    # Collect registry keys
    (Get-ItemProperty $RegPaths.Uninstall | Where-Object { $_.DisplayName -eq 'NinjaRMMAgent' }).PSPath | ForEach-Object { $KeysToRemove.Add($_) }
    (Get-ItemProperty $RegPaths.ProductInstaller | Where-Object { $_.ProductName -eq 'NinjaRMMAgent' }).PSPath | ForEach-Object { $KeysToRemove.Add($_) }
    (Get-ChildItem $RegPaths.MSIWrapper | Where-Object { $_.Name -match 'NinjaRMMAgent' }).PSPath | ForEach-Object { $KeysToRemove.Add($_) }
    
    Get-ChildItem $RegPaths.HKCRInstaller | ForEach-Object {
        if ((Get-ItemPropertyValue $_.PSPath -Name 'ProductName' -ErrorAction SilentlyContinue) -eq 'NinjaRMMAgent') {
            $KeysToRemove.Add($_.PSPath)
        }
    }
    
    # Additional product installer keys
    Get-ChildItem $RegPaths.ProductInstaller | ForEach-Object {
        $InstallProps = "$($_.PSPath)\InstallProperties"
        if ((Get-ItemProperty $InstallProps -ErrorAction SilentlyContinue) | Where-Object { $_.DisplayName -eq 'NinjaRMMAgent' }) {
            $KeysToRemove.Add($_.PSPath)
        }
    }
    
    writeText -type "plain" -text "Removing registry items if found..."
    foreach ($Key in $KeysToRemove | Where-Object { $_ }) {
        removeRegistryKey -RegPath $Key
    }
    
    # Remove main registry path
    removeRegistryKey -RegPath $RegPaths.Main
}

function removeNinjaRemoteService {
    $ServiceName = 'ncstreamer'
    $ProcessName = 'ncstreamer'
    
    # Stop process
    $Process = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue
    if ($Process) {
        writeText -type "plain" -text "Stopping Ninja Remote process..."
        try {
            Stop-Process $Process -Force -ErrorAction Stop
        } catch {
            writeText -type "error" -text "removeNinjaRemoteService-$($_.InvocationInfo.ScriptLineNumber) | $($_.Exception.Message)" -lineAfter
        }
    }
    
    # Stop and remove service
    $Service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    if ($Service) {
        try {
            Stop-Service $ServiceName -Force -ErrorAction Stop
        } catch {
            writeText -type "warning" -text "removeNinjaRemoteService-$($_.InvocationInfo.ScriptLineNumber) | $($_.Exception.Message)" -lineAfter
        }
        
        & sc.exe DELETE $ServiceName
        Start-Sleep -Seconds 5
        
        if (Get-Service -Name $ServiceName -ErrorAction SilentlyContinue) {
            writeText -type "warning" -text "Failed to remove Ninja Remote service. Continuing..." -lineAfter
        }
    }
}

function removeNinjaRemoteDriver {
    $DriverName = 'nrvirtualdisplay.inf'
    $DriverCheck = pnputil /enum-drivers | Where-Object { $_ -match $DriverName }
    
    if ($DriverCheck) {
        writeText -type "plain" -text "Ninja Remote Virtual Driver found. Removing..."
        
        $DriversArray = [System.Collections.Generic.List[object]]::new()
        $CurrentDriver = @{}
        
        $DriverBreakdown = pnputil /enum-drivers | Where-Object { $_ -ne 'Microsoft PnP Utility' }
        
        foreach ($Line in $DriverBreakdown) {
            if ($Line -ne "") {
                $ObjectName = $Line.Split(':').Trim()[0]
                $ObjectValue = $Line.Split(':').Trim()[1]
                $CurrentDriver[$ObjectName] = $ObjectValue
            } else {
                if ($CurrentDriver.Count -gt 0) {
                    $DriversArray.Add([PSCustomObject]$CurrentDriver)
                    $CurrentDriver = @{}
                }
            }
        }
        
        $DriverToRemove = ($DriversArray | Where-Object { $_.'Provider Name' -eq 'NinjaOne' }).'Published Name'
        if ($DriverToRemove) {
            pnputil /delete-driver "$DriverToRemove" /force
        }
    }
}

function removeNinjaRemoteDirectories {
    $Directories = @(
        "$env:ProgramFiles\NinjaRemote",
        "$env:SystemDrive\Users\Public\Documents\NrSpool\NrPdfPrint"
    )
    
    foreach ($Directory in $Directories) {
        if (Test-Path $Directory) {
            writeText -type "plain" -text "Removing directory: $Directory"
            try {
                Remove-Item $Directory -Recurse -Force -ErrorAction Stop
            } catch {
                writeText -type "error" -text "removeNinjaRemoteDirectories-$($_.InvocationInfo.ScriptLineNumber) | $($_.Exception.Message)" -lineAfter
            }
        }
    }
}

function removeNinjaRemoteRegistriesForUser {
    param (
        [Parameter(Mandatory = $true)]
        [string]$SID
    )
    
    $RunRegPath = "Registry::\HKEY_USERS\$SID\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
    $SoftwareRegPath = "Registry::\HKEY_USERS\$SID\Software\NinjaRMM LLC"
    
    # Remove Run registry entries
    if (Test-Path $RunRegPath) {
        $RunValues = Get-ItemProperty -Path $RunRegPath
        $PropertiesToRemove = $RunValues.PSObject.Properties | Where-Object { $_.Name -match "NinjaRMM|NinjaOne" }
        
        foreach ($Property in $PropertiesToRemove) {
            writeText -type "plain" -text "Removing registry entry: $($Property.Name) = $($Property.Value)"
            Remove-ItemProperty -Path $RunRegPath -Name $Property.Name -Force -ErrorAction SilentlyContinue
        }
    }
    
    # Remove software registry key
    removeRegistryKey -RegPath $SoftwareRegPath
    
    # Remove HKU base key
    removeRegistryKey -RegPath "Registry::\HKEY_USERS\S-1-5-18\Software\NinjaRMM LLC"
}

function removeNinjaRemoteRegistries {
    $AllProfiles = Get-CimInstance Win32_UserProfile | 
    Where-Object { $_.SID -like "S-1-5-21-*" }
    
    $Mounted = $AllProfiles | Where-Object { $_.Loaded -eq $true }
    $Unmounted = $AllProfiles | Where-Object { $_.Loaded -eq $false }
    
    # Process mounted profiles
    foreach ($Profile in $Mounted) {
        writeText -type "plain" -text "Removing registry items for $($Profile.LocalPath)"
        removeNinjaRemoteRegistriesForUser -SID $Profile.SID
    }
    
    # Process unmounted profiles
    foreach ($Profile in $Unmounted) {
        $HivePath = "$($Profile.LocalPath)\NTUSER.DAT"
        if (Test-Path $HivePath) {
            writeText -type "plain" -text "Loading hive and removing Ninja Remote registry items for $($Profile.LocalPath)..."
            
            REG LOAD "HKU\$($Profile.SID)" $HivePath 2>&1 > $null
            removeNinjaRemoteRegistriesForUser -SID $Profile.SID
            
            [GC]::Collect()
            [GC]::WaitForPendingFinalizers()
            
            REG UNLOAD "HKU\$($Profile.SID)" 2>&1 > $null
        }
    }
}

function removeNinjaRemotePrinter {
    $Printer = Get-Printer -Name 'NinjaRemote' -ErrorAction SilentlyContinue
    if ($Printer) {
        writeText -type "plain" -text "Removing Ninja Remote printer..."
        Remove-Printer -InputObject $Printer -ErrorAction SilentlyContinue
    }
}

function removeNinjaRemote {
    writeText -type "plain" -text "Starting Ninja Remote removal..."
    removeNinjaRemoteService
    removeNinjaRemoteDriver
    removeNinjaRemoteDirectories
    removeNinjaRemoteRegistries
    removeNinjaRemotePrinter
    writeText -type "plain" -text "Ninja Remote removal complete"
}

function removeNinjaRMM {
    $InstallPath = findNinjaInstallPaths
    
    # Disable uninstall prevention if installation found
    if ($InstallPath -and (Test-Path "$InstallPath\NinjaRMMAgent.exe")) {
        writeText -type "plain" -text "Disabling uninstall prevention..."
        Start-Process "$InstallPath\NinjaRMMAgent.exe" -ArgumentList "-disableUninstallPrevention NOUI" -Wait -NoNewWindow
    }
    
    # Run MSI uninstaller
    $UninstallString = Get-NinjaUninstallString
    if ($UninstallString) {
        invokeNinjaMSIUninstall -UninstallString $UninstallString
    } else {
        writeText -type "warning" -text "Unable to determine uninstall string. Continuing with cleanup..." -lineAfter
    }
    
    # Cleanup operations
    stopNinjaProcess
    removeNinjaServices -InstallLocation $InstallPath
    removeNinjaDirectories -InstallLocation $InstallPath
    removeNinjaRegistryItems
}

function findMissingProductKeyNames {
    $MissingPNs = [System.Collections.Generic.List[string]]::new()
    $ChildKeys = Get-ChildItem 'HKLM:\Software\Classes\Installer\Products' -ErrorAction SilentlyContinue
    
    foreach ($Key in $ChildKeys) {
        if ($Key.Name -match '99E80CA9B0328e74791254777B1F42AE') {
            continue
        }
        
        try {
            Get-ItemPropertyValue $Key.PSPath -Name 'ProductName' -ErrorAction Stop | Out-Null
        } catch {
            $MissingPNs.Add($Key.Name)
        }
    }
    
    if ($MissingPNs.Count -gt 0) {
        writeText -type "warning" -text "############################# !!! WARNING !!! ####################################" -lineAfter
        writeText -type "warning" -text "Some registry keys are missing the Product Name." -lineAfter
        writeText -type "warning" -text "This could be an indicator of a corrupt Ninja install key." -lineAfter
        writeText -type "warning" -text "If you are still unable to install the NinjaOne Agent after running this script..." -lineAfter
        writeText -type "warning" -text "Please make a backup of the following keys and then remove them from the registry:" -lineAfter
        writeText -type "warning" -text ($MissingPNs | Out-String) -lineAfter
        writeText -type "warning" -text "##################################################################################" -lineAfter
    }
}
