function Hide-UpnLocalPart {
    <#
    .SYNOPSIS
        Masks the local part of a UPN / email address so it can be safely
        echoed to UI-visible output without leaking the full identifier.
    .DESCRIPTION
        `user@example.com` -> `u***@example.com`
        `a@example.com`    -> `a***@example.com`
        `@example.com`     -> `***@example.com`
        `user`             -> `***`
        `$null` / empty    -> returns the input unchanged

        Used where Exchange / Entra UPNs would otherwise appear verbatim in
        the shared txtOutput log. Classified `pii` in lazywinadmin.speq —
        masking keeps enough context for admins to match log lines to the
        mailbox they acted on without recording the full PII.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [AllowEmptyString()]
        [AllowNull()]
        [string]$Upn
    )
    process {
        if ([string]::IsNullOrWhiteSpace($Upn)) { return $Upn }
        $at = $Upn.IndexOf('@')
        if ($at -lt 0) { return '***' }
        if ($at -eq 0) { return "***$Upn" }
        $local  = $Upn.Substring(0, $at)
        $domain = $Upn.Substring($at)
        return "$($local.Substring(0,1))***$domain"
    }
}
