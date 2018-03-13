cls;

Login-AzureRmAccount;

$cred = Get-Credential;
[string]$user = $cred.UserName;
$pass = $cred.GetNetworkCredential().Password;
$sqlserver = "yoursqlserver.database.windows.net";
$dbccquery = "EXECUTE [dbo].[DatabaseIntegrityCheck] @Databases = 'USER_DATABASES', @LogToTable = 'Y';"
$indexquery = "EXECUTE [dbo].[IndexOptimize] @Databases = 'USER_DATABASES', @LogToTable = 'Y';"

$databases = Invoke-Sqlcmd -ServerInstance $sqlserver -Database master -Username $user -Password $pass -Query "SELECT name FROM sys.databases WHERE database_id > 4";

$databases;

foreach($database in $databases)
{

Invoke-Sqlcmd -ServerInstance $sqlserver -Database $database.name -Username $user -Password $pass -Query $dbccquery;
Invoke-Sqlcmd -ServerInstance $sqlserver -Database $database.name -Username $user -Password $pass -Query $indexquery;

}
