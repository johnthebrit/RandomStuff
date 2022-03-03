$key = Get-Secret -Name YouTubeAPIKey -AsPlainText
$channelId = 'UCpIn7ox7j7bH_OFj7tYouOQ' #replace with yours

$outputname = 's:\scratch\videos.html'

$daysToFetch = 7
#Midnight start of both days
$endDate = (Get-Date).date.AddDays(1)
$startDate = (Get-Date).date.AddDays(-($daysToFetch-1))

$urltofetch = "https://www.googleapis.com/youtube/v3/search?key=$key&channelId=$channelId&part=snippet,id&order=date&maxResults=20"
$response = Invoke-RestMethod -Uri $urltofetch
$videoItems = $response.items
$videoItemsInRange = $videoItems | Where-Object {([datetime]$_.snippet.publishedAt -ge $startDate) -and ([datetime]$_.snippet.publishedAt -le $endDate)} |
    Select-Object @{Name='id';Expression={$_.id.videoId}}, @{Name='title';Expression={$_.snippet.title}}, @{Name="date";Expression={[datetime]$_.snippet.publishedAt}}, @{Name='link';Expression={"https://youtu.be/$($_.id.videoId)"}}

[array]::Reverse($videoItemsInRange) #oldest first

$NewVideos = "<ul>"
foreach($videoItem in $videoItemsInRange)
{
    $NewVideos += "<li>$($videoItem.title) - <a href=`"$($videoItem.link)`">$($videoItem.link)</a></li>"
}
$NewVideos +="</ul>"

Set-Content -Path $outputname -Value $NewVideos