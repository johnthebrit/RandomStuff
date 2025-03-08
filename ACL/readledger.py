import json
import hashlib
import os
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

def compute_sha256(file_path):
    sha256_hash = hashlib.sha256()
    with open(file_path, "rb") as f:
        for byte_block in iter(lambda: f.read(4096), b""):
            sha256_hash.update(byte_block)
    return sha256_hash.hexdigest()

def main(file_path):
    # Compute SHA256 digest of the file
    current_digest = compute_sha256(file_path)
    file_name = os.path.basename(file_path)

    print(f"Digest for file is: {current_digest}")

    # Fetch the ledger entry for the given file name
    entries = ledger_client.list_ledger_entries()
    ledger_digest = None
    for entry in entries:
        try:
            contents = json.loads(entry["contents"])
        except json.JSONDecodeError:
            # Skip this entry if the content is not valid JSON
            continue

        if contents["file_name"] == file_name:
            ledger_digest = contents["digest"]
            transaction_id = entry["transactionId"]
            print(f"Digest for file from ledger is: {ledger_digest}")
            print(f"Transaction ID from ledger is: {transaction_id}")
            break

    if ledger_digest is None:
        print(f"No ledger entry found for file: {file_name}")
        return

    # Compare the current digest with the ledger digest
    if current_digest == ledger_digest:
        print("The digests match! The file has not been altered.")
    else:
        print("The digests do not match! The file may have been modified.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Read ledger digest for a file and compare with current digest")
    parser.add_argument("file_path", help="Path to the file to compute the digest for")
    args = parser.parse_args()

    if not os.path.isfile(args.file_path):
        print(f"File not found: {args.file_path}")
        exit(1)

    main(args.file_path)