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

    #content = 'You are a skilled editor and in charge of editorial content and you will be given a transcript from an interview, video essay, podcast or speech. Your job is to keep as much as possible from the original transcript and only make fixes for clarity or abbreviation, grammar, punctuation and format according to this general set of rules:- Beware that this transcript is auto generated from speech so it can contain wrong or misspelled words, make your best effort to fix those words, never change the overall structure of the transcript, just focus on correcting specific words, fixing punctuation and formatting.- Before doing your task be sure to read enough of the transcript so you can infer the overall context and make better judgements for the needed fixes.- The most important rule is to keep the original transcript mostly unaltered word for word and especially in tone. You are only allowed to make small editorial changes for punctuation, grammar, formatting and clarity.- You are allowed to modify the text only if in said context the subject correct themselves, so your job is to clean up the phrase for clarity and eliminate repetition.- If by any chance you have to replace a word, please ~~strike trough~~ the original word and add a memo emoji 📝 next to your predicted correction.- Use markdown for your output.Do not add any pre or post comments, only output the edited text'
    content = 'You are an AI assistant that will act like an editor making this transcript an easier to read manuscript. Edit this manuscript according to the Chicago Manual of Style. Focus on punctuation, grammar, syntax, typos, capitalization, formatting and consistency. Format all numbers according to the Chicago Manual of Style, spelling them out if necessary. Use italics and smart quotes and indent each paragraph. Do not add any pre or post comments, only output the edited text'
    }
    $messages += @{
    role = 'user'
    content = $Text
    }

    # Adjust these values to fine-tune completions
    $body = [ordered]@{
        messages = $messages
        max_tokens = 16384
        temperature = 0.3
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
    api_version = '2024-08-01-preview' # Current API at time of creation
    name        = 'gpt-4o' #This will correspond to the custom name you chose for your deployed model
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
