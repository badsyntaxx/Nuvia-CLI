function debloat {
    disableHibernateFile
    cleanTempFiles

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
    uninstallWin32App -AppName "Microsoft 365 Copilot"

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
        @{ Name = "Microsoft Clipchamp"; Package = "Microsoft.Clipchamp" },
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
        writeText -type "plain" -text "Searching for OneDrive" -lineBefore

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
            writeText -type "plain" -text "OneDrive not found."
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
        
        foreach ($prof in $userProfiles) {
            $teamsPath = "$($prof.FullName)\AppData\Local\Microsoft\Teams\Update.exe"
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
                    "$($prof.FullName)\AppData\Local\Microsoft\Teams",
                    "$($prof.FullName)\AppData\Roaming\Microsoft\Teams"
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
function cleanTempFiles {
    try {
        $paths = @(
            @{ Path = "C:\Windows\Temp"; Label = "C:\Windows\Temp" },
            @{ Path = "C:\Windows\Prefetch"; Label = "C:\Windows\Prefetch" }
        )

        # Get all user profile directories under C:\Users, excluding system/service profiles
        $excludedProfiles = @("Public", "Default", "Default User", "All Users")
        $userProfiles = Get-ChildItem -Path "C:\Users" -Directory -ErrorAction SilentlyContinue |
        Where-Object { $excludedProfiles -notcontains $_.Name }

        foreach ($profile in $userProfiles) {
            $tempPath = Join-Path $profile.FullName "AppData\Local\Temp"
            if (Test-Path $tempPath) {
                $paths += @{ Path = $tempPath; Label = "C:\Users\$($profile.Name)\AppData\Local\Temp" }
            }
        }

        foreach ($item in $paths) {
            $beforeSize = getFolderSize -Path $item.Path
            writeText -type "plain" -text "$(formatSize $beforeSize) found at $($item.Label)."
            writeText -type "plain" -text "Cleaning..."

            Remove-Item -Path "$($item.Path)\*" -Recurse -Force -ErrorAction SilentlyContinue

            $afterSize = getFolderSize -Path $item.Path
            $freedSize = $beforeSize - $afterSize
            writeText -type "plain" -text "$(formatSize $freedSize) has been removed. Current size: $(formatSize $afterSize)" -lineAfter
        }

        writeText -type "plain" -text "Emptying Recycle Bin"
        Clear-RecycleBin -Force
        writeText -type "success" -text "Temporary files cleaned."
    } catch {
        writeText -type "error" -text "$($MyInvocation.MyCommand.Name)-$($_.InvocationInfo.ScriptLineNumber)"
        log -msg "$($MyInvocation.MyCommand.Name)-$($_.InvocationInfo.ScriptLineNumber):$($_.Exception.Message)" -lvl "ERROR"
    }
}
function disableHibernateFile {
    param(
        [string]$DriveLetter = $env:SystemDrive
    )

    # Normalize drive letter (e.g. "C:")
    $drive = $DriveLetter.TrimEnd('\')

    # Helper to get free space in GB
    function Get-FreeSpaceGB($DriveRoot) {
        $vol = Get-PSDrive -Name $DriveRoot.TrimEnd(':') -ErrorAction Stop
        return [math]::Round($vol.Free / 1GB, 2)
    }

    $spaceBefore = Get-FreeSpaceGB $drive
    writeText -type "plain" -text "Free space BEFORE: $spaceBefore GB"

    & "C:\Windows\System32\cmd.exe" /c "powercfg /hibernate off"

    $spaceAfter = Get-FreeSpaceGB $drive
    $spaceFreed = [math]::Round($spaceAfter - $spaceBefore, 2)

    writeText -type "plain" -text "Free space AFTER:  $spaceAfter GB"
    writeText -type "plain" -text "Space freed:       $spaceFreed GB"
}