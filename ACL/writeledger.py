import json

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

# The method begin_create_ledger_entry returns a poller that
# we can use to wait for the transaction to be committed
create_entry_poller = ledger_client.begin_create_ledger_entry(
    {"contents": "Hello World!"}
)
create_entry_result = create_entry_poller.result()

# The method begin_get_receipt returns a poller that
# we can use to wait for the receipt to be available by the system
get_receipt_poller = ledger_client.begin_get_receipt(
    create_entry_result["transactionId"]
)
get_receipt_result = get_receipt_poller.result()

# Save fetched receipt into a file
with open("receipt.json", "w") as receipt_file:
    receipt_file.write(json.dumps(get_receipt_result, sort_keys=True, indent=2))