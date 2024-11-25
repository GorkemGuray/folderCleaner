# Configuration
$folderPaths = @("C:\OMRON\Soft-NA\Storage\SDCard\Data Logging\Log Files\DataSet0", "C:\OMRON\Soft-NA\Storage\SDCard\Data Logging\Log Files\DataSet1", "C:\OMRON\Soft-NA\Storage\SDCard\Data Logging\Log Files\DataSet2", "C:\OMRON\Soft-NA\Storage\SDCard\OperationLog")
$maxFolderCount = 2
$folderThreshold = 2
$logFilePath = "C:\FolderCleaner\Logs\cleanup.log"
$logRetentionDays = 30  # Changed back to 30 days retention

# Ensure log directory exists
$logDir = Split-Path -Parent $logFilePath
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

# Function to validate folder name format (yyyyMMdd)
function Test-FolderNameFormat {
    param([string]$folderName)
    
    # First check if it matches the basic pattern
    if (-not ($folderName -match '^\d{8}$')) {
        return $false
    }
    
    try {
        # Try to parse the date
        [datetime]::ParseExact($folderName, 'yyyyMMdd', [System.Globalization.CultureInfo]::InvariantCulture)
        return $true
    }
    catch {
        return $false
    }
}

# Function to write log entry
function Write-LogEntry {
    param(
        [string]$message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] $message"
    Add-Content -Path $logFilePath -Value $logEntry
    Write-Host $logEntry
}

# Function to remove old log entries
function Remove-OldLogEntries {
    if (-not (Test-Path $logFilePath)) {
        return
    }

    $tempFile = "$logFilePath.temp"
    $cutoffDate = (Get-Date).AddDays(-$logRetentionDays)
    
    try {
        Write-LogEntry "Starting log cleanup - Removing entries older than $($cutoffDate.ToString('yyyy-MM-dd HH:mm:ss'))"
        
        $content = Get-Content $logFilePath | Where-Object {
            if ($_ -match '^\[([\d-]+ [\d:]+)\]') {
                $logDate = [DateTime]::ParseExact($matches[1], "yyyy-MM-dd HH:mm:ss", $null)
                $keep = $logDate -gt $cutoffDate
                if (-not $keep) {
                    Write-LogEntry "Removing old log entry: $_"
                }
                $keep
            } else {
                $true  # Keep lines that don't match the timestamp format
            }
        }
        
        if ($content) {
            $content | Set-Content $tempFile
            Move-Item -Path $tempFile -Destination $logFilePath -Force
            Write-LogEntry "Log cleanup completed successfully"
        }
    }
    catch {
        Write-LogEntry "Error removing old log entries: $_"
    }
}

# Main cleanup function
function Remove-Folders {
    param(
        [string]$path
    )
    
    if (-not (Test-Path $path)) {
        Write-LogEntry "Path not found: $path"
        return
    }

    try {
        # Get all folders with valid yyyyMMdd format
        $folders = Get-ChildItem -Path $path -Directory | 
            Where-Object { Test-FolderNameFormat $_.Name } |
            Sort-Object { [datetime]::ParseExact($_.Name, 'yyyyMMdd', [System.Globalization.CultureInfo]::InvariantCulture) } -Descending

        $totalFolders = $folders.Count
        Write-LogEntry "Path: $path | Total Folders Before Cleanup: $totalFolders"

        if ($totalFolders -le $maxFolderCount) {
            Write-LogEntry "No cleanup needed for $path (Count within limits)"
            return
        }

        # Keep the most recent $maxFolderCount folders, delete the rest
        $foldersToKeep = $folders | Select-Object -First $maxFolderCount
        $foldersToRemove = $folders | Select-Object -Skip $maxFolderCount

        # Delete folders and log the operation
        $deletedFolders = @()
        foreach ($folder in $foldersToRemove) {
            try {
                Remove-Item -Path $folder.FullName -Recurse -Force
                $deletedFolders += $folder.Name
            }
            catch {
                Write-LogEntry "Error deleting folder $($folder.Name): $_"
            }
        }

        # Count only the folders that match our date format
        $remainingFolders = (Get-ChildItem -Path $path -Directory | 
            Where-Object { Test-FolderNameFormat $_.Name }).Count
        Write-LogEntry "Path: $path | Total Folders After Cleanup: $remainingFolders"
        
        if ($deletedFolders.Count -gt 0) {
            $sortedDeletedFolders = $deletedFolders | Sort-Object
            Write-LogEntry "Deleted Folders: [$($sortedDeletedFolders -join ', ')]"
        }
    }
    catch {
        Write-LogEntry "Error processing path $path : $_"
    }
}

# Main execution
Write-LogEntry "=== Starting Folder Cleanup Process ==="

foreach ($folderPath in $folderPaths) {
    Remove-Folders -path $folderPath
}

# Remove old log entries
Remove-OldLogEntries

Write-LogEntry "=== Folder Cleanup Process Completed ==="
