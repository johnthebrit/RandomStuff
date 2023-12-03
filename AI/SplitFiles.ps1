$pathToFiles = "C:\Users\john\OneDrive\Captions\ForIndexing"
$filterForFiles = "*.txt"
[int]$maxCharPerDoc = 64000
$searchSequence = "`n`n"
$deleteOriginal = $true

$files = Get-ChildItem -Path $pathToFiles -Filter $filterForFiles

foreach($file in $files)
{
    $fileContent = Get-Content -Path $file -Raw

    if($fileContent.Length -gt $maxCharPerDoc)
    {
        #Need to split the file
        [int]$chunkNumber = 1

        while($fileContent -ne $null)
        {
            $outputFileName = "$($file.DirectoryName)\$([System.IO.Path]::GetFileNameWithoutExtension($file))-Part$($chunkNumber)$($file.Extension)"

            if($fileContent.Length -gt $maxCharPerDoc)
            {
                # Get the substring from start to the specified position
                $substring = $fileContent.Substring(0, $maxCharPerDoc)

                # Reverse the substring
                $charArray = $substring.ToCharArray()
                [Array]::Reverse($charArray)
                $reversedSubstring = -join $charArray

                # Find the first occurrence of two newlines which in my files is between paragraphs
                $indexInReversed = $reversedSubstring.IndexOf($searchSequence)

                if ($indexInReversed -ne -1) {
                    # Calculate the original position
                    $originalIndex = $maxCharPerDoc - $indexInReversed - 2
                    $fileContent.Substring(0, $originalIndex) | Out-File -FilePath $outputFileName
                    $fileContent=$fileContent.Substring($originalIndex+2) #set the content to what is left
                    $chunkNumber++
                }
                else
                {
                    Write-Host "*** No occurrence of two newlines found before position $maxCharPerDoc for $($file.name) ***"
                    $fileContent = $null #we are now broken
                }
            }
            else
            {
                $fileContent | Out-File -FilePath $outputFileName
                $fileContent = $null
            }
        }

        if($deleteOriginal)
        {
            Remove-Item $file
        }
    }
}