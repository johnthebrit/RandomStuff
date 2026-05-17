import os
from openai import OpenAI

endpoint = "https://foundryagentproject-resource.services.ai.azure.com/openai/v1"
deployment_name = "gpt-5.4-mini"
api_key = os.getenv("AZURE_OPENAI_KEY")

client = OpenAI(
    base_url=endpoint,
    api_key=api_key
)

completion = client.chat.completions.create(
    model=deployment_name,
    messages=[
        {
            "role": "user",
            "content": "What is the capital of England?",
        }
    ],
)

print(completion.choices[0].message)