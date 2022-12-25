#I'm using native secret management of PS to get my YouTube API key
#Set-Secret -Name YouTubeAPIKey -Secret "YOURKEY" #to set
$key = Get-Secret -Name YouTubeAPIKey -AsPlainText
$channelId = 'UCpIn7ox7j7bH_OFj7tYouOQ' #replace with yours

$part='contentDetails,snippet'

#get a list of all playlists for my channel
$urltofetch = "https://www.googleapis.com/youtube/v3/playlists?part=$($part)&maxResults=50&key=$($key)&channelId=$($channelId)"
$response = Invoke-RestMethod -Uri $urltofetch

$playlists = $response.items

foreach($playlist in $playlists) {

    #Get playlist details
    $urltofetch = "https://www.googleapis.com/youtube/v3/playlists?part=$($part)&maxResults=50&id=$($playlist.id)&key=$($key)"
    $response = Invoke-RestMethod -Uri $urltofetch

    $playlistTitle = $response.items[0].snippet.title
    $playlistCount = $response.items[0].contentDetails.itemCount

    $playlist | Add-Member NoteProperty "title" $playlistTitle
    $playlist | Add-Member NoteProperty "itemCount" $playlistCount

    $items = @()
    $response = $null

    #Get the playlist items
    do {
        if($null -ne $response.nextPageToken) {
            $urltofetch = "https://www.googleapis.com/youtube/v3/playlistItems?part=$($part)&maxResults=50&&playlistId=$($playlist.id)&key=$($key)&pageToken=$($response.nextPageToken)"
        }
        else {
            $urltofetch = "https://www.googleapis.com/youtube/v3/playlistItems?part=$($part)&maxResults=50&&playlistId=$($playlist.id)&key=$($key)"
        }
        $response = Invoke-RestMethod -Uri $urltofetch
        $items += $response.items
    } while($null -ne $response.nextPageToken)

    $totalnumber = $items.length
    if($playlistCount -ne $totalnumber) {
        Write-Error "Playlist count does not match the number of items for $($playlistTitle)"
        exit 1
    }

    $totaltime = 0
    $totallikes = 0
    $totalviews = 0
    $totalcomments = 0

    #Get each video detail
    foreach($item in $items){
        $urltofetch = "https://www.googleapis.com/youtube/v3/videos?id=$($item.contentDetails.videoId)&key=$key&part=contentDetails,statistics"
        $response = Invoke-RestMethod -Uri $urltofetch
        #want $response.items.contentdetails.duration
        $durseconds = [System.Xml.XmlConvert]::ToTimeSpan($response.items[0].contentDetails.duration).TotalSeconds
        $item | Add-Member NoteProperty "duration" $durseconds
        $durstr = [System.Xml.XmlConvert]::ToTimeSpan($response.items[0].contentDetails.duration).ToString("hh\:mm\:ss")
        $item | Add-Member NoteProperty "durationStr" $durstr
        $item | Add-Member NoteProperty "viewCount" $response.items[0].statistics.viewCount
        $item | Add-Member NoteProperty "likeCount" $response.items[0].statistics.likeCount
        $item | Add-Member NoteProperty "commentCount" $response.items[0].statistics.commentCount
        $totaltime += $item.duration
        $totallikes += $item.likeCount
        $totalviews += $item.viewCount
        $totalcomments += $item.commentCount
    }

    #Convert the total seconds to hours, minutes, seconds
    $durstr = [timespan]::FromSeconds($totaltime).ToString("dd\:hh\:mm\:ss")

    $playlist | Add-Member NoteProperty "totalDuration" $durStr
    $playlist | Add-Member NoteProperty "totalViews" $totalviews
    $playlist | Add-Member NoteProperty "totalLikes" $totallikes
    $playlist | Add-Member NoteProperty "totalComments" $totalcomments
}

$playlists | Sort-Object totalViews -Descending | Format-Table title, itemCount, totalDuration, totalViews, totalLikes, totalComments -autosize
