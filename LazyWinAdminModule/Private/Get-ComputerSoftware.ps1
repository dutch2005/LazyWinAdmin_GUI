function Get-ComputerSoftware {
    <#
    .SYNOPSIS
        Retrieves installed software from a remote computer using CIM (WMI over WinRM).
    .DESCRIPTION
        Uses Win32_Product class via CIM. Note that Win32_Product can be slow 
        as it performs a consistency check of the installed packages.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$ComputerName,

        [string]$Search
    )

    process {
        try {
            $filter = if ($Search) { "Name LIKE '%$Search%'" } else { $null }
            
            $software = Get-CimInstance -ComputerName $ComputerName -ClassName Win32_Product -Filter $filter -ErrorAction Stop
            
            $results = foreach ($item in $software) {
                [PSCustomObject]@{
                    Name        = $item.Name
                    Version     = $item.Version
                    Vendor      = $item.Vendor
                    InstallDate = if ($item.InstallDate) { [DateTime]::ParseExact($item.InstallDate, "yyyyMMdd", $null).ToString("yyyy-MM-dd") } else { "Unknown" }
                }
            }

            return $results | Sort-Object Name
        }
        catch {
            Write-Warning "Error retrieving software on $ComputerName`: $_"
            return $null
        }
    }
}