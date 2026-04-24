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

            $resolvedRoot = (Resolve-Path -LiteralPath $DownloadPath).ProviderPath

            foreach ($script in $scripts) {
                try {
                    $detail = Invoke-MgGraphRequest -Method GET `
                        -Uri "https://graph.microsoft.com/beta/deviceManagement/deviceManagementScripts/$($script.id)" `
                        -ErrorAction Stop
                    if ($detail.scriptContent) {
                        $rawName  = [string]$detail.fileName
                        $safeName = [System.IO.Path]::GetFileName($rawName)
                        $invalid  = [System.IO.Path]::GetInvalidFileNameChars() -join ''
                        $escaped  = [regex]::Escape($invalid)
                        $safeName = [regex]::Replace($safeName, "[$escaped]", '_')
                        if ([string]::IsNullOrWhiteSpace($safeName) -or $safeName -in '.', '..') {
                            Write-Warning "Skipping script '$($script.displayName)': server-supplied filename is unsafe."
                            continue
                        }

                        $filePath = Join-Path -Path $resolvedRoot -ChildPath $safeName
                        $fullPath = [System.IO.Path]::GetFullPath($filePath)
                        $rootWithSep = $resolvedRoot.TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar
                        if (-not $fullPath.StartsWith($rootWithSep, [System.StringComparison]::OrdinalIgnoreCase)) {
                            Write-Warning "Skipping script '$($script.displayName)': resolved path escapes download folder."
                            continue
                        }

                        $decoded = [System.Text.Encoding]::UTF8.GetString(
                                       [System.Convert]::FromBase64String($detail.scriptContent))
                        $decoded | Out-File -LiteralPath $fullPath -Encoding UTF8 -Force
                    }
                }
                catch {
                    Write-Warning "Could not download script '$($script.displayName)'."
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
