# Configuration Parameters
$testMode = $false        # Set to true for dry-run mode (no actual deletions)
$maxFolderCount = 15      # Maximum number of folders to retain (0 to disable count-based retention)
$daysThreshold = 18       # Keep folders newer than this many days (0 to disable date-based retention)
$enableLogging = $true    # Enable detailed logging of all operations
$logFilePath = "C:\FolderCleaner\Logs\cleanup.log"
$logRetentionDays = 30    # Days to keep log entries before cleanup

<# Retention Scenarios:
   1. Count Only ($maxFolderCount = 15, $daysThreshold = 0):
      - Keeps exactly 15 newest folders
      - Ignores folder age
      - Example: From 20 folders, keeps newest 15, deletes oldest 5
   
   2. Date Only ($maxFolderCount = 0, $daysThreshold = 18):
      - Keeps all folders newer than 18 days
      - Ignores folder count limit
      - Example: Keeps all folders after 07.11.2024, deletes older ones
   
   3. Combined ($maxFolderCount = 15, $daysThreshold = 18):
      - First keeps folders newer than 18 days
      - Then adds older folders to reach 15 total if needed
      - Example: Keeps 14 new folders + 1 oldest remaining to reach 15
#>

# Target folder paths
$folderPaths = @(
    "C:\OMRON\Soft-NA\Storage\SDCard\Data Logging\Log Files\DataSet0",
    "C:\OMRON\Soft-NA\Storage\SDCard\Data Logging\Log Files\DataSet1",
    "C:\OMRON\Soft-NA\Storage\SDCard\Data Logging\Log Files\DataSet2",
    "C:\OMRON\Soft-NA\Storage\SDCard\OperationLog"
)

# Color configuration for console output
$Colors = @{
    TestMode = 'Magenta'
    Production = 'Red'
    Success = 'Green'
    Info = 'Gray'
    Header = 'Cyan'
}

# Validation checks
if ($maxFolderCount -eq 0 -and $daysThreshold -eq 0) {
    throw "At least one retention criterion (maxFolderCount or daysThreshold) must be active"
}

# Ensure log directory exists
$logDir = Split-Path -Parent $logFilePath
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

# Function to validate folder name format (yyyyMMdd)
function Test-FolderNameFormat {
    param([string]$folderName)
    
    if (-not ($folderName -match '^\d{8}$')) {
        return $false
    }
    
    try {
        [datetime]::ParseExact($folderName, 'yyyyMMdd', [System.Globalization.CultureInfo]::InvariantCulture)
        return $true
    }
    catch {
        return $false
    }
}

# Function to write log entry with color support
function Write-LogEntry {
    param(
        [string]$message,
        [string]$color = 'White',
        [switch]$skipLog
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] $message"
    
    # Console output with color
    Write-Host $logEntry -ForegroundColor $color
    
    # File logging if enabled and not skipped
    if ($enableLogging -and -not $skipLog) {
        Add-Content -Path $logFilePath -Value $logEntry
    }
}

# Function to remove old log entries
function Remove-OldLogEntries {
    if (-not (Test-Path $logFilePath) -or -not $enableLogging) {
        return
    }

    $tempFile = "$logFilePath.temp"
    $cutoffDate = (Get-Date).AddDays(-$logRetentionDays)
    
    try {
        Write-LogEntry "Starting log cleanup - Removing entries older than $($cutoffDate.ToString('yyyy-MM-dd HH:mm:ss'))" -color $Colors.Info
        
        $content = Get-Content $logFilePath | Where-Object {
            if ($_ -match '^\[([\d-]+ [\d:]+)\]') {
                $logDate = [DateTime]::ParseExact($matches[1], "yyyy-MM-dd HH:mm:ss", $null)
                $keep = $logDate -gt $cutoffDate
                if (-not $keep) {
                    Write-LogEntry "Removing old log entry: $_" -color $Colors.Info -skipLog
                }
                $keep
            } else {
                $true
            }
        }
        
        if ($content) {
            $content | Set-Content $tempFile
            Move-Item -Path $tempFile -Destination $logFilePath -Force
            Write-LogEntry "Log cleanup completed successfully" -color $Colors.Success
        }
    }
    catch {
        Write-LogEntry "Error removing old log entries: $_" -color $Colors.Production
    }
}

