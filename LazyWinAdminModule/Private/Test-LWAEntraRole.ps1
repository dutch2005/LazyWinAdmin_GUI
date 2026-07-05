function Test-LWAEntraRole {
    <#
    .SYNOPSIS
        Checks if the currently authenticated user holds an active Entra ID directory role.
    .DESCRIPTION
        Queries Microsoft Graph to determine if the current user has the specified 
        directory role (e.g., Intune Administrator, Global Administrator) active in their token.
    .EXAMPLE
        Test-LWAEntraRole -RoleTemplateId '3a2c62eb-5318-48c8-b9ce-cece2840c14c' # Intune Administrator
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false, ParameterSetName='DirectoryRole')]
        [string]$RoleTemplateId,
        
        [Parameter(Mandatory=$true, ParameterSetName='Group')]
        [string]$GroupId
    )

    try {
        $context = Get-MgContext -ErrorAction SilentlyContinue
        if (-not $context) {
            Write-Verbose "Not connected to Microsoft Graph."
            return $false
        }

        if ($PSCmdlet.ParameterSetName -eq 'DirectoryRole') {
            # Check Directory Roles
            $uri = "v1.0/me/memberOf/microsoft.graph.directoryRole?`$select=roleTemplateId"
            $response = Invoke-MgGraphRequest -Method GET -Uri $uri -ErrorAction Stop
            
            $activeRoles = @($response.value.roleTemplateId)
            $globalAdminTemplateId = '62e90394-69f5-4237-9190-012177145e10'
            
            if ($RoleTemplateId -in $activeRoles -or $globalAdminTemplateId -in $activeRoles) {
                return $true
            }

            while ($response.'@odata.nextLink') {
                $response = Invoke-MgGraphRequest -Method GET -Uri $response.'@odata.nextLink' -ErrorAction Stop
                $activeRoles = @($response.value.roleTemplateId)
                if ($RoleTemplateId -in $activeRoles -or $globalAdminTemplateId -in $activeRoles) {
                    return $true
                }
            }
        }
        else {
            # Check Groups
            $uri = "v1.0/me/memberOf/microsoft.graph.group?`$select=id"
            $response = Invoke-MgGraphRequest -Method GET -Uri $uri -ErrorAction Stop
            
            $activeGroups = @($response.value.id)
            if ($GroupId -in $activeGroups) {
                return $true
            }

            while ($response.'@odata.nextLink') {
                $response = Invoke-MgGraphRequest -Method GET -Uri $response.'@odata.nextLink' -ErrorAction Stop
                $activeGroups = @($response.value.id)
                if ($GroupId -in $activeGroups) {
                    return $true
                }
            }
        }

        return $false
    }
    catch {
        Write-Verbose "Error checking Entra Role: $_"
        return $false
    }
}
