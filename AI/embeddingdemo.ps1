#$Env:AZURE_OPENAI_KEY = 'YOUR API KEY'

$response = curl https://savilltech-openai.openai.azure.com/openai/deployments/savtechada002/embeddings?api-version=2023-05-15 `
  -H 'Content-Type: application/json' `
  -H "api-key: $Env:AZURE_OPENAI_KEY" `
  -d '{"input": "Can you tell me about embedding models?"}'

$objresponse = $response | convertfrom-json

$objresponse.data.embedding
$objresponse.data.embedding.count
