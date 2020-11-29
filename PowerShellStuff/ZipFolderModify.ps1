
$workingdir = "S:\working" #empty folder
$newdir = "s:\Scratch2" #empty folder where new files will be created
$filedir = "S:\Scratch" #folder with current zip files

$items = Get-ChildItem -Path $filedir

#Creates copy of all zips but moves files from the single folder to root
foreach($item in $items)
{
    Expand-Archive -Path $item.FullName -DestinationPath $workingdir
    $folder = Get-ChildItem $workingdir
    Compress-Archive -Path "$($folder.FullName)\*" -DestinationPath "$newdir\$($item.name)" -Update
    Remove-Item "$workingdir\*" -Recurse -Force
}