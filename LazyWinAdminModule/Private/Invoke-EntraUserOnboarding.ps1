function Invoke-EntraUserOnboarding {
    <#
    .SYNOPSIS
        Creates a new user and applies the standard joiner setup. Every step after
        creation is opt-in.
    .DESCRIPTION
        Composes the individually-tested atomic operations: create the account, assign
        licenses, add to groups, set the manager, and optionally copy mailbox access
        from a template colleague (so a new hire inherits the same shared-mailbox rights
        as a peer). A failed step is recorded and does NOT abort the rest. Passing
        -WhatIf performs a dry run. The one-time password is returned on the result
        object (for hand-off) and is never placed in any step Result.
    .OUTPUTS
        PSCustomObject with UserId (string or $null), Password (string or $null),
        and Steps (a list of Step/Result records).
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$DisplayName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$UserPrincipalName,

        [string]$MailNickname,
        [string[]]$AddLicenseSkuId,
        [string[]]$AddToGroupId,
        [string]$ManagerId,
        [string]$CopyAccessFromUpn
    )

    $steps  = [System.Collections.Generic.List[object]]::new()
    $record = {
        param([string]$step, [string]$result)
        $steps.Add([PSCustomObject]@{ Step = $step; Result = $result })
    }

    if (-not $PSCmdlet.ShouldProcess($UserPrincipalName, 'Run onboarding workflow')) {
        & $record 'Dry run' "[!] -WhatIf: would create $UserPrincipalName and apply the selected steps."
        return [PSCustomObject]@{ UserId = $null; Password = $null; Steps = $steps }
    }

    $created = New-EntraUser -DisplayName $DisplayName -UserPrincipalName $UserPrincipalName -MailNickname $MailNickname
    & $record 'Create user' $created.Status
    if (-not $created.UserId) {
        return [PSCustomObject]@{ UserId = $null; Password = $null; Steps = $steps }
    }
    $userId = $created.UserId

    if ($AddLicenseSkuId) {
        foreach ($sku in $AddLicenseSkuId) {
            & $record "Assign license $sku" (Set-EntraUserLicense -UserPrincipalName $UserPrincipalName -AddSkuId $sku)
        }
    }
    if ($AddToGroupId) {
        foreach ($groupId in $AddToGroupId) {
            & $record "Add to group $groupId" (Set-EntraGroupMembership -GroupId $groupId -UserId $userId -Action Add)
        }
    }
    if ($ManagerId) {
        & $record 'Set manager' (Set-EntraUserManager -UserId $userId -ManagerId $ManagerId)
    }
    if ($CopyAccessFromUpn) {
        & $record "Copy access from $CopyAccessFromUpn" (Set-ExchangeMailboxPermission -SourceUser $CopyAccessFromUpn -TargetUser $UserPrincipalName)
    }

    return [PSCustomObject]@{ UserId = $userId; Password = $created.Password; Steps = $steps }
}
