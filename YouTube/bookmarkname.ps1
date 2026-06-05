# Paths
$srtPath = "s:\Captures\Subtitle.srt"
$namesPath = "s:\Captures\bookmarknames.txt"
$outputPath = "s:\Captures\NamedSubtitle.srt"
$bookmarksOutPath = Join-Path (Split-Path $outputPath) "bookmarks.txt"

function Format-BookmarkTime {
    param(
        [Parameter(Mandatory)]
        [string]$SrtTimestamp
    )

    # SRT timestamps are like: 00:00:27,000
    $normalized = $SrtTimestamp -replace ',', '.'
    $ts = [TimeSpan]::Parse($normalized)

    $totalHours = [int][Math]::Floor($ts.TotalHours)
    if ($totalHours -gt 0) {
        return ('{0:00}:{1:00}:{2:00}' -f $totalHours, $ts.Minutes, $ts.Seconds)
    }

    return ('{0:00}:{1:00}' -f [int]$ts.TotalMinutes, $ts.Seconds)
}

# Load files
$srt = Get-Content $srtPath
$names = Get-Content $namesPath
$nameIndex = 0

$bookmarkLines = New-Object System.Collections.Generic.List[string]
$bookmarkLines.Add('00:00 - Introduction')
$currentStartTimestamp = $null

# Replace only the <b>...</b> line, keep everything else
# Also emit bookmarks.txt as: mm:ss - Title (or hh:mm:ss for long videos)
$updated = foreach ($line in $srt) {
    if ($line -match '^(?<start>\d{2}:\d{2}:\d{2},\d{3})\s*-->\s*\d{2}:\d{2}:\d{2},\d{3}') {
        $currentStartTimestamp = $Matches['start']
        $line
        continue
    }

    if ($line -match "<b>.*?</b>") {
        if ($nameIndex -lt $names.Count) {
            $title = $names[$nameIndex]
            $replacement = "<b>$title</b>"

            if ($null -ne $currentStartTimestamp) {
                $bookmarkLine = "$(Format-BookmarkTime $currentStartTimestamp) - $title"
                if ($bookmarkLine -ne '00:00 - Introduction') {
                    $bookmarkLines.Add($bookmarkLine)
                }
            }

            $nameIndex++
            $replacement
        } else {
            $line  # No more names; leave unchanged
        }
        continue
    }

    $line  # Non-bookmark lines stay exactly the same
}

# Save output
$updated | Set-Content $outputPath
$bookmarkLines | Set-Content -Encoding utf8 $bookmarksOutPath

Write-Host "Updated SRT written to $outputPath"
Write-Host "Bookmarks written to $bookmarksOutPath"
