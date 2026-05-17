from openai import OpenAI
from azure.identity import DefaultAzureCredential, get_bearer_token_provider

endpoint = "https://foundryagentproject-resource.services.ai.azure.com/openai/v1"
deployment_name = "gpt-5.4-mini"
token_provider = get_bearer_token_provider(DefaultAzureCredential(), "https://ai.azure.com/.default")

client = OpenAI(
    base_url=endpoint,
    api_key=token_provider
)

completion = client.chat.completions.create(
    model=deployment_name,
    messages=[
        {
            "role": "system",
            "content": "You are a helpful assistant that always answers like a Pirate and with humor.",
        },
        {
            "role": "user",
            "content": "What is the capital of England?",
        }
    ],
)

print(completion.choices[0].message.content)