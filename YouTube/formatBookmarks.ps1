#This is taken from the RegEx\RegExDemos.ps1 example
$samplestring = Get-Content S:\captures\subtitle.srt -Raw
$updatedstring = $samplestring -replace '[\s\S]*?(?:\r\n|\r|\n)(?(?!00:)(?:0*)(?<time>[0-9]+?:[0-9]{2}:[0-9]{2})|00:(?<time>[0-9]{2}:[0-9]{2})),\d{1,3} --> \d{2}:\d{2}:\d{2},\d{1,3}(?:\r\n|\r|\n)<b>(?<text>[\s\S]*?)</b>(?:\r\n|\r|\n)',$('${time} - ${text}'+"`n")
$updatedstring | out-file S:\Captures\bookmarks.txt


<#
Named group for time
'02:05:34' -cmatch '(?(?!00:)(?<time>[0-9]{2}:[0-9]{2}:[0-9]{2})|00:(?<time>[0-9]{2}:[0-9]{2}))'
$matches
Blank out leading zero. We look for 0 or more (*) zeros before the time capture. Then in the time lazily (+?) look for 0-9 multiple times
'12:05:34' -cmatch '(?(?!00:)(?:0*)(?<time>[0-9]+?:[0-9]{2}:[0-9]{2})|00:(?<time>[0-9]{2}:[0-9]{2}))'
$matches
#>