function Send-GPTForCompletion
{
    param(
        [array]$messages
    )

    $endpoint = $env:AZURE_OPENAI_ENDPOINT
    $deployment_name = $env:CHAT_COMPLETIONS_DEPLOYMENT_NAME

    if (-not $endpoint) {
        throw "Environment variable AZURE_OPENAI_ENDPOINT not found."
    }

    if (-not $deployment_name) {
        throw "Environment variable CHAT_COMPLETIONS_DEPLOYMENT_NAME not found."
    }

    $ai_url = $endpoint + "openai/deployments/" + $deployment_name + "/chat/completions?api-version=2024-06-01"

    #Get an Entra ID token
    $token = Get-AzAccessToken -ResourceUrl "https://cognitiveservices.azure.com/" #need a token for cognitive services
    #Construct authentication header
    $headers = @{
        'Content-Type'='application/json'
        'Authorization'='Bearer ' + $token.Token
    }

    $body = @{
        messages = $messages
        max_tokens = 2048
        temperature = 0.3
    } | ConvertTo-Json

    try {
        $resp = Invoke-RestMethod -Uri $ai_url -Method Post -Header $headers -Body $body
    }
    catch {
        Write-Host "An error occurred: $($_.Exception.Message)" -ForegroundColor Red
        exit 1 #exit with error occured
    }

    return $resp.choices[0].message.content
}

<#
 .Synopsis
  Returns the completion from GPT based on the string given.

 .Description
  Returns the completion from GPT based on the string given including a limited message history.
  You must have defined two environment variables and authenticated to Azure.
  $env:CHAT_COMPLETIONS_DEPLOYMENT_NAME = "gpt-4o"
  $env:AZURE_OPENAI_ENDPOINT = "https://yourendpoint.openai.azure.com/"

 .Parameter Clear
  Clears the message history.

 .Parameter UseClipboard
  Adds current clipboard content to the user prompt sent to the LLM.

 .Parameter PromptStringArray
  The user prompt.

 .Example
   # Clear the memory and ask the capital of the US
   Get-GPTCompletion -clear what is the capital of the United States

 .Example
   # Includes the clipboard content and then the users request
   Get-GPTCompletion -UseClipboard what does this error mean?

 .Example
   # Regular question that would include any memory
   Get-GPTCompletion what about the UK
#>
function Get-GPTCompletion
{
    [CmdletBinding()]
    Param(
        [switch]$Clear,
        [switch]$UseClipboard,
        [Parameter(Mandatory=$true, ValueFromRemainingArguments=$true)]
        [string[]]$PromptStringArray
    )

    process {

        #Where are history will be stored
        $filePath = Join-Path -Path $env:LocalAppData -ChildPath "savgpt\gptcompletedata.json"
        $folderPath = Split-Path -Path $filePath -Parent

        $messages = @() #Create an empty array
        $historyToKeep = 5

        #Check if our path exists and ifnot create it
        if (-not (Test-Path -Path $folderPath))
        {
            New-Item -Path $folderPath -ItemType Directory | Out-Null
        }

        if (-not (Test-Path -Path $filePath))
        {
            # The does not exist so treat as if clear was selected
            $Clear = $true
        }

        #If no history set the system message
        if ($Clear) {
            $messages += [ordered]@{
                role = 'system'
                content = 'You are an AI assistant that will help answer questions.'
                }
        }
        else {
            #Load in the history from JSON file
            $messages = Get-Content -Path $filePath | ConvertFrom-Json
        }

        $messageCount = $messages.Count
        #Do we need to trim messages based on history desired memory
        if($messageCount -gt (($historyToKeep*2)+1))
        {
            Write-Debug "Trimming history"
            #Need to trim the history and only keep the newest max entries
            $newMessages = @()
            $newMessages += $messages[0] #get the system message

            $startingInstance = $messageCount - (($historyToKeep)*2) #position to start
            $newMessages += $messages[$startingInstance..$($messageCount - 1)] #copy all remaining
            $messages = $newMessages #replace the content with the new message array
        }

        # Combine the string array into a single string
        $PromptString = $PromptStringArray -join ' '

        #If want the clipboard add to the user prompt as additional information
        if ($UseClipboard) {
            $clipboardContent = Get-Clipboard
            $PromptString += "`nADDITIONAL INFORMATION:`n$clipboardContent"
        }

        #We use ordered to keep role in front of content
        $messages += [ordered]@{
            role = 'user'
            content = $PromptString
            }

        $resp = Send-GPTForCompletion $messages

        if($null -ne $resp)
        {
            #add to history
            $messages += [ordered]@{
                role = 'assistant'
                content = $resp
                }

            write-output "> $resp"

            #Output for history
            $messages | ConvertTo-Json -Depth 5 | Set-Content -Path $filePath
        }
        else
        {
            write-output "> NO RESPONSE RECEIVED"
        }
    }
}
Export-ModuleMember -Function Get-GPTCompletion