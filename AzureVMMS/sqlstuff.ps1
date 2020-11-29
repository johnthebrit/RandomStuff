#Setup SQL Connection
$projectRGName='RG-SQL-SCUS'
$projectSQLDatabaseServer='savtechsqldbserver'
$projectSQLDatabaseName='savtechsqldb'
$projectSQLTableName='vmmsscaleactions'

$sqlDatabaseServer = Get-AzSqlServer -ServerName $projectSQLDatabaseServer -ResourceGroupName $projectRGName
$sqlDatabase = Get-AzSqlDatabase -DatabaseName $projectSQLDatabaseName -ServerName $projectSQLDatabaseServer -ResourceGroupName $projectRGName
$sqlAdminLogin = $sqlDatabaseServer.SqlAdministratorLogin
$sqlAdminPass = $sqlDatabaseServer.SqlAdministratorPassword