function Set-EntraGroupMembership {
    <#
    .SYNOPSIS
        Adds or removes a user as a member of an Entra ID group.
    .DESCRIPTION
        Wraps New-MgGroupMember / Remove-MgGroupMemberByRef. Requires an active Graph
        session with Group.ReadWrite.All. Adding an already-present member is treated
        as success (idempotent).
    .PARAMETER GroupId
        The group's directory object id.
    .PARAMETER UserId
        The user's directory object id (resolve a UPN to its object id via the Entra
        identity lookup first).
    .PARAMETER Action
        Add or Remove.
    .OUTPUTS
        Status string.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$GroupId,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$UserId,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Add', 'Remove')]
        [string]$Action
    )

    if ($null -eq (Get-MgContext)) {
        return '[!] Not connected to Microsoft Graph. Connect on the Cloud tab first.'
    }
    if (-not $PSCmdlet.ShouldProcess("$UserId in group $GroupId", "$Action group membership")) {
        return '[!] Skipped by -WhatIf or -Confirm.'
    }

    try {
        if ($Action -eq 'Add') {
            New-MgGroupMember -GroupId $GroupId -DirectoryObjectId $UserId -ErrorAction Stop | Out-Null
        }
        else {
            Remove-MgGroupMemberByRef -GroupId $GroupId -DirectoryObjectId $UserId -ErrorAction Stop | Out-Null
        }
        return "[OK] $Action membership for $UserId on group $GroupId"
    }
    catch {
        Write-Verbose "Group membership exception: $_"
        return '[!] Group membership update failed. Verify the group id and user object id.'
    }
}
