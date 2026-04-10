function Get-ExchangeMailboxPermission {
    <#
    .SYNOPSIS
        Lists all shared mailboxes a given user has FullAccess or SendAs on.
    .DESCRIPTION
        Iterates every shared mailbox in the connected Exchange Online organisation
        and checks whether the target user holds FullAccess (via Get-MailboxPermission)
        or SendAs (via Get-RecipientPermission). Returns only mailboxes where at
        least one permission is held.
    .PARAMETER UserPrincipalName
        UPN of the user to check, e.g. 'user@contoso.com'. Must be in standard
        UPN format (local-part@domain.tld). Invalid format returns $null with a
        Write-Warning message.
    .OUTPUTS
        System.Object[] — array of PSCustomObject with properties:
          Mailbox     (System.String)  — primary SMTP address of the shared mailbox.
          DisplayName (System.String)  — display name of the shared mailbox.
          FullAccess  (System.Boolean) — $true if the user holds FullAccess.
          SendAs      (System.Boolean) — $true if the user holds SendAs.
        Returns $null on UPN validation failure or on error.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$UserPrincipalName
    )

    try {
        if ($UserPrincipalName -notmatch '^[^@\s]+@[^@\s]+\.[^@\s]+$') {
            Write-Warning "UserPrincipalName '$UserPrincipalName' is not a valid UPN format."
            return $null
        }

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
