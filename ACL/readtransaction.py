import json
import argparse

# Import the Azure authentication library
from azure.identity import DefaultAzureCredential

# Import the Confidential Ledger Data Plane SDK
from azure.confidentialledger import ConfidentialLedgerClient
from azure.confidentialledger.certificate import ConfidentialLedgerCertificateClient

# Constants
ledger_name = "savillledger"
identity_url = "https://identity.confidential-ledger.core.azure.com"
ledger_url = "https://" + ledger_name + ".confidential-ledger.azure.com"

# Setup authentication
credential = DefaultAzureCredential()

# Create Ledger Certificate client and use it to
# retrieve the service identity for our ledger
identity_client = ConfidentialLedgerCertificateClient(identity_url)
network_identity = identity_client.get_ledger_identity(ledger_id=ledger_name)

# Save network certificate into a file for later use
ledger_tls_cert_file_name = "network_certificate.pem"

with open(ledger_tls_cert_file_name, "w") as cert_file:
    cert_file.write(network_identity["ledgerTlsCertificate"])

# Create Confidential Ledger client
ledger_client = ConfidentialLedgerClient(
    endpoint=ledger_url,
    credential=credential,
    ledger_certificate_path=ledger_tls_cert_file_name,
)

def display_transaction(transaction_id):
    # Fetch the transaction from the ledger
    transaction = ledger_client.get_ledger_entry(transaction_id)
    print(f"Transaction ID: {transaction_id}")
    print("Transaction contents:")
    print(json.dumps(transaction, indent=2))

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Display a transaction from Azure Confidential Ledger for a given transaction ID")
    parser.add_argument("transaction_id", help="Transaction ID to fetch from the ledger")
    args = parser.parse_args()

    display_transaction(args.transaction_id)