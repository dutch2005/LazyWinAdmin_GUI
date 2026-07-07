# LazyWinAdmin UI section — control lookup.
# Dot-sourced by Start-LazyWinAdmin INTO its scope (scope-transparent): every
# variable assigned here becomes a local of Start-LazyWinAdmin. Requires $window.
# This is NOT a standalone function and is NOT auto-loaded by the .psm1 (it lives
# under UI/Handlers/, which the module loader does not glob).

# --- FIND CONTROLS ---
$txtComputerName   = $window.FindName("txtComputerName")
$btnPing           = $window.FindName("btnPing")
$btnUptime         = $window.FindName("btnUptime")
$btnEnableRdp      = $window.FindName("btnEnableRdp")
$btnDisableRdp     = $window.FindName("btnDisableRdp")
$txtOutput         = $window.FindName("txtOutput")

$btnGetServices    = $window.FindName("btnGetServices")
$btnGetStoppedAuto = $window.FindName("btnGetStoppedAuto")
$lvServices        = $window.FindName("lvServices")
$txtServiceSearch  = $window.FindName("txtServiceSearch")

$btnGetSoftware    = $window.FindName("btnGetSoftware")
$lvSoftware        = $window.FindName("lvSoftware")
$txtSoftwareSearch = $window.FindName("txtSoftwareSearch")

$btnGetHardware    = $window.FindName("btnGetHardware")
$txtHwModel        = $window.FindName("txtHwModel")
$txtHwSerial       = $window.FindName("txtHwSerial")
$txtHwCpu          = $window.FindName("txtHwCpu")
$txtHwRam          = $window.FindName("txtHwRam")
$txtHwOs           = $window.FindName("txtHwOs")
$txtHwMobo         = $window.FindName("txtHwMobo")
$lvHwDisks         = $window.FindName("lvHwDisks")

$btnGetNetwork     = $window.FindName("btnGetNetwork")
$chkOnlyIPEnabled  = $window.FindName("chkOnlyIPEnabled")
$lvNetwork         = $window.FindName("lvNetwork")

$btnGetLocalUsers  = $window.FindName("btnGetLocalUsers")
$btnGetLocalGroups = $window.FindName("btnGetLocalGroups")
$lvLocalAccounts   = $window.FindName("lvLocalAccounts")
$btnGetEntraUsers  = $window.FindName("btnGetEntraUsers")
$btnGetEntraGroups = $window.FindName("btnGetEntraGroups")
$lvEntraIdentity   = $window.FindName("lvEntraIdentity")
$txtEntraSearch    = $window.FindName("txtEntraSearch")

$btnGetIntuneDevices = $window.FindName("btnGetIntuneDevices")
$lvIntuneDevices     = $window.FindName("lvIntuneDevices")
$txtIntuneSearch     = $window.FindName("txtIntuneSearch")
$btnGetAzureSummary  = $window.FindName("btnGetAzureSummary")
$lvAzureResources    = $window.FindName("lvAzureResources")

# Intune Scripts controls
$btnGetIntuneScripts         = $window.FindName("btnGetIntuneScripts")
$txtIntuneScriptSearch       = $window.FindName("txtIntuneScriptSearch")
$txtIntuneScriptDownloadPath = $window.FindName("txtIntuneScriptDownloadPath")
$btnDownloadIntuneScripts    = $window.FindName("btnDownloadIntuneScripts")
$lvIntuneScripts             = $window.FindName("lvIntuneScripts")

# Device Compliance controls
$btnCheckCompliance  = $window.FindName("btnCheckCompliance")
$lvComplianceStatus  = $window.FindName("lvComplianceStatus")
$btnFixLocation      = $window.FindName("btnFixLocation")
$btnFixOutlookImages = $window.FindName("btnFixOutlookImages")
$btnRemoveOneDrive   = $window.FindName("btnRemoveOneDrive")
$txtUpdateHoursStart = $window.FindName("txtUpdateHoursStart")
$txtUpdateHoursEnd   = $window.FindName("txtUpdateHoursEnd")
$btnFixUpdateHours   = $window.FindName("btnFixUpdateHours")
$txtComplianceOutput = $window.FindName("txtComplianceOutput")

# Exchange controls
$txtExchangeUpn         = $window.FindName("txtExchangeUpn")
$txtExchangeDelegatedOrg = $window.FindName("txtExchangeDelegatedOrg")
$btnConnectExchange     = $window.FindName("btnConnectExchange")
$lblExchangeStatus      = $window.FindName("lblExchangeStatus")
$btnGetMailboxPerms     = $window.FindName("btnGetMailboxPerms")
$txtExchangeViewUser    = $window.FindName("txtExchangeViewUser")
$lvMailboxPerms         = $window.FindName("lvMailboxPerms")
$txtExchangeSourceUser  = $window.FindName("txtExchangeSourceUser")
$txtExchangeTargetUser  = $window.FindName("txtExchangeTargetUser")
$btnMirrorMailboxPerms  = $window.FindName("btnMirrorMailboxPerms")
$txtExchangeMailbox     = $window.FindName("txtExchangeMailbox")
$txtExchangeGrantUser   = $window.FindName("txtExchangeGrantUser")
$btnGrantMailboxPerms   = $window.FindName("btnGrantMailboxPerms")

$btnRegRead        = $window.FindName("btnRegRead")
$btnRegWrite       = $window.FindName("btnRegWrite")
$btnRegDelete      = $window.FindName("btnRegDelete")
$cbRegHive         = $window.FindName("cbRegHive")
$cbRegType         = $window.FindName("cbRegType")
$txtRegValueName   = $window.FindName("txtRegValueName")
$txtRegValueData   = $window.FindName("txtRegValueData")
$txtRegPath        = $window.FindName("txtRegPath")
$txtRegResult      = $window.FindName("txtRegResult")

$btnGetAdComputer  = $window.FindName("btnGetAdComputer")
$btnGetAdUsers     = $window.FindName("btnGetAdUsers")
$btnGetAdGroups    = $window.FindName("btnGetAdGroups")
$txtAdSearch       = $window.FindName("txtAdSearch")
$lvAdResults       = $window.FindName("lvAdResults")

$btnCloudLogin     = $window.FindName("btnCloudLogin")
$lblCloudStatus    = $window.FindName("lblCloudStatus")
$txtTenantId       = $window.FindName("txtTenantId")
$txtClientId       = $window.FindName("txtClientId")
$txtClientSecret   = $window.FindName("txtClientSecret")
$btnCloudConnectSP = $window.FindName("btnCloudConnectSP")

$lblStatus         = $window.FindName("lblStatus")
$lblAdminStatus    = $window.FindName("lblAdminStatus")
$btnRestartAdmin   = $window.FindName("btnRestartAdmin")
$pbBusy            = $window.FindName("pbBusy")
$lblTime           = $window.FindName("lblTime")

# Service control and export controls (v1.3.0)
$lblServicesCount       = $window.FindName("lblServicesCount")
$btnStartService        = $window.FindName("btnStartService")
$btnStopService         = $window.FindName("btnStopService")
$btnRestartService      = $window.FindName("btnRestartService")
$btnExportServices      = $window.FindName("btnExportServices")
$lblSoftwareCount       = $window.FindName("lblSoftwareCount")
$btnExportSoftware      = $window.FindName("btnExportSoftware")
$lblNetworkCount        = $window.FindName("lblNetworkCount")
$btnExportNetwork       = $window.FindName("btnExportNetwork")
$lblIntuneDevicesCount  = $window.FindName("lblIntuneDevicesCount")
$btnExportIntuneDevices = $window.FindName("btnExportIntuneDevices")
$lblMailboxPermsCount   = $window.FindName("lblMailboxPermsCount")
$btnExportMailboxPerms  = $window.FindName("btnExportMailboxPerms")

# Default value
$txtComputerName.Text = $env:COMPUTERNAME

# --- RMM & PIM CONTROLS ---
$txtRmmComputer      = $window.FindName("txtRmmComputer")
$txtRmmOutput        = $window.FindName("txtRmmOutput")
$btnRmmProcess       = $window.FindName("btnRmmProcess")
$btnRmmEventLog      = $window.FindName("btnRmmEventLog")
$btnRmmVolume        = $window.FindName("btnRmmVolume")
$btnRmmSmb           = $window.FindName("btnRmmSmb")
$btnRmmUpdates       = $window.FindName("btnRmmUpdates")
$btnRmmSession       = $window.FindName("btnRmmSession")

$txtRmmCloudTarget   = $window.FindName("txtRmmCloudTarget")
$txtRmmTicket        = $window.FindName("txtRmmTicket")
$btnRmmBitLocker     = $window.FindName("btnRmmBitLocker")
$btnRmmIntuneSync    = $window.FindName("btnRmmIntuneSync")
$btnRmmEntraLogs     = $window.FindName("btnRmmEntraLogs")
$btnRmmRevokeSession = $window.FindName("btnRmmRevokeSession")
$btnRmmResetMFA      = $window.FindName("btnRmmResetMFA")

$txtHelpdeskTarget = $window.FindName('txtHelpdeskTarget')
$txtHelpdeskOutput = $window.FindName('txtHelpdeskOutput')

$btnGetLaps = $window.FindName('btnGetLaps')
$btnStartRdp = $window.FindName('btnStartRdp')
$btnQuickAssist = $window.FindName('btnQuickAssist')
$btnRestartComputer = $window.FindName('btnRestartComputer')
$btnRemoteCommand = $window.FindName('btnRemoteCommand')
$btnGpUpdate = $window.FindName('btnGpUpdate')
$btnFlushDns = $window.FindName('btnFlushDns')
$btnGetPrinter = $window.FindName('btnGetPrinter')
$btnRestartSpooler = $window.FindName('btnRestartSpooler')
$btnUnlockAd = $window.FindName('btnUnlockAd')
$btnResetAdPassword = $window.FindName('btnResetAdPassword')
$btnEntraSync = $window.FindName('btnEntraSync')
$btnMessageTrace = $window.FindName('btnMessageTrace')
$btnMailboxStats = $window.FindName('btnMailboxStats')
$btnExchangeBlockDomain = $window.FindName('btnExchangeBlockDomain')
$btnGetAutoReply = $window.FindName('btnGetAutoReply')


$btnUninstallSoftware = $window.FindName('btnUninstallSoftware')
$btnForceUpdates = $window.FindName('btnForceUpdates')
$btnSendPopup = $window.FindName('btnSendPopup')
$btnForceLogoff = $window.FindName('btnForceLogoff')
$btnLockWorkstation = $window.FindName('btnLockWorkstation')
$btnSetTenant = $window.FindName('btnSetTenant')

