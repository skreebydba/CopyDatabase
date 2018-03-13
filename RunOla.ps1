cls;

Login-AzureRmAccount;

$cred = Get-Credential;
[string]$user = $cred.UserName;
$pass = $cred.GetNetworkCredential().Password;
$dbccquery = "EXECUTE [dbo].[DatabaseIntegrityCheck] @Databases = 'USER_DATABASES', @LogToTable = 'Y';"
$indexquery = "EXECUTE [dbo].[IndexOptimize] @Databases = 'USER_DATABASES', @LogToTable = 'Y';"

$databases = Invoke-Sqlcmd -ServerInstance "fbgguggenheimsrv.database.windows.net" -Database master -Username $user -Password $pass -Query "SELECT name FROM sys.databases WHERE database_id > 4";

$databases;

foreach($database in $databases)
{

Invoke-Sqlcmd -ServerInstance "fbgguggenheimsrv.database.windows.net" -Database $database.name -Username $user -Password $pass -Query $dbccquery;
Invoke-Sqlcmd -ServerInstance "fbgguggenheimsrv.database.windows.net" -Database $database.name -Username $user -Password $pass -Query $indexquery;

}