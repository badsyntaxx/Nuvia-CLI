function isrAddBookmarks {
    try {
        $user = selectUser -prompt "Select user to add bookmarks for:"
        $chromeUserDataPath = getOrCreateUserPath -username $user["Name"]
        $profiles = getChromeProfiles -userPath $chromeUserDataPath
        $choice = readOption -options $profiles -prompt "Select a Chrome profile:" -ReturnKey 
        $chromeProfile = $profiles["$choice"]
        $boomarksurl = "https://drive.google.com/uc?export=download&id=1WmvSnxtDSLOt0rgys947sOWW-v9rzj9U"

        $download = getDownload -url $boomarksurl -target "$env:SystemRoot\Temp\Bookmarks" 

        if ($download) {
            ROBOCOPY $env:SystemRoot\Temp $chromeProfile "Bookmarks" /NFL /NDL /NC /NS /NP | Out-Null
            Remove-Item -Path "$env:SystemRoot\Temp\Bookmarks" -Force

            updateChromePreferences -profile $chromeProfile

            if (Test-Path -Path $chromeProfile) {
                writeText -type "success" -text "The bookmarks have been added."
            }
        }
    } catch {
        writeText -type "error" -text "isrAddBookmarks-$($_.InvocationInfo.ScriptLineNumber) | $($_.Exception.Message)"
    }
}
function getOrCreateUserPath {
    param (
        [parameter(Mandatory = $true)]
        [string]$username
    )

    $chromeUserDataPath = "C:\Users\$username\AppData\Local\Google\Chrome\User Data"
    if (!(Test-Path $chromeUserDataPath)) {
        write-Host 'no user path'
        New-Item -ItemType Directory -Path $chromeUserDataPath
    }
    write-host $chromeUserDataPath
    return $chromeUserDataPath
}
function getChromeProfiles {
    param (
        [parameter(Mandatory = $true)]
        [string]$userPath
    )
    
    $profiles = [ordered]@{}
    $profileFolders = Get-ChildItem -Path $userPath -Directory

    if ($null -eq $profileFolders) { 
        New-Item -ItemType Directory -Path "$userPath\Default" -Force
    }

    foreach ($profileFolder in $profileFolders) {
        $preferencesFile = Join-Path -Path $profileFolder.FullName -ChildPath "Preferences"
        if (Test-Path -Path $preferencesFile) {
            $preferencesContent = Get-Content -Path $preferencesFile -Raw | ConvertFrom-Json
            $profileName = $preferencesContent.account_info.email

            if ($null -eq $preferencesContent.account_info.email) {
                $profileName = $preferencesContent.account_info.account_id
            } 

            $folderName = Split-Path -Path $profileFolder.FullName -Leaf

            if ($null -eq $profileName) {
                $profiles["$folderName"] = $folderName
            } else {
                $profiles["$profileName"] = $folderName
            }
        }
    }

    return $profiles
}
function updateChromePreferences {
    param (
        [parameter(Mandatory = $true)]
        [string]$profile
    )

    $preferencesFilePath = Join-Path -Path $profile -ChildPath "Preferences"
    if (Test-Path -Path $preferencesFilePath) {
        $preferences = Get-Content -Path $preferencesFilePath -Raw | ConvertFrom-Json
        if (-not $preferences.PSObject.Properties.Match('bookmark_bar').Count) {
            $preferences | Add-Member -type NoteProperty -Name 'bookmark_bar' -Value @{}
        }

        if (-not $preferences.bookmark_bar.PSObject.Properties.Match('show_on_all_tabs').Count) {
            $preferences.bookmark_bar | Add-Member -type NoteProperty -Name 'show_on_all_tabs' -Value $true
        } else {
            $preferences.bookmark_bar.show_on_all_tabs = $true
        }

        $preferences | ConvertTo-Json -Depth 100 | Set-Content -Path $preferencesFilePath
    }
}