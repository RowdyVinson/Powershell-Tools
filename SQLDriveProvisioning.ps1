#Bring disks online
Get-Disk | Where-Object IsOffline –Eq $True | Set-Disk –IsOffline $False
#Find NVME Disk
$NVMeDisk = get-disk |where FriendlyName -like NVMe* | select number
#Find Smaller Perc Disk for TempDB
$TempDBDisk = get-disk |where FriendlyName -like DELL* |where PartitionStyle -like RAW | where FriendlyName -like DELL* | Where size -lt 2TB | select number
#Find larger Perc Disk for Data and backups
$BulkDataDisk = get-disk |where FriendlyName -like DELL* |where PartitionStyle -like RAW | where FriendlyName -like DELL* | Where size -gt 10TB | select number

#Make Drives (Partition, Letters, Names, and Folders)
$NVMeDisk | New-Partition -size 2TB -DriveLetter F 
Format-Volume -DriveLetter F -FileSystem NTFS -AllocationUnitSize 65536 -NewFileSystemLabel Data1 -Confirm:$false
cd f:\
md Data
$NVMeDisk | New-Partition -size 300GB -DriveLetter G
Format-Volume -DriveLetter G -FileSystem NTFS -AllocationUnitSize 65536 -NewFileSystemLabel Logs -Confirm:$false
cd G:\
md Logs
$TempDBDisk | New-Partition -UseMaximumSize -DriveLetter H
Format-Volume -DriveLetter H -FileSystem NTFS -AllocationUnitSize 65536 -NewFileSystemLabel TempDB -Confirm:$false
cd H:\
md TempDB
$BulkDataDisk | New-Partition -size 2TB -DriveLetter J 
Format-Volume -DriveLetter J -FileSystem NTFS -AllocationUnitSize 65536 -NewFileSystemLabel Data2 -Confirm:$false
cd J:\
md Data
md Instance
$BulkDataDisk | New-Partition -size 2TB -DriveLetter V 
Format-Volume -DriveLetter V -FileSystem NTFS -AllocationUnitSize 65536 -NewFileSystemLabel Backup -Confirm:$false
cd V:\
md Backup