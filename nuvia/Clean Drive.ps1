function cleanDrive {
    cleanVatech
    readCommand -command "disable hybernate file"
}

function cleanVatech {
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

function cleanTemp {
    param(
        [int]$DaysOld = 0,  # 0 = delete everything, 7 = delete files older than 7 days
        [switch]$WhatIf    # Preview what would be deleted
    )
    
    $totalSize = 0
    $totalFiles = 0
    
    # Function to clean a temp folder
    function Clear-TempFolder {
        param($FolderPath)
        
        if (-not (Test-Path $FolderPath)) { return }
        
        $items = Get-ChildItem -Path $FolderPath -Force -Recurse -ErrorAction SilentlyContinue
        
        if ($DaysOld -gt 0) {
            $cutoff = (Get-Date).AddDays(-$DaysOld)
            $items = $items | Where-Object { $_.LastWriteTime -lt $cutoff }
        }
        
        $size = ($items | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
        $count = ($items | Measure-Object).Count
        
        if ($WhatIf) {
            Write-Host "[WHATIF] Would delete $count items ($([math]::Round($size/1MB, 2)) MB) from $FolderPath" -ForegroundColor Cyan
        } else {
            $items | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
            Write-Host "Cleaned $FolderPath - Removed $count items ($([math]::Round($size/1MB, 2)) MB)" -ForegroundColor Green
        }
        
        return @{ Size = $size; Count = $count }
    }
    
    # Clean system TEMP
    Write-Host "`n=== Cleaning System TEMP ===" -ForegroundColor Yellow
    $result1 = Clear-TempFolder -FolderPath "C:\Windows\Temp"
    
    # Clean ALL user TEMP folders
    Write-Host "`n=== Cleaning User TEMP folders ===" -ForegroundColor Yellow
    
    # Get all user profile folders
    $userFolders = Get-ChildItem -Path "C:\Users" -Directory -ErrorAction SilentlyContinue | 
    Where-Object { $_.Name -notin @('Public', 'Default', 'Default User') }
    
    # Also add current user (in case they're in a different location)
    $userFolders += Get-ChildItem -Path "$env:USERPROFILE" -ErrorAction SilentlyContinue
    
    foreach ($user in $userFolders | Select-Object -Unique) {
        $tempPath = Join-Path -Path $user.FullName -ChildPath "AppData\Local\Temp"
        $result2 = Clear-TempFolder -FolderPath $tempPath
        
        if ($result2) {
            $totalSize += $result2.Size
            $totalFiles += $result2.Count
        }
    }
    
    # Summary
    Write-Host "`n=== SUMMARY ===" -ForegroundColor Cyan
    Write-Host "Total files deleted: $totalFiles" -ForegroundColor White
    Write-Host "Total space freed: $([math]::Round($totalSize/1MB, 2)) MB ($([math]::Round($totalSize/1GB, 2)) GB)" -ForegroundColor White
    
    if ($WhatIf) {
        Write-Host "`n(Preview mode - no files were actually deleted)" -ForegroundColor Yellow
    }
}