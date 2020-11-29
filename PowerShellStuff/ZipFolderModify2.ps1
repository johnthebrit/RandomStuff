$filedir = "S:\Scratch2" #folder with current zip files
$items = Get-ChildItem -Path $filedir

foreach($item in $items)
{
    Compress-Archive -Path "$($item.FullName)\*" -DestinationPath "$($item.FullName).zip" -Update
}