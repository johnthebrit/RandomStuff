#Perf Test Command
c:\tools\diskspd -t2 -o32 -b4k -r4k -w0 -d10 -Sh -D -L -c1G e:\test\IO.dat

#Look at all disks
Get-AzDisk | Select-Object -Property Name, ResourceGroupName,DiskSizeGB,@{Name = 'DiskType'; Expression = {$_.sku.name}}

#Getting a SAS to a managed disk to see really is a storage account behind it!
$diskSas = Grant-AzDiskAccess -ResourceGroupName 'RG-LiveResize' -DiskName 'disk1' -DurationInSecond 60 -Access 'Read'
$diskSas
Revoke-AzDiskAccess -ResourceGroupName 'RG-LiveResize' -DiskName 'disk1'

#Change an ultra disk IOPS dynamically, i.e. the VM can be running and connected
$DiskUpdateconfig = New-AzDiskUpdateConfig -DiskIOPSReadWrite $iops
Update-AzDisk -ResourceGroupName $RGName -DiskName $SiskName -DiskUpdate $DiskUpdateconfig
