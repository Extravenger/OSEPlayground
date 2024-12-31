### Leveraging AlwaysInstallElevated
Check if enabled:
- `reg query HKCU\SOFTWARE\Policies\Microsoft\Windows\Installer /v AlwaysInstallElevated` 
- `reg query HKLM\software\policies\microsoft\windows\installer /v alwaysinstallelevated` 

### MSI File Purpose

1. Creating the user "amit" with the password "Password123!" 
2. Adding the user to the local administrators group. 

Then we can use `Invoke-RunasCs` to get code execution as the newly created amit user:
- `Invoke-RunasCs amit 'Password123!' 'whoami /priv' -ForceProfile -CreateProcessFunction 2 -BypassUac`
