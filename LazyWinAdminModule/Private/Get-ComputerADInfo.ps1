function Get-ComputerADInfo {
    <#
    .SYNOPSIS
        Queries Active Directory for computer, user, or group objects.
    .DESCRIPTION
        Uses the ActiveDirectory module (RSAT). Requires rsat-ad-ds installed on the machine
        running this function. Validates AdFilter input before passing to AD cmdlets.
        Adheres to: ad_computer.* REQUIRES rsat-ad-module (CONTRACTS)
                    ad_user.samaccountname NEVER logged (CLASSIFY: pii)
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateSet("Computer", "User", "Group")]
        [string]$Type,

        # AdFilter: the canonical search term for AD queries (never: ad_search, s, search_str)
        [string]$AdFilter,

        [string]$ComputerName
    )

    process {
        try {
            # Verify RSAT AD module is present — dep.system: rsat-ad-ds
            if (-not (Get-Module -Name ActiveDirectory -ListAvailable -ErrorAction SilentlyContinue)) {
                Write-Warning "ActiveDirectory module not found. Install via: Get-WindowsCapability -Name Rsat.ActiveDirectory* -Online | Add-WindowsCapability -Online"
                return $null
            }

            Import-Module ActiveDirectory -ErrorAction Stop

            # Validate AdFilter — only allow characters safe for LDAP filter strings
            if ($AdFilter -and $AdFilter -match "[^a-zA-Z0-9\s\-\.\@_\*]") {
                Write-Warning "AdFilter contains characters not permitted in an AD filter."
                return $null
            }

            switch ($Type) {
                "Computer" {
                    # ScriptBlock -Filter form: AD cmdlets parameterise $AdFilter / $ComputerName
                    # safely into the LDAP query, eliminating interpolation-based injection.
                    if ($AdFilter) {
                        $result = Get-ADComputer -Filter { Name -like $AdFilter } `
                            -Properties Description, OperatingSystem, OperatingSystemVersion,
                                        LastLogonDate, DistinguishedName, Enabled -ErrorAction Stop
                    }
                    elseif ($ComputerName) {
                        $result = Get-ADComputer -Filter { Name -eq $ComputerName } `
                            -Properties Description, OperatingSystem, OperatingSystemVersion,
                                        LastLogonDate, DistinguishedName, Enabled -ErrorAction Stop
                    }
                    else {
                        $result = Get-ADComputer -Filter * `
                            -Properties Description, OperatingSystem, OperatingSystemVersion,
                                        LastLogonDate, DistinguishedName, Enabled -ErrorAction Stop
                    }
                    return $result |
                        Select-Object Name, DNSHostName, OperatingSystem, OperatingSystemVersion,
                                      LastLogonDate, Enabled, Description, DistinguishedName
                }
                "User" {
                    # SamAccountName is pii — Select-Object excludes it from the returned object
                    # to prevent accidental logging in the UI layer
                    if ($AdFilter) {
                        $result = Get-ADUser -Filter { DisplayName -like $AdFilter -or SamAccountName -like $AdFilter } `
                            -Properties DisplayName, EmailAddress, Department, Title,
                                        LastLogonDate, Enabled -ErrorAction Stop
                    }
                    else {
                        $result = Get-ADUser -Filter { Enabled -eq $true } `
                            -Properties DisplayName, EmailAddress, Department, Title,
                                        LastLogonDate, Enabled -ErrorAction Stop
                    }
                    return $result |
                        Select-Object DisplayName, EmailAddress, Department, Title,
                                      LastLogonDate, Enabled, DistinguishedName
                }
                "Group" {
                    if ($AdFilter) {
                        $result = Get-ADGroup -Filter { Name -like $AdFilter } `
                            -Properties Description, MemberOf -ErrorAction Stop
                    }
                    else {
                        $result = Get-ADGroup -Filter * `
                            -Properties Description, MemberOf -ErrorAction Stop
                    }
                    return $result |
                        Select-Object Name, SamAccountName, GroupCategory, GroupScope, Description
                }
            }
        }
        catch {
            Write-Warning "Error querying Active Directory for $Type (type: $($_.Exception.GetType().Name))."
            Write-Verbose "AD exception detail: $($_.Exception.Message)"
            return $null
        }
    }
}
