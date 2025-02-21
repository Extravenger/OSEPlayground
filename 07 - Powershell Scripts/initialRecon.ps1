# PowerShell Enumeration Script for OSEP
# 1. Enumerate Network Shares and Mapped Shares
Write-Host "Enumerating Network and Mapped Shares... Please check for non default shares."
net share
get-smbmapping

# 2. List Specific File Types in C:\Users
Write-Host "`nListing Specific File Types in C:\Users..."
Get-ChildItem -Path C:\Users -Include *.xml,*.txt,*.pdf,*.xls,*.xlsx,*.doc,*.docx,id_rsa,authorized_keys,*.exe,*.log -File -Recurse -ErrorAction SilentlyContinue

# 3. List Folders in C:\Program Files, C:\ProgramData and C:\Program Files (x86)
Write-Host "`nListing Folders in C:\Program Files and C:\Program Files (x86)..."
Get-ChildItem -Path "C:\Program Files", "C:\Program Files (x86)", "C:\ProgramData" -Directory

# 4. List All Folders in C:\
Write-Host "`nListing All Folders in C:\..."
Get-ChildItem -Path "C:\" -Directory

# 5. Search for flag files on machine
Write-Host "`n Searching for flags on machine..."
Get-ChildItem -Path C:\ -Include local.txt,proof.txt -File -Recurse -ErrorAction SilentlyContinue

# 6. Enumerate Open Ports and Services
Write-Host "`nEnumerating Open Ports and Services..."
Get-NetTCPConnection | Where-Object {$_.State -eq 'Listen'} | Select-Object LocalAddress, LocalPort, OwningProcess | ForEach-Object {
    $processName = Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue | Select-Object -ExpandProperty ProcessName
    "$($_.LocalAddress):$($_.LocalPort) is being listened on by $processName"
}

# 7. Check Write Permissions for C:\inetpub\wwwroot
Write-Host "`nChecking Write Permissions for C:\inetpub\wwwroot..."
if (Test-Path "C:\inetpub\wwwroot") {
    $hasWriteAccess = $false
    try {
        [IO.File]::WriteAllText("C:\inetpub\wwwroot\test.txt", "test")
        Remove-Item "C:\inetpub\wwwroot\test.txt"
        $hasWriteAccess = $true
    } catch {
        $hasWriteAccess = $false
    }
    
    if ($hasWriteAccess) {
        Write-Host "You have write access to C:\inetpub\wwwroot. Consider writing an ASPX shell to escalate privileges as IISSVC using SeImpersonate."
    } else {
        Write-Host "You don't have write access to C:\inetpub\wwwroot."
    }
}
else {
    Write-Host "C:\inetpub\wwwroot does not exist."
}

# 8. Check Sticky Notes and PowerShell History
Write-Host "`nChecking Sticky Notes and PowerShell History..."

# Check for Sticky Notes
$stickyNotesPath = "C:\Users\*\AppData\Local\Packages\Microsoft.MicrosoftStickyNotes_8wekyb3d8bbwe\LocalState\*"
$stickyFiles = Get-ChildItem -Path $stickyNotesPath -File -ErrorAction SilentlyContinue
if ($stickyFiles) {
    Write-Host "Found Sticky Notes. You should manually check these for sensitive info:"
    $stickyFiles.FullName
} else {
    Write-Host "No Sticky Notes found."
}

# Check for PowerShell History
$psHistoryPath = "C:\Users\*\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt"
$psHistoryFiles = Get-ChildItem -Path $psHistoryPath -File -ErrorAction SilentlyContinue
if ($psHistoryFiles) {
    Write-Host "Found PowerShell history. You might want to sift through these for juicy details:"
    $psHistoryFiles.FullName
} else {
    Write-Host "No PowerShell history found."
}

# 9. Listing Services
# Search by binary name: reg query HKLM\SYSTEM\CurrentControlSet\Services /s /f "Service.exe" /t REG_EXPAND_SZ
# Enumerate from service name: reg query HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\CustomService  
reg query HKLM\SYSTEM\CurrentControlSet\Services
