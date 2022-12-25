$key = Get-Secret -Name YouTubeAPIKey -AsPlainText
$channelId = 'UCpIn7ox7j7bH_OFj7tYouOQ' #replace with yours

$part='contentDetails,snippet'


$urltofetch = "https://www.googleapis.com/youtube/v3/channels?forUsername=ntfaqguy&key=$($key)&part=contentDetails"
$response = Invoke-RestMethod -Uri $urltofetch

$uploadsPL = $response.items.contentdetails.relatedPlaylists.uploads

#Get count of every video, duration, likes and comments
#Get the playlist items
$items = @()
$response = $null

do {
    if($null -ne $response.nextPageToken) {
        $urltofetch = "https://www.googleapis.com/youtube/v3/playlistItems?part=$($part)&maxResults=50&&playlistId=$($uploadsPL)&key=$($key)&pageToken=$($response.nextPageToken)"
    }
    else {
        $urltofetch = "https://www.googleapis.com/youtube/v3/playlistItems?part=$($part)&maxResults=50&&playlistId=$($uploadsPL)&key=$($key)"
    }
    $response = Invoke-RestMethod -Uri $urltofetch
    $items += $response.items
} while($null -ne $response.nextPageToken)

$totalnumber = $items.length

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

$ts =  [timespan]::fromseconds($totaltime)
$totalTimeString = ("{0:dd}d:{0:hh}h:{0:mm}m:{0:ss}s" -f $ts)

#'{0:N0}' -f $number to make readable string
Write-Output "Number of Videos `t $('{0:N0}' -f $totalnumber) `nTotal Time `t`t $totalTimeString `nTotal Views `t`t $('{0:N0}' -f $totalviews) `nTotal Likes `t`t $('{0:N0}' -f $totallikes) `nTotal Comments `t`t $('{0:N0}' -f $totalcomments)"
