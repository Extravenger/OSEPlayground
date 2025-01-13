# This is a super **SIMPLE** example of how to create a very basic PowerShell webserver
# 2019-05-18 UPDATE — Created by me and evaluated by @jakobii and the community.

param (
    [string]$IPAddress = (Read-Host "Enter IP address (e.g., 127.0.0.1)"),
    [int]$Port = (Read-Host "Enter Port number (e.g., 8080)" -AsInt)
)

# Ensure that IPAddress and Port are provided
if (-not $IPAddress) {
    Write-Host "IP Address is required. Exiting." -f 'red'
    exit
}

if (-not $Port) {
    Write-Host "Port is required. Exiting." -f 'red'
    exit
}

# Http Server
$http = [System.Net.HttpListener]::new() 

# Hostname and port to listen on, using parameters
$http.Prefixes.Add("http://${IPAddress}:${Port}/")

# Start the Http Server
$http.Start()

# Log ready message to terminal
if ($http.IsListening) {
    write-host " HTTP Server Ready!  " -f 'black' -b 'green'
    write-host "Now try going to http://${IPAddress}:${Port}" -f 'yellow'
    write-host "Files in this directory will be available for download!" -f 'yellow'
}

# Infinite loop to listen for HTTP requests
try {
    while ($http.IsListening) {

        # Get the next request asynchronously
        $contextTask = $http.GetContextAsync()

        # Wait in 200ms increments allowing pipeline stops to be processed (i.e. CTRL+C)
        while (-not $contextTask.AsyncWaitHandle.WaitOne(200)) { }

        # Retrieve the context (request)
        $context = $contextTask.GetAwaiter().GetResult()

        # ROUTE EXAMPLE 1: Display Folder Contents (this happens immediately when accessing the server)
        if ($context.Request.HttpMethod -eq 'GET' -and $context.Request.RawUrl -eq '/') {
            write-host "$($context.Request.UserHostAddress) => $($context.Request.Url)" -f 'magenta'

            # Get the list of files in the current directory
            $files = Get-ChildItem -File

            # Create HTML to display the file list
            $html = "<h1>Available Files</h1><ul>"

            foreach ($file in $files) {
                $html += "<li><a href='/download/$($file.Name)'>$($file.Name)</a></li>"
            }

            $html += "</ul>"
            
            # Respond with the list of files
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($html)
            $context.Response.ContentLength64 = $buffer.Length
            $context.Response.OutputStream.Write($buffer, 0, $buffer.Length)
            $context.Response.OutputStream.Close()
        }

        # ROUTE EXAMPLE 2: Download File
        # http://127.0.0.1/download/filename
        if ($context.Request.HttpMethod -eq 'GET' -and $context.Request.RawUrl -like '/download/*') {
            write-host "$($context.Request.UserHostAddress) => $($context.Request.Url)" -f 'magenta'

            # Extract the file name from the URL
            $fileName = $context.Request.RawUrl.Substring(10)  # "/download/" is 10 characters

            # Check if the file exists
            $filePath = Join-Path (Get-Location) $fileName
            if (Test-Path $filePath) {
                # Read the file content and serve it
                $fileBytes = [System.IO.File]::ReadAllBytes($filePath)
                
                # Set response headers for download
                $context.Response.ContentLength64 = $fileBytes.Length
                $context.Response.ContentType = "application/octet-stream"
                $context.Response.AddHeader("Content-Disposition", "attachment; filename=$fileName")

                # Write the file to the response stream
                $context.Response.OutputStream.Write($fileBytes, 0, $fileBytes.Length)
                $context.Response.OutputStream.Close()
            } else {
                # File not found response
                $context.Response.StatusCode = 404
                $context.Response.StatusDescription = "Not Found"
                $context.Response.OutputStream.Close()
            }
        }

        # Loop continues listening for new requests...
    }
}
finally {
    # This block will always be called when Ctrl+C is pressed, ensuring the server stops cleanly
    Write-Host "Stopping the HTTP server..." -f 'red'
    $http.Stop()
    Write-Host "Server stopped." -f 'yellow'
}