function adNuAdmin {
    try {
        $accountName = "NuAdmin"
        $keyUrl = "https://drive.google.com/uc?export=download&id=1-1bV76OHwbu-g2RroIUvZ7s6I3FeLL0w"
        $phraseUrl = "https://drive.google.com/uc?export=download&id=1qeSFJaKTmabGFwRoqf5mgnZd3rtSr37o"

        (New-Object System.Net.WebClient).DownloadFile($keyUrl, "$env:SystemRoot\Temp\KEY.txt")
        (New-Object System.Net.WebClient).DownloadFile($phraseUrl, "$env:SystemRoot\Temp\PHRASE.txt")

        # Read the key file and convert it to a byte array
        $keyString = Get-Content -Path "$env:SystemRoot\Temp\KEY.txt"
        $keyBytes = $keyString -split "," | ForEach-Object { [byte]$_ }

        # Read the encrypted password and convert it to a secure string using the key
        $password = Get-Content -Path "$env:SystemRoot\Temp\PHRASE.txt" | ConvertTo-SecureString -Key $keyBytes

        Write-Host "Phrase converted."

        # Check if the NuAdmin user already exists
        $account = Get-LocalUser -Name $accountName -ErrorAction SilentlyContinue

        if ($null -eq $account) {
            # Create the NuAdmin user with specified password and attributes
            New-LocalUser -Name $accountName -Password $password -FullName "" -Description "NuAdministrator" -AccountNeverExpires -PasswordNeverExpires -ErrorAction stop | Out-Null
            Write-Host "Account created."
        } else {
            # Update the existing NuAdmin user's password
            Write-Host "Account already exists."
            $account | Set-LocalUser -Password $password
            Write-Host "Password updated."
        }

        # Add the NuAdmin user to the Administrators, Remote Desktop Users, and Users groups
        Add-LocalGroupMember -Group "Administrators" -Member $accountName -ErrorAction SilentlyContinue
        Write-Host "Account added to 'Administrators' group."
        Add-LocalGroupMember -Group "Remote Desktop Users" -Member $accountName -ErrorAction SilentlyContinue
        Write-Host "Account added to 'Remote Desktop Users' group."
        Add-LocalGroupMember -Group "Users" -Member $accountName -ErrorAction SilentlyContinue
        Write-Host "Account added to 'Users' group."

        # Remove the downloaded files for security reasons
        Remove-Item -Path "$env:SystemRoot\Temp\PHRASE.txt"
        Remove-Item -Path "$env:SystemRoot\Temp\KEY.txt"

        # Informational messages about deleting temporary files
        if (-not (Test-Path -Path "$env:SystemRoot\Temp\KEY.txt")) {
            Write-Host "Encryption key deleted."
        } else {
            Write-Host "Encryption key not deleted!"
        }
        
        if (-not (Test-Path -Path "$env:SystemRoot\Temp\PHRASE.txt")) {
            Write-Host "Encryption phrase deleted."
        } else {
            Write-Host "Encryption phrase not deleted!"
        }

        Write-Host "NuAdmin account created"
    } catch {
        writeText -type "error" -text "$($MyInvocation.MyCommand.Name): $($_.InvocationInfo.ScriptLineNumber)-$($_.Exception.Message)"
    }
}