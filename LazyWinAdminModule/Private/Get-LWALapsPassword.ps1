function Get-LWALapsPassword {
    <#
    .SYNOPSIS
        Retrieves the LAPS password for a device from On-Premises AD or Entra ID.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$ComputerName
    )
    process {
        $result = @{ Source = 'Unknown'; Password = $null; Expiration = $null }
        
        # Try AD LAPS First
        if (Get-Module ActiveDirectory -ListAvailable) {
            Import-Module ActiveDirectory -ErrorAction Stop
            $adComp = Get-ADComputer -Filter {Name -eq $ComputerName} -Properties ms-Mcs-AdmPwd, ms-Mcs-AdmPwdExpirationTime -ErrorAction SilentlyContinue
            if ($adComp -and $adComp.'ms-Mcs-AdmPwd') {
                $result.Source = 'Active Directory'
                $result.Password = $adComp.'ms-Mcs-AdmPwd'
                # FileTime might be large int
                if ($adComp.'ms-Mcs-AdmPwdExpirationTime') {
                    $result.Expiration = [datetime]::FromFileTime($adComp.'ms-Mcs-AdmPwdExpirationTime')
                }
                return [PSCustomObject]$result
            }
        }

        # Try Entra ID Windows LAPS via Graph API
        try {
            Assert-ModuleRequirement -ModuleName 'Microsoft.Graph.Authentication' | Out-Null
            $context = Get-MgContext -ErrorAction SilentlyContinue
            if ($context) {
                # Require Microsoft.Graph.Identity.DirectoryManagement for device queries
                $device = Get-MgDevice -Filter "displayName eq '$ComputerName'" -ErrorAction SilentlyContinue | Select-Object -First 1
                if ($device) {
                    $laps = Invoke-MgGraphRequest -Method GET -Uri "v1.0/directory/deviceLocalCredentials?`$filter=deviceId eq '$($device.Id)'" -ErrorAction SilentlyContinue
                    if ($laps -and $laps.value) {
                        $result.Source = 'Entra ID'
                        $result.Password = $laps.value[0].credentials[0].accountPassword
                        $result.Expiration = $laps.value[0].credentials[0].accountPasswordExpirationDateTime
                        return [PSCustomObject]$result
                    }
                }
            }
        } catch {
            Write-Verbose "Failed to query Entra ID LAPS: $_"
        }

        Write-Warning "LAPS Password not found for $ComputerName."
        return $null
    }
}
