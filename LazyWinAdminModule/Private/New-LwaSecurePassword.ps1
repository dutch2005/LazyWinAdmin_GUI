function New-LwaSecurePassword {
    <#
    .SYNOPSIS
        Generates a cryptographically strong random password.
    .DESCRIPTION
        Uses the OS CSPRNG (RandomNumberGenerator) to build a password that always
        contains at least one upper-case letter, one lower-case letter, one digit
        and one symbol. Ambiguous characters (0/O, 1/l/I) are excluded so the
        password can be read aloud or typed reliably. The value is returned as a
        plain string for one-time display / clipboard use; callers MUST NOT log it
        (it is a credential).
    .PARAMETER Length
        Total length. Minimum 8, default 16.
    #>
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions', '',
        Justification = 'Pure function: generates and returns a value with no system state change.')]
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [ValidateRange(8, 128)]
        [int]$Length = 16
    )

    $upper  = 'ABCDEFGHJKLMNPQRSTUVWXYZ'
    $lower  = 'abcdefghijkmnpqrstuvwxyz'
    $digit  = '23456789'
    $symbol = '!@#$%^&*-_=+?'
    $all    = $upper + $lower + $digit + $symbol

    $pick = {
        param([string]$set)
        $set[[System.Security.Cryptography.RandomNumberGenerator]::GetInt32($set.Length)]
    }

    # Guarantee one character from each required class, then fill from the full set.
    $chars = [System.Collections.Generic.List[char]]::new()
    $chars.Add((& $pick $upper))
    $chars.Add((& $pick $lower))
    $chars.Add((& $pick $digit))
    $chars.Add((& $pick $symbol))
    while ($chars.Count -lt $Length) {
        $chars.Add((& $pick $all))
    }

    # Fisher-Yates shuffle so the guaranteed classes are not fixed at the front.
    for ($i = $chars.Count - 1; $i -gt 0; $i--) {
        $j = [System.Security.Cryptography.RandomNumberGenerator]::GetInt32($i + 1)
        $tmp = $chars[$i]; $chars[$i] = $chars[$j]; $chars[$j] = $tmp
    }

    return (-join $chars)
}
