function init {
    $script:scriptStarted = Get-Date
    $stamp = $script:scriptStarted.ToString('yyyy-MM-dd_HH-mm-ss')
    $script:logPath = "$env:SystemDrive\Nuvia\logs\shellcli\$stamp.log"
    $script:errors = $([ordered]@{})

    writeText -type "header" -text "Initializing Nuvia Onboarding Script"
    writeText -type "plain" -text "Hostname : $env:COMPUTERNAME"
    writeText -type "plain" -text "Started  : $script:scriptStarted"
    writeText -type "plain" -text "Context  : $(if (isSystemContext) { 'SYSTEM' } else { $env:USERNAME })"
    writeText -type "plain" -text "Log      : $script:logPath" -lineAfter

    $locationType = readOption -options $([ordered]@{
            "ADV"   = "Advanced Dentistry"
            "CLI"   = "Clinic"
            "LAB"   = "Lab"
            "OTHER" = "All other types"
        }) -prompt "Select a location type:" -returnKey -lineAfter

    if ($locationType -ne "OTHER") {
        writeText -type "prompt" -text "What is the location of this computer? Example: ALX, DAL, IND" -lineBefore
        $location = readInput -prompt "Location:"
        $location = $location.ToUpper()

        writeText -type "notice" -text "$location-$locationType-XXX"

        $validSet = @(
            "FD",
            "FD1", 
            "FD2", 
            "FD3", 
            "OM", 
            "HAL", 
            "EX1", 
            "EX2", 
            "EX3", 
            "EX4", 
            "EX5", 
            "CN1", 
            "CN2", 
            "CN3", 
            "IOS", 
            "MM", 
            "MM1", 
            "MM2", 
            "SED1", 
            "SED2", 
            "SED3", 
            "SUR1", 
            "SUR2", 
            "SUR3", 
            "SUR4", 
            "TRN", 
            "DR1", 
            "DR2", 
            "DR3", 
            "DR4",
            "LLT",
            "ML",
            "BKS",
            "BKU",
            "CAM",
            "SCAN",
            "SCAN1",
            "SCAN2"
        )

        writeText -type "prompt" -text "What type of computer is this? Example: DR1, FD1, EX2"
        $computerType = readInput -prompt "Computer type:" -validSet $validSet

        $computerType = $computerType.ToUpper()

        writeText -type "notice" -text "$location-$locationType-$computerType"
    }


    createNuviaFolders
    debloat
    declutter
    optimize
    installApps -computerType $computerType
    normalizeEnvironment -location $location -locationType $locationType -computerType $computerType
    writeSummary

    # Restart explorer to see GUI changes.
    # Under SYSTEM, Start-Process explorer would launch in session 0 where the
    # user never sees it. Kill it and let Windows respawn it in the interactive
    # session instead.
    Get-Process -Name explorer -ErrorAction SilentlyContinue | Stop-Process -Force
    if (-not (isSystemContext)) {
        Start-Sleep -Seconds 2
        Start-Process explorer
    }
}
function debloat {
    try {
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
        uninstallWin32App -AppName "Microsoft 365 Copilot"

        $appxList = @(
            @{ Name = "Family Safety"; Package = "Microsoft.FamilySafety" },
            @{ Name = "Family Safety (Corp)"; Package = "MicrosoftCorporationII.MicrosoftFamily" },
            @{ Name = "Feedback Hub"; Package = "Microsoft.WindowsFeedbackHub" },
            @{ Name = "Game Bar"; Package = "Microsoft.XboxGameOverlay" },
            @{ Name = "Get Help"; Package = "Microsoft.GetHelp" },
            @{ Name = "Get Started"; Package = "Microsoft.Getstarted" },
            @{ Name = "Microsoft Office Hub"; Package = "Microsoft.MicrosoftOfficeHub" },
            @{ Name = "Microsoft Copilot (AppX)"; Package = "Microsoft.Copilot" },
            @{ Name = "Microsoft News"; Package = "Microsoft.BingNews" },
            @{ Name = "Microsoft To Do"; Package = "Microsoft.Todos" },
            @{ Name = "Microsoft 3D Builder"; Package = "Microsoft.3DBuilder" },
            @{ Name = "Bing Finance"; Package = "Microsoft.BingFinance" },
            @{ Name = "Bing Sports"; Package = "Microsoft.BingSports" },
            @{ Name = "Bing Weather"; Package = "Microsoft.BingWeather" },
            @{ Name = "Bing Travel"; Package = "Microsoft.BingTravel" },
            @{ Name = "Bing Health And Fitness"; Package = "Microsoft.BingHealthAndFitness" },
            @{ Name = "Bing Food And Drink"; Package = "Microsoft.BingFoodAndDrink" },
            @{ Name = "Clipchamp"; Package = "Clipchamp.Clipchamp" },
            @{ Name = "Office OneNote"; Package = "Microsoft.Office.OneNote" },
            @{ Name = "Office Sway"; Package = "Microsoft.Office.Sway" },
            @{ Name = "People"; Package = "Microsoft.People" },
            @{ Name = "Skype"; Package = "Microsoft.SkypeApp" },
            @{ Name = "Alarms And Clock"; Package = "Microsoft.WindowsAlarms" },
            @{ Name = "Maps"; Package = "Microsoft.WindowsMaps" },
            @{ Name = "Windows Phone"; Package = "Microsoft.WindowsPhone" },
            @{ Name = "Sound Recorder"; Package = "Microsoft.WindowsSoundRecorder" },
            @{ Name = "Groove Music"; Package = "Microsoft.ZuneMusic" },
            @{ Name = "Movies And TV"; Package = "Microsoft.ZuneVideo" },
            @{ Name = "App Connector"; Package = "Microsoft.AppConnector" },
            @{ Name = "Connectivity Store"; Package = "Microsoft.ConnectivityStore" },
            @{ Name = "Messaging"; Package = "Microsoft.Messaging" },
            @{ Name = "Comms Phone"; Package = "Microsoft.CommsPhone" },
            @{ Name = "OneConnect"; Package = "Microsoft.OneConnect" },
            @{ Name = "Network Speed Test"; Package = "Microsoft.NetworkSpeedTest" },
            @{ Name = "3D Viewer"; Package = "Microsoft.Microsoft3DViewer" },
            @{ Name = "Print 3D"; Package = "Microsoft.Print3D" },
            @{ Name = "Music Preview"; Package = "Microsoft.Music.Preview" },
            @{ Name = "Mixed Reality Portal"; Package = "Microsoft.MixedReality.Portal" },
            @{ Name = "Quick Assist"; Package = "MicrosoftCorporationII.QuickAssist" },
            @{ Name = "Solitaire"; Package = "Microsoft.MicrosoftSolitaireCollection" },
            @{ Name = "Xbox"; Package = "Microsoft.GamingApp" },
            @{ Name = "Xbox (Legacy)"; Package = "Microsoft.XboxApp" },
            @{ Name = "Xbox Live"; Package = "Microsoft.Xbox.TCUI" },
            @{ Name = "Xbox Gaming Overlay"; Package = "Microsoft.XboxGamingOverlay" },
            @{ Name = "Xbox Identity Provider"; Package = "Microsoft.XboxIdentityProvider" },
            @{ Name = "Xbox Speech To Text"; Package = "Microsoft.XboxSpeechToTextOverlay" },
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

        # Dedupe so the same package is not attempted twice
        $appxList = $appxList | Group-Object { $_.Package } | ForEach-Object { $_.Group[0] }

        foreach ($app in $appxList) { 
            uninstallAppXApp -PackageName $app.Package -FriendlyName $app.Name 
        }
    } catch {
        $script:errors += "$($MyInvocation.MyCommand.Name)-$($_.InvocationInfo.ScriptLineNumber):$($_.Exception.Message)"
        writeText -type "error" -text "$($MyInvocation.MyCommand.Name)-$($_.InvocationInfo.ScriptLineNumber)"
        log -msg "$($MyInvocation.MyCommand.Name)-$($_.InvocationInfo.ScriptLineNumber):$($_.Exception.Message)" -lvl "ERROR"
    }
}
function declutter {
    try {
        writeText -type "header" -text "Decluttering" -lineBefore
        disableBingSearch
        disableTaskbarWidgets
        removeTaskbarPins
    } catch {
        $script:errors += "$($MyInvocation.MyCommand.Name)-$($_.InvocationInfo.ScriptLineNumber):$($_.Exception.Message)"
        writeText -type "error" -text "$($MyInvocation.MyCommand.Name)-$($_.InvocationInfo.ScriptLineNumber)"
        log -msg "$($MyInvocation.MyCommand.Name)-$($_.InvocationInfo.ScriptLineNumber):$($_.Exception.Message)" -lvl "ERROR"
    }
    
}
function optimize {
    try {
        writeText -type "header" -text "Optimizing"
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
        disableRemoteDesktop
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
        disableGameModeAndGameBar
        disableSearchAppInStore 
    } catch {
        $script:errors += "$($MyInvocation.MyCommand.Name)-$($_.InvocationInfo.ScriptLineNumber):$($_.Exception.Message)"
        writeText -type "error" -text "$($MyInvocation.MyCommand.Name)-$($_.InvocationInfo.ScriptLineNumber)"
        log -msg "$($MyInvocation.MyCommand.Name)-$($_.InvocationInfo.ScriptLineNumber):$($_.Exception.Message)" -lvl "ERROR"
    }
}
function installApps {
    param (
        [Parameter(Mandatory = $true)][string]$computerType
    )

    writeText -type "header" -text "Installing Applications" -lineBefore

    $winget = getWingetPath

    if (-not $winget) {
        WriteText -Type "plain" -Text "winget not found. Installing winget..."

        try {
            Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted -ErrorAction Stop | Out-Null
            Install-Script -Name winget-install -Force -ErrorAction Stop | Out-Null
        } catch {
            writeText -Type "error" -text "Failed to install winget-install script: $($_.Exception.Message)"
            return
        }

        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
        [System.Environment]::GetEnvironmentVariable("Path", "User")

        winget-install -Force 2>&1 | Out-Null

        $winget = getWingetPath
        if (-not $winget) {
            writeText -Type "error" -text "winget installation failed. Please install winget manually from https://github.com/microsoft/winget-cli"
            return
        }

        WriteText -Type "success" -Text "winget installed successfully."
    }

    writeText -type "plain" -text "Winget found:"
    writeText -type "plain" -text "$winget"

    function getWingetInstallerUrl {
        param(
            [string]$Id
        )

        $output = & $winget show --id $Id --exact --accept-source-agreements --disable-interactivity 2>&1
        $match = $output | Select-String "Installer Url:\s*(\S+)" | Select-Object -First 1

        if (-not $match) {
            return $null
        }

        return $match.Matches[0].Groups[1].Value
    }

    $sonosUrl = getWingetInstallerUrl -Id "Sonos.Controller"
    $adobeUrl = getWingetInstallerUrl -Id "Adobe.Acrobat.Reader.64-bit"
    $googleChromeUrl = getWingetInstallerUrl -Id "Google.Chrome"
    $cliqUrl = getWingetInstallerUrl -Id "Zoho.Cliq"
    $dropboxUrl = getWingetInstallerUrl -Id "Dropbox.Dropbox"

    $appsToInstall = @(
        @{ Url = $adobeUrl; Name = "Adobe Acrobat"; Params = "/sAll /rs /msi EULA_ACCEPT=YES ALLUSERS=1" }
        @{ Url = $googleChromeUrl; Name = "Google Chrome"; Params = "/qn /norestart" }
        @{ Url = $cliqUrl; Name = "Cliq"; Params = "/qn /norestart" }
        @{ Url = $dropboxUrl; Name = "Dropbox"; Params = "/qn /norestart" }
    )

    if ($computerType -in @("FD1", "FD2", "FD3", "OM")) {
        $appsToInstall += @{ Url = $sonosUrl; Name = "Sonos"; Params = "/S /v/qn" }
    }

    foreach ($app in $appsToInstall) {
        if (-not $app.Url) {
            writeText -Type "error" -text "Could not resolve installer URL for $($app.Name). Skipping."
            continue
        }
        installApp -url $app.Url -appName $app.Name -params $app.Params
    }

    pinAppsToTaskbar

    #Install-NinjaOne  -InstallerUrl $NinjaInstallerUrl
}
function normalizeEnvironment {
    param (
        [Parameter(Mandatory = $true)]
        [string]$location,
        [Parameter(Mandatory = $true)]
        [string]$locationType,
        [Parameter(Mandatory = $true)]
        [string]$computerType
    )

    try {
        if ($locationType -notin @("OTHER", "LAB")) {
            editHostname -location $location -locationType $locationType -computerType $computerType
        }

        getBGInfo
    } catch {
        $script:errors += "$($MyInvocation.MyCommand.Name)-$($_.InvocationInfo.ScriptLineNumber):$($_.Exception.Message)"
        writeText -type "error" -text "$($MyInvocation.MyCommand.Name)-$($_.InvocationInfo.ScriptLineNumber)"
        log -msg "$($MyInvocation.MyCommand.Name)-$($_.InvocationInfo.ScriptLineNumber):$($_.Exception.Message)" -lvl "ERROR"
    }
   
}
function writeSummary {
    writeText -type "header" -text "Summary"
    writeText -type "plain" -text "Computer     : $env:COMPUTERNAME"
    writeText -type "plain" -text "started      : $script:scriptStarted"
    writeText -type "plain" -text "completed    : $(Get-Date)"
    writeText -type "plain" -text "Log          : $script:logPath"
    writeText -type "list" -list $script:errors
}



# --- Helpers ------------------------------------------------
function uninstallOneDrive {
    try {
        writeText -type "plain" -text "Searching for OneDrive" -lineBefore

        $onedriveInstalled = $false
        $onedriveProcess = Get-Process -Name "OneDrive" -ErrorAction SilentlyContinue

        $users = getUserProfiles | Where-Object { $_.Name -ne 'Default' }

        foreach ($u in $users) {
            $odBase = "$($u.Path)\AppData\Local\Microsoft\OneDrive"
            if (Test-Path $odBase) {
                $onedriveExe = Get-ChildItem $odBase -Filter "OneDrive.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
                if ($onedriveExe) {
                    $onedriveInstalled = $true
                    writeText -type "plain" -text "Found OneDrive installation for user: $($u.Name)"
                    break
                }
            }
        }

        if (-not $onedriveInstalled) {
            $regPaths = @(
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
            return
        }

        if ($onedriveProcess) {
            writeText -type "plain" -text "Stopping OneDrive processes"
            $onedriveProcess | Stop-Process -Force
            Start-Sleep -Seconds 3
        } else {
            writeText -type "plain" -text "OneDrive is not running, skipping process termination"
        }

        $uninstalled = $false

        foreach ($u in $users) {
            $odBase = "$($u.Path)\AppData\Local\Microsoft\OneDrive"
            if (-not (Test-Path $odBase)) { 
                writeText -type "plain" -text "No OneDrive folder found for user: $($u.Name)"
                continue 
            }

            $odSetupExe = Get-ChildItem $odBase -Filter "OneDriveSetup.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
            if (-not $odSetupExe) {
                writeText -type "plain" -text "No OneDriveSetup.exe found for user: $($u.Name)"
                continue
            }

            writeText -type "plain" -text "Processing OneDrive for user: $($u.Name)"

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

            $safeName = $u.Name -replace '[^a-zA-Z0-9]', '_'
            $taskName = "NuviaODRemove_$safeName"

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

        writeText -type "plain" -text "Cleaning up OneDrive folders and registry entries"

        # Machine-wide paths, then per-profile paths. The old version used
        # $env:LOCALAPPDATA and $env:USERPROFILE, which under SYSTEM resolved to
        # the systemprofile and Default folders instead of real users.
        $oneDrivePaths = @(
            "$env:SystemDrive\Microsoft OneDrive",
            "$env:SYSTEMDRIVE\OneDriveTemp"
        )
        foreach ($u in (getUserProfiles)) {
            $oneDrivePaths += "$($u.Path)\AppData\Local\Microsoft\OneDrive"
            $oneDrivePaths += "$($u.Path)\OneDrive"
        }

        $removedCount = 0
        foreach ($folder in $oneDrivePaths) {
            if (Test-Path $folder) { 
                writeText -type "plain" -text "Removing folder: $folder"
                Remove-Item -Path $folder -Recurse -Force -ErrorAction SilentlyContinue
                if (-not (Test-Path $folder)) { $removedCount++ }
            }
        }
        writeText -type "plain" -text "Removed $removedCount OneDrive folders"

        if (-not (Get-PSDrive -Name HKCR -ErrorAction SilentlyContinue)) {
            New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT -Scope Global | Out-Null
        }

        $machineRegPaths = @(
            "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}",
            "HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}",
            "HKLM:\SOFTWARE\Microsoft\OneDrive",
            "HKLM:\SOFTWARE\WOW6432Node\Microsoft\OneDrive"
        )

        $regRemovedCount = 0
        foreach ($regPath in $machineRegPaths) {
            if (Test-Path $regPath) {
                writeText -type "plain" -text "Removing registry entry: $regPath"
                Remove-Item -Path $regPath -Recurse -Force -ErrorAction SilentlyContinue
                if (-not (Test-Path $regPath)) { $regRemovedCount++ }
            }
        }

        # Per-user OneDrive key
        invokeForEachUserHive {
            param($root, $user)
            $p = "$root\Software\Microsoft\OneDrive"
            if (Test-Path $p) {
                Remove-Item -Path $p -Recurse -Force -ErrorAction SilentlyContinue
                writeText -type "plain" -text "Removed OneDrive registry key for user: $user"
            }
        }

        writeText -type "plain" -text "Removed $regRemovedCount machine registry entries"

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

        foreach ($prof in (getUserProfiles)) {
            $teamsPath = "$($prof.Path)\AppData\Local\Microsoft\Teams\Update.exe"
            if (Test-Path $teamsPath) {
                try {
                    Start-Process -FilePath $teamsPath -ArgumentList "--uninstall /s" -Wait -WindowStyle Hidden
                    writeText -type "plain" -text "Teams Classic uninstalled for $($prof.Name)."
                } catch {
                    writeText -type "error" -text "$($MyInvocation.MyCommand.Name)-$($_.InvocationInfo.ScriptLineNumber)"
                    log -msg "$($MyInvocation.MyCommand.Name)-$($_.InvocationInfo.ScriptLineNumber):$($_.Exception.Message)" -lvl "ERROR"
                }
            }
            foreach ($folder in @(
                    "$($prof.Path)\AppData\Local\Microsoft\Teams",
                    "$($prof.Path)\AppData\Roaming\Microsoft\Teams"
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
function disableBingSearch {
    try {
        writeText -type "plain" -text "Disabling Bing Search in Start Menu" -lineBefore

        invokeForEachUserHive {
            param($root, $user)
            $bingPath = "$root\SOFTWARE\Microsoft\Windows\CurrentVersion\Search"
            setRegValue -Path $bingPath -Name "BingSearchEnabled" -Value 0
            setRegValue -Path $bingPath -Name "CortanaConsent"    -Value 0
        }

        $policyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
        setRegValue -Path $policyPath -Name "DisableWebSearch"      -Value 1
        setRegValue -Path $policyPath -Name "ConnectedSearchUseWeb" -Value 0

        writeText -type "success" -text "Bing search disabled."
    } catch {
        writeText -type "error" -text "$($MyInvocation.MyCommand.Name)-$($_.InvocationInfo.ScriptLineNumber)"
        log -msg "$($MyInvocation.MyCommand.Name)-$($_.InvocationInfo.ScriptLineNumber):$($_.Exception.Message)" -lvl "ERROR"
    }
}
function disableTaskbarWidgets {
    try {
        writeText -type "plain" -text "Disabling Taskbar Widgets" -lineBefore

        setRegValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" -Name "AllowNewsAndInterests" -Value 0
        setRegValue -Path "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\NewsAndInterests\AllowNewsAndInterests" -Name "value" -Value 0

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

        # The Shell.Application "Unpin from taskbar" verb only works inside an
        # interactive desktop session. Under SYSTEM it silently enumerates nothing,
        # so skip it there and rely on the per-profile LayoutModification.xml
        # written by pinAppsToTaskbar (PinListPlacement="Replace" clears the rest).
        if (isSystemContext) {
            writeText -type "plain" -text "SYSTEM context - skipping shell verb unpin, using layout XML instead."
        } else {
            $shell = New-Object -Com Shell.Application
            $taskbarItems = $shell.NameSpace('shell:::{4234d49b-0245-4df3-b780-3893943456e1}').Items()

            foreach ($item in $taskbarItems) {
                $shouldUnpin = $false
                foreach ($appName in $appsToUnpin) {
                    if ($item.Name -like "*$appName*") { $shouldUnpin = $true; break }
                }
                if ($shouldUnpin) {
                    try {
                        $unpinVerb = $item.Verbs() | Where-Object { $_.Name -match "Unpin from taskbar" }
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
        }

        # Remove the pinned .lnk files from every profile, not just $env:APPDATA
        foreach ($prof in (getUserProfiles)) {
            $taskbarPinPath = "$($prof.Path)\AppData\Roaming\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar"
            if (-not (Test-Path $taskbarPinPath)) { continue }

            Get-ChildItem $taskbarPinPath -Filter "*.lnk" -ErrorAction SilentlyContinue |
            ForEach-Object {
                $shouldRemove = $false
                foreach ($appName in $appsToUnpin) {
                    if ($_.Name -match [regex]::Escape($appName)) { $shouldRemove = $true; break }
                }
                if ($shouldRemove) {
                    Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue
                    writeText -type "plain" -text "Removed shortcut for $($prof.Name): $($_.Name)"
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
    setRegValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name "AllowTelemetry" -Value 0
    setRegValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0
    setRegValue -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name "AllowTelemetry" -Value 0
    # Disable-ScheduledTask -TaskName "Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" | Out-Null
    # Disable-ScheduledTask -TaskName "Microsoft\Windows\Application Experience\ProgramDataUpdater" | Out-Null
    foreach ($t in @(
            "Microsoft\Windows\Autochk\Proxy",
            "Microsoft\Windows\Customer Experience Improvement Program\Consolidator",
            "Microsoft\Windows\Customer Experience Improvement Program\UsbCeip",
            "Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector"
        )) {
        Disable-ScheduledTask -TaskName $t -ErrorAction SilentlyContinue | Out-Null
    }
}
function disableWiFiSense {
    writeText -type "plain" -text "Disabling Wi-Fi Sense..."
    setRegValue -Path "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting" -Name "Value" -Value 0
    setRegValue -Path "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots" -Name "Value" -Value 0
    setRegValue -Path "HKLM:\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\config" -Name "AutoConnectAllowedOEM" -Value 0
    setRegValue -Path "HKLM:\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\config" -Name "WiFISenseAllowed" -Value 0
}
function disableAppSuggestions {
    writeText -type "plain" -text "Disabling Application suggestions..."

    invokeForEachUserHive {
        param($root, $user)
        $cdm = "$root\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
        foreach ($v in @(
                'ContentDeliveryAllowed', 'OemPreInstalledAppsEnabled', 'PreInstalledAppsEnabled',
                'PreInstalledAppsEverEnabled', 'SilentInstalledAppsEnabled',
                'SubscribedContent-338389Enabled', 'SystemPaneSuggestionsEnabled',
                'SubscribedContent-338388Enabled'
            )) {
            setRegValue -Path $cdm -Name $v -Value 0
        }
    }

    setRegValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsConsumerFeatures" -Value 1
}
function disableLockScreenSpotlight {
    writeText -type "plain" -text "Disabling Lock screen spotlight..."
    invokeForEachUserHive {
        param($root, $user)
        $cdm = "$root\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
        setRegValue -Path $cdm -Name "RotatingLockScreenEnabled"        -Value 0
        setRegValue -Path $cdm -Name "RotatingLockScreenOverlayEnabled" -Value 0
        setRegValue -Path $cdm -Name "SubscribedContent-338387Enabled"  -Value 0
    }
}
function disableFeedback {
    writeText -type "plain" -text "Disabling Feedback..."
    invokeForEachUserHive {
        param($root, $user)
        setRegValue -Path "$root\SOFTWARE\Microsoft\Siuf\Rules" -Name "NumberOfSIUFInPeriod" -Value 0
    }
    Disable-ScheduledTask -TaskName "Microsoft\Windows\Feedback\Siuf\DmClient" -ErrorAction SilentlyContinue | Out-Null
    Disable-ScheduledTask -TaskName "Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload" -ErrorAction SilentlyContinue | Out-Null
}
function disableAdvertisingID {
    writeText -type "plain" -text "Disabling Advertising ID..."
    invokeForEachUserHive {
        param($root, $user)
        setRegValue -Path "$root\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Value 0
        setRegValue -Path "$root\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy" -Name "TailoredExperiencesWithDiagnosticDataEnabled" -Value 0
    }
}
function disableCortana {
    writeText -type "plain" -text "Disabling Cortana..."
    invokeForEachUserHive {
        param($root, $user)
        setRegValue -Path "$root\SOFTWARE\Microsoft\Personalization\Settings" -Name "AcceptedPrivacyPolicy" -Value 0
        setRegValue -Path "$root\SOFTWARE\Microsoft\InputPersonalization" -Name "RestrictImplicitTextCollection" -Value 1
        setRegValue -Path "$root\SOFTWARE\Microsoft\InputPersonalization" -Name "RestrictImplicitInkCollection" -Value 1
        setRegValue -Path "$root\SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore" -Name "HarvestContacts" -Value 0
    }
    setRegValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana" -Value 0
}
function enableErrorReporting {
    writeText -type "plain" -text "Enabling Error reporting..."
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting" -Name "Disabled" -ErrorAction SilentlyContinue
    Enable-ScheduledTask -TaskName "Microsoft\Windows\Windows Error Reporting\QueueReporting" -ErrorAction SilentlyContinue | Out-Null
}
function disableAutoLogger {
    writeText -type "plain" -text "Removing AutoLogger file and restricting directory..."
    $autoLoggerDir = "$env:SystemDrive\Microsoft\Diagnosis\ETLLogs\AutoLogger"
    if (Test-Path "$autoLoggerDir\AutoLogger-Diagtrack-Listener.etl") {
        Remove-Item -Path "$autoLoggerDir\AutoLogger-Diagtrack-Listener.etl" -Force -ErrorAction SilentlyContinue
    }
    if (Test-Path $autoLoggerDir) {
        icacls $autoLoggerDir /deny SYSTEM:`(OI`)`(CI`)F | Out-Null
    }
}
function disableDiagTrack {
    writeText -type "plain" -text "Stopping and disabling Diagnostics Tracking Service..."
    Stop-Service "DiagTrack" -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
    Set-Service "DiagTrack" -StartupType Disabled -ErrorAction SilentlyContinue
}
function disableWAPPush {
    writeText -type "plain" -text "Stopping and disabling WAP Push Service..."
    Stop-Service "dmwappushservice" -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
    Set-Service "dmwappushservice" -StartupType Disabled -ErrorAction SilentlyContinue
}
function disableSMB1 {
    writeText -type "plain" -text "Disabling SMB 1.0 protocol..."
    Set-SmbServerConfiguration -EnableSMB1Protocol $false -Force
}
function setCurrentNetworkPrivate {
    writeText -type "plain" -text "Setting current network profile to private..."
    try {
        Get-NetConnectionProfile -ErrorAction Stop |
        Set-NetConnectionProfile -NetworkCategory Private -ErrorAction Stop
    } catch {
        writeText -type "notice" -text "Could not set network profile to private: $($_.Exception.Message)"
    }
}
function disableUpdateRestart {
    writeText -type "plain" -text "Disabling Windows Update automatic restart..."
    $au = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
    setRegValue -Path $au -Name "NoAutoRebootWithLoggedOnUsers" -Value 1
    setRegValue -Path $au -Name "AUPowerManagement" -Value 0
}
function disableRemoteAssistance {
    writeText -type "plain" -text "Disabling Remote Assistance..."
    setRegValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Remote Assistance" -Name "fAllowToGetHelp" -Value 0
}
function disableRemoteDesktop {
    writeText -type "plain" -text "Disabling Remote Desktop..."
    setRegValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 1
    setRegValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "UserAuthentication" -Value 1
}
function disableAutoplay {
    writeText -type "plain" -text "Disabling Autoplay..."
    invokeForEachUserHive {
        param($root, $user)
        setRegValue -Path "$root\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers" -Name "DisableAutoplay" -Value 1
    }
}
function disableAutorun {
    writeText -type "plain" -text "Disabling Autorun for all drives..."
    setRegValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "NoDriveTypeAutoRun" -Value 255
}
function disableHibernation {
    writeText -type "plain" -text "Disabling Hibernation..."
    # powercfg is the reliable way; the registry value alone does not release
    # hiberfil.sys. (The old value name "HibernteEnabled" was also a typo.)
    & powercfg.exe /hibernate off 2>&1 | Out-Null
    setRegValue -Path "HKLM:\System\CurrentControlSet\Control\Session Manager\Power" -Name "HibernateEnabled" -Value 0
    setRegValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings" -Name "ShowHibernateOption" -Value 0
}
function showShutdownOnLockScreen {
    writeText -type "plain" -text "Showing shutdown options on Lock Screen..."
    setRegValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ShutdownWithoutLogon" -Value 1
}
function disableStickyKeys {
    writeText -type "plain" -text "Disabling Sticky keys prompt..."
    invokeForEachUserHive {
        param($root, $user)
        # Control Panel hangs off the hive root - no SOFTWARE prefix
        setRegValue -Path "$root\Control Panel\Accessibility\StickyKeys" -Name "Flags" -Value "506" -Type String
    }
}
function showFileOperationsDetails {
    writeText -type "plain" -text "Showing file operations details..."
    invokeForEachUserHive {
        param($root, $user)
        setRegValue -Path "$root\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\OperationStatusManager" -Name "EnthusiastMode" -Value 1
    }
}
function hideTaskbarSearchBox {
    writeText -type "plain" -text "Hiding Taskbar Search box / button..."
    invokeForEachUserHive {
        param($root, $user)
        setRegValue -Path "$root\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -Value 0
    }
}
function hideTaskView {
    writeText -type "plain" -text "Hiding Task View button..."
    invokeForEachUserHive {
        param($root, $user)
        setRegValue -Path "$root\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton" -Value 0
    }
}
function hideTaskbarPeopleIcon {
    writeText -type "plain" -text "Hiding People icon..."
    invokeForEachUserHive {
        param($root, $user)
        setRegValue -Path "$root\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People" -Name "PeopleBand" -Value 0
    }
}
function showTrayIcons {
    writeText -type "plain" -text "Showing all tray icons..."
    invokeForEachUserHive {
        param($root, $user)
        setRegValue -Path "$root\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" -Name "EnableAutoTray" -Value 0
    }
}
function showThisPCOnDesktop {
    writeText -type "plain" -text "Showing This PC shortcut on desktop..."
    invokeForEachUserHive {
        param($root, $user)
        $clsid = "{20D04FE0-3AEA-1069-A2D8-08002B30309D}"
        setRegValue -Path "$root\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\ClassicStartMenu" -Name $clsid -Value 0
        setRegValue -Path "$root\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" -Name $clsid -Value 0
    }
}
function showDesktopInThisPC {
    writeText -type "plain" -text "Showing Desktop icon in This PC..."
    $p = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{B4BFCC3A-DB2C-424C-B029-7FE99A87C641}"
    if (!(Test-Path $p)) { New-Item -Path $p -Force | Out-Null }
}
function showDesktopInExplorer {
    writeText -type "plain" -text "Showing Desktop icon in Explorer namespace..."
    setRegValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\{B4BFCC3A-DB2C-424C-B029-7FE99A87C641}\PropertyBag" -Name "ThisPCPolicy" -Value "Show" -Type String
    setRegValue -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\{B4BFCC3A-DB2C-424C-B029-7FE99A87C641}\PropertyBag" -Name "ThisPCPolicy" -Value "Show" -Type String
}
function showDocumentsInThisPC {
    writeText -type "plain" -text "Showing Documents icon in This PC..."
    foreach ($guid in @("{d3162b92-9365-467a-956b-92703aca08af}", "{A8CDFF1C-4878-43be-B5FD-F8091C1C60D0}")) {
        $p = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\$guid"
        if (!(Test-Path $p)) { New-Item -Path $p -Force | Out-Null }
    }
}
function showDocumentsInExplorer {
    writeText -type "plain" -text "Showing Documents icon in Explorer namespace..."
    setRegValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\{f42ee2d3-909f-4907-8871-4c22fc0bf756}\PropertyBag" -Name "ThisPCPolicy" -Value "Show" -Type String
    setRegValue -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\{f42ee2d3-909f-4907-8871-4c22fc0bf756}\PropertyBag" -Name "ThisPCPolicy" -Value "Show" -Type String
}
function showDownloadsInThisPC {
    writeText -type "plain" -text "Showing Downloads icon in This PC..."
    foreach ($guid in @("{088e3905-0323-4b02-9826-5d99428e115f}", "{374DE290-123F-4565-9164-39C4925E467B}")) {
        $p = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\$guid"
        if (!(Test-Path $p)) { New-Item -Path $p -Force | Out-Null }
    }
}
function showDownloadsInExplorer {
    writeText -type "plain" -text "Showing Downloads icon in Explorer namespace..."
    setRegValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\{7d83ee9b-2244-4e70-b1f5-5393042af1e4}\PropertyBag" -Name "ThisPCPolicy" -Value "Show" -Type String
    setRegValue -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\{7d83ee9b-2244-4e70-b1f5-5393042af1e4}\PropertyBag" -Name "ThisPCPolicy" -Value "Show" -Type String
}
function disableXboxFeatures {
    writeText -type "plain" -text "Disabling Xbox features..."
    invokeForEachUserHive {
        param($root, $user)
        setRegValue -Path "$root\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 0
    }
    setRegValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" -Name "AllowGameDVR" -Value 0
}
function disableGameModeAndGameBar {
    writeText -type "plain" -text "Disabling Game Mode and Game Bar..."

    invokeForEachUserHive {
        param($root, $user)

        # Game Mode
        $gameBar = "$root\SOFTWARE\Microsoft\GameBar"
        setRegValue -Path $gameBar -Name "AllowAutoGameMode"        -Value 0
        setRegValue -Path $gameBar -Name "AutoGameModeEnabled"      -Value 0
        setRegValue -Path $gameBar -Name "UseNexusForGameBarEnabled" -Value 0
        setRegValue -Path $gameBar -Name "ShowStartupPanel"         -Value 0
        setRegValue -Path $gameBar -Name "GamePanelStartupTipIndex" -Value 3

        # Game Bar hotkeys and the "open Game Bar?" prompt
        $gcs = "$root\System\GameConfigStore"
        setRegValue -Path $gcs -Name "GameDVR_Enabled"                       -Value 0
        setRegValue -Path $gcs -Name "GameDVR_FSEBehaviorMode"               -Value 2
        setRegValue -Path $gcs -Name "GameDVR_HonorUserFSEBehaviorMode"      -Value 1
        setRegValue -Path $gcs -Name "GameDVR_DXGIHonorFSEWindowsCompatible" -Value 1
        setRegValue -Path $gcs -Name "GameDVR_EFSEFeatureFlags"              -Value 0

        # Background recording
        setRegValue -Path "$root\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" `
            -Name "AppCaptureEnabled" -Value 0
    }

    # Machine-wide policy - blocks Game DVR regardless of per-user settings
    setRegValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" `
        -Name "AllowGameDVR" -Value 0
}
function disableSearchAppInStore {
    writeText -type "plain" -text "Disabling search for app in store for unknown extensions..."
    setRegValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name "NoUseStoreOpenWith" -Value 1
}
function pinAppsToTaskbar {
    try {
        $chromeExe = "C:\Program Files\Google\Chrome\Application\chrome.exe"
        if (-not (Test-Path $chromeExe)) {
            writeText -type "notice" -text "Chrome not found at expected path - pin may not work"
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

        # Write to every profile, not $env:LOCALAPPDATA (= systemprofile under SYSTEM)
        $written = 0
        foreach ($prof in (getUserProfiles)) {
            $shellDir = "$($prof.Path)\AppData\Local\Microsoft\Windows\Shell"
            if (-not (Test-Path $shellDir)) {
                New-Item -Path $shellDir -ItemType Directory -Force | Out-Null
            }
            $layoutXml | Out-File -FilePath (Join-Path $shellDir 'LayoutModification.xml') -Encoding UTF8 -Force
            $written++
        }

        writeText -type "success" -text "Taskbar layout written for $written profile(s)."
    } catch {
        writeText -type "error" -text "$($MyInvocation.MyCommand.Name)-$($_.InvocationInfo.ScriptLineNumber)"
        log -msg "$($MyInvocation.MyCommand.Name)-$($_.InvocationInfo.ScriptLineNumber):$($_.Exception.Message)" -lvl "ERROR"
    }
}
function editHostname {
    param (
        [Parameter(Mandatory = $true)][string]$location,
        [Parameter(Mandatory = $true)][string]$locationType,
        [Parameter(Mandatory = $true)][string]$computerType
    )

    try {
        writeText -type "header" -text "Editing Hostname" -lineBefore

        $currentHostname = $env:COMPUTERNAME
        writeText -type "plain" -text "Current Hostname: $currentHostname"

        $hostname = "$($location)-$($locationType)-$($computerType)"
        writeText -type "plain" -text "New Hostname:     $hostname"

        if ($hostname -eq "") { 
            $hostname = $currentHostname 
        } 

        if ($hostname -ne "") {
            Remove-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -name "Hostname" -ErrorAction SilentlyContinue
            Remove-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -name "NV Hostname" -ErrorAction SilentlyContinue
            Set-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Control\Computername\Computername" -name "Computername" -value $hostname
            Set-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Control\Computername\ActiveComputername" -name "Computername" -value $hostname
            Set-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -name "Hostname" -value $hostname
            Set-ItemProperty -path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -name "NV Hostname" -value  $hostname
            Set-ItemProperty -path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -name "AltDefaultDomainName" -value $hostname
            Set-ItemProperty -path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -name "DefaultDomainName" -value $hostname
            $env:COMPUTERNAME = $hostname
        } 

        $hostnameChanged = $currentHostname -ne $env:COMPUTERNAME

        if ($hostnameChanged) {
            writeText -type "success" -text "Hostname changed."
        } else {
            writeText -type "success" -text "Hostname unchanged."
        }

        $choice = readOption -options $([ordered]@{
                "Yes" = "Change the description of the PC."
                "No"  = "Do not change the description of the PC."
            }) -prompt "Do you also want to change the description for the target PC?" -lineAfter

        switch ($choice) {
            0 { editDescription }
            1 { readCommand }
        }
    } catch {
        writeText -type "error" -text "$($MyInvocation.MyCommand.Name)-$($_.InvocationInfo.ScriptLineNumber)"
        log -msg "$($MyInvocation.MyCommand.Name)-$($_.InvocationInfo.ScriptLineNumber):$($_.Exception.Message)" -lvl "ERROR"
    }
}
function getBGInfo {
    try {
        writeText -type "header" -text "Adding Nuvia Background" -lineBefore

        $url = "https://drive.google.com/uc?export=download&id=1XAP5hAgu3k9067NvoZb2YU6TiPr9I68H"

        # Set the wallpaper properties
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name WallPaper -Value "" 
        Set-ItemProperty -Path "HKCU:\Control Panel\Colors" -Name Background -Value "0 0 0" 

        $download = getDownload -url $url -target "$env:SystemDrive\Nuvia\temp\BGInfo.zip"

        if ($download -eq $true) { 
            Expand-Archive -LiteralPath "$env:SystemDrive\Nuvia\temp\BGInfo.zip" -DestinationPath "$env:SystemDrive\Nuvia\temp\"

            # Test if the extracted folder exists
            if (Test-Path "$env:SystemDrive\Nuvia\temp\BGInfo") {
                writeText -type "plain" -text "BGInfo unpacked."
            } else {
                writeText -type "error" -text "Failed to unpack BGInfo."
            }

            ROBOCOPY "$env:SystemDrive\Nuvia\temp\BGInfo" "$env:SystemDrive\Nuvia\tools\BGInfo" /E /NFL /NDL /NJH /NJS /nc /ns | Out-Null
            ROBOCOPY "$env:SystemDrive\Nuvia\temp\BGInfo" "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup" "Start BGInfo.bat" /NFL /NDL /NJH /NJS /nc /ns | Out-Null

            if (Test-Path "$env:SystemDrive\Nuvia\tools\BGInfo") {
                writeText -type "plain" -text "BGInfo installed."
            } else {
                writeText -type "error" -text "Failed to install BGInfo."
            }

            Remove-Item -Path "$env:SystemDrive\Nuvia\temp\BGInfo.zip" -Recurse
            Remove-Item -Path "$env:SystemDrive\Nuvia\temp\BGInfo" -Recurse 

            $filesDeleted = $true
            if (Test-Path "$env:SystemDrive\Nuvia\temp\BGInfo.zip") { 
                $filesDeleted = $false 
            }
            if (Test-Path "$env:SystemDrive\Nuvia\temp\BGInfo") { 
                $filesDeleted = $false 
            } 
            if (!$filesDeleted) {
                writeText -type "error" -text "Some temp files were not deleted. This is harmless."
            }

            Start-Process -FilePath "cmd.exe" `
                -ArgumentList '/c ""C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\Start BGInfo.bat""' `
                -WorkingDirectory "$env:SystemDrive\Nuvia\tools\BGInfo" `
                -WindowStyle Hidden

            writeText -type "success" -text "BGInfo installed and should be applied."
        }
    } catch {
        writeText -type "error" -text "$($MyInvocation.MyCommand.Name)-$($_.InvocationInfo.ScriptLineNumber)"
        log -msg "$($MyInvocation.MyCommand.Name)-$($_.InvocationInfo.ScriptLineNumber):$($_.Exception.Message)" -lvl "ERROR"
    }
}

# --- SYSTEM-context helpers ------------------------------------------------
function isSystemContext {
    return ([Security.Principal.WindowsIdentity]::GetCurrent()).User.Value -eq 'S-1-5-18'
}

# Creates the full key path before writing. New-Item WITHOUT -Force fails when
# the parent key is missing, which is what broke ...\Explorer\Advanced\People.
function setRegValue {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)]$Value,
        [ValidateSet('String', 'ExpandString', 'Binary', 'DWord', 'MultiString', 'QWord')]
        [string]$Type = 'DWord'
    )
    try {
        if (-not (Test-Path -LiteralPath $Path)) {
            New-Item -Path $Path -Force -ErrorAction Stop | Out-Null
        }
        New-ItemProperty -LiteralPath $Path -Name $Name -Value $Value `
            -PropertyType $Type -Force -ErrorAction Stop | Out-Null
    } catch {
        writeText -type "error" -text "setRegValue failed: $Path\$Name - $($_.Exception.Message)"
    }
}

# Returns every real user profile directory, plus Default so future users
# inherit whatever we do. Use this instead of $env:USERPROFILE / $env:LOCALAPPDATA,
# which point at C:\Windows\system32\config\systemprofile under SYSTEM.
function getUserProfiles {
    $out = @()

    $defaultDir = Join-Path $env:SystemDrive 'Users\Default'
    if (Test-Path $defaultDir) {
        $out += [pscustomobject]@{ Name = 'Default'; Path = $defaultDir; Sid = $null }
    }

    $profileList = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList'
    Get-ChildItem $profileList -ErrorAction SilentlyContinue |
    Where-Object { $_.PSChildName -match '^S-1-5-21-' } |
    ForEach-Object {
        $img = (Get-ItemProperty $_.PSPath -Name ProfileImagePath -ErrorAction SilentlyContinue).ProfileImagePath
        if ($img -and (Test-Path $img)) {
            $out += [pscustomobject]@{
                Name = (Split-Path $img -Leaf)
                Path = $img
                Sid  = $_.PSChildName
            }
        }
    }

    return $out
}

# Runs a scriptblock once per user hive, handing it that user's registry root
# in place of HKCU:. Logged-on users are edited live via HKEY_USERS\<SID>;
# everyone else has NTUSER.DAT loaded and unloaded around the call.
#
#   invokeForEachUserHive {
#       param($root, $user)
#       setRegValue -Path "$root\SOFTWARE\..." -Name "Foo" -Value 0
#   }
#
# Do NOT reference variables from the calling function inside the scriptblock -
# PowerShell resolves them at the invocation scope, not the definition scope.
# Declare anything you need inside the block.
function invokeForEachUserHive {
    param([Parameter(Mandatory)][scriptblock]$ScriptBlock)

    if (-not (Get-PSDrive -Name HKU -ErrorAction SilentlyContinue)) {
        New-PSDrive -Name HKU -PSProvider Registry -Root HKEY_USERS -Scope Global | Out-Null
    }

    foreach ($p in (getUserProfiles)) {
        $tempKey = $null
        $root = $null

        if ($p.Sid -and (Test-Path "Registry::HKEY_USERS\$($p.Sid)")) {
            $root = "Registry::HKEY_USERS\$($p.Sid)"
        } else {
            $dat = Join-Path $p.Path 'NTUSER.DAT'
            if (-not (Test-Path $dat)) { continue }

            $tempKey = 'NuviaHive_' + ($p.Name -replace '[^A-Za-z0-9]', '_')
            & reg.exe load "HKU\$tempKey" "$dat" 2>&1 | Out-Null
            if ($LASTEXITCODE -ne 0) {
                writeText -type "notice" -text "Could not load hive for $($p.Name) (in use?). Skipping."
                continue
            }
            $root = "Registry::HKEY_USERS\$tempKey"
        }

        try {
            & $ScriptBlock $root $p.Name
        } catch {
            writeText -type "error" -text "Hive edit failed for $($p.Name): $($_.Exception.Message)"
        } finally {
            if ($tempKey) {
                # These GC calls are required. Without them PowerShell still
                # holds handles and the unload fails with "Access is denied".
                [gc]::Collect()
                [gc]::WaitForPendingFinalizers()
                & reg.exe unload "HKU\$tempKey" 2>&1 | Out-Null
            }
        }
    }
}

# winget reaches interactive users through an App Execution Alias in
# %LOCALAPPDATA%\Microsoft\WindowsApps, which SYSTEM has no copy of. Resolve
# the real binary under Program Files\WindowsApps instead.
function getWingetPath {
    $cmd = Get-Command winget.exe -ErrorAction SilentlyContinue
    if ($cmd -and (Test-Path $cmd.Source)) { return $cmd.Source }

    $candidates = Get-ChildItem -Path "$env:ProgramFiles\WindowsApps" -Directory -Force -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -like 'Microsoft.DesktopAppInstaller_*_*__8wekyb3d8bbwe' } |
    Sort-Object -Property Name -Descending

    foreach ($c in $candidates) {
        $exe = Join-Path $c.FullName 'winget.exe'
        if (Test-Path $exe) { return $exe }
    }
    return $null
}