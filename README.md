# Get-LargestFiles.ps1

You can find my blog post here:
https://robwillis.info/2021/04/powershell-script-quickly-find-the-largest-files/

This script will help locate the largest files on the specified drive, while also displaying
the sizes of the folders in the root directory.

The script will execute in the following order:
– Create a log file, default log name is Get-LargestFiles-output.txt
– Gather the date, hostname, and current privileges
– Gather the basic drive info, capacity and free space (Default drive is C:)
– Gather the root folder sizes
– Find the top x largest files on the drive (Default count is 10)
– Optional scan of a specific directory

# Usage

Basic usage:

C:\PS> PowerShell.exe -ExecutionPolicy Bypass .\Get-LargestFiles.ps1

Specify a different drive and change the amount of files to show:

C:\PS> PowerShell.exe -ExecutionPolicy Bypass .\Get-LargestFiles.ps1 -c “25” -d “d:”

Skip the default root drive scans and only scan a specific directory (you will be prompted for the path):

C:\PS> PowerShell.exe -ExecutionPolicy Bypass .\Get-LargestFiles.ps1 -s
