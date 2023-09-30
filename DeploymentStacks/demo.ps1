Set-Location .\DeploymentStacks


# DEMO 1 - Simple create at RG scope and actionOnUnmanage examples

az stack group create --name demoGroupStack -g rgstacktest -f oneStack.bicep --deny-settings-mode None

# Comment out a resource then run again which will default to detach (will show as such in stack)
az stack group create --name demoGroupStack -g rgstacktest -f oneStack.bicep --deny-settings-mode None
# Remove the comments and this time just automate the yes (back)
az stack group create --name demoGroupStack -g rgstacktest -f oneStack.bicep --deny-settings-mode None --yes
# Comment out the resource then run again this type specifying delete as the actionOnUnmanage. Will remove from stack and Azure (not in RG)
az stack group create --name demoGroupStack -g rgstacktest -f oneStack.bicep --deny-settings-mode None --delete-all
# Show the deny settings. Only John can delete as excluded, others (Clark, an owner of RG) will get detailed error why they cannot
az stack group create --name demoGroupStack -g rgstacktest -f oneStack.bicep --deny-settings-mode DenyDelete `
    --deny-settings-excluded-principals "ed17220d-a6d8-45d0-a7bd-2aadc44c39e7" --yes

# Delete the stack and delete the resources (notice I'm not specifying a template)
az stack group delete --name demoGroupStack -g rgstacktest --delete-resources



# DEMO 2 -Subscription Stack with Excluded Principals
az stack sub create --name demoSubStack -f tosubmultiRGstorage.bicep -l southcentralus `
    --deny-settings-mode None #defaults to Detach behavior since no parameter given
# Look at the subscription to see the new stack

# View stacks at subscription level
az stack sub list
az stack sub show --name demoSubStack

# Update with deny. Benefit now is even RG owners would not be able to change the stack
az stack sub create --name demoSubStack -f tosubmultiRGstorage.bicep -l southcentralus `
    --deny-settings-mode "DenyDelete" `
    --deny-settings-excluded-principals "ed17220d-a6d8-45d0-a7bd-2aadc44c39e7 0a27b6b7-2327-4ce6-94c8-78008693bbd9" `
    --yes

# Add an excluded action so now anyone (including Clark can delete)
az stack sub create --name demoSubStack -f tosubmultiRGstorage.bicep -l southcentralus `
    --deny-settings-mode "DenyDelete" `
    --deny-settings-excluded-principals "ed17220d-a6d8-45d0-a7bd-2aadc44c39e7 0a27b6b7-2327-4ce6-94c8-78008693bbd9" `
    --deny-settings-excluded-actions "Microsoft.Storage/StorageAccounts/delete"

# Delete the stack
az stack sub delete --name demoSubStack --delete-all
    # OR delete in portal. You have all the same actionOnUnmanage etc.
    # Note will delete everything including RGs (and anything else).
    # Using --delete-resource-groups or --delete-resources would be more granular


# DEMO 3 - List, Show, and Export MG Stack
az stack mg list -m SavillTechSubs

az stack mg create -m SavillTechSubs -n demoMgStack -f toMGRGstorage.bicep --location southcentralus `
    --parameters subscriptionID=466c1a5d-e93b-4138-91a5-670daf44b0f8 `
    --deny-settings-mode DenyWriteAndDelete

az stack mg list -m SavillTechSubs

# Not at the sub
az stack sub list

az stack mg show -m SavillTechSubs -n demoMgStack
az stack mg export -m SavillTechSubs -n demoMgStack

#Not even I can delete the storage accounts

az stack mg delete -m SavillTechSubs --name demoMgStack --delete-all