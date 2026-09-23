# LazyWinAdmin UI section — Helpdesk Quick Actions.
# Dot-sourced by Start-LazyWinAdmin into its scope.
# Individual handler groups live under Helpdesk/ to keep each concern small.

Add-Type -AssemblyName Microsoft.VisualBasic

$helpdeskHandlerPath = Join-Path $UiHandlerPath 'Helpdesk'

. (Join-Path $helpdeskHandlerPath 'Initialize-HelpdeskHelpers.ps1')
. (Join-Path $helpdeskHandlerPath 'Register-HelpdeskEndpointHandlers.ps1')
. (Join-Path $helpdeskHandlerPath 'Register-HelpdeskSessionHandlers.ps1')
. (Join-Path $helpdeskHandlerPath 'Register-HelpdeskIdentityHandlers.ps1')
. (Join-Path $helpdeskHandlerPath 'Register-HelpdeskExchangeHandlers.ps1')
