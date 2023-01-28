$header = Get-Content .\largelogo.ppm -Head 3
$header | Out-File -FilePath header.txt
$contentfile = Get-Content .\largelogo.ppm -asbytestream -raw
<# we really just need to add back in at the end the dimensions
P6
1600 1600
255#>
#HexEdit to remove these lines
openssl enc -aes-128-ecb -nosalt -pass pass:"onboardtoazure" -in body.ppm -out body.aes
openssl enc -aes-128-cbc -nosalt -pass pass:"onboardtoazure" -in body.ppm -out body.aescbc
#HexEdit to add back in the 3 lines at the start
