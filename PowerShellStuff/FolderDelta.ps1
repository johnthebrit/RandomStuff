$folder1 = "S:\Scratch\v20"
$folder2 = "S:\Scratch\v20.1"
$folder3 = "S:\Scratch\changes"

$folder1hashcontent = Get-ChildItem -path $folder1 -Recurse | Where-Object { -not $_.PsIsContainer } | ForEach-Object  {Get-FileHash –Path $_.FullName}
$folder2hashcontent = Get-ChildItem -path $folder2 -Recurse | Where-Object { -not $_.PsIsContainer } | ForEach-Object  {Get-FileHash –Path $_.FullName}

$differences = (Compare-Object $folder1hashcontent $folder2hashcontent -Property Hash -PassThru)

foreach ($difference in $differences)
{
    $filepath = $difference.path
    if($filepath.StartsWith($folder2))
    {
        $relativepath = $filepath.Substring($folder2.Length)
        $targetpath = "$folder3$relativepath"
        Write-Output "$filepath to $targetpath"
        $targetfolder = Split-Path $targetpath -Parent
        if (!(Test-Path -path $targetfolder)) {New-Item $targetfolder -Type Directory}
        Copy-Item $filepath -Destination $targetpath
    }
}