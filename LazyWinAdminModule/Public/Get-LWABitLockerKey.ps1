function Get-LWABitLockerKey {
    <#
    .SYNOPSIS
        Retrieves BitLocker Recovery Keys for an Entra ID joined device.
    .DESCRIPTION
        Queries Microsoft Graph for BitLocker recovery keys associated with a specific device.
        Automatically handles Just-In-Time PIM elevation if the technician lacks active access.
    .EXAMPLE
        Get-LWABitLockerKey -DeviceId "a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d" -Justification "INC1234 Need key for locked out user"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$DeviceId,

        [Parameter(Mandatory=$false)]
        [ValidateScript({
            if ($null -ne $_ -and $_.Trim().Length -lt 10) { throw "Justification must be at least 10 characters." }
            if ($null -ne $_ -and $_ -notmatch '(?i)^(INC|REQ|TKT|CHG|RITM|IT)\d+ .') {
                throw "Justification must start with a valid ticket format (e.g., INC1234, TKT5678) followed by a short motivation."
            }
            return $true
        })]
        [string]$Justification
    )

    try {
        $context = Get-MgContext -ErrorAction SilentlyContinue
        if (-not $context) { throw "Not connected to Microsoft Graph." }

        # Check for Cloud Device Administrator or Helpdesk Administrator
        $cloudDeviceAdmin = '7698a772-787b-4ac8-901f-60d6b08fafd4'
        $helpdeskAdmin = '729827e3-9c14-49f7-bb1b-9608f156bbb8'
        
        $hasAccess = (Test-LWAEntraRole -RoleTemplateId $cloudDeviceAdmin) -or (Test-LWAEntraRole -RoleTemplateId $helpdeskAdmin)

        if (-not $hasAccess) {
            if ([string]::IsNullOrWhiteSpace($Justification)) {
                throw "Active permission missing. Please provide a -Justification to elevate via PIM."
            }

            Write-Verbose "Attempting PIM Elevation for Cloud Device Administrator..."
            $elevate = Invoke-LWAEntraPIMElevation -RoleTemplateId $cloudDeviceAdmin -Justification $Justification
            if (-not $elevate.Success) {
                throw "PIM Elevation failed: $($elevate.Error)"
            }
        }

        # 1. Fetch Key Metadata
        $uri = "v1.0/informationProtection/bitlocker/recoveryKeys?`$filter=deviceId eq '$DeviceId'"
        $keysData = Invoke-MgGraphRequest -Method GET -Uri $uri -ErrorAction Stop

        if (-not $keysData.value -or $keysData.value.Count -eq 0) {
            Write-Verbose "No BitLocker keys found for device $DeviceId."
            return $null
        }

        $results = @()
        foreach ($k in $keysData.value) {
            # 2. Fetch Actual Key Payload (requires specific select or expanding)
            $keyUri = "v1.0/informationProtection/bitlocker/recoveryKeys/$($k.id)?`$select=key"
            $keyPayload = Invoke-MgGraphRequest -Method GET -Uri $keyUri -ErrorAction Stop

            $results += [PSCustomObject]@{
                DeviceId = $DeviceId
                CreatedDateTime = $k.createdDateTime
                VolumeType = $k.volumeType
                Key = $keyPayload.key
            }
        }

        return $results
    }
    catch {
        Write-Verbose "Error retrieving BitLocker Key: $_"
        throw $_
    }
}
