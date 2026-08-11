$LogDir = "C:\Nuvia\Logs"
$LogFile = "$LogDir\Onboard_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$NuviaDir = "C:\Nuvia"
$WallpaperDir = "$NuviaDir\Assets\Wallpapers"
$BGInfoDir = "$NuviaDir\Apps\BGInfo"
$BGInfoExe = "$BGInfoDir\Apps\Bginfo64.exe"

function init {
    writeText -type "header" -text "Initializing Nuvia Onboarding Script"
    writeText -type "plain" -text "Hostname : $env:COMPUTERNAME"
    writeText -type "plain" -text "Started  : $(Get-Date)"
    writeText -type "plain" -text "Log      : $LogFile" -lineAfter

    $type = readOption -options $([ordered]@{
            "Clinical" = "Clinical"
            "Sales"    = "Sales"
            "Exit"     = "Cancel onboarding and exit script"
        }) -prompt "Select an onboarding type:" -returnKey -lineAfter

    switch ($type) {
        "Clinical" {
            clinicalOnboarding
        }
        "Sales" {
            salesOnboarding
        }
        "Exit" {
            readCommand
        }
    }
}
function clinicalOnboarding {
    writeText -type "header" -text "Initializing Clinical Onboarding"

    $locationType = readOption -options $([ordered]@{
            "ADV"   = "Advanced Dentistry"
            "CLI"   = "Clinic"
            "LAB"   = "Lab"
            "OTHER" = "All other types (Dental Implant Center wallpaper)"
        }) -prompt "Select a location type:" -returnKey -lineAfter

    debloat
    declutter
    installApps
    # normalizeEnvironment -locationType $locationType

    # Add this at the end of your function after setting registry values
    Stop-Process -Name explorer -Force
    Start-Sleep -Seconds 2
    Start-Process explorer
}
function salesOnboarding {
    writeText -type "notice" -text "Sales are currently on Macs. No onboarding actions are available."
}
function debloat {
    writeText -type "header" -text "Debloating"
    foreach ($lang in @("es-es", "fr-fr", "pt-br")) { 
        uninstallWin32App -AppName "Microsoft 365 - $lang" 
    }

    foreach ($lang in @("en-us", "es-es", "fr-fr", "pt-br")) { 
        uninstallWin32App -AppName "Microsoft OneNote - $lang" 
    }

    uninstallOneDrive
    uninstallTeams
    uninstallWin32App -AppName "Microsoft Copilot"
    uninstallWin32App -AppName "Copilot"
    disableTelemetry
    disableWiFiSense
    disableAppSuggestions
    disableLockScreenSpotlight
    disableFeedback
    disableAdvertisingID
    disableCortana     
    enableErrorReporting 
    disableAutoLogger
    disableDiagTrack
    disableWAPPush
    disableSMB1
    setCurrentNetworkPrivate
    disableUpdateRestart
    disableRemoteAssistance
    #disableRemoteDesktop
    disableAutoplay
    disableAutorun
    disableHibernation
    showShutdownOnLockScreen
    disableStickyKeys
    showFileOperationsDetails
    hideTaskbarSearchBox
    hideTaskView
    hideTaskbarPeopleIcon
    showTrayIcons                
    showThisPCOnDesktop          
    showDesktopInThisPC
    showDesktopInExplorer
    showDocumentsInThisPC
    showDocumentsInExplorer
    showDownloadsInThisPC
    showDownloadsInExplorer
    disableXboxFeatures
    disableSearchAppInStore 

    $appxList = @(
        @{ Name = "Family Safety"; Package = "Microsoft.FamilySafety" },
        @{ Name = "Family Safety (Corp)"; Package = "MicrosoftCorporationII.MicrosoftFamily" },
        @{ Name = "Feedback Hub"; Package = "Microsoft.WindowsFeedbackHub" },
        @{ Name = "Game Bar"; Package = "Microsoft.XboxGameOverlay" },
        @{ Name = "Get Help"; Package = "Microsoft.GetHelp" },
        @{ Name = "Get Started"; Package = "Microsoft.Getstarted" },
        @{ Name = "Microsoft 365 Copilot"; Package = "Microsoft.MicrosoftOfficeHub" },
        @{ Name = "Microsoft Copilot (AppX)"; Package = "Microsoft.Copilot" },
        @{ Name = "Microsoft News"; Package = "Microsoft.BingNews" },
        @{ Name = "Microsoft To Do"; Package = "Microsoft.Todos" },
        @{ Name = "Microsoft 3D Builder"; Package = "Microsoft.3DBuilder" },
        @{ Name = "Microsoft Bing Finance"; Package = "Microsoft.BingFinance" },
        @{ Name = "Microsoft Bing News"; Package = "Microsoft.BingNews" },
        @{ Name = "Microsoft Bing Sports"; Package = "Microsoft.BingSports" },
        @{ Name = "Microsoft Bing Weather"; Package = "Microsoft.BingWeather" },
        @{ Name = "Microsoft Get Started"; Package = "Microsoft.Getstarted" },
        @{ Name = "Microsoft Office Hub"; Package = "Microsoft.MicrosoftOfficeHub" },
        @{ Name = "Microsoft Solitaire Collection"; Package = "Microsoft.MicrosoftOfficeHub" },
        @{ Name = "Microsoft Office OneNote"; Package = "Microsoft.MicrosoftOfficeHub" },
        @{ Name = "Microsoft People"; Package = "Microsoft.MicrosoftOfficeHub" },
        @{ Name = "Microsoft SkypeApp"; Package = "Microsoft.MicrosoftOfficeHub" },
        @{ Name = "Microsoft WindowsAlarms"; Package = "Microsoft.MicrosoftOfficeHub" },
        @{ Name = "Microsoft WindowsMaps"; Package = "Microsoft.MicrosoftOfficeHub" },
        @{ Name = "Microsoft WindowsPhone"; Package = "Microsoft.MicrosoftOfficeHub" },
        @{ Name = "Microsoft WindowsSoundRecorder"; Package = "Microsoft.MicrosoftOfficeHub" },
        @{ Name = "Microsoft ZuneMusic"; Package = "Microsoft.MicrosoftOfficeHub" },
        @{ Name = "Microsoft ZuneVideo"; Package = "Microsoft.MicrosoftOfficeHub" },
        @{ Name = "Microsoft AppConnector"; Package = "Microsoft.MicrosoftOfficeHub" },
        @{ Name = "Microsoft ConnectivityStore"; Package = "Microsoft.MicrosoftOfficeHub" },
        @{ Name = "Microsoft Office.Sway"; Package = "Microsoft.MicrosoftOfficeHub" },
        @{ Name = "Microsoft Messaging"; Package = "Microsoft.MicrosoftOfficeHub" },
        @{ Name = "Microsoft CommsPhone"; Package = "Microsoft.MicrosoftOfficeHub" },
        @{ Name = "Microsoft OneConnect"; Package = "Microsoft.MicrosoftOfficeHub" },
        @{ Name = "Microsoft WindowsFeedbackHub"; Package = "Microsoft.MicrosoftOfficeHub" },
        @{ Name = "Microsoft NetworkSpeedTest"; Package = "Microsoft.MicrosoftOfficeHub" },
        @{ Name = "Microsoft Microsoft3DViewer"; Package = "Microsoft.MicrosoftOfficeHub" },
        @{ Name = "Microsoft Print3D"; Package = "Microsoft.MicrosoftOfficeHub" },
        @{ Name = "Microsoft Music.Preview"; Package = "Microsoft.MicrosoftOfficeHub" },	
        @{ Name = "Microsoft BingTravel"; Package = "Microsoft.MicrosoftOfficeHub" },
        @{ Name = "Microsoft BingHealthAndFitness"; Package = "Microsoft.MicrosoftOfficeHub" },
        @{ Name = "Microsoft BingFoodAndDrink"; Package = "Microsoft.MicrosoftOfficeHub" },
        @{ Name = "Mixed Reality Portal"; Package = "Microsoft.MixedReality.Portal" },
        @{ Name = "Quick Assist"; Package = "MicrosoftCorporationII.QuickAssist" },
        @{ Name = "Solitaire"; Package = "Microsoft.MicrosoftSolitaireCollection" },
        @{ Name = "Weather"; Package = "Microsoft.BingWeather" },
        @{ Name = "Xbox"; Package = "Microsoft.GamingApp" },
        @{ Name = "Xbox (Legacy)"; Package = "Microsoft.XboxApp" },
        @{ Name = "Xbox Live"; Package = "Microsoft.Xbox.TCUI" },
        @{ Name = "Xbox Game Overlay"; Package = "Microsoft.XboxGameOverlay" },
        @{ Name = "Xbox Gaming Overlay"; Package = "Microsoft.XboxGamingOverlay" },
        @{ Name = "Xbox Identity Provider"; Package = "Microsoft.XboxIdentityProvider" },
        @{ Name = "Xbox Speech To Text"; Package = "Microsoft.XboxSpeechToTextOverlay" },
        @{ Name = "Xbox TCUI"; Package = "Microsoft.Xbox.TCUI" },
        @{ Name = "Twitter"; Package = "9E2F88E3.Twitter" },
        @{ Name = "CandyCrushSodaSaga"; Package = "king.com.CandyCrushSodaSaga" },
        @{ Name = "Netflix"; Package = "4DF9E0F8.Netflix" },
        @{ Name = "DrawboardPDF"; Package = "Drawboard.DrawboardPDF" },
        @{ Name = "FarmVille2CountryEscape"; Package = "D52A8D61.FarmVille2CountryEscape" },
        @{ Name = "Asphalt8Airborne"; Package = "GAMELOFTSA.Asphalt8Airborne" },
        @{ Name = "RoyalRevolt2"; Package = "flaregamesGmbH.RoyalRevolt2" },
        @{ Name = "AdobePhotoshopExpress"; Package = "AdobeSystemsIncorporated.AdobePhotoshopExpress" },
        @{ Name = "ActiproSoftwareLLC"; Package = "ActiproSoftwareLLC.562882FEEB491" },
        @{ Name = "Duolingo-LearnLanguagesforFree"; Package = "D5EA27B7.Duolingo-LearnLanguagesforFree" },
        @{ Name = "Facebook"; Package = "Facebook.Facebook" },
        @{ Name = "EclipseManager"; Package = "46928bounde.EclipseManager" },
        @{ Name = "MarchofEmpires"; Package = "A278AB0D.MarchofEmpires" },
        @{ Name = "BubbleWitch3Saga"; Package = "king.com.BubbleWitch3Saga" },
        @{ Name = "AutodeskSketchBook"; Package = "89006A2E.AutodeskSketchBook" },
        @{ Name = "Plex"; Package = "CAF9E577.Plex" },
        @{ Name = "DisneyMagicKingdoms"; Package = "A278AB0D.DisneyMagicKingdoms" },
        @{ Name = "HiddenCityMysteryofShadows"; Package = "828B5831.HiddenCityMysteryofShadows" },
        @{ Name = "WinZipUniversal"; Package = "WinZipComputing.WinZipUniversal" },
        @{ Name = "SpotifyMusic"; Package = "SpotifyAB.SpotifyMusic" },
        @{ Name = "PandoraMediaInc"; Package = "PandoraMediaInc.29680B314EFC2" },
        @{ Name = "Viber"; Package = "2414FC7A.Viber" },
        @{ Name = "OneCalendar"; Package = "64885BlueEdge.OneCalendar" },
        @{ Name = "ACGMediaPlayer"; Package = "41038Axilesoft.ACGMediaPlayer" }
    )

    foreach ($app in $appxList) { 
        uninstallAppXApp -PackageName $app.Package -FriendlyName $app.Name 
    }
}
function uninstallOneDrive {
    try {
        writeText -type "plain" -text "Searching for OneDrive"

        # Check if OneDrive is actually installed by checking user folders and registry
        $onedriveInstalled = $false
        $onedriveProcess = Get-Process -Name "OneDrive" -ErrorAction SilentlyContinue
        
        # Check user-specific OneDrive installations
        $users = Get-ChildItem "$env:SystemDrive\Users" -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -notin @("Public", "Default", "Default User", "All Users") }
        
        foreach ($u in $users) {
            $odBase = "$($u.FullName)\AppData\Local\Microsoft\OneDrive"
            if (Test-Path $odBase) {
                # Check for OneDrive.exe or version folder to confirm installation
                $onedriveExe = Get-ChildItem $odBase -Filter "OneDrive.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
                if ($onedriveExe) {
                    $onedriveInstalled = $true
                    writeText -type "plain" -text "Found OneDrive installation for user: $($u.Name)"
                    break
                }
            }
        }

        # Also check registry for OneDrive installation
        if (-not $onedriveInstalled) {
            $regPaths = @(
                "HKCU:\Software\Microsoft\OneDrive",
                "HKLM:\SOFTWARE\Microsoft\OneDrive",
                "HKLM:\SOFTWARE\WOW6432Node\Microsoft\OneDrive"
            )
            
            foreach ($regPath in $regPaths) {
                if (Test-Path $regPath) {
                    $onedriveInstalled = $true
                    writeText -type "plain" -text "Found OneDrive registry entries at: $regPath"
                    break
                }
            }
        }

        if (-not $onedriveInstalled) {
            writeText -type "plain" -text "OneDrive not found. Skipping."
            writeText -type "plain" -text "----------------------------------"
            return  # <-- ADD THIS LINE TO EXIT THE FUNCTION
        }

        # Stop OneDrive process if running
        if ($onedriveProcess) {
            writeText -type "plain" -text "Stopping OneDrive processes"
            $onedriveProcess | Stop-Process -Force
            Start-Sleep -Seconds 3
        } else {
            writeText -type "plain" -text "OneDrive is not running, skipping process termination"
        }

        $uninstalled = $false

        # Try per-user uninstall using OneDriveSetup.exe from user folders
        foreach ($u in $users) {
            $odBase = "$($u.FullName)\AppData\Local\Microsoft\OneDrive"
            if (-not (Test-Path $odBase)) { 
                writeText -type "plain" -text "No OneDrive folder found for user: $($u.Name)"
                continue 
            }

            # Find OneDriveSetup.exe in the user's OneDrive folder
            $odSetupExe = Get-ChildItem $odBase -Filter "OneDriveSetup.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
            
            if (-not $odSetupExe) {
                writeText -type "plain" -text "No OneDriveSetup.exe found for user: $($u.Name)"
                continue
            }

            writeText -type "plain" -text "Processing OneDrive for user: $($u.Name)"
            
            # Try direct uninstall first
            try {
                writeText -type "plain" -text "Attempting direct uninstall for user: $($u.Name)"
                $proc = Start-Process -FilePath $odSetupExe.FullName -ArgumentList "/uninstall" -Wait -WindowStyle Hidden -PassThru
                Start-Sleep -Seconds 3
                if ($proc.ExitCode -eq 0 -or $proc.ExitCode -eq 1603) {
                    writeText -type "success" -text "OneDrive uninstalled for user: $($u.Name)"
                    $uninstalled = $true
                    continue
                }
            } catch {
                writeText -type "notice" -text "Direct uninstall failed for user $($u.Name): $($_.Exception.Message)"
            }

            # Fallback to scheduled task method if direct uninstall fails
            $safeName = $u.Name -replace '[^a-zA-Z0-9]', '_'
            $taskName = "NuviaODRemove_$safeName"
            
            # Check if scheduled task already exists and remove it
            $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
            if ($existingTask) {
                writeText -type "plain" -text "Removing existing scheduled task: $taskName"
                Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
            }

            try {
                $action = New-ScheduledTaskAction -Execute $odSetupExe.FullName -Argument "/uninstall"
                $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest -LogonType ServiceAccount
                
                writeText -type "plain" -text "Creating scheduled task for user uninstall: $taskName"
                Register-ScheduledTask -TaskName $taskName -Action $action -Principal $principal -Force -ErrorAction Stop | Out-Null
                
                $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
                if ($task) {
                    writeText -type "plain" -text "Starting scheduled task: $taskName"
                    Start-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
                    Start-Sleep -Seconds 30
                    
                    # Clean up the task
                    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
                    writeText -type "success" -text "OneDrive uninstalled for user: $($u.Name) via scheduled task"
                    $uninstalled = $true
                } else {
                    writeText -type "notice" -text "Failed to register scheduled task for user: $($u.Name)"
                }
            } catch {
                writeText -type "notice" -text "Failed to uninstall OneDrive for user $($u.Name): $($_.Exception.Message)"
                Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
            }
        }

        if ($uninstalled) {
            writeText -type "success" -text "OneDrive uninstalled successfully"
        } else {
            writeText -type "error" -text "OneDrive failed to uninstall"
        }

        # Clean up OneDrive folders with checks
        writeText -type "plain" -text "Cleaning up OneDrive folders and registry entries"
        
        $oneDrivePaths = @(
            "$env:PROGRAMDATA\Microsoft OneDrive", 
            "$env:SYSTEMDRIVE\OneDriveTemp", 
            "$env:LOCALAPPDATA\Microsoft\OneDrive", 
            "$env:USERPROFILE\OneDrive"
        )

        $removedCount = 0
        foreach ($folder in $oneDrivePaths) {
            if (Test-Path $folder) { 
                writeText -type "plain" -text "Removing folder: $folder"
                Remove-Item -Path $folder -Recurse -Force -ErrorAction SilentlyContinue
                if (-not (Test-Path $folder)) {
                    $removedCount++
                }
            } else {
                writeText -type "plain" -text "Folder not found, skipping: $folder"
            }
        }
        
        if ($removedCount -gt 0) {
            writeText -type "plain" -text "Removed $removedCount OneDrive folders"
        } else {
            writeText -type "plain" -text "No OneDrive folders found to remove"
        }

        # Clean up registry entries with checks
        if (!(Test-Path "HKCR:")) {
            New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT | Out-Null
        }

        $registryPaths = @(
            "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}",
            "HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}",
            "HKCU:\Software\Microsoft\OneDrive",
            "HKLM:\SOFTWARE\Microsoft\OneDrive",
            "HKLM:\SOFTWARE\WOW6432Node\Microsoft\OneDrive"
        )

        $regRemovedCount = 0
        foreach ($regPath in $registryPaths) {
            if (Test-Path $regPath) {
                writeText -type "plain" -text "Removing registry entry: $regPath"
                Remove-Item -Path $regPath -Recurse -Force -ErrorAction SilentlyContinue
                if (-not (Test-Path $regPath)) {
                    $regRemovedCount++
                }
            } else {
                writeText -type "plain" -text "Registry entry not found, skipping: $regPath"
            }
        }
        
        if ($regRemovedCount -gt 0) {
            writeText -type "plain" -text "Removed $regRemovedCount registry entries"
        } else {
            writeText -type "plain" -text "No registry entries found to remove"
        }

    } catch {
        writeText -type "error" -text "$($MyInvocation.MyCommand.Name)-$($_.InvocationInfo.ScriptLineNumber)"
        log -msg "$($MyInvocation.MyCommand.Name)-$($_.InvocationInfo.ScriptLineNumber):$($_.Exception.Message)" -lvl "ERROR"
    }
}
function uninstallTeams {
    try {
        writeText -type "plain" -text "Searching for Microsoft Teams"
        foreach ($proc in @("Teams", "ms-teams", "msteams")) {
            Get-Process -Name $proc -ErrorAction SilentlyContinue | Stop-Process -Force
        }

        Start-Sleep -Seconds 3

        uninstallAppXApp -PackageName "MSTeams"        -FriendlyName "Microsoft Teams (New)"
        uninstallAppXApp -PackageName "MicrosoftTeams" -FriendlyName "Microsoft Teams (AppX)"

        $userProfiles = Get-ChildItem "$env:SystemDrive\Users" -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -notin @("Public", "Default", "Default User", "All Users") }
        
        foreach ($profile in $userProfiles) {
            $teamsPath = "$($profile.FullName)\AppData\Local\Microsoft\Teams\Update.exe"
            if (Test-Path $teamsPath) {
                try {
                    Start-Process -FilePath $teamsPath -ArgumentList "--uninstall /s" -Wait -WindowStyle Hidden
                    writeText -type "plain" -text "Teams Classic uninstalled."
                } catch {
                    writeText -type "error" -text "$($MyInvocation.MyCommand.Name)-$($_.InvocationInfo.ScriptLineNumber)"
                    log -msg "$($MyInvocation.MyCommand.Name)-$($_.InvocationInfo.ScriptLineNumber):$($_.Exception.Message)" -lvl "ERROR"
                }
            }
            foreach ($folder in @(
                    "$($profile.FullName)\AppData\Local\Microsoft\Teams",
                    "$($profile.FullName)\AppData\Roaming\Microsoft\Teams"
                )) {
                if (Test-Path $folder) { Remove-Item -Path $folder -Recurse -Force -ErrorAction SilentlyContinue }
            }
        }

        uninstallWin32App -AppName "Teams Machine-Wide Installer"
        uninstallWin32App -AppName "Microsoft Teams" 
    } catch {
        writeText -type "error" -text "$($MyInvocation.MyCommand.Name)-$($_.InvocationInfo.ScriptLineNumber)"
        log -msg "$($MyInvocation.MyCommand.Name)-$($_.InvocationInfo.ScriptLineNumber):$($_.Exception.Message)" -lvl "ERROR"
    }
    
}
function declutter {
    writeText -type "header" -text "Decluttering"
    disableBingSearch
    disableTaskbarWidgets
    removeTaskbarPins
}
function disableBingSearch {
    try {
        writeText -type "plain" -text "Disabling Bing Search in Start Menu" -lineBefore
        $bingPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search"
        if (-not (Test-Path $bingPath)) { 
            New-Item -Path $bingPath -Force | Out-Null 
        }

        Set-ItemProperty -Path $bingPath -Name "BingSearchEnabled" -Value 0 -Type DWord -Force
        Set-ItemProperty -Path $bingPath -Name "CortanaConsent"    -Value 0 -Type DWord -Force

        $policyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
        if (-not (Test-Path $policyPath)) { 
            New-Item -Path $policyPath -Force | Out-Null 
        }

        Set-ItemProperty -Path $policyPath -Name "DisableWebSearch"      -Value 1 -Type DWord -Force
        Set-ItemProperty -Path $policyPath -Name "ConnectedSearchUseWeb" -Value 0 -Type DWord -Force
        writeText -type "success" -text "Bing search disabled."
    } catch {
        writeText -type "error" -text "$($MyInvocation.MyCommand.Name)-$($_.InvocationInfo.ScriptLineNumber)"
        log -msg "$($MyInvocation.MyCommand.Name)-$($_.InvocationInfo.ScriptLineNumber):$($_.Exception.Message)" -lvl "ERROR"
    }
}
function disableTaskbarWidgets {
    try {
        writeText -type "plain" -text "Disabling Taskbar Widgets" -lineBefore
        
        # Method 1: Group Policy path (HKLM)
        $widgetsPolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Dsh"
        if (-not (Test-Path $widgetsPolicyPath)) { 
            New-Item -Path $widgetsPolicyPath -Force | Out-Null 
        }
        Set-ItemProperty -Path $widgetsPolicyPath -Name "AllowNewsAndInterests" -Value 0 -Type DWord -Force

        $widgetsW11Path = "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\NewsAndInterests\AllowNewsAndInterests"
        if (-not (Test-Path $widgetsW11Path)) { 
            New-Item -Path $widgetsW11Path -Force | Out-Null 
        }
        Set-ItemProperty -Path $widgetsW11Path -Name "value" -Value 0 -Type DWord -Force
        
        writeText -type "success" -text "Taskbar widgets removed."
        
    } catch {
        writeText -type "error" -text "$($MyInvocation.MyCommand.Name)-$($_.InvocationInfo.ScriptLineNumber)"
        log -msg "$($MyInvocation.MyCommand.Name)-$($_.InvocationInfo.ScriptLineNumber):$($_.Exception.Message)" -lvl "ERROR"
    }
}
function removeTaskbarPins {
    try {
        writeText -type "plain" -text "Removing Taskbar Pins"
        $appsToUnpin = @("Microsoft Edge", "Microsoft Store", "Dell Optimizer", "Dell Command Update", "Copilot")
        
        # Get all taskbar pins
        $shell = New-Object -Com Shell.Application
        $taskbarItems = $shell.NameSpace('shell:::{4234d49b-0245-4df3-b780-3893943456e1}').Items()
        
        foreach ($item in $taskbarItems) {
            $shouldUnpin = $false
            foreach ($appName in $appsToUnpin) {
                if ($item.Name -like "*$appName*") {
                    $shouldUnpin = $true
                    break
                }
            }
            
            if ($shouldUnpin) {
                try {
                    $verbs = $item.Verbs()
                    $unpinVerb = $verbs | Where-Object { $_.Name -match "Unpin from taskbar" }
                    if ($unpinVerb) {
                        $unpinVerb.DoIt()
                        writeText -type "success" -text "$($item.Name) Unpinned successfully"
                    }
                } catch {
                    writeText -type "error" -text "$($MyInvocation.MyCommand.Name)-$($_.InvocationInfo.ScriptLineNumber)"
                    log -msg "$($MyInvocation.MyCommand.Name)-$($_.InvocationInfo.ScriptLineNumber):$($_.Exception.Message)" -lvl "ERROR" 
                }
            }
        }

        # Clean up registry - but ONLY remove specific entries, not all
        $taskbarRegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband"
        if (Test-Path $taskbarRegPath) {
            # Don't remove Favorites and FavoritesResolve as these might contain other pins
            # Only remove if you're sure these only contain the apps you want to remove
            # Remove-ItemProperty -Path $taskbarRegPath -Name "FavoritesResolve" -ErrorAction SilentlyContinue
            # Remove-ItemProperty -Path $taskbarRegPath -Name "Favorites"        -ErrorAction SilentlyContinue
        }

        $taskbarLayoutFile = "$env:LOCALAPPDATA\Microsoft\Windows\Shell\LayoutModification.xml"
        if (Test-Path $taskbarLayoutFile) { 
            # Only remove if this file only contains the apps you want to remove
            # Consider parsing the XML instead of deleting the entire file
            # Remove-Item $taskbarLayoutFile -Force -ErrorAction SilentlyContinue 
        }

        $taskbarPinPath = "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar"
        if (Test-Path $taskbarPinPath) {
            # Only remove specific .lnk files, not all matching the pattern
            Get-ChildItem $taskbarPinPath -Filter "*.lnk" -ErrorAction SilentlyContinue |
            ForEach-Object {
                $shouldRemove = $false
                foreach ($appName in $appsToUnpin) {
                    if ($_.Name -match [regex]::Escape($appName)) {
                        $shouldRemove = $true
                        break
                    }
                }
                if ($shouldRemove) {
                    Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue
                    writeText -type "info" -text "Removed shortcut: $($_.Name)"
                }
            }
        }

        writeText -type "success" -text "Taskbar Pins removal completed"
    } catch {
        writeText -type "error" -text "$($MyInvocation.MyCommand.Name)-$($_.InvocationInfo.ScriptLineNumber)"
        log -msg "$($MyInvocation.MyCommand.Name)-$($_.InvocationInfo.ScriptLineNumber):$($_.Exception.Message)" -lvl "ERROR"
    }
}
function disableTelemetry {
    writeText -type "plain" -text "Disabling Telemetry..."
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name "AllowTelemetry" -type DWord -Value 0
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -type DWord -Value 0
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name "AllowTelemetry" -type DWord -Value 0
    # Disable-ScheduledTask -TaskName "Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" | Out-Null
    # Disable-ScheduledTask -TaskName "Microsoft\Windows\Application Experience\ProgramDataUpdater" | Out-Null
    Disable-ScheduledTask -TaskName "Microsoft\Windows\Autochk\Proxy" | Out-Null
    Disable-ScheduledTask -TaskName "Microsoft\Windows\Customer Experience Improvement Program\Consolidator" | Out-Null
    Disable-ScheduledTask -TaskName "Microsoft\Windows\Customer Experience Improvement Program\UsbCeip" | Out-Null
    Disable-ScheduledTask -TaskName "Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector" | Out-Null
}
function disableWiFiSense {
    writeText -type "plain" -text "Disabling Wi-Fi Sense..."
    if (!(Test-Path "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting")) {
        New-Item -Path "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting" -Force | Out-Null
    }
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting" -Name "Value" -type DWord -Value 0
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots" -Name "Value" -type DWord -Value 0
    if (!(Test-Path "HKLM:\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\config")) {
        New-Item -Path "HKLM:\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\config" -Force | Out-Null
    }
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\config" -Name "AutoConnectAllowedOEM" -type Dword -Value 0
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\config" -Name "WiFISenseAllowed" -type Dword -Value 0
}
function disableAppSuggestions {
    writeText -type "plain" -text "Disabling Application suggestions..."
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "ContentDeliveryAllowed" -type DWord -Value 0
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "OemPreInstalledAppsEnabled" -type DWord -Value 0
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "PreInstalledAppsEnabled" -type DWord -Value 0
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "PreInstalledAppsEverEnabled" -type DWord -Value 0
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SilentInstalledAppsEnabled" -type DWord -Value 0
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338389Enabled" -type DWord -Value 0
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SystemPaneSuggestionsEnabled" -type DWord -Value 0
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338388Enabled" -type DWord -Value 0
    if (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent")) {
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Force | Out-Null
    }
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsConsumerFeatures" -type DWord -Value 1
}
function disableLockScreenSpotlight {
    writeText -type "plain" -text "Disabling Lock screen spotlight..."
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "RotatingLockScreenEnabled" -type DWord -Value 0
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "RotatingLockScreenOverlayEnabled" -type DWord -Value 0
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338387Enabled" -type DWord -Value 0
}
function disableFeedback {
    writeText -type "plain" -text "Disabling Feedback..."
    if (!(Test-Path "HKCU:\SOFTWARE\Microsoft\Siuf\Rules")) {
        New-Item -Path "HKCU:\SOFTWARE\Microsoft\Siuf\Rules" -Force | Out-Null
    }
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Siuf\Rules" -Name "NumberOfSIUFInPeriod" -type DWord -Value 0
    Disable-ScheduledTask -TaskName "Microsoft\Windows\Feedback\Siuf\DmClient" -ErrorAction SilentlyContinue | Out-Null
    Disable-ScheduledTask -TaskName "Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload" -ErrorAction SilentlyContinue | Out-Null
}
function disableAdvertisingID {
    writeText -type "plain" -text "Disabling Advertising ID..."
    if (!(Test-Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo")) {
        New-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" | Out-Null
    }
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -type DWord -Value 0
    if (!(Test-Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy")) {
        New-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy" | Out-Null
    }
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy" -Name "TailoredExperiencesWithDiagnosticDataEnabled" -type DWord -Value 0
}
function disableCortana {
    writeText -type "plain" -text "Disabling Cortana..."
    if (!(Test-Path "HKCU:\SOFTWARE\Microsoft\Personalization\Settings")) {
        New-Item -Path "HKCU:\SOFTWARE\Microsoft\Personalization\Settings" -Force | Out-Null
    }
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Personalization\Settings" -Name "AcceptedPrivacyPolicy" -type DWord -Value 0
    if (!(Test-Path "HKCU:\SOFTWARE\Microsoft\InputPersonalization")) {
        New-Item -Path "HKCU:\SOFTWARE\Microsoft\InputPersonalization" -Force | Out-Null
    }
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\InputPersonalization" -Name "RestrictImplicitTextCollection" -type DWord -Value 1
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\InputPersonalization" -Name "RestrictImplicitInkCollection" -type DWord -Value 1
    if (!(Test-Path "HKCU:\SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore")) {
        New-Item -Path "HKCU:\SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore" -Force | Out-Null
    }
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore" -Name "HarvestContacts" -type DWord -Value 0
    if (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search")) {
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Force | Out-Null
    }
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana" -type DWord -Value 0
}
function enableErrorReporting {
    writeText -type "plain" -text "Enabling Error reporting..."
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting" -Name "Disabled" -ErrorAction SilentlyContinue
    Enable-ScheduledTask -TaskName "Microsoft\Windows\Windows Error Reporting\QueueReporting" | Out-Null
}
function disableAutoLogger {
    writeText -type "plain" -text "Removing AutoLogger file and restricting directory..."
    $autoLoggerDir = "$env:PROGRAMDATA\Microsoft\Diagnosis\ETLLogs\AutoLogger"
    if (Test-Path "$autoLoggerDir\AutoLogger-Diagtrack-Listener.etl") {
        Remove-Item -Path "$autoLoggerDir\AutoLogger-Diagtrack-Listener.etl"
    }
    icacls $autoLoggerDir /deny SYSTEM:`(OI`)`(CI`)F | Out-Null
}
function disableDiagTrack {
    writeText -type "plain" -text "Stopping and disabling Diagnostics Tracking Service..."
    Stop-Service "DiagTrack" -WarningAction SilentlyContinue
    Set-Service "DiagTrack" -StartupType Disabled
}
function disableWAPPush {
    writeText -type "plain" -text "Stopping and disabling WAP Push Service..."
    Stop-Service "dmwappushservice" -WarningAction SilentlyContinue
    Set-Service "dmwappushservice" -StartupType Disabled
}
function disableSMB1 {
    writeText -type "plain" -text "Disabling SMB 1.0 protocol..."
    Set-SmbServerConfiguration -EnableSMB1Protocol $false -Force
}
function setCurrentNetworkPrivate {
    writeText -type "plain" -text "Setting current network profile to private..."
    Set-NetConnectionProfile -NetworkCategory Private
}
function disableUpdateRestart {
    writeText -type "plain" -text "Disabling Windows Update automatic restart..."
    if (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU")) {
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Force | Out-Null
    }
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "NoAutoRebootWithLoggedOnUsers" -type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "AUPowerManagement" -type DWord -Value 0
}
function disableRemoteAssistance {
    writeText -type "plain" -text "Disabling Remote Assistance..."
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Remote Assistance" -Name "fAllowToGetHelp" -type DWord -Value 0
}
function disableRemoteDesktop {
    writeText -type "plain" -text "Disabling Remote Desktop..."
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -type DWord -Value 1
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "UserAuthentication" -type DWord -Value 1
}
function disableAutoplay {
    writeText -type "plain" -text "Disabling Autoplay..."
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers" -Name "DisableAutoplay" -type DWord -Value 1
}
function disableAutorun {
    writeText -type "plain" -text "Disabling Autorun for all drives..."
    if (!(Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer")) {
        New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" | Out-Null
    }
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "NoDriveTypeAutoRun" -type DWord -Value 255
}
function disableHibernation {
    writeText -type "plain" -text "Disabling Hibernation..."
    Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Session Manager\Power" -Name "HibernteEnabled" -type Dword -Value 0
    if (!(Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings")) {
        New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings" | Out-Null
    }
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings" -Name "ShowHibernateOption" -type Dword -Value 0
}
function showShutdownOnLockScreen {
    writeText -type "plain" -text "Showing shutdown options on Lock Screen..."
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ShutdownWithoutLogon" -type DWord -Value 1
}
function disableStickyKeys {
    writeText -type "plain" -text "Disabling Sticky keys prompt..."
    Set-ItemProperty -Path "HKCU:\Control Panel\Accessibility\StickyKeys" -Name "Flags" -type String -Value "506"
}
function showFileOperationsDetails {
    writeText -type "plain" -text "Showing file operations details..."
    if (!(Test-Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\OperationStatusManager")) {
        New-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\OperationStatusManager" | Out-Null
    }
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\OperationStatusManager" -Name "EnthusiastMode" -type DWord -Value 1
}
function hideTaskbarSearchBox {
    writeText -type "plain" -text "Hiding Taskbar Search box / button..."
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -type DWord -Value 0
}
function hideTaskView {
    writeText -type "plain" -text "Hiding Task View button..."
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton" -type DWord -Value 0
}
function hideTaskbarPeopleIcon {
    writeText -type "plain" -text "Hiding People icon..."
    if (!(Test-Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People")) {
        New-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People" | Out-Null
    }
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People" -Name "PeopleBand" -type DWord -Value 0
}
function showTrayIcons {
    writeText -type "plain" -text "Showing all tray icons..."
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" -Name "EnableAutoTray" -type DWord -Value 0
}
function showThisPCOnDesktop {
    writeText -type "plain" -text "Showing This PC shortcut on desktop..."
    if (!(Test-Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\ClassicStartMenu")) {
        New-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\ClassicStartMenu" -Force | Out-Null
    }
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\ClassicStartMenu" -Name "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" -type DWord -Value 0
    if (!(Test-Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel")) {
        New-Item -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" -Force | Out-Null
    }
    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" -Name "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" -type DWord -Value 0
}
function showDesktopInThisPC {
    writeText -type "plain" -text "Showing Desktop icon in This PC..."
    if (!(Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{B4BFCC3A-DB2C-424C-B029-7FE99A87C641}")) {
        New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{B4BFCC3A-DB2C-424C-B029-7FE99A87C641}" | Out-Null
    }
}
function showDesktopInExplorer {
    writeText -type "plain" -text "Showing Desktop icon in Explorer namespace..."
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\{B4BFCC3A-DB2C-424C-B029-7FE99A87C641}\PropertyBag" -Name "ThisPCPolicy" -type String -Value "Show"
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\{B4BFCC3A-DB2C-424C-B029-7FE99A87C641}\PropertyBag" -Name "ThisPCPolicy" -type String -Value "Show"
}
function showDocumentsInThisPC {
    writeText -type "plain" -text "Showing Documents icon in This PC..."
    if (!(Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{d3162b92-9365-467a-956b-92703aca08af}")) {
        New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{d3162b92-9365-467a-956b-92703aca08af}" | Out-Null
    }
    if (!(Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{A8CDFF1C-4878-43be-B5FD-F8091C1C60D0}")) {
        New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{A8CDFF1C-4878-43be-B5FD-F8091C1C60D0}" | Out-Null
    }
}
function showDocumentsInExplorer {
    writeText -type "plain" -text "Showing Documents icon in Explorer namespace..."
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\{f42ee2d3-909f-4907-8871-4c22fc0bf756}\PropertyBag" -Name "ThisPCPolicy" -type String -Value "Show"
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\{f42ee2d3-909f-4907-8871-4c22fc0bf756}\PropertyBag" -Name "ThisPCPolicy" -type String -Value "Show"
}
function showDownloadsInThisPC {
    writeText -type "plain" -text "Showing Downloads icon in This PC..."
    if (!(Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{088e3905-0323-4b02-9826-5d99428e115f}")) {
        New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{088e3905-0323-4b02-9826-5d99428e115f}" | Out-Null
    }
    if (!(Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{374DE290-123F-4565-9164-39C4925E467B}")) {
        New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{374DE290-123F-4565-9164-39C4925E467B}" | Out-Null
    }
}
function showDownloadsInExplorer {
    writeText -type "plain" -text "Showing Downloads icon in Explorer namespace..."
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\{7d83ee9b-2244-4e70-b1f5-5393042af1e4}\PropertyBag" -Name "ThisPCPolicy" -type String -Value "Show"
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\{7d83ee9b-2244-4e70-b1f5-5393042af1e4}\PropertyBag" -Name "ThisPCPolicy" -type String -Value "Show"
}
function disableXboxFeatures {
    writeText -type "plain" -text "Disabling Xbox features..."
    Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -type DWord -Value 0
    if (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR")) {
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" | Out-Null
    }
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" -Name "AllowGameDVR" -type DWord -Value 0
}
function disableSearchAppInStore {
    writeText -type "plain" -text "Disabling search for app in store for unknown extensions..."
    if (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer")) {
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer" | Out-Null
    }
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name "NoUseStoreOpenWith" -type DWord -Value 1
}
function installApps {
    installViaWinget -appName "Sonos"         -WingetId "Sonos.Controller"
    installViaWinget -appName "Adobe Acrobat" -WingetId "Adobe.Acrobat.Reader.64-bit"
    installViaWinget -appName "Google Chrome" -WingetId "Google.Chrome"
    installViaWinget -appName "Cliq"     -WingetId "Zoho.Cliq"
    installViaWinget -appName "Dropbox"       -WingetId "Dropbox.Dropbox"
    #Install-NinjaOne  -InstallerUrl $NinjaInstallerUrl
}
function normalizeEnvironment {
    param (
        [Parameter(Mandatory = $true)]
        [string]$locationType
    )

    Write-Section "Setting Up Nuvia Directory and Wallpapers"
    foreach ($dir in @($NuviaDir, $WallpaperDir, $BGInfoDir, $LogDir)) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
            Write-Log "Created: $dir" "SUCCESS"
        } else {
            Write-Log "Exists: $dir" "SKIP"
        }
    }

    Write-Log "Script directory: $ScriptDir"
    Add-Type -AssemblyName System.Drawing

    $wallpapers = @(
        @{ PngName = "Nuvia_Advanced_Dentistry_Wallpaper.png"; JpgName = "Nuvia_Advanced_Dentistry_Wallpaper.jpg"; Name = "Advanced Dentistry" },
        @{ PngName = "Nuvia_Impant_Center_Wallpaper.png"; JpgName = "Nuvia_Impant_Center_Wallpaper.jpg"; Name = "Dental Implant Center" }
    )
    foreach ($wp in $wallpapers) {
        $srcPng = Join-Path $ScriptDir $wp.PngName
        $dstPng = Join-Path $WallpaperDir $wp.PngName
        $dstJpg = Join-Path $WallpaperDir $wp.JpgName
        if (-not (Test-Path $dstPng)) {
            if (Test-Path $srcPng) { Copy-Item -Path $srcPng -Destination $dstPng -Force; Write-Log "Copied PNG: $($wp.Name)" "SUCCESS" }
            else { Write-Log "PNG source not found: $srcPng" "WARNING" }
        }
        if (-not (Test-Path $dstJpg)) {
            if (Test-Path $dstPng) {
                try {
                    $img = [System.Drawing.Image]::FromFile($dstPng)
                    $enc = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq "image/jpeg" }
                    $params = New-Object System.Drawing.Imaging.EncoderParameters(1)
                    $params.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, 95L)
                    $img.Save($dstJpg, $enc, $params)
                    $img.Dispose()
                    Write-Log "JPG created: $($wp.Name)" "SUCCESS"
                } catch { Write-Log "JPG conversion failed: $($_.Exception.Message)" "ERROR" }
            }
        } else { Write-Log "JPG already exists: $($wp.Name)" "SKIP" }
    }

    foreach ($bgi in @("Nuvia_CLI.bgi", "Nuvia_ADV.bgi")) {
        $src = Join-Path $ScriptDir $bgi
        $dst = Join-Path $BGInfoDir $bgi
        if ((Test-Path $src) -and (-not (Test-Path $dst))) {
            Copy-Item -Path $src -Destination $dst -Force
            Write-Log "Copied BGI config: $bgi" "SUCCESS"
        }
    }

    Write-Section "Installing BGInfo"
    if (-not (Test-Path $BGInfoExe)) {
        Write-Log "Downloading BGInfo from Sysinternals..."
        try {
            $zip = "$env:TEMP\BGInfo.zip"
            Invoke-WebRequest -Uri "https://download.sysinternals.com/files/BGInfo.zip" -OutFile $zip -UseBasicParsing
            Expand-Archive -Path $zip -DestinationPath $BGInfoDir -Force
            Remove-Item $zip -Force -ErrorAction SilentlyContinue
            Write-Log "BGInfo downloaded and extracted" "SUCCESS"
        } catch { Write-Log "BGInfo download failed: $($_.Exception.Message)" "ERROR" }
    } else { Write-Log "BGInfo already present" "SKIP" }

    Write-Section "Configuring BGInfo"

    if ($Script:LocationType -eq "ADV") {
        $BGInfoCfg = Join-Path $BGInfoDir "Nuvia_ADV.bgi"
        $WallpaperJpg = Join-Path $WallpaperDir "Nuvia_Advanced_Dentistry_Wallpaper.jpg"
    } else {
        $BGInfoCfg = Join-Path $BGInfoDir "Nuvia_CLI.bgi"
        $WallpaperJpg = Join-Path $WallpaperDir "Nuvia_Impant_Center_Wallpaper.jpg"
    }
    Write-Log "BGInfo config: $BGInfoCfg"
    Write-Log "Wallpaper JPG: $WallpaperJpg"

    if (Test-Path $BGInfoExe) {
        if (-not (Test-Path $BGInfoCfg)) {
            Write-Host ""
            Write-Host "  ============================================" -ForegroundColor Yellow
            Write-Host "  ONE-TIME BGINFO SETUP REQUIRED" -ForegroundColor Yellow
            Write-Host "  ============================================" -ForegroundColor Yellow
            Write-Host "  BGInfo will open. Follow these exact steps:" -ForegroundColor White
            Write-Host ""
            Write-Host "  1. Click [Background...] button" -ForegroundColor Cyan
            Write-Host "       Select: Use these settings" -ForegroundColor White
            Write-Host "       Wallpaper Bitmap: $WallpaperJpg" -ForegroundColor Yellow
            Write-Host "       Wallpaper Position: Fill" -ForegroundColor White
            Write-Host "       CHECK: Make wallpaper visible behind text" -ForegroundColor White
            Write-Host "       Click [Desktops...] inside Background:" -ForegroundColor White
            Write-Host "         User Desktop = Update the wallpaper" -ForegroundColor Yellow
            Write-Host "       Click OK" -ForegroundColor White
            Write-Host ""
            Write-Host "  2. Click [Position...] button" -ForegroundColor Cyan
            Write-Host "       Click the UPPER RIGHT dot in the 3x3 grid" -ForegroundColor Yellow
            Write-Host "       Click OK" -ForegroundColor White
            Write-Host ""
            Write-Host "  3. Set text color to white:" -ForegroundColor Cyan
            Write-Host "       Click a field > Ctrl+A (select all fields)" -ForegroundColor White
            Write-Host "       Click [Font...] > Set color to White > OK" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "  4. Click [Apply] to preview on desktop" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "  5. File > Save As" -ForegroundColor Cyan
            Write-Host "       Navigate to: $BGInfoDir" -ForegroundColor Yellow
            Write-Host "       Filename: $(Split-Path $BGInfoCfg -Leaf)" -ForegroundColor Yellow
            Write-Host "       Click Save" -ForegroundColor White
            Write-Host ""
            Write-Host "  6. Close BGInfo - script will continue" -ForegroundColor Cyan
            Write-Host "  ============================================" -ForegroundColor Yellow
            Write-Host ""
            Read-Host "  Press ENTER to open BGInfo now"

            $proc = Start-Process -FilePath $BGInfoExe -ArgumentList "/accepteula" -PassThru
            Write-Host "  BGInfo is open. Save to $BGInfoCfg then close it." -ForegroundColor Yellow
            $proc.WaitForExit()
            Write-Log "BGInfo closed by user"
        } else {
            Write-Log "BGInfo config already exists - skipping one-time setup" "SKIP"
        }

        if (Test-Path $BGInfoCfg) {
            $runKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
            $runValue = "`"$BGInfoExe`" `"$BGInfoCfg`" /timer:0 /silent /nolicprompt /accepteula"
            Set-ItemProperty -Path $runKey -Name "NuviaBGInfo" -Value $runValue -Force
            Write-Log "BGInfo added to HKLM Run key" "SUCCESS"

            $taskName = "NuviaBGInfo"
            $taskAction = New-ScheduledTaskAction -Execute $BGInfoExe `
                -Argument "`"$BGInfoCfg`" /timer:0 /silent /nolicprompt /accepteula"
            $taskTrigger = New-ScheduledTaskTrigger -AtLogOn
            $taskPrincipal = New-ScheduledTaskPrincipal -GroupId "BUILTIN\Users" -RunLevel Limited
            $taskSettings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Minutes 1)
            Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
            Register-ScheduledTask -TaskName $taskName `
                -Action $taskAction -Trigger $taskTrigger `
                -Principal $taskPrincipal -Settings $taskSettings -Force | Out-Null
            Write-Log "BGInfo scheduled task registered (all users, every logon)" "SUCCESS"

            Write-Log "Applying BGInfo to current desktop..."
            $proc = Start-Process -FilePath $BGInfoExe `
                -ArgumentList "`"$BGInfoCfg`" /timer:0 /silent /nolicprompt /accepteula" `
                -PassThru -WindowStyle Hidden
            $proc.WaitForExit(15000) | Out-Null
            if (-not $proc.HasExited) {
                $proc.Kill() | Out-Null
                Write-Log "BGInfo timed out - will apply at next logon" "WARNING"
            } else {
                Write-Log "BGInfo applied to desktop (exit: $($proc.ExitCode))" "SUCCESS"
            }
        } else {
            Write-Log "No .bgi config found after setup - re-run to complete BGInfo" "WARNING"
        }
    } else {
        Write-Log "BGInfo not found - skipping" "WARNING"
    }

    # ═════════════════════════════════════════════════════════════
    # PART 5: PIN FILE EXPLORER AND CHROME TO TASKBAR
    # ═════════════════════════════════════════════════════════════
    Write-Section "Pinning Apps to Taskbar"
    try {
        $chromeExe = "C:\Program Files\Google\Chrome\Application\chrome.exe"
        if (-not (Test-Path $chromeExe)) {
            Write-Log "Chrome not found at expected path - pin may not work" "WARNING"
        }

        $layoutXml = @"
<?xml version="1.0" encoding="utf-8"?>
<LayoutModificationTemplate
    xmlns="http://schemas.microsoft.com/Start/2014/LayoutModification"
    xmlns:defaultlayout="http://schemas.microsoft.com/Start/2014/FullDefaultLayout"
    xmlns:start="http://schemas.microsoft.com/Start/2014/StartLayout"
    xmlns:taskbar="http://schemas.microsoft.com/Start/2014/TaskbarLayout"
    Version="1">
  <CustomTaskbarLayoutCollection PinListPlacement="Replace">
    <defaultlayout:TaskbarLayout>
      <taskbar:TaskbarPinList>
        <taskbar:DesktopApp DesktopApplicationLinkPath="%APPDATA%\Microsoft\Windows\Start Menu\Programs\File Explorer.lnk"/>
        <taskbar:DesktopApp DesktopApplicationLinkPath="%PROGRAMFILES%\Google\Chrome\Application\chrome.exe"/>
      </taskbar:TaskbarPinList>
    </defaultlayout:TaskbarLayout>
  </CustomTaskbarLayoutCollection>
</LayoutModificationTemplate>
"@

        $layoutPath = "$env:LOCALAPPDATA\Microsoft\Windows\Shell\LayoutModification.xml"
        $layoutXml | Out-File -FilePath $layoutPath -Encoding UTF8 -Force
        Write-Log "Taskbar layout written - pinned: File Explorer, Google Chrome" "SUCCESS"
    } catch {
        Write-Log "Taskbar pin failed: $($_.Exception.Message)" "ERROR"
    }

}
function Write-Summary {
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "  MASTER SETUP SUMMARY" -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "  Computer     : $env:COMPUTERNAME" -ForegroundColor White
    Write-Host "  Location Type: $Script:LocationType" -ForegroundColor White
    Write-Host "  Completed    : $(Get-Date)" -ForegroundColor White
    Write-Host "  Log          : $LogFile" -ForegroundColor White
    Write-Host ""
    Write-Host "  REMOVALS: Removed=$($Script:RemovedCount) Skipped=$($Script:SkippedRemCount) Failed=$($Script:FailedRemCount)" -ForegroundColor $(if ($Script:FailedRemCount -gt 0) { "Yellow" } else { "Green" })
    Write-Host "  INSTALLS: Installed=$($Script:InstalledCount) Skipped=$($Script:SkippedInstCount) Failed=$($Script:FailedInstCount)" -ForegroundColor $(if ($Script:FailedInstCount -gt 0) { "Yellow" } else { "Green" })

    $removed = $Script:RemoveResults  | Where-Object { $_.Status -eq "REMOVED" }
    $remFailed = $Script:RemoveResults  | Where-Object { $_.Status -eq "FAILED" }
    $instOk = $Script:InstallResults | Where-Object { $_.Status -eq "INSTALLED" }
    $instFail = $Script:InstallResults | Where-Object { $_.Status -eq "FAILED" }

    if ($removed) {
        Write-Host ""
        Write-Host "  REMOVED:" -ForegroundColor Green
        $removed | ForEach-Object { Write-Host "    [OK] $($_.App)" -ForegroundColor Green }
    }
    if ($instOk) {
        Write-Host ""
        Write-Host "  INSTALLED:" -ForegroundColor Green
        $instOk | ForEach-Object { Write-Host "    [OK] $($_.App) - $($_.Detail)" -ForegroundColor Green }
    }
    if ($remFailed) {
        Write-Host ""
        Write-Host "  REMOVAL FAILURES:" -ForegroundColor Red
        $remFailed | ForEach-Object { Write-Host "    [!!] $($_.App) - $($_.Detail)" -ForegroundColor Red }
    }
    if ($instFail) {
        Write-Host ""
        Write-Host "  INSTALL FAILURES:" -ForegroundColor Red
        $instFail | ForEach-Object { Write-Host "    [!!] $($_.App) - $($_.Detail)" -ForegroundColor Red }
    }
    Write-Host "============================================" -ForegroundColor Cyan
}