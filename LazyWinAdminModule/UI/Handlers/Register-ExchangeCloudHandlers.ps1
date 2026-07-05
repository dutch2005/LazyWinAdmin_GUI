# LazyWinAdmin UI section — Exchange + Cloud Auth tab handlers.
# Dot-sourced by Start-LazyWinAdmin INTO its scope.

# --- EXCHANGE HANDLERS ---
$btnConnectExchange.Add_Click({
    $upn   = $txtExchangeUpn.Text
    $deleg = $txtExchangeDelegatedOrg.Text
    Invoke-AsyncAction `
        -InitializationScript ([scriptblock]::Create(". '$PrivatePath\Connect-ExchangeSession.ps1'")) `
        -Parameters  @{ u = $upn; d = $deleg } `
        -ScriptBlock { Connect-ExchangeSession -UserPrincipalName $u -DelegatedOrganization $d } `
        -OnCompleted {
            param($res)
            $connected = $res -match '^\[OK\]'
            $state.SyncHash.ExchangeConnected = $connected
            $lblExchangeStatus.Text       = $res
            $lblExchangeStatus.Foreground  = if ($connected) {
                [System.Windows.Media.Brushes]::Green
            } else {
                [System.Windows.Media.Brushes]::Red
            }
            $lblStatus.Text = if ($connected) { "Exchange: connected" } else { "Exchange: not connected" }
        }
})

$btnGetMailboxPerms.Add_Click({
    if (-not ($RequireExchangeSession.Invoke())) { return }
    $upn = $txtExchangeViewUser.Text
    if ([string]::IsNullOrWhiteSpace($upn)) {
        $lblStatus.Text = "[!] Enter a User Principal Name to look up."
        return
    }
    Invoke-AsyncAction `
        -InitializationScript ([scriptblock]::Create(". '$PrivatePath\Get-ExchangeMailboxPermission.ps1'")) `
        -Parameters  @{ u = $upn } `
        -ScriptBlock { Get-ExchangeMailboxPermission -UserPrincipalName $u } `
        -OnCompleted {
            param($data)
            $lvMailboxPerms.Items.Clear()
            if ($data) {
                $data | ForEach-Object { $lvMailboxPerms.Items.Add($_) }
                $lblMailboxPermsCount.Text = "$($lvMailboxPerms.Items.Count) mailbox(es)"
            } else {
                $lblMailboxPermsCount.Text = "0 mailbox(es)"
                $AppendOutput.Invoke("[Exchange] No mailbox permissions found for $(Hide-UpnLocalPart $upn).")
            }
        }
})

$btnMirrorMailboxPerms.Add_Click({
    if (-not ($RequireExchangeSession.Invoke())) { return }
    $src = $txtExchangeSourceUser.Text
    $tgt = $txtExchangeTargetUser.Text
    if ([string]::IsNullOrWhiteSpace($src) -or [string]::IsNullOrWhiteSpace($tgt)) {
        $lblStatus.Text = "[!] Enter both source and target UPNs for mirror."
        return
    }
    Invoke-AsyncAction `
        -InitializationScript ([scriptblock]::Create(". '$PrivatePath\Set-ExchangeMailboxPermission.ps1'")) `
        -Parameters  @{ src = $src; tgt = $tgt } `
        -ScriptBlock { Set-ExchangeMailboxPermission -SourceUser $src -TargetUser $tgt } `
        -OnCompleted {
            param($res)
            $AppendOutput.Invoke("[Exchange Mirror] $res")
            $lblStatus.Text = $res
        }
})

$btnGrantMailboxPerms.Add_Click({
    if (-not ($RequireExchangeSession.Invoke())) { return }
    $mb   = $txtExchangeMailbox.Text
    $user = $txtExchangeGrantUser.Text
    if ([string]::IsNullOrWhiteSpace($mb) -or [string]::IsNullOrWhiteSpace($user)) {
        $lblStatus.Text = "[!] Enter both a mailbox address and a user UPN."
        return
    }
    Invoke-AsyncAction `
        -InitializationScript ([scriptblock]::Create(". '$PrivatePath\Set-ExchangeMailboxPermission.ps1'")) `
        -Parameters  @{ mb = $mb; u = $user } `
        -ScriptBlock { Set-ExchangeMailboxPermission -Mailbox $mb -User $u } `
        -OnCompleted {
            param($res)
            $AppendOutput.Invoke("[Exchange Grant] $res")
            $lblStatus.Text = $res
        }
})

# --- CLOUD AUTH HANDLER ---
$btnCloudLogin.Add_Click({
    Invoke-AsyncAction `
        -InitializationScript ([scriptblock]::Create(". '$PrivatePath\Connect-ModernCloud.ps1'")) `
        -ScriptBlock { Connect-ModernCloud -Interactive } `
        -OnCompleted {
            param($res)
            $connected = $res -match "^\[OK\]"
            # Persist auth state so $RequireCloudSession guards can read it
            $state.SyncHash.CloudConnected = $connected
            $lblCloudStatus.Text       = $res
            $lblCloudStatus.Foreground = if ($connected) {
                [System.Windows.Media.Brushes]::Green
            } else {
                [System.Windows.Media.Brushes]::Red
            }
            $lblStatus.Text = if ($connected) { "Cloud: connected" } else { "Cloud: not connected" }
        }
})

# Service Principal login — TenantId/ClientId sourced from UI text boxes.
# ClientSecret is read from a PasswordBox (.SecurePassword) — never stored as plaintext.
# Secrets are scoped to CLOUD layer per lazywinadmin.speq SECRETS block.
$btnCloudConnectSP.Add_Click({
    $tenantId     = $txtTenantId.Text
    $clientId     = $txtClientId.Text
    $clientSecret = $txtClientSecret.SecurePassword   # SecureString — never .Password
    Invoke-AsyncAction `
        -InitializationScript ([scriptblock]::Create(". '$PrivatePath\Connect-ModernCloud.ps1'")) `
        -Parameters  @{ tid = $tenantId; cid = $clientId; cs = $clientSecret } `
        -ScriptBlock { Connect-ModernCloud -TenantId $tid -ClientId $cid -ClientSecret $cs } `
        -OnCompleted {
            param($res)
            $connected = $res -match "^\[OK\]"
            # Persist auth state so $RequireCloudSession guards can read it
            $state.SyncHash.CloudConnected = $connected
            $lblCloudStatus.Text       = $res
            $lblCloudStatus.Foreground = if ($connected) {
                [System.Windows.Media.Brushes]::Green
            } else {
                [System.Windows.Media.Brushes]::Red
            }
            $lblStatus.Text = if ($connected) { "Cloud: connected" } else { "Cloud: not connected" }
        }
})
