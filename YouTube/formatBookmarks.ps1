$samplestring = Get-Content S:\captures\subtitle.srt -Raw
$updatedstring = $samplestring -replace '[\s\S]*?(?:\r\n|\r|\n)(?(?!00:)(?:0*)(?<time>[0-9]+?:[0-9]{2}:[0-9]{2})|00:(?<time>[0-9]{2}:[0-9]{2})),\d{1,3} --> \d{2}:\d{2}:\d{2},\d{1,3}(?:\r\n|\r|\n)<b>(?<text>[\s\S]*?)</b>(?:\r\n|\r|\n)',$('${time} - ${text}'+"`n")
"00:00 - Introduction" | out-file S:\Captures\bookmarks.txt
$updatedstring | out-file S:\Captures\bookmarks.txt -Append


<#
1
00:00:46,899 --> 00:00:51,899
<b>WSL introduction</b>

to

00:46 - WSL introduction


[\s\S]*? - Capture as few times as possible as lazy any character (\s any whitespace, \S any non-whitesace). Just consuming anything until I get to what I want which is a newline then my time structure

(?:\r\n|\r|\n) - non-capture group any form of new line \r carriage return \n new line

Then a regular expression pattern that matches a time string in the format of hh:mm:ss except when it is 00:mm:ss.
The pattern uses a conditional construct (?(condition)yes-pattern|no-pattern) which tests whether the string does NOT start with 00: using a negative lookahead (?!00:).
If it does not start with 00: then it matches the time string using the named capture group (?<time>[0-9]{2}:[0-9]{2}:[0-9]{2}) that captures hours:minutes:seconds
If it starts with 00: then it matches the time string using the same named capture group but with a different pattern 00:(?<time>[0-9]{2}:[0-9]{2}) that just captures minutes:seconds.
The named capture group (?<time>) captures the matched time string for later use in replacement or other operations#>

<#
'02:05:34' -cmatch '(?(?!00:)(?<time>[0-9]{2}:[0-9]{2}:[0-9]{2})|00:(?<time>[0-9]{2}:[0-9]{2}))'
$matches
'00:05:34' -cmatch '(?(?!00:)(?<time>[0-9]{2}:[0-9]{2}:[0-9]{2})|00:(?<time>[0-9]{2}:[0-9]{2}))'
$matches

#Blank out leading zero in the hour.
#The (?:0*) matches zero or more leading zeros before the hour digits and (?:) creates a non-capturing group for this match
#Then in the time lazily (?) look for 0-9 one or more (+) times (+?) (since I don't want to take the leading 0 as part of the hour)
#                             Technically could just look for 1-9 in the hour since would never be 2 0's in this condition part :-)
'12:05:34' -cmatch '(?(?!00:)(?:0*)(?<time>[0-9]+?:[0-9]{2}:[0-9]{2})|00:(?<time>[0-9]{2}:[0-9]{2}))'
$matches
'02:05:34' -cmatch '(?(?!00:)(?:0*)(?<time>[0-9]+?:[0-9]{2}:[0-9]{2})|00:(?<time>[0-9]{2}:[0-9]{2}))'
$matches
#>
#,\d{1,3} -->  - just find a comma then between 1 and 3 digits then the right arrow characters
#then burns most of the rest of the string
#(?<text>[\s\S]*?)  - any character 0 (*) or more times lazily (?) (few times as possible). basically until the next string specified is found (everything between the b tags). Stores as named group 'text'
