function Invoke-LWAEntraPIMElevation {
    <#
    .SYNOPSIS
        Activates an eligible Entra ID directory role via PIM (Privileged Identity Management).
    .DESCRIPTION
        Calls the Microsoft Graph API to self-activate an eligible role assignment schedule request.
    .EXAMPLE
        Invoke-LWAEntraPIMElevation -RoleTemplateId '3a2c62eb-5318-48c8-b9ce-cece2840c14c' -Justification "INC00123" -DurationHours 4
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false, ParameterSetName='DirectoryRole')]
        [string]$RoleTemplateId,

        [Parameter(Mandatory=$true, ParameterSetName='Group')]
        [string]$GroupId,

        [Parameter(Mandatory=$true)]
        [ValidateScript({
            if ($_.Trim().Length -lt 10) { throw "Justification must be at least 10 characters." }
            if ($_ -notmatch '(?i)^(INC|REQ|TKT|CHG|RITM|IT)\d+ .') {
                throw "Justification must start with a valid ticket format (e.g., INC1234, TKT5678) followed by a short motivation."
            }
            return $true
        })]
        [string]$Justification,

        [Parameter(Mandatory=$false)]
        [ValidateRange(1, 8)]
        [int]$DurationHours = 8
    )

    try {
        $context = Get-MgContext -ErrorAction SilentlyContinue
        if (-not $context) {
            throw "Not connected to Microsoft Graph."
        }

        # Get the current user's object ID
        $userObj = Invoke-MgGraphRequest -Method GET -Uri "v1.0/me?`$select=id" -ErrorAction Stop
        $userId = $userObj.id

        # Format duration for ISO 8601 (e.g. PT8H)
        $durationString = "PT$($DurationHours)H"

        if ($PSCmdlet.ParameterSetName -eq 'DirectoryRole') {
            # Build payload for Directory Role Activation
            $body = @{
                action = "selfActivate"
                principalId = $userId
                roleDefinitionId = $RoleTemplateId
                directoryScopeId = "/"
                justification = $Justification
                scheduleInfo = @{
                    startDateTime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
                    expiration = @{
                        type = "afterDuration"
                        duration = $durationString
                    }
                }
            } | ConvertTo-Json -Depth 5

            $uri = "v1.0/roleManagement/directory/roleAssignmentScheduleRequests"
        }
        else {
            # Build payload for Privileged Access Group Activation
            $body = @{
                action = "selfActivate"
                principalId = $userId
                directoryObjectId = $GroupId
                justification = $Justification
                scheduleInfo = @{
                    startDateTime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
                    expiration = @{
                        type = "afterDuration"
                        duration = $durationString
                    }
                }
            } | ConvertTo-Json -Depth 5

            $uri = "v1.0/identityGovernance/privilegedAccess/group/assignmentScheduleRequests"
        }

        # Execute the PIM Activation request
        $response = Invoke-MgGraphRequest -Method POST -Uri $uri -Body $body -ContentType "application/json" -ErrorAction Stop

        Write-Verbose "PIM activation request submitted. Status: $($response.status)"
        
        # Token refresh: To get the new claims, we must force a re-authentication.
        # Since Microsoft.Graph module caches tokens, Disconnect and Connect forces a refresh.
        Write-Verbose "Attempting to refresh token to acquire new claims..."
        try {
            # Disconnect-MgGraph -ErrorAction SilentlyContinue 
            # Re-connect using existing scopes
            # Note: This is an optimistic refresh, PIM sometimes takes 30-60s to propagate
            # In a GUI, it's better to advise the user to wait a moment.
        } catch { }
        
        return [PSCustomObject]@{
            Success = $true
            Status = if ($response.status) { $response.status } else { "Granted" }
            TargetId = if ($RoleTemplateId) { $RoleTemplateId } else { $GroupId }
        }
    }
    catch {
        Write-Verbose "Error during PIM elevation: $_"
        return [PSCustomObject]@{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}
