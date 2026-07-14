function declutterDrive {
    declutterVatech
}

function declutterVatech {
    writeText -type "plain" -text "Checking for a VaTech cache"
    $vatechPath = "C:\Program Files (x86)\VATECH\EzDent-i\Cache\Images"
    
    if (Test-Path $vatechPath) {       
        # Get initial size
        $initialSize = getFolderSize -Path $vatechPath
        $initialSizeFormatted = formatSize -Bytes $initialSize
        
        # Get count of files to be removed (for reporting)
        $filesToRemove = Get-ChildItem $vatechPath | Where-Object { 
            $_.CreationTime -lt (Get-Date).AddDays(-7) -and 
            $_.Name -ne "Backup" 
        }
        $fileCount = ($filesToRemove | Measure-Object).Count
        
        writeText -type "plain" -text "Current VaTech cache size: $initialSizeFormatted"
        writeText -type "plain" -text "Found $fileCount folders/files older than 7 days to remove (excluding 'Backup')"
        
        # Perform the removal
        $filesToRemove | Remove-Item -Recurse -Force
        
        # Get final size
        $finalSize = getFolderSize -Path $vatechPath
        $finalSizeFormatted = formatSize -Bytes $finalSize
        
        # Calculate difference
        $sizeDifference = $initialSize - $finalSize
        $sizeDifferenceFormatted = formatSize -Bytes $sizeDifference
        
        writeText -type "plain" -text "New VaTech cache size: $finalSizeFormatted"
        writeText -type "plain" -text "Space freed: $sizeDifferenceFormatted"
        
    } else {
        writeText -type "plain" -text "No VaTech cache found"
    }
}