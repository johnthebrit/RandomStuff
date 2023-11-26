$apiKey = Get-Secret -Name YouTubeAPIKey -AsPlainText
$channelId = Get-Secret -Name YouTubeChannelID -AsPlainText #replace with yours

# Function to Get Video IDs from Channel
function Get-VideoIdsFromChannel {
    param (
        [string]$channelId,
        [string]$apiKey
    )

    $videoIds = @()
    $nextPageToken = $null

    do {
        # YouTube API URL to list videos with pagination support
        $url = "https://www.googleapis.com/youtube/v3/search?key=$apiKey&channelId=$channelId&part=id,snippet&order=date&maxResults=50&pageToken=$nextPageToken"

        # Make the API request
        $response = Invoke-RestMethod -Uri $url -Method Get

        # Add video IDs to the list
        $videoIds += $response.items
        #$response.items.id.videoId | ForEach-Object { $videoIds += $_ }

        # Update nextPageToken for the next iteration
        $nextPageToken = $response.nextPageToken
    }
    while ($nextPageToken -ne $null)

    # Return all video IDs
    return $videoIds
}

# Function to Download Subtitles
function Download-Subtitles {
    param (
        [string]$videoId,
        [string]$videoTile,
        [string]$apiKey
    )

    #FIX THIS
    #Get the video detail for proper title
    $outputFileName = "$videoID - $videoTitle.srt"

    # Construct URL for subtitles
    #Need list of subtitles
    $urltofetch = "https://www.googleapis.com/youtube/v3/captions?videoId=$($videoId)&key=$apiKey&part=snippet,id"
    $response = Invoke-RestMethod -Uri $urltofetch
    $captionID = $response.items[0].id

    #HAVE TO AUTH HERE!!!!
    $subtitleUrl = "https://www.googleapis.com/youtube/v3/captions/$captionID&fmt=srt"
    $subtitleResponse = Invoke-WebRequest -Uri $subtitleUrl

    # Save the subtitle file
    $subtitleResponse.Content | Out-File $outputFileName
}

# Main Script
#$videoIds = Get-VideoIdsFromChannel -channelId $channelId -apiKey $apiKey
$videoIds | ConvertTo-Json -Depth 5 | Out-File -FilePath "S:\Captions\videoids.json"

$videoIds = Get-Content -Path "S:\Captions\videoids.json" | ConvertFrom-Json
$videoIdPosition = [int](Get-Content -Path "S:\Captions\videoidposition.txt")
$videoProcessedCount = 0
$batchSize = 20

for ($i = $videoIdPosition; $i -lt ($videoIdPosition+$batchSize); $i++) {
    Write-Output "Processing video $i, $($videoIds[$i])"
    Download-Subtitles -videoId $videoIds[$i].id.videoid -videoTitle $videoIds[$i].snippet.title -apiKey $apiKey
}
$videoIdPosition = $i

$videoIdPosition | Out-File -FilePath "S:\Captions\videoidposition.txt"
