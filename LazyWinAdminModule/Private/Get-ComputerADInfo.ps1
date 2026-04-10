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
                    $ldapFilter = if ($AdFilter) { "Name -like '$AdFilter'" } `
                                  elseif ($ComputerName) { "Name -eq '$ComputerName'" } `
                                  else { "Name -like '*'" }

                    return Get-ADComputer -Filter $ldapFilter `
                        -Properties Description, OperatingSystem, OperatingSystemVersion,
                                    LastLogonDate, DistinguishedName, Enabled -ErrorAction Stop |
                        Select-Object Name, DNSHostName, OperatingSystem, OperatingSystemVersion,
                                      LastLogonDate, Enabled, Description, DistinguishedName
                }
                "User" {
                    $ldapFilter = if ($AdFilter) { "DisplayName -like '$AdFilter' -or SamAccountName -like '$AdFilter'" } `
                                  else { "Enabled -eq `$true" }

                    # SamAccountName is pii — Select-Object excludes it from the returned object
                    # to prevent accidental logging in the UI layer
                    return Get-ADUser -Filter $ldapFilter `
                        -Properties DisplayName, EmailAddress, Department, Title,
                                    LastLogonDate, Enabled -ErrorAction Stop |
                        Select-Object DisplayName, EmailAddress, Department, Title,
                                      LastLogonDate, Enabled, DistinguishedName
                }
                "Group" {
                    $ldapFilter = if ($AdFilter) { "Name -like '$AdFilter'" } `
                                  else { "Name -like '*'" }

                    return Get-ADGroup -Filter $ldapFilter `
                        -Properties Description, MemberOf -ErrorAction Stop |
                        Select-Object Name, SamAccountName, GroupCategory, GroupScope, Description
                }
            }
        }
        catch {
            Write-Warning "Error querying Active Directory for $Type`: $_"
            return $null
        }
    }
}
