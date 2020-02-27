#https://docs.microsoft.com/en-us/azure/storage/files/storage-files-identity-auth-active-directory-enable
#Download AzFilesHybrid module from https://github.com/Azure-Samples/azure-files-samples/releases

#Import AzFilesHybrid module
Import-Module -name AzFilesHybrid

#Register the target storage account with your active directory environment under the target OU
join-AzStorageAccountForAuth -ResourceGroupName "RG-WCUS" -StorageAccountName "sawcusadfiles" `
    -Domain "savilltech.net" -OrganizationalUnitDistinguishedName "OU=SPNs,DC=savilltech,DC=net"

#Check healthy
#Get the target storage account
$storageaccount = Get-AzStorageAccount -ResourceGroupName "RG-WCUS" -Name "sawcusadfiles"
#See the created kerberos key used by the AD account created
$storageaccount | Get-AzStorageAccountKey -ListKerbKey | ft KeyName
#List the directory service of the selected service account
$storageAccount.AzureFilesIdentityBasedAuth.DirectoryServiceOptions
#List the directory domain information if the storage account has enabled AD authentication for file shares
$storageAccount.AzureFilesIdentityBasedAuth.ActiveDirectoryProperties

#Computer object now present
#Can set access control on files share, e.g. Storage File Data SMB Share Elevated Contributor

New-PSDrive -Name "X" -PSProvider "FileSystem" -Root "\\sawcusadfiles.file.core.windows.net\data" -Scope Global
Get-PSDrive x | Remove-PSDrive
