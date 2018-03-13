<# Connect to your Azure Account #>
Login-AzureRmAccount;

<# Declare local variables #>
$sourceserver = 'sourcesrv';
$targetserver = 'destsrv';
$sourcedatabase = 'source';
$sourcefqdn = "$sourceserver.database.windows.net";
$destdatabase = 'dbcopy';
$destfqdn = "$targetserver.database.windows.net";
$resourcegroup = 'sourcerg';

$cred = Get-Credential;
[string]$adminuser = $cred.UserName;
$adminpassword = $cred.GetNetworkCredential().Password;

<# Query to return a list of database users and their associated roles #>
$query = "SELECT DP1.name AS DatabaseRoleName,   
DP2.name AS DatabaseUserName
 FROM sys.database_role_members AS DRM  
 RIGHT OUTER JOIN sys.database_principals AS DP1  
   ON DRM.role_principal_id = DP1.principal_id  
 LEFT OUTER JOIN sys.database_principals AS DP2  
   ON DRM.member_principal_id = DP2.principal_id  
WHERE DP1.type = 'R'
AND DP2.name IS NOT NULL
AND DP1.name <> 'db_owner'
ORDER BY DP1.name;"

<# Execute query and write results to variable $userroles #>
$userroles = Invoke-Sqlcmd -ServerInstance $sourcefqdn -Database $sourcedatabase -Username $adminuser -Password $adminpassword -Query $query;

<# Execute New-AzureRmSqlDatabaseCopy to copy an Azure SQL Database
   The copy can be done to the same server or a different server #>
New-AzureRmSqlDatabaseCopy -ResourceGroupName $resourcegroup `
    -ServerName $sourceserver `
    -DatabaseName $sourcedatabase `
    -CopyResourceGroupName $resourcegroup `
    -CopyServerName $targetserver `
    -CopyDatabaseName $destdatabase

<# Get a unique list of database users to disable existing users, create test logins, and test database users #>
$users = $userroles.DatabaseUserName | Sort-Object | Get-Unique;
$users;

foreach($user in $users)
{
    <# Revoke CONNECT permissions to the database users from the source database #>
    $query2 = "REVOKE CONNECT TO $user;"
    Invoke-Sqlcmd -ServerInstance $destfqdn -Database $destdatabase -Username $adminuser -Password $adminpassword -Query $query2;


    $newlogin = "$($user)test"
    $query3 = "CREATE LOGIN $newlogin
	WITH PASSWORD = '$adminpassword';"
    $query3;
    Invoke-Sqlcmd -ServerInstance $destfqdn -Database master -Username $adminuser -Password $adminpassword -Query $query3;

    $query4 = "CREATE USER $newlogin
	    FOR LOGIN $newlogin
	    WITH DEFAULT_SCHEMA = dbo
    GO";
    $query4;
    Invoke-Sqlcmd -ServerInstance $destfqdn -Database $destdatabase -Username $adminuser -Password $adminpassword -Query $query4;

}

<# Assign test users the database roles of the prod users #>
foreach($r in $userroles)
{

    $query5 = "EXEC sp_addrolemember N'$($r.databaserolename)', N'$($r.DatabaseUserName)test'";
    $query5;
    Invoke-Sqlcmd -ServerInstance $destfqdn -Database $destdatabase -Username $adminuser -Password $adminpassword -Query $query5;
}

#$query5 = "ALTER DATABASE $destdatabase SET RECOVERY SIMPLE";
#Invoke-Sqlcmd -ServerInstance $destfqdn -Database $destdatabase -Username $adminuser -Password $adminpassword -Query $query5;
