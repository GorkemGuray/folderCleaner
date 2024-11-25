# 🧹 OMRON Folder Cleanup Script

A PowerShell script designed to automatically manage and clean up OMRON log folders based on configurable retention criteria. The script supports both test (dry run) and production modes, with comprehensive logging capabilities.

## 👨‍💻 Author & Contact
- **Author**: Görkem Güray
- **Website**: [gorkem.co](https://gorkem.co)
- **Created**: 2024

> ## ⚠️ IMPORTANT DISCLAIMER
> 
> **BY USING THIS SCRIPT, YOU ACKNOWLEDGE AND ACCEPT THE FOLLOWING:**
> 
> ❗ This script permanently deletes folders and their contents
> ❗ No guarantee is provided against accidental data loss
> ❗ The user is solely responsible for:
>   - Verifying script settings before use
>   - Testing in dry-run mode first
>   - Backing up important data
>   - Monitoring script execution
>   - Any data loss that may occur
> 
> **🚨 ALWAYS TEST THE SCRIPT IN DRY-RUN MODE BEFORE PRODUCTION USE 🚨**
> 
> ⚖️ The authors and contributors of this script cannot be held responsible for any data loss or damage caused by its use.

## ✨ Features

### 📂 Folder Management
- Support for multiple folder paths
- Configurable maximum folder count
- Date-based threshold for folder deletion
- Validation of folder names in 'yyyyMMdd' format

### 🔄 Operation Modes
- 🧪 Test Mode (Dry Run)
  - Shows potential deletions without modifying files
  - Highlighted console output in Magenta color
  - Safe testing environment
- ⚡ Production Mode
  - Performs actual folder cleanup
  - Detailed logging of all operations

### 🧠 Smart Retention Logic
- Keeps the newest specified number of folders
- Additional date-based filtering for older folders
- Prevents accidental deletion of all folders
- Configurable retention parameters

### 📋 Comprehensive Logging
- Detailed timestamped logs
- Configurable log retention
- Optional logging feature
- Separate success and error logging

## ⚙️ Configuration

### 🎮 Main Parameters
```powershell
$testMode = $true        # Set to false for production mode
$maxFolderCount = 15     # Number of newest folders to keep (0 to disable)
$daysThreshold = 18      # Age threshold in days (0 to disable)
$enableLogging = $true   # Enable/disable logging
```

### 📂 Folder Paths
```powershell
$folderPaths = @(
    "C:\OMRON\Soft-NA\Storage\SDCard\Data Logging\Log Files\DataSet0",
    "C:\OMRON\Soft-NA\Storage\SDCard\Data Logging\Log Files\DataSet1",
    "C:\OMRON\Soft-NA\Storage\SDCard\Data Logging\Log Files\DataSet2",
    "C:\OMRON\Soft-NA\Storage\SDCard\OperationLog"
)
```

### 📝 Logging Configuration
```powershell
$logFilePath = "C:\folderCleaner\Logs\cleanup.txt"
$logRetentionDays = 30  # Days to keep log entries
```

## 🚀 Usage

### ⌨️ Direct Execution
Run the script directly in PowerShell with administrator privileges:

```powershell
powershell -ExecutionPolicy Bypass -File "C:\folderCleaner\FolderCleanup.ps1"
```

### ⏰ Task Scheduler Setup
1. Open Task Scheduler
2. Create a new task:
   - General tab:
     - Name: "OMRON Folder Cleanup"
     - Run with highest privileges: ✓
     - Configure for: Windows 10
   - Triggers tab:
     - New Trigger: Daily at your preferred time
   - Actions tab:
     - New Action:
       - Program/script: `powershell.exe`
       - Arguments: `-ExecutionPolicy Bypass -File "C:\folderCleaner\FolderCleanup.ps1"`
   - Conditions tab:
     - Start the task only if the computer is on AC power: ✓
   - Settings tab:
     - If the task fails, restart every: 5 minutes
     - Attempt to restart up to: 3 times


## 🧪 Test Scenarios

> 📅 Test Date: November 25, 2024
> 🎯 Threshold Date: November 07, 2024 (18 days prior)

To demonstrate how different configurations affect folder retention, here are three test scenarios using a mixed-date folder list:

#### 📁 Sample Folder List (Mixed Dates)
```
Group 1 (Newer than 18 days, after 07.11.2024):
20241125, 20241124, 20241122, 20241121, 20241120, 
20241118, 20241116, 20241115, 20241112, 20241111, 
20241110, 20241109, 20241108, 20241107

Group 2 (Older than 18 days, before 07.11.2024):
20241106, 20241105, 20241104, 20241103, 20241102, 20241101
```

#### 📊 Scenario Results Summary
| Scenario | Configuration | Folders Kept | Folders Deleted |
|----------|--------------|--------------|-----------------|
| 1: Count Only | maxCount=15, days=0 | 15 newest | 5 oldest |
| 2: Date Only | maxCount=0, days=18 | 14 (>18 days) | 6 (<18 days) |
| 3: Combined | maxCount=15, days=18 | 15 (14 new + 1 old) | 5 oldest |

#### 📊 Scenario 1: Keep Newest N Folders
```powershell
$maxFolderCount = 15
$daysThreshold = 0    # Disabled
```
- Only considers folder count
- Keeps 15 newest folders regardless of date
- Result:
  - Kept (15): 20241125 through 20241106
  - Deleted (5): 20241105 through 20241101

#### 📊 Scenario 2: Keep Recent Folders
```powershell
$maxFolderCount = 0    # Disabled
$daysThreshold = 18
```
- Only considers date threshold
- Keeps folders newer than 18 days
- Result:
  - Kept (14): 20241125 through 20241107
  - Deleted (6): 20241106 through 20241101

#### 📊 Scenario 3: Combined Criteria
```powershell
$maxFolderCount = 15
$daysThreshold = 18
```
- Applies both date threshold and folder count
- First keeps folders newer than 18 days
- Then adds oldest folders to reach maxFolderCount
- Result:
  - Kept (15):
    * From date criteria (14): 20241125 through 20241107
    * Added to reach max (1): 20241106
  - Deleted (5): 20241105 through 20241101

## 🔒 Security Considerations

- Script requires administrator privileges
- Test mode recommended before production use
- Validation prevents accidental deletion:
  - At least one retention criterion must be active
  - Folder name format validation
  - Path existence checks

## 🐛 Error Handling

- Comprehensive try-catch blocks
- Detailed error logging
- Safe failure modes
- Invalid configuration detection
- Path accessibility verification

## 🎨 Console Output

- Color-coded status messages:
  - Magenta: Test mode messages
  - Red: Production mode and deletions
  - Green: Success messages
  - Gray: Informational messages
  - Cyan: Section headers

## 🔧 Maintenance

- Log files are automatically cleaned up based on retention period
- Invalid folder names are skipped
- Failed operations are logged for review
- No permanent changes in test mode

## ❗ Important Notes

1. Always run in test mode first
2. Verify folder paths before production use
3. Backup important data before first production run
4. Monitor log files for unexpected behavior
5. Adjust retention parameters based on your needs

## 📜 License

This project is licensed under the GNU Affero General Public License v3.0 - see the [LICENSE](LICENSE) file for details.

The AGPL-3.0 license ensures that any modifications made to the software, especially when used over a network, are shared back with the community.

### Key Points:
- Commercial use allowed
- Modification allowed
- Distribution allowed
- Private use allowed
- Modifications must be shared
- No warranty provided
- No liability accepted

For the full license text, please see the [LICENSE](LICENSE) file in the repository.

## Contributing

Feel free to submit issues and enhancement requests!
