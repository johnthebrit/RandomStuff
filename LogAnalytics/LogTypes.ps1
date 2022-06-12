#Restore logs
az monitor log-analytics workspace table restore create --subscription "SavillTech Dev Subscription" --resource-group defaultresourcegroup-scus  --workspace-name DefaultWorkspace-466c1a5d-e93b-4138-91a5-670daf44b0f8-SCUS --name AzureActivity_RST --restore-source-table AzureActivity --start-restore-time "2022-09-05T00:00:00.000Z" --end-restore-time "2022-09-10T00:00:00.000Z" --no-wait

#Performa a search
az monitor log-analytics workspace table search-job create --resource-group defaultresourcegroup-scus  --workspace-name DefaultWorkspace-466c1a5d-e93b-4138-91a5-670daf44b0f8-SCUS --name AzureActivity_SRCH --search-query "AzureActivity"  --limit 500 --start-search-time "2022-09-05T00:00:00.000Z" --end-search-time "2022-09-10T00:00:00.000Z" --no-wait
