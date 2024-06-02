import os
from openai import AzureOpenAI
from azure.identity import DefaultAzureCredential, get_bearer_token_provider

endpoint = os.environ["AZURE_OPENAI_ENDPOINT"]
deployment = os.environ["CHAT_COMPLETIONS_DEPLOYMENT_NAME"]

token_provider = get_bearer_token_provider(DefaultAzureCredential(), "https://cognitiveservices.azure.com/.default")

client = AzureOpenAI(
    azure_endpoint=endpoint,
    azure_ad_token_provider=token_provider,
    api_version="2024-02-01"
)

#Array for our messages
messages_array = [{"role": "system", "content": "You are an AI assistant that helps people find information."}]

#Initialize variables for the prompt and completion tokens
prompt_token_count = int()
completion_token_count = int()

while True:
    user_input = input("Enter a message (type 'finished' to exit): ")
    if user_input.lower() == "finished":
        break

    #Add what the user typed as the user message
    messages_array.append({"role": "user", "content": user_input})

    completion = client.chat.completions.create(
        model=deployment,
        max_tokens=500,
        messages=messages_array
    )

    prompt_token_count += completion.usage.prompt_tokens
    completion_token_count += completion.usage.completion_tokens

    completion_message = completion.choices[0].message.content
    print("> " + completion_message + "\n")

    #Add what the response is as assistant message
    messages_array.append({"role": "assistant", "content": completion_message})

    # print(completion.to_json())

print("Have a great day!")
print("Prompt tokens " + str(prompt_token_count) + ", completion tokens " + str(completion_token_count))

'''
print("Your history was:\n")
for msg_entry in messages_array:
    print(msg_entry)
'''