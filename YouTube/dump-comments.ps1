#I'm using native secret management of PS to get my YouTube API key
#Set-Secret -Name YouTubeAPIKey -Secret "YOURKEY" #to set
$key = Get-Secret -Name YouTubeAPIKey -AsPlainText
$channelId = 'UCpIn7ox7j7bH_OFj7tYouOQ' #replace with yours

$part='id,snippet'

$items = @()
$response = $null

do {
    if($null -ne $response.nextPageToken) {
        $urltofetch = "https://www.googleapis.com/youtube/v3/comments?part=$($part)&key=$($key)&maxResults=100&channelId=$($channelId)&pageToken=$($response.nextPageToken)"
    }
    else {
        $urltofetch = "https://www.googleapis.com/youtube/v3/comments?part=$($part)&key=$($key)&maxResults=100&channelId=$($channelId)"
    }
    $response = Invoke-RestMethod -Uri $urltofetch
    $items += $response.items
} while($null -ne $response.nextPageToken)
