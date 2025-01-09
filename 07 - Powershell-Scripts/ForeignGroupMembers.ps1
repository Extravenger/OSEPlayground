function Get-ForeignGroupMembers {
    Write-Host "Retrieving domain trust mappings..."
    $trusts = Get-DomainTrustMapping -API

    if ($trusts) {
        Write-Host "Found trust mappings. Processing each domain..."

        foreach ($trust in $trusts) {
            $trustedDomain = $trust.TargetName

            if ($trustedDomain) {
                Write-Host "Processing domain: $trustedDomain"

                try {
                    # Get foreign group members for the trusted domain
                    $foreignGroupMembers = Get-DomainForeignGroupMember -Domain $trustedDomain -DomainController dmzdc01.complyedge.com

                    if ($foreignGroupMembers) {
                        Write-Host "Found foreign group members in ${trustedDomain}:"
                        $foreignGroupMembers | Format-Table -AutoSize -Wrap
                    } else {
                        Write-Host "No foreign group members found in ${trustedDomain}."
                    }
                } catch {
                    Write-Host "Error processing domain ${trustedDomain}: $_"
                }
            } else {
                Write-Host "No target domain found for a trust. Skipping..."
            }
        }
    } else {
        Write-Host "No domain trusts found."
    }
}
