# Run under the deployment identity (Windows integrated SQL authentication).
param(
    [Parameter(Mandatory)][ValidatePattern('^[A-Za-z][A-Za-z0-9_]{2,80}$')][string]$Database,
    [string]$Server='localhost', [switch]$Create, [switch]$TrustServerCertificate,
    [string]$BaselineThrough, [string]$Through
)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Data
$steps=[ordered]@{
    'QuanLyGaraOTo.sql'="OBJECT_ID('dbo.TRG_PhieuSuaChua_ThongBaoHoanTat') IS NOT NULL AND OBJECT_ID('dbo.ThanhToan') IS NOT NULL"
    'migrations/V001__add_customer_status.sql'="COL_LENGTH('dbo.KhachHang','TrangThai') IS NOT NULL"
    'migrations/V002__repair_progress_and_payment_requests.sql'="COL_LENGTH('dbo.ThanhToan','MaYeuCau') IS NOT NULL AND OBJECT_ID('dbo.NhatKySuaChua') IS NOT NULL"
    'migrations/V003__receiving_bank_accounts.sql'="COL_LENGTH('dbo.ThanhToan','MaTaiKhoanNhan') IS NOT NULL AND OBJECT_ID('dbo.TaiKhoanNganHangGara') IS NOT NULL"
    'migrations/V004__service_status.sql'="COL_LENGTH('dbo.DichVu','TrangThai') IS NOT NULL"
    'migrations/V002__warehouse_actual_used_and_stock_check.sql'="OBJECT_ID('dbo.ChiTietKiemKe') IS NOT NULL AND COL_LENGTH('dbo.ChiTietPhieuXuat','SoLuongThucDung') IS NOT NULL"
    'migrations/V003__confirm_usage_row_lock.sql'="OBJECT_DEFINITION(OBJECT_ID('dbo.sp_XacNhanSuDungPhuTung')) LIKE '%WITH (UPDLOCK, HOLDLOCK)%'"
    'patches/Repair_Safety_Procedures.sql'="OBJECT_DEFINITION(OBJECT_ID('dbo.sp_GhiNhanThanhToan')) LIKE '%WITH (UPDLOCK, HOLDLOCK)%'"
    'migrations/V004__customer_notifications_and_maintenance_reminders.sql'="OBJECT_ID('dbo.TRG_LichHen_ThongBao') IS NOT NULL AND COL_LENGTH('dbo.ThongBao','MaLichNhac') IS NOT NULL"
    'migrations/V005__insurance_company_policy.sql'="OBJECT_ID('dbo.HopDongBaoHiem') IS NOT NULL"
    'migrations/V006__insurance_claim.sql'="OBJECT_ID('dbo.NhatKyHoSoBaoHiem') IS NOT NULL"
    'migrations/V007__insurance_owner_names.sql'="COL_LENGTH('dbo.HopDongBaoHiem','TenChuXeTrenChungNhan') IS NOT NULL"
    'migrations/V008__appointment_workflow.sql'="OBJECT_ID('dbo.LichSuLichHen') IS NOT NULL AND OBJECT_ID('dbo.KhungGioTiepNhan') IS NOT NULL"
    'migrations/V009__quotation_workflow.sql'="OBJECT_ID('dbo.TRG_ChiTietPhieuXuat_BaoGiaDaDuyet') IS NOT NULL AND OBJECT_ID('dbo.LichSuBaoGia') IS NOT NULL"
    'migrations/V010__reception_workflow.sql'="COL_LENGTH('dbo.PhieuTiepNhan','MaLichHen') IS NOT NULL AND COL_LENGTH('dbo.PhieuTiepNhan','PhienBan') IS NOT NULL"
    'migrations/V011__customer_contact_messages.sql'="OBJECT_ID('dbo.LienHeKhachHang') IS NOT NULL"
    'migrations/V012__insurance_assessment.sql'="OBJECT_ID('dbo.ChungTuBaoHiem') IS NOT NULL AND OBJECT_ID('dbo.KetQuaGiamDinh') IS NOT NULL"
    'migrations/V013__insurance_receivables.sql'="OBJECT_ID('dbo.ThuBaoHiem') IS NOT NULL AND OBJECT_ID('dbo.PhanBoDongBaoHiem') IS NOT NULL AND OBJECT_ID('dbo.CongNoBaoHiem') IS NOT NULL"
    'migrations/V014__session_revocations.sql'="OBJECT_ID('dbo.RevokedSession') IS NOT NULL"
}
$ids=@($steps.Keys); $end=$ids.Count-1; $baseline=-1
if($Through){$end=$ids.IndexOf($Through); if($end -lt 0){throw 'Unknown Through migration'}}
if($BaselineThrough){$baseline=$ids.IndexOf($BaselineThrough); if($baseline -lt 0 -or $baseline -gt $end){throw 'Invalid baseline'}}
if($Database -in @('master','model','msdb','tempdb')){throw 'System database is forbidden'}
$cs=New-Object System.Data.SqlClient.SqlConnectionStringBuilder
$cs['Data Source']=$Server; $cs['Initial Catalog']='master'; $cs['Integrated Security']=$true
$cs['Encrypt']=$true; $cs['TrustServerCertificate']=[bool]$TrustServerCertificate
$c=New-Object System.Data.SqlClient.SqlConnection $cs.ConnectionString
$tx=$null
function Query([string]$sql) {
    $cmd=$c.CreateCommand(); try {
        $cmd.CommandText=$sql; $cmd.CommandTimeout=180; if($tx){$cmd.Transaction=$tx}
        return $cmd.ExecuteScalar()
    } finally {$cmd.Dispose()}
}
try {
    $c.Open()
    if(!(Query "SELECT COUNT(*) FROM sys.databases WHERE name=N'$Database'")){
        if(!$Create -or $BaselineThrough){throw 'Database does not exist. Use -Create for a new database.'}
        $null=Query "CREATE DATABASE [$Database]"
    } elseif($Create){throw 'Database already exists. Refusing -Create.'}
    $c.ChangeDatabase($Database)
    $null=Query "SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; SET ANSI_WARNINGS ON; SET ARITHABORT ON; SET XACT_ABORT ON; DECLARE @r int; EXEC @r=sys.sp_getapplock @Resource='garage:schema',@LockMode='Exclusive',@LockOwner='Session',@LockTimeout=5000; IF @r<0 THROW 51000,'Schema migration in progress',1;"
    $tracked=Query "SELECT COUNT(*) FROM sys.tables WHERE object_id=OBJECT_ID('dbo.GarageSchemaHistory')"
    if(!$tracked -and (Query 'SELECT COUNT(*) FROM sys.tables WHERE is_ms_shipped=0') -and !$BaselineThrough){throw 'Untracked existing schema. Verify the last applied script and provide -BaselineThrough.'}
    if($tracked -and $BaselineThrough){throw 'Database already tracked. Omit -BaselineThrough.'}
    $content=@{}; $hashes=@{}
    foreach($id in $ids){
        $source=[IO.File]::ReadAllText((Join-Path $PSScriptRoot $id)).Replace([string][char]13,'')
        if($id -eq 'QuanLyGaraOTo.sql'){
            $schema=[regex]::Match($source,'(?ims)^CREATE TABLE KhachHang\b.*?^CREATE OR ALTER TRIGGER dbo\.TRG_PhieuSuaChua_ThongBaoHoanTat\b.*?^END;[ \t]*\nGO[ \t]*$')
            if(!$schema.Success){throw 'Unrecognized base schema boundaries.'}
            $source=$schema.Value
        }
        $content[$id]=$source
        $sha=[Security.Cryptography.SHA256]::Create()
        try {$hashes[$id]=[BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($source))).Replace('-','')} finally {$sha.Dispose()}
    }
    if(!$tracked){
        $tx=$c.BeginTransaction()
        $null=Query 'CREATE TABLE dbo.GarageSchemaHistory (Step int NOT NULL PRIMARY KEY, Script varchar(180) NOT NULL UNIQUE, Sha256 char(64) NOT NULL, Mode varchar(12) NOT NULL, AppliedAt datetime2 NOT NULL DEFAULT SYSUTCDATETIME())'
        for($i=0;$i -le $baseline;$i++){
            $id=$ids[$i]; if(!(Query "SELECT CASE WHEN $($steps[$id]) THEN 1 ELSE 0 END")){throw "Baseline evidence missing: $id"}
            $null=Query "INSERT dbo.GarageSchemaHistory(Step,Script,Sha256,Mode) VALUES($i,'$id','$($hashes[$id])','baseline')"
        }
        $tx.Commit(); $tx=$null
    }
    $count=Query 'SELECT COUNT(*) FROM dbo.GarageSchemaHistory'
    if($count -gt $ids.Count){throw 'Database ahead of this release.'}
    for($i=0;$i -lt $count;$i++){
        $id=$ids[$i]
        if(!(Query "SELECT COUNT(*) FROM dbo.GarageSchemaHistory WHERE Step=$i AND Script='$id' AND Sha256='$($hashes[$id])'")){throw "History mismatch: $id"}
    }
    if($count -gt ($end+1)){throw 'Refusing downgrade.'}
    for($i=$count;$i -le $end;$i++){
        $id=$ids[$i]
        $source=$content[$id] -replace '(?im)^USE\s+QuanLyGaraOTo;[ \t]*$',''
        if($source -match '(?im)^\s*(USE\s|:r\s|:connect\s|(?:DROP|ALTER|CREATE)\s+DATABASE\b)'){throw "Unexpected database directive: $id"}
        $tx=$c.BeginTransaction()
        foreach($batch in [regex]::Split($source,'(?im)^[ \t]*GO[ \t]*(?:--[^\n]*)?$')){
            if($batch.Trim()){$null=Query $batch}
        }
        if(!(Query "SELECT CASE WHEN $($steps[$id]) THEN 1 ELSE 0 END")){throw "Postcondition failed: $id"}
        $null=Query "INSERT dbo.GarageSchemaHistory(Step,Script,Sha256,Mode) VALUES($i,'$id','$($hashes[$id])','applied')"
        $tx.Commit(); $tx=$null; Write-Output "Applied $id"
    }
    Write-Output "$Database verified through $($ids[$end])"
} catch {
    if($tx -and $tx.Connection){$tx.Rollback()}
    throw
} finally {$c.Dispose()}
