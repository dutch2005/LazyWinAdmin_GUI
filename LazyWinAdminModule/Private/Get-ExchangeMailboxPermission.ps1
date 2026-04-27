function Get-ExchangeMailboxPermission {
    <#
    .SYNOPSIS
        Lists all shared mailboxes a given user has FullAccess or SendAs on.
    .DESCRIPTION
        Iterates every shared mailbox in the connected Exchange Online organisation
        and checks whether the target user holds FullAccess (via Get-MailboxPermission)
        or SendAs (via Get-RecipientPermission). Returns only mailboxes where at
        least one permission is held.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$UserPrincipalName
    )

    try {
        $sharedMailboxes = Get-Mailbox -RecipientTypeDetails SharedMailbox -ErrorAction Stop

        $results = foreach ($mailbox in $sharedMailboxes) {
            $fa = Get-MailboxPermission -Identity $mailbox.Alias -ErrorAction SilentlyContinue |
                      Where-Object { $_.User -like $UserPrincipalName -and $_.AccessRights -contains 'FullAccess' }
            $sa = Get-RecipientPermission -Identity $mailbox.Alias -ErrorAction SilentlyContinue |
                      Where-Object { $_.Trustee -like $UserPrincipalName -and $_.AccessRights -contains 'SendAs' }

            if ($fa -or $sa) {
                [PSCustomObject]@{
                    Mailbox     = $mailbox.PrimarySmtpAddress
                    DisplayName = $mailbox.DisplayName
                    FullAccess  = [bool]$fa
                    SendAs      = [bool]$sa
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
