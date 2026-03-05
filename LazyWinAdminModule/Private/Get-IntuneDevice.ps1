function Get-IntuneDevice {
    <#
    .SYNOPSIS
        Retrieves managed devices from Microsoft Intune using Microsoft Graph.
    #>
    [CmdletBinding()]
    param (
        [string]$Search
    )

    process {
        try {
            if ($null -eq (Get-MgContext)) {
                Write-Warning "Not connected to Microsoft Graph."
                return $null
            }

            if ($Search) {
                return Get-MgDeviceManagementManagedDevice -Filter "startsWith(DeviceName, '$Search') or startsWith(UserPrincipalName, '$Search')" -Top 50 | 
                       Select-Object DeviceName, UserPrincipalName, ComplianceState, OS, Model, SerialNumber
            }
            
            return Get-MgDeviceManagementManagedDevice -Top 50 | 
                   Select-Object DeviceName, UserPrincipalName, ComplianceState, OS, Model, SerialNumber
        }
        catch {
            Write-Warning "Error querying Intune: $_"
            return $null
        }
    }
}