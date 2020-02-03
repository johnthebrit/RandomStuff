function Install-Patch
{
    <#
    .SYNOPSIS
        Patches a WIM or VHD file
    .DESCRIPTION
        Applies downloaded patches to a VHD or WIM file
    .NOTES
        File Name: Install-Patch.psm1
        Author: John Savill
        Requires: Tests on PowerShell 3 on Windows Server 2012
        Copyright (c) 2013 John Savill
    .LINK
        http://www.savilltech.com
    .PARAMETER updateTargetPassed
        File (WIM, VHD or VHDX) to be patched
    .PARAMETER patchpath
        Path containing the updates
    .EXAMPLE
        Install-Patch d:\files\test.vhd d:\updates\win2012\
        Install-Patch d:\files\install.wim:4 d:\updates\win2012\
    #>

    [cmdletbinding()]
    Param(
    [Parameter(ValuefromPipeline=$false,Mandatory=$true)][string]$updateTargetPassed,
    [Parameter(ValuefromPipeline=$false,Mandatory=$true)][string]$patchpath)

    #$updateTargetPassed = "G:\Temp\Win2012DatacenterRTM.vhdx"
    #or
    #$updateTargetPassed = "d:\sources\install.wim:4"
    #$patchpath = "D:\software\Windows 2012 Updates\"

    if(($updateTargetPassed.ToLower().Contains(".vhd")) -eq $true) # if its VHD or VHDX. Contains is case sensitive so have to convert to lower when comparing 
    {
        $isVHD = $true
    }
    else
    {
        $isVHD = $false
    }

    if($isVHD)
    {
        $updateTarget=$updateTargetPassed
        if ((Test-Path $updateTarget) -eq $false) #if not found
        {
            write-output "Source not found ($updateTarget)"
            break
        }
        else
        {
            mount-vhd -path $updateTarget
            $disks = Get-CimInstance -ClassName Win32_DiskDrive | where Caption -eq "Microsoft Virtual Disk"            
            foreach ($disk in $disks)
            {            
                $vols = Get-CimAssociatedInstance -CimInstance $disk -ResultClassName Win32_DiskPartition             
                foreach ($vol in $vols)
                {            
                    $updatedrive = Get-CimAssociatedInstance -CimInstance $vol -ResultClassName Win32_LogicalDisk |            
                    where VolumeName -ne 'System Reserved'          
                }            
            }
            $updatepath = $updatedrive.DeviceID + "\"
        }
    }
    if(!$isVHD)  #its a WIM file
    {
        #Need to extract the WIM part and the index
        #extract file name and the index number
        $updateTargetPassedSplit = $updateTargetPassed.Split(":")
        if($updateTargetPassedSplit.Count -eq 3) #one for drive letter, one for folder and one for image number so would have been two colons in it c:\temp\install.wim:4
        {
            $updateTarget = $updateTargetPassedSplit[0] + ":" + $updateTargetPassedSplit[1]   #There are two colons. The first is drive letter then the folder!
            $updateTargetIndex = $updateTargetPassedSplit[2]
            $updatepath = "c:\wimmount\"

            #check if exists and if not create it
            if ((Test-Path $updatepath) -eq $false) #if not found
            {
                Write-Host "Creating folder " + $updatepath
                New-Item -Path $updatepath -ItemType directory
                #could have also used [system.io.directory]::CreateDirectory($updatepath)
            }

            # Mount it as folder
            #dism /get-wiminfo /wimfile:install.wim
            dism /Mount-Wim /wimfile:$updateTarget /index:$updateTargetIndex /mountdir:$updatepath 
        }
        else
        {
            write-output "Missing index number for WIM file. Example: c:\temp\install.wim:4"
            break
        }
    }

    # For WIM or VHD
    $updates = get-childitem -path $patchpath -Recurse | where {($_.extension -eq ".msu") -or ($_.extension -eq ".cab")} | select fullname
    foreach($update in $updates)
    {
        write-debug $update.fullname
        $command = "dism /image:" + $updatepath + " /add-package /packagepath:'" + $update.fullname + "'"
        write-debug $command
        Invoke-Expression $command
    }

    $command = "dism /image:" + $updatepath + " /Cleanup-Image /spsuperseded"
    Invoke-Expression $command

    if($isVHD)
    {
        dismount-vhd -path $updateTarget -confirm:$false
    }
    else
    {
        dism /Unmount-Wim /mountdir:$updatepath /commit 
        #dism /Unmount-Wim /mountdir:$updatepath /discard
    }
}