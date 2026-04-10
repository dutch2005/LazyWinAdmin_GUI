function Get-IntuneManagementScript {
    <#
    .SYNOPSIS
        Lists Intune device management scripts and optionally downloads their content.
    .DESCRIPTION
        Uses Invoke-MgGraphRequest (Microsoft.Graph.Authentication) against the
        beta Graph endpoint for deviceManagementScripts.  Requires an active
        Graph session with DeviceManagementConfiguration.Read.All scope.
    .PARAMETER Search
        Optional name/filename filter — returns scripts whose DisplayName or
        FileName contains the search string (case-insensitive).
    .PARAMETER DownloadPath
        If specified and the path exists, each script's content is base64-decoded
        and written as a .ps1 file under this folder.
    .OUTPUTS
        System.Object[] — array of PSCustomObject with properties:
          Id          (System.String)   — Intune script GUID.
          DisplayName (System.String)   — friendly name of the script.
          FileName    (System.String)   — original filename (e.g. 'Deploy-App.ps1').
          RunAs       (System.String)   — execution context, e.g. 'system' or 'user'.
          Enforcement (System.String)   — enforcement type reported by Intune.
          Created     (System.DateTime) — script creation timestamp.
          Modified    (System.DateTime) — last modification timestamp.
        Returns $null when not connected to Graph or when an error occurs.
    .EXAMPLE
        # List all Intune management scripts
        Get-IntuneManagementScript
    .EXAMPLE
        # Filter scripts by name and download them locally
        Get-IntuneManagementScript -Search 'Deploy' -DownloadPath 'C:\Temp\IntuneScripts'
    #>
    [CmdletBinding()]
    param (
        [string]$Search,
        [string]$DownloadPath
    )

    try {
        $ctx = Get-MgContext -ErrorAction SilentlyContinue
        if (-not $ctx) {
            Write-Warning "Not connected to Microsoft Graph. Please authenticate on the Cloud Auth tab."
            return $null
        }

        $response = Invoke-MgGraphRequest -Method GET `
            -Uri "https://graph.microsoft.com/beta/deviceManagement/deviceManagementScripts" `
            -ErrorAction Stop

        $scripts = $response.value

        if ($Search) {
            $scripts = $scripts | Where-Object {
                $_.fileName    -like "*$Search*" -or
                $_.displayName -like "*$Search*"
            }
        }

        if ($DownloadPath) {
            if (-not (Test-Path $DownloadPath)) {
                New-Item -ItemType Directory -Path $DownloadPath -Force | Out-Null
            }

            foreach ($script in $scripts) {
                try {
                    $detail = Invoke-MgGraphRequest -Method GET `
                        -Uri "https://graph.microsoft.com/beta/deviceManagement/deviceManagementScripts/$($script.id)" `
                        -ErrorAction Stop
                    if ($detail.scriptContent) {
                        $decoded  = [System.Text.Encoding]::UTF8.GetString(
                                        [System.Convert]::FromBase64String($detail.scriptContent))
                        $filePath = Join-Path $DownloadPath $detail.fileName
                        $decoded | Out-File -FilePath $filePath -Encoding UTF8 -Force
                    }
                }
                catch {
                    Write-Warning "Could not download script '$($script.displayName)': $_"
                }
            }
        }

        return $scripts | ForEach-Object {
            [PSCustomObject]@{
                Id          = $_.id
                DisplayName = $_.displayName
                FileName    = $_.fileName
                RunAs       = $_.runAsAccount
                Enforcement = $_.enforcementType
                Created     = $_.createdDateTime
                Modified    = $_.lastModifiedDateTime
            }
        }
    }
    catch {
        Write-Warning "Error querying Intune management scripts: $_"
        return $null
    }
}
