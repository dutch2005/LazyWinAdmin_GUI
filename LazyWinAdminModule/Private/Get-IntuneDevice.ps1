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

            # Validate IntuneFilter: allow only characters safe for OData $filter strings
            if ($Search -and $Search -match "[^a-zA-Z0-9\s\-\.\@_]") {
                Write-Warning "Search term contains characters not permitted in an Intune filter."
                return $null
            }

            if ($Search) {
                $SafeSearch = $Search.Trim()
                return Get-MgDeviceManagementManagedDevice `
                    -Filter "startsWith(deviceName,'$SafeSearch') or startsWith(userPrincipalName,'$SafeSearch')" `
                    -Top 50 |
                    Select-Object DeviceName, UserPrincipalName, ComplianceState, OperatingSystem, Model, SerialNumber,
                                  JoinType, ManagementState, DeviceEnrollmentType
            }

            return Get-MgDeviceManagementManagedDevice -Top 50 |
                   Select-Object DeviceName, UserPrincipalName, ComplianceState, OperatingSystem, Model, SerialNumber,
                                 JoinType, ManagementState, DeviceEnrollmentType
        }
        catch {
            Write-Warning "Error querying Intune (type: $($_.Exception.GetType().Name))."
            Write-Verbose "Intune exception detail: $($_.Exception.Message)"
            return $null
        }
    }
}
