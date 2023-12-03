<#
Create edited versions of transcripts
John Savill, https://savilltech.net

To get resource endpoint and key
$OpenAIObj = Get-AzCognitiveServicesAccount -ResourceGroupName RG-OpenAI -Name SavillTech-OpenAI
$OpenAIObj.endpoint
$OpenAIObjKeys = Get-AzCognitiveServicesAccountKey -ResourceGroupName RG-OpenAI -Name SavillTech-OpenAI
$OpenAIObjKeys.Key1

I store them as secrets in the credential store to make it easy!
Set-Secret -Name OpenAIKey -Secret "SECRET" -Vault CredManStore
Set-Secret -Name OpenAIEndpoint -Secret "ENDPOINT" -Vault CredManStore

#Could also have set as environment variables then use these later in array
#$Env:AZURE_OPENAI_KEY = 'KEYHERE'
#$Env:AZURE_OPENAI_ENDPOINT = 'ENDPOINTHERE'
#>


function Edit-TextSegment {
    param(
        [string]$Text
    )

    $messages = @()
    $messages += @{
    role = 'system'
    content = 'You are an AI assistant that will act like an editor making this transcript an easier to read manuscript. Edit this manuscript according to the Chicago Manual of Style. Focus on punctuation, grammar, syntax, typos, capitalization, formatting and consistency. Format all numbers according to the Chicago Manual of Style, spelling them out if necessary. Use italics and smart quotes and indent each paragraph.'
    }
    $messages += @{
    role = 'user'
    content = $Text
    }

    # Adjust these values to fine-tune completions
    $body = [ordered]@{
        messages = $messages
        max_tokens = 4096
        temperature = 0.7
        top_p = 0.7
    } | ConvertTo-Json

    # Send a request to generate an answer
    $url = "$($openai.api_base)/openai/deployments/$($openai.name)/chat/completions?api-version=$($openai.api_version)"

    $response = Invoke-RestMethod -Uri $url -Headers $headers -Body $body -Method Post -ContentType 'application/json'
    Write-Debug $response
    return $response.choices.message.content
}


#Main body of function

$CheckForPeriod = $false

$pathToFiles = "C:\Users\john\OneDrive\Captions\Raw"
$pathForOutput = "C:\Users\john\OneDrive\Captions\Output"
$filterForFiles = "*.srt"
[int]$wordLimit = 2000 # will process around 2000 words (next period character) at a time. Remember tokens will be more than words

$openai = @{
    api_key     = (Get-Secret -Name OpenAIKey -AsPlainText) # one of the 2 keys for your OpenAI resource
    api_base    = (Get-Secret -Name OpenAIEndpoint -AsPlainText) # your endpoint, e.g. https://RESOURCE_NAME.openai.azure.com/
    api_version = '2023-05-15' # Curren API at time of creation
    name        = 'gpt4' #This will correspond to the custom name you chose for your deployed model
 }

 $headers = [ordered]@{
    'api-key' = $openai.api_key
 }

$files = Get-ChildItem -Path $pathToFiles -Filter $filterForFiles

foreach($file in $files)
{
    $outputfile = "$($pathForOutput)\$($file.name)"
    $outputfile = $outputfile.Replace('.srt','.txt') #make a txt file

    $fileContent = Get-Content -Path $file -raw #Need raw for the RegEx
    $generatedContent = ""

    Write-Output "Working on file $($file.Name)"

    #Check if srt file and if so remove all the timestamps
    if($file.Extension -eq '.srt')
    {
        $fileContent = $fileContent -replace '[\s\S]*?(?:\r\n|\r|\n)(\d{2}:\d{2}:\d{2}),\d{3} --> \d{2}:\d{2}:\d{2},\d{3}(?:\r\n|\r|\n)([\s\S]*?)(?:\r\n|\r|\n)',$('$2'+"`n")
    }

    $words = $fileContent -split '\s+'
    $segment = ""
    $wordCount = 0

    # Loop through words
    foreach ($word in $words)
    {
        $segment += "$word "
        $wordCount++

        # Check if word limit is reached
        if ($wordCount -ge $WordLimit) {
            # Find the nearest period or just stop if not checking for period characters.
            if (($word -match "\.") -or !$CheckForPeriod)
            {
                # Output the segment
                $segment = $segment.Trim()
                Write-Debug "Number of words was $wordCount"
                $generatedContent += Edit-TextSegment($segment)

                # Reset for next segment
                $segment = ""
                $wordCount = 0
            }
        }
    }

    # Output any remaining text
    if ($segment -ne "")
    {
        $segment = $segment.Trim()
        Write-Debug "Number of words was $wordCount"
        $generatedContent +=  Edit-TextSegment($segment)
    }

    #output to file
    $wordsinFinalCount = ($generatedContent -split '\s+').Count
    Write-Output "Original word count $($words.Count), edited count $($wordsinFinalCount)"
    $generatedContent | Out-File -FilePath $outputfile #-Append if wanted to add to existing
}
