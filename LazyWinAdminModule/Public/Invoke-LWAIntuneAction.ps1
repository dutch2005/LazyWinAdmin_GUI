function Invoke-LWAIntuneAction {
    <#
    .SYNOPSIS
        Executes Intune Device Actions (Sync, Wipe, Restart, etc.) with automatic PIM elevation.
    .DESCRIPTION
        Initiates remote actions on Entra ID joined devices enrolled in Intune via Microsoft Graph.
        Elevates to Intune Administrator via PIM if the active session lacks sufficient roles.
    .EXAMPLE
        Invoke-LWAIntuneAction -DeviceId "a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d" -Action 'syncDevice' -Justification "INC1234 Need to sync device for new policies"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$DeviceId,

        [Parameter(Mandatory=$true)]
        [ValidateSet('syncDevice', 'wipe', 'rebootNow', 'windowsDefenderUpdateSignatures', 'windowsDefenderScan')]
        [string]$Action,

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

        # Check for Intune Administrator
        $intuneAdmin = '3a2c62eb-5318-48c8-b9ce-cece2840c14c'
        $hasAccess = Test-LWAEntraRole -RoleTemplateId $intuneAdmin

        if (-not $hasAccess) {
            if ([string]::IsNullOrWhiteSpace($Justification)) {
                throw "Active permission missing. Please provide a -Justification to elevate via PIM."
            }

            Write-Verbose "Attempting PIM Elevation for Intune Administrator..."
            $elevate = Invoke-LWAEntraPIMElevation -RoleTemplateId $intuneAdmin -Justification $Justification
            if (-not $elevate.Success) {
                throw "PIM Elevation failed: $($elevate.Error)"
            }
        }

        # Intune Actions use a POST request to deviceManagement/managedDevices
        $uri = "v1.0/deviceManagement/managedDevices/$DeviceId/$Action"
        
        $body = $null
        if ($Action -eq 'wipe') {
            # Wipe has specific parameters depending on if you want to keep enrollment data.
            # We default to standard wipe (retain enrollment state = false).
            $body = @{
                keepEnrollmentData = $false
                keepUserData = $false
            } | ConvertTo-Json -Depth 2
        } elseif ($Action -eq 'windowsDefenderScan') {
            $body = @{ quickScan = $true } | ConvertTo-Json -Depth 2
        }

        if ($body) {
            $response = Invoke-MgGraphRequest -Method POST -Uri $uri -Body $body -ContentType "application/json" -ErrorAction Stop
        } else {
            $response = Invoke-MgGraphRequest -Method POST -Uri $uri -ErrorAction Stop
        }

        return [PSCustomObject]@{
            DeviceId = $DeviceId
            Action = $Action
            Success = $true
            Status = "Initiated"
        }
    }
    catch {
        Write-Verbose "Error executing Intune action '$Action': $_"
        throw $_
    }
}
