#This is taken from the RegEx\RegExDemos.ps1 example
$samplestring = Get-Content S:\captures\subtitle.srt -Raw
$updatedstring = $samplestring -replace '[\s\S]*?(?:\r\n|\r|\n)(\d{2}:\d{2}:\d{2}),\d{3} --> \d{2}:\d{2}:\d{2},\d{3}(?:\r\n|\r|\n)([\s\S]*?)(?:\r\n|\r|\n)',$('$1 - $2'+"`n")
$updatedstring | out-file S:\Captures\bookmarks.txt