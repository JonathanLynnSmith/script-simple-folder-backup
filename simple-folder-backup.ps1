param(
    [switch]$Help,
    [Parameter(Mandatory = $true)]
    [string]$Source,
    [Parameter(Mandatory = $true)]
    [string]$Destination,
    [Parameter(Mandatory = $true)]
    [string]$Log,
    [Parameter(Mandatory = $false)]
    [int]$RobocopyLogDaysThreshold = 0,
    [Parameter(Mandatory = $false)]
    [switch]$TestMode = $false
)

Set-Location -Path $PSScriptRoot
$notificationTitle =  $MyInvocation.MyCommand.Name

function Main{
    Parse-Params
    Check-LogFile
    Check-Source-Folder
    Check-Destination-Folder
    Run-Backup
}

function Parse-Params{
    if ($Help) {
        Show-Help
        Exit 0
    }

    $global:SOURCE_PATH = $Source.TrimEnd('\')
    $global:DESTINATION_PATH = $Destination.TrimEnd('\')
}

function Show-Help {
    Write-Host "Backup Script"
    Write-Host "Usage: $PSCommandPath [options]"
    Write-Host
    Write-Host "Options:"
    Write-Host "  -h, --help         Show this help message and exit"
    Write-Host "  -s, --source PATH  Specify the source folder path (default: $SOURCE_PATH)"
    Write-Host "  -d, --dest PATH    Specify the destination folder path (default: $DESTINATION_PATH)"
    Write-Host "  -l, --log FILE     Specify the log file path (default: $Log)"
    Write-Host
}

function Notify($title, $message) {
    $notification = New-Object -ComObject WScript.Shell
    $notification.Popup($message, 0, $title, 48)
}

# Function to log messages
function Log($message) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] $message"
    Add-Content -Path $Log -Value $logEntry
    Write-Host $message
}

function Log-Error($message) {
    Log($message)
    Notify $notificationTitle $message
    Exit
}

function Check-LogFile {
    if (-not (Test-Path $Log)) {
        New-Item -ItemType File -Path $Log -Force | Out-Null
        if (-not $?) {
            Log-Error "Error: Failed to create log file: $Log"
            Exit 1
        }
    }
}

function Check-Source-Folder {
    if (-not (Test-Path $SOURCE_PATH -PathType Container)) {
        Log-Error "Error: Source folder does not exist or is inaccessible!: $SOURCE_PATH"
        Exit 1
    }
}

function Check-Destination-Folder{
    if (-not (Test-Path $DESTINATION_PATH -PathType Container)) {
        New-Item -Path $DESTINATION_PATH -ItemType Directory | Out-Null
        if ($?) {
            Log "Created destination folder: $DESTINATION_PATH"
        } else {
            Log-Error "Error: Failed to create destination folder: $DESTINATION_PATH"
            Exit 1
        }
    }
}

function Create-Robocopy-Log {
    $logDirectory = Join-Path (Split-Path $Log -Parent) "Robocopy Logs"
    $logPath = Join-Path $logDirectory ("{0}.{1}" -f (Get-Date -Format 'yyyyMMdd-HHmmss'), "robocopy.log")
    
    if (-not (Test-Path $logDirectory)) {
        New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null
        if (-not $?) {
            Log-Error "Error: Failed to create the Robocopy Logs directory: $logDirectory"
            Exit 1
        }
    }
    
    New-Item -ItemType File -Path $logPath -Force | Out-Null
    if (-not $?) {
        Log-Error "Error: Failed to create the Robocopy log file: $logPath"
        Exit 1
    }
    
    return $logPath
}

function Remove-OldLogs {
    param (
        [Parameter(Mandatory=$true)]
        [string]$LogDirectory,
        [Parameter(Mandatory=$true)]
        [int]$DaysThreshold
    )

    if ($DaysThreshold -eq 0 -or $TestMode) {
        return
    }

    $cutoffDate = (Get-Date).AddDays(-$DaysThreshold)

    $logFiles = Get-ChildItem -Path $LogDirectory -File | Where-Object { $_.LastWriteTime -lt $cutoffDate }

    if ($logFiles.Count -gt 0) {
        Log "$($logFiles.Count) Logs found that are older than $cutoffDate, these will be deleted."
        foreach ($logFile in $logFiles) {
            Remove-Item -Path $logFile.FullName -Force
            Write-Host "Deleted log file: $($logFile.Name)"
        }
    } else {
        Write-Host "No log files older than $cutoffDate days found."
    }
}

function Check-Success {
    if ($LASTEXITCODE -eq 0 -or $? -eq $true) {
        return $true
    } else {
        return $false
    }
}



function Run-Backup {
    Log "Starting backup..."
    $robocopyLog = Create-Robocopy-Log

    $arguments = @()
    $arguments += "`"$SOURCE_PATH`""
    $arguments += "`"$DESTINATION_PATH`""
    $arguments += "/E"
    $arguments += "/tee"
    $arguments += "/log+:`"$robocopyLog`""
    if ($TestMode) {
        $arguments += "/L"
    }

    Start-Process -FilePath "robocopy" -ArgumentList $arguments -NoNewWindow -Wait
    
    
    if($TestMode){
        $result = "TEST"
        Log "Backup completed successfully."
    }
    elseif(Check-Success){
        $result = "SUCCESS"
        Log "Backup completed successfully."
    }
    else{
        $result = "FAILED"
        Log "Backup failed. Exit Code: $LASTEXITCODE"
    }

    $oldLogName = (Get-Item -Path $robocopyLog).Name
    $newLogName = "{0}.{1}" -f $result, $oldLogName
    Write-Host($newLogPath)
    Rename-Item -Path $robocopyLog -NewName $newLogName -ErrorAction SilentlyContinue
    

    Remove-OldLogs -LogDirectory (Split-Path $robocopyLog -Parent) -DaysThreshold $RobocopyLogDaysThreshold
}

Main