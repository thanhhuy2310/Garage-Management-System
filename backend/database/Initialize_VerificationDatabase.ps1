param(
    [string]$Database = 'QuanLyGaraOTo_Verify_20261029',
    [string]$Server = 'localhost'
)
$ErrorActionPreference = 'Stop'
if ($Database -notmatch '^QuanLyGaraOTo_Verify_[0-9]{8}(_[a-zA-Z0-9]+)?$') {
    throw 'Only a separate QuanLyGaraOTo_Verify_YYYYMMDD database is allowed.'
}
$exists = & sqlcmd -S $Server -E -C -d master -h -1 -W -b -Q "SET NOCOUNT ON; SELECT COUNT(*) FROM sys.databases WHERE name=N'$Database';"
if ($LASTEXITCODE -ne 0) { throw 'Cannot inspect SQL Server.' }
if (($exists | Out-String).Trim() -ne '0') { throw 'Database already exists. Initialization is never rerun over existing data.' }
$scripts = @(
    'QuanLyGaraOTo.sql',
    'migrations/V001__add_customer_status.sql',
    'migrations/V002__repair_progress_and_payment_requests.sql',
    'migrations/V003__receiving_bank_accounts.sql',
    'migrations/V004__service_status.sql',
    'migrations/V002__warehouse_actual_used_and_stock_check.sql',
    'migrations/V003__confirm_usage_row_lock.sql',
    'patches/Repair_Safety_Procedures.sql',
    'migrations/V004__customer_notifications_and_maintenance_reminders.sql',
    'migrations/V005__insurance_company_policy.sql',
    'migrations/V006__insurance_claim.sql',
    'migrations/V007__insurance_owner_names.sql',
    'migrations/V008__appointment_workflow.sql',
    'migrations/V009__quotation_workflow.sql'
)
$targetFolder = Join-Path ([IO.Path]::GetTempPath()) $Database
New-Item -ItemType Directory -Path $targetFolder -Force | Out-Null
foreach ($script in $scripts) {
    $source = Get-Content -LiteralPath (Join-Path $PSScriptRoot $script) -Raw -Encoding utf8
    $source = $source.Replace('QuanLyGaraOTo', $Database)
    $target = Join-Path $targetFolder ([IO.Path]::GetFileName($script))
    Set-Content -LiteralPath $target -Value $source -Encoding utf8
    $contextDatabase = if ($script -eq 'QuanLyGaraOTo.sql') { 'master' } else { $Database }
    & sqlcmd -S $Server -E -C -I -f 65001 -d $contextDatabase -b -i $target
    if ($LASTEXITCODE -ne 0) { throw "Failed: $script. Keep database for diagnosis; do not recreate it." }
    Write-Output "Applied: $script"
}
Write-Output "Created isolated verification database: $Database"
