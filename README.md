# Simple Folder Backup Script

This PowerShell script performs a backup operation from a source folder to a destination folder using the Robocopy command. It provides options to specify the source folder path, destination folder path, and log file path.

## Usage

```powershell
PS> .\BackupScript.ps1 [options]
```

## Options

- `-h, --help`: Show the help message and exit.
- `-s, --source` (PATH): Specify the source folder path (default: $Source).
- `-d, --dest` (PATH): Specify the destination folder path (default: $Destination).
- `-l, --log` (FILE): Specify the log file path (default: $Log).

## Prerequisites

- PowerShell 5.1 or later.
- Robocopy utility (included with Windows).

## Parameters

- `Source` (mandatory): The path to the source folder to be backed up.
- `Destination` (mandatory): The path to the destination folder where the backup will be stored.
- `Log` (mandatory): The path to the log file to record backup details.

## Execution

1. Change to the script's directory.
2. Run the script using the appropriate command-line arguments.
3. The script will perform the backup operation using Robocopy and log the details to the specified log file.
4. Upon completion, the script will display a success or failure message based on the Robocopy exit code.

**Note** - Ensure that the script is executed with appropriate permissions to read from the source folder, create the destination folder, and write to the log file.

## Example


```powershell
PS> .\BackupScript.ps1 -s "C:\SourceFolder" -d "D:\Backup" -l "C:\Logs\backup.log"
```

This example runs the backup script, specifying the source folder as "C:\SourceFolder", the destination folder as "D:\Backup", and the log file path as "C:\Logs\backup.log". The script will perform the backup operation and log the details to the specified log file.

For more information, use the -h or --help option to display the help message.

Note: Please ensure that you have the necessary permissions and appropriate backups of important data before running this script. Use it at your own risk. The script author and OpenAI take no responsibility for any data loss or damage caused by this script.