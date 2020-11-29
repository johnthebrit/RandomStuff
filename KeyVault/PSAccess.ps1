$secret = Get-AzKeyVaultSecret -VaultName 'SavillVault' -Name 'SamplePassword'
$secret.SecretValue | ConvertFrom-SecureString -AsPlainText

$secret = Get-AzKeyVaultSecret -VaultName 'SavillVaultRBAC' -Name 'Secret1'
$secret.SecretValue | ConvertFrom-SecureString -AsPlainText

$secret = Get-AzKeyVaultSecret -VaultName 'SavillVaultRBAC' -Name 'Secret2'
$secret.SecretValue | ConvertFrom-SecureString -AsPlainText

<#SecretValueText deprecated so below no longer works
(Get-AzKeyVaultSecret –VaultName 'SavillVault' -Name 'SamplePassword').SecretValueText
#>