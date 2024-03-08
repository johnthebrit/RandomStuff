#Get pip installed (run in elevated)
#python.exe -m pip install --upgrade pip
#pip install azure-identity azure-keyvault-secrets

#Get your endpoints setup
#setx AZ_AKS_VAULT YOURVAULTURL
#setx AZ_AKS_SECRET YOURSECRETNAME

from msrest.authentication import CognitiveServicesCredentials
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient

from array import array
import os
import time

#Authenticate to Entra (Azure AD)
credential = DefaultAzureCredential()

# Connect to the Azure Key Vault
key_vault_url = os.environ["AZ_AKS_VAULT"]
client = SecretClient(vault_url=key_vault_url, credential=credential)

# Retrieve the secret
secret_name = os.environ["AZ_AKS_SECRET"]
secret = client.get_secret(secret_name)

# Store the value of the secret into a variable
secret_message = secret.value
print("Fetched secret value - " + secret_message)