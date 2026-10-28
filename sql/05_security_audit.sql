/* Visible server metadata; absence of rows is not proof of secure configuration. */
SET NOCOUNT ON;
SELECT name, value_in_use FROM sys.configurations
WHERE name IN ('xp_cmdshell', 'clr enabled', 'cross db ownership chaining',
               'Ad Hoc Distributed Queries', 'remote access');
SELECT rolep.name AS server_role, memberp.name AS member_name, memberp.type_desc,
       memberp.is_disabled
FROM sys.server_role_members AS rm
JOIN sys.server_principals AS rolep ON rolep.principal_id = rm.role_principal_id
JOIN sys.server_principals AS memberp ON memberp.principal_id = rm.member_principal_id;
SELECT name, type_desc, is_disabled, is_policy_checked, is_expiration_checked
FROM sys.sql_logins WHERE name NOT LIKE '##%';
SELECT p.name AS principal_name, sp.state_desc, sp.permission_name
FROM sys.server_permissions AS sp
JOIN sys.server_principals AS p ON p.principal_id = sp.grantee_principal_id;
SELECT name, is_trustworthy_on, is_db_chaining_on, containment_desc
FROM sys.databases WHERE database_id > 4;
SELECT name, is_state_enabled, type_desc, on_failure_desc
FROM sys.server_audits;
