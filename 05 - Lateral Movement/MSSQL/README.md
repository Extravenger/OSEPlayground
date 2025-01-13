# Custom CLR DLL for SQL Server

We can compile the `CreateAssembly.cs` file with csc.exe:
- `csc.exe /target:library cmd_exec.cs`

Next, we must run these SQL Statements before continue:

```
EXECUTE AS LOGIN = 'sa';
use msdb
EXEC sp_configure 'show advanced options',1
RECONFIGURE
EXEC sp_configure 'clr enabled',1
RECONFIGURE
EXEC sp_configure 'clr strict security', 0
RECONFIGURE
```

Now you should be able to execute OS commands via the “cmd_exec” stored procedure in the “msdb” database as shown in the example below:

<img width="540" alt="{6011A196-9EFE-4CFA-A551-FDD505DF9E59}" src="https://github.com/user-attachments/assets/be2976cc-7965-4279-a55d-c4d552e86d26" />

### How Do I Convert My CLR DLL into a Hexadecimal String and Import It Without a File?

If you read Nathan Kirk’s original blog series, you already know that you don’t have to reference a physical DLL when importing CLR assemblies into SQL Server. “CREATE ASSEMBLY” will also accept a hexadecimal string representation of a CLR DLL file. Below is a PowerShell script example showing how to convert your “cmd_exec.dll” file into a TSQL command that can be used to create the assembly without a physical file reference.

- Use the `Convert-toHex.ps1` to convert your DLL to pure TSQL, If everything went smoothly, the `c:\temp\cmd_exec.txt` file should contain the following TSQL commands. In the example, the hexadecimal string has been truncated, but yours should be much longer. 😉

<img width="536" alt="{2C94DB37-1C77-42FC-A415-7D1F14462202}" src="https://github.com/user-attachments/assets/7f6a292d-c834-44d9-a55e-14dbfcf15669" />

