$pathToFiles = "C:\Users\john\OneDrive\Captions\Raw"
$pathForOutput = "C:\Users\john\OneDrive\Captions\Text"
$filterForFiles = "*.srt"

$files = Get-ChildItem -Path $pathToFiles -Filter $filterForFiles

foreach($file in $files)
{
    $outputfile = "$($pathForOutput)\$($file.name.replace('.srt','.txt'))"
    $fileContent = Get-Content -Path $file -Raw

    $updatedstring = $fileContent -replace '[\s\S]*?(?:\r\n|\r|\n)(\d{2}:\d{2}:\d{2}),\d{3} --> \d{2}:\d{2}:\d{2},\d{3}(?:\r\n|\r|\n)([\s\S]*?)(?:\r\n|\r|\n)',$('$2'+"`n")
    $updatedstring | out-file $outputfile
}