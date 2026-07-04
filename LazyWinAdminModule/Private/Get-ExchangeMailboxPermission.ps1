function Get-ExchangeMailboxPermission {
    <#
    .SYNOPSIS
        Lists every mailbox a given user can access — FullAccess, SendAs, or Send-on-Behalf.
    .DESCRIPTION
        Scans the mailboxes in the connected Exchange Online organisation and reports
        each one on which the target user holds at least one of:
          - FullAccess     (via Get-MailboxPermission)
          - SendAs         (via Get-RecipientPermission)
          - Send-on-Behalf (via the mailbox GrantSendOnBehalfTo delegate list)
        Covers user, shared, room and equipment mailboxes by default — not just shared
        mailboxes — so delegated access on a colleague's own mailbox is not missed.
    .PARAMETER UserPrincipalName
        The delegate (UPN) to search for.
    .PARAMETER RecipientTypeDetails
        Mailbox types to scan. Defaults to the four common mailbox types.
    .NOTES
        This enumerates every mailbox and queries permissions per mailbox, so on a
        large tenant it is inherently O(number of mailboxes). SendOnBehalf matching
        is best-effort (the delegate list stores display names / aliases, not UPNs).
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$UserPrincipalName,

        [string[]]$RecipientTypeDetails = @('UserMailbox', 'SharedMailbox', 'RoomMailbox', 'EquipmentMailbox')
    )

    try {
        $mailboxes = Get-Mailbox -RecipientTypeDetails $RecipientTypeDetails -ResultSize Unlimited -ErrorAction Stop

        $results = foreach ($mailbox in $mailboxes) {
            $fa = Get-MailboxPermission -Identity $mailbox.Alias -ErrorAction SilentlyContinue |
                      Where-Object { $_.User -like $UserPrincipalName -and $_.AccessRights -contains 'FullAccess' }
            $sa = Get-RecipientPermission -Identity $mailbox.Alias -ErrorAction SilentlyContinue |
                      Where-Object { $_.Trustee -like $UserPrincipalName -and $_.AccessRights -contains 'SendAs' }

            # Send-on-Behalf lives on the mailbox itself (GrantSendOnBehalfTo).
            # Guard the property access so the function is safe under Set-StrictMode
            # and against fixtures/mailboxes that omit the property.
            $sob     = $false
            $sobProp = $mailbox.PSObject.Properties['GrantSendOnBehalfTo']
            if ($sobProp -and $sobProp.Value) {
                $local = ($UserPrincipalName -split '@')[0]
                $sob   = @($sobProp.Value | Where-Object {
                    "$_" -like "*$UserPrincipalName*" -or ($local -and "$_" -like "*$local*")
                }).Count -gt 0
            }

            if ($fa -or $sa -or $sob) {
                $rtdProp = $mailbox.PSObject.Properties['RecipientTypeDetails']
                [PSCustomObject]@{
                    Mailbox       = $mailbox.PrimarySmtpAddress
                    DisplayName   = $mailbox.DisplayName
                    RecipientType = if ($rtdProp) { $rtdProp.Value } else { $null }
                    FullAccess    = [bool]$fa
                    SendAs        = [bool]$sa
                    SendOnBehalf  = [bool]$sob
                }
            }
        }

        return $results
    }
    catch {
        Write-Warning "Error querying mailbox permissions: $_"
        return $null
    }
}
