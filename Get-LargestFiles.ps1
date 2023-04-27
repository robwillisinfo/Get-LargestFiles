<# 
.SYNOPSIS

This script will help locate the largest files on the specified drive.

.DESCRIPTION

This script will help locate the largest files on the specified drive, while also displaying
the sizes of the folders in the root directory.

The script will execute in the following order:
- Create a log file, default log is saved to the current directory as Get-LargestFiles-output.txt
- Gather the date, hostname, and current privileges
- Gather the basic drive info, capacity and free space (Default drive is C:)
- Gather the root folder sizes
- Find the top x largest files on the drive (Default count is 10)
- Optional scan of a specific directory

.EXAMPLE

Basic usage:
C:\PS> PowerShell.exe -ExecutionPolicy Bypass .\Get-LargestFiles.ps1

Specify a different drive and change the amount of files to show:
C:\PS> PowerShell.exe -ExecutionPolicy Bypass .\Get-LargestFiles.ps1 -c "25" -d "d:"

Skip the default root drive scans and only scan a specific directory (you will be prompted for the path):
C:\PS> PowerShell.exe -ExecutionPolicy Bypass .\Get-LargestFiles.ps1 -s

#>

[CmdletBinding()] Param(
    [Parameter(Mandatory = $false)]
    [Alias("o")]
    [String]
    $outputFile = "Get-LargestFiles-output.txt",

    [Parameter(Mandatory = $false)]
    [Alias("d")]
    [String]
    $drive = "C:",

    [Parameter(Mandatory = $false)]
    [Alias("c")]
    [int]
    $filesToCount = "10",

    [Parameter(Mandatory = $false)]
    [Alias("s")]
    [Switch]
    $specificDirScanSwitch

)

# Start logging
Start-Transcript -Path $outputFile

# Time stamp
$time = Get-Date -format "MMM-dd-yyyy HH:mm"

# Hostname
$hostname = $env:COMPUTERNAME

function isUserAdmin {
    # Check to see if the script is being executed with admin privileges
    $user = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if ($user.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) -eq $true ) {
        Write-Host " Script executed with admin privileges: Yes"
    } else {
        Write-Host " Script executed with admin privileges:" -NoNewLine
        Write-Host " No (This can interfere with scanning the entire drive)" -ForegroundColor Red 
    }
}

function Get-DiskSizeSpace {
    # Get disk size and free space
    $disk = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='$drive'" | Select-Object Size,FreeSpace
    $total = "{0:N0}" -f ($disk.Size / 1GB) + " GB"
    $free = "{0:N0}" -f ($disk.FreeSpace / 1GB) + " GB"
    $freeMB = "{0:N0}" -f ($disk.FreeSpace / 1MB) + " MB"
    " Target Drive: $drive"
    " Capacity: $total"
    " Free space:  $free / $freeMb"
}

function Get-RootFolderSizes($path) {
    " Please wait, this is going to take a moment..."
    " "
    " "
    # Get the names of the folders at the root of the drive
    $subDirectories = Get-ChildItem $path\ -Force -ErrorAction SilentlyContinue | Where-Object{($_.PSIsContainer)} | foreach-object{$_.Name}
    # Create the hash table to store the data
    $directoryTable = @{}
    # Loop through the directories
    foreach ($directory in $subDirectories) {
        $targetDir = $path + "\" + $directory
        $folderSize = (Get-ChildItem $targetDir -Recurse -File -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum 2> $null
        $folderSizeMB = "{0:N0}" -f ($folderSize / 1MB)
        $directoryTable.Add("$targetDir","$folderSizeMB")
    }
    # Label the table, verify there is data in it and display it
    $directoryTable = ($directoryTable.keys).GetEnumerator() | Select @{label='Folder';expression={$_}},@{label='FolderSizeInMB';expression={$directoryTable.$_}} | sort -Property Folder
    if ($directoryTable -eq $null) {
        " No folders found in this directory"
    } else {
        $directoryTable
    }
}

function Get-LargestFiles($path) {
        " "
        " Please wait, this is going to take a moment..."
        # Minimum file size
        $minFileSize = 10MB;
        # Search for specific file extensions - Default *.*
        $extension = "*.*";
        $largestFiles = Get-ChildItem -path $path\ -include $Extension -recurse -ErrorAction "SilentlyContinue" | ? { $_.GetType().Name -eq "FileInfo" } | where-Object {$_.Length -gt $minFileSize} | sort-Object -property length -Descending | Select-Object Name, @{Name="SizeInMB";Expression={ "{0:N0}" -f ($_.Length / 1MB)}},@{Name="LastWriteTime";Expression={$_.LastWriteTime}},@{Name="Path";Expression={$_.directory}} -first $filesToCount
        $largestFiles | Format-Table -property Name,Path,SizeInMB,LastWriteTime -AutoSize
}


function Get-SpecificDirFilesFolders {
    # Prompt user for optional additional directory scan
    " "
    $customDirScanInput = Read-Host -Prompt " Would you like to scan a specific directory? (Y or N)"
    if ($customDirScanInput -like "y") {
        # User entered yes
        $customDir = Read-Host -Prompt " What is the path to scan? (Ex - C:\Users)"
        " "
        "-------------------------------------------------------------------------------------------------------------------------------------------"
        " Folder Sizes - $customDir"
        "-------------------------------------------------------------------------------------------------------------------------------------------"
        " "
        Get-RootFolderSizes $customDir
        " "
        " "
        "-------------------------------------------------------------------------------------------------------------------------------------------"
        " Top $filesToCount Largest Files - $customDir"
        "-------------------------------------------------------------------------------------------------------------------------------------------"
        Get-LargestFiles $customDir
        "-------------------------------------------------------------------------------------------------------------------------------------------"
        Get-SpecificDirFilesFolders
    } elseif ($customDirScanInput -notlike "n") {
        Get-SpecificDirFilesFolders
    }
}


# Build Report
" "
"-------------------------------------------------------------------------------------------------------------------------------------------"
" Script info"
"-------------------------------------------------------------------------------------------------------------------------------------------"
" "
" Date: $time"
" Hostname: $hostname"
# Call the isUserAdmin function
isUserAdmin
" "
"-------------------------------------------------------------------------------------------------------------------------------------------"
" Drive info"
"-------------------------------------------------------------------------------------------------------------------------------------------"
# Call the Get-DiskSizeSpace function
" "
Get-DiskSizeSpace
" "
# Check to see if the specific directory scan switch was set, skip the two default root drive scans if it is
if ($specificDirScanSwitch -match "false") {
    "-------------------------------------------------------------------------------------------------------------------------------------------"
    " Root Folder Sizes"
    "-------------------------------------------------------------------------------------------------------------------------------------------"
    " "
    Get-RootFolderSizes $drive
    " "
    " "
    "-------------------------------------------------------------------------------------------------------------------------------------------"
    " Top $filesToCount Largest Files"
    "-------------------------------------------------------------------------------------------------------------------------------------------"
    Get-LargestFiles $drive
}
"-------------------------------------------------------------------------------------------------------------------------------------------"
" Custom scan"
"-------------------------------------------------------------------------------------------------------------------------------------------"
Get-SpecificDirFilesFolders
" "
"-------------------------------------------------------------------------------------------------------------------------------------------"

#Stop logging
Stop-Transcript
