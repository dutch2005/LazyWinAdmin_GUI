function Get-IntuneDevice {
    <#
    .SYNOPSIS
        Retrieves managed devices from Microsoft Intune using Microsoft Graph.
    .DESCRIPTION
        Queries the Intune managed device endpoint via Microsoft Graph using OData
        $filter expressions against deviceName and userPrincipalName.
        Results are limited to a maximum of 50 devices per call (-Top 50).

        Input validation rejects characters not safe for OData $filter strings before
        the query is constructed. Single quotes in the search term are escaped as two
        consecutive single quotes to prevent OData filter string breakage.

        Requires an active Microsoft Graph session with at least
        DeviceManagementManagedDevices.Read.All scope.
    .PARAMETER Search
        Optional filter string. Must contain only alphanumeric characters, spaces,
        hyphens, dots, @ signs, and underscores. Single quotes are automatically
        escaped. When provided, a startsWith OData filter is applied against both
        deviceName and userPrincipalName; when omitted, the first 50 devices are
        returned (-Top 50 pagination limit applies in both cases).
    .OUTPUTS
        System.Object[] — array of PSCustomObject with properties:
        DeviceName, UserPrincipalName, ComplianceState, OperatingSystem, Model,
        SerialNumber, JoinType, ManagementState, DeviceEnrollmentType.
        Returns $null on error or when not connected to Graph.
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
                $SafeSearch = $Search.Trim() -replace "'", "''"
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
            Write-Warning "Error querying Intune: $_"
            return $null
        }
    }
}