# Main cleanup function
function Remove-Folders {
    param(
        [string]$path
    )
    
    # Verify path accessibility
    if (-not (Test-Path $path)) {
        Write-LogEntry "Path not found or inaccessible: $path" -color $Colors.Production
        return
    }

    try {
        # Get all folders with valid yyyyMMdd format
        $folders = Get-ChildItem -Path $path -Directory | 
            Where-Object { Test-FolderNameFormat $_.Name } |
            Sort-Object { [datetime]::ParseExact($_.Name, 'yyyyMMdd', [System.Globalization.CultureInfo]::InvariantCulture) } -Descending

        $totalFolders = $folders.Count
        Write-LogEntry "Path: $path | Total Folders Before Cleanup: $totalFolders" -color $Colors.Info

        # Initialize folders to keep
        $foldersToKeep = $folders

        # Apply retention criteria based on configuration
        if ($daysThreshold -gt 0) {
            $dateThreshold = (Get-Date).Date.AddDays(-$daysThreshold)
            $foldersToKeep = $foldersToKeep | Where-Object {
                $folderDate = [datetime]::ParseExact($_.Name, 'yyyyMMdd', [System.Globalization.CultureInfo]::InvariantCulture)
                $folderDate.Date -ge $dateThreshold
            }
        }

        # If maxFolderCount is set and we have more folders than the limit
        if ($maxFolderCount -gt 0 -and $folders.Count -gt $maxFolderCount) {
            # If we have more folders after date filtering than maxFolderCount
            if ($foldersToKeep.Count -gt $maxFolderCount) {
                $foldersToKeep = $foldersToKeep | Select-Object -First $maxFolderCount
            }
            # If we have fewer folders after date filtering than maxFolderCount,
            # add more folders from the original list up to maxFolderCount
            elseif ($foldersToKeep.Count -lt $maxFolderCount) {
                $additionalNeeded = $maxFolderCount - $foldersToKeep.Count
                $additionalFolders = $folders | 
                    Where-Object { $_.Name -notin $foldersToKeep.Name } |
                    Select-Object -First $additionalNeeded
                $foldersToKeep = @($foldersToKeep) + @($additionalFolders)
            }
        }

        # Determine folders to remove (all folders not in foldersToKeep)
        $foldersToRemove = $folders | Where-Object { $_.Name -notin $foldersToKeep.Name }

        # Process folders
        $deletedFolders = @()
        foreach ($folder in $foldersToRemove) {
            if ($testMode) {
                $actionMsg = "[TEST MODE] Would delete folder: $($folder.Name)"
                $messageColor = $Colors.TestMode
            } else {
                $actionMsg = "Deleting folder: $($folder.Name)"
                $messageColor = $Colors.Production
            }
            
            Write-LogEntry $actionMsg -color $messageColor
            
            if (-not $testMode) {
                try {
                    Remove-Item -Path $folder.FullName -Recurse -Force
                    $deletedFolders += $folder.Name
                }
                catch {
                    Write-LogEntry "Error deleting folder $($folder.Name): $_" -color $Colors.Production
                }
            }
        }

        # Final status
        $remainingFolders = (Get-ChildItem -Path $path -Directory | 
            Where-Object { Test-FolderNameFormat $_.Name }).Count
        
        Write-LogEntry "Path: $path | Total Folders After Cleanup: $remainingFolders" -color $Colors.Success
        
        if ($deletedFolders.Count -gt 0) {
            $sortedDeletedFolders = $deletedFolders | Sort-Object
            Write-LogEntry "Deleted Folders: [$($sortedDeletedFolders -join ', ')]" -color $Colors.Success
        }
    }
    catch {
        Write-LogEntry "Error processing path $path : $_" -color $Colors.Production
    }
}

# Main execution
Write-LogEntry "=== Starting Folder Cleanup Process ===" -color $Colors.Header

if ($testMode) {
    $modeMsg = "Running in TEST MODE - No files will be deleted"
    $modeColor = $Colors.TestMode
} else {
    $modeMsg = "Running in PRODUCTION MODE - Files will be deleted"
    $modeColor = $Colors.Production
}
Write-LogEntry $modeMsg -color $modeColor

Write-LogEntry "Configuration:" -color $Colors.Info
Write-LogEntry "- Max Folder Count: $maxFolderCount" -color $Colors.Info
Write-LogEntry "- Days Threshold: $daysThreshold" -color $Colors.Info
Write-LogEntry "- Logging Enabled: $enableLogging" -color $Colors.Info

foreach ($folderPath in $folderPaths) {
    Write-LogEntry "Processing path: $folderPath" -color $Colors.Header
    Remove-Folders -path $folderPath
}

# Remove old log entries
if ($enableLogging) {
    Remove-OldLogEntries
}

Write-LogEntry "=== Folder Cleanup Process Completed ===" -color $Colors.Header
