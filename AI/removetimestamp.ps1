<#
Create edited versions of transcripts
John Savill, https://savilltech.net

#>

#Main body of function

$pathToFiles = "C:\Users\john\OneDrive\Captions\Raw"
$pathForOutput = "C:\Users\john\OneDrive\Captions\Raw"
$filterForFiles = "*.srt"

$files = Get-ChildItem -Path $pathToFiles -Filter $filterForFiles

foreach($file in $files)
{
    $outputfile = "$($pathForOutput)\$($file.name)"
    $outputfile = $outputfile.Replace('.srt','.txt') #make a txt file

    $fileContent = Get-Content -Path $file -raw #Need raw for the RegEx

    Write-Output "Working on file $($file.Name)"

    #Check if srt file and if so remove all the timestamps
    if($file.Extension -eq '.srt')
    {
        $fileContent = $fileContent -replace '[\s\S]*?(?:\r\n|\r|\n)(\d{2}:\d{2}:\d{2}),\d{3} --> \d{2}:\d{2}:\d{2},\d{3}(?:\r\n|\r|\n)([\s\S]*?)(?:\r\n|\r|\n)',$('$2'+"`n")
    }

    $fileContent | Out-File -FilePath $outputfile #-Append if wanted to add to existing
}
