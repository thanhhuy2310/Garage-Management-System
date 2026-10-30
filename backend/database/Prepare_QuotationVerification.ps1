param([string]$FixturePath = (Join-Path ([IO.Path]::GetTempPath()) 'garage-verify-session.json'))
$ErrorActionPreference='Stop'
$fixture=Get-Content -LiteralPath $FixturePath -Raw|ConvertFrom-Json
if($fixture.database -notmatch '^QuanLyGaraOTo_Verify_\d{8}$' -or $fixture.apiUrl -ne 'http://127.0.0.1:8088/api') {
    throw 'Only the isolated verification environment is allowed.'
}
$login=(Invoke-RestMethod -Method Post -Uri ($fixture.apiUrl+'/auth/login') -ContentType 'application/json' -Body (@{username=$fixture.manager.username;password=$fixture.manager.password}|ConvertTo-Json)).data
$headers=@{Authorization='Bearer '+$login.accessToken}
$vehicleId=[int]$fixture.vehicleId
$customerId=[int]$fixture.customer.customerId
$sql=@"
SET NOCOUNT ON;
SET XACT_ABORT ON;
IF NOT EXISTS(SELECT 1 FROM Xe WHERE MaXe=$vehicleId AND MaKhachHang=$customerId) THROW 51000,'Fixture does not match database',1;
INSERT INTO PhieuTiepNhan(MaXe,NgayTiepNhan,TinhTrangBanDau,YeuCauKhachHang)
VALUES($vehicleId,SYSDATETIME(),N'Phanh có tiếng kêu',N'Kiểm tra phanh và lọc dầu');
SELECT CONVERT(INT,SCOPE_IDENTITY());
"@
$path=Join-Path ([IO.Path]::GetTempPath()) 'garage-quote-reception.sql'
Set-Content -LiteralPath $path -Value $sql -Encoding utf8
$output=& sqlcmd -S localhost -E -C -I -f 65001 -d $fixture.database -b -h -1 -W -i $path
if($LASTEXITCODE -ne 0){throw 'Cannot create isolated reception prerequisite.'}
$receptionId=[int](($output|Out-String).Trim())
$order=(Invoke-RestMethod -Method Post -Uri ($fixture.apiUrl+'/repair-orders') -Headers $headers -ContentType 'application/json' -Body (@{receptionId=$receptionId;services=@(@{serviceId=[int]$fixture.serviceId;quantity=1})}|ConvertTo-Json -Depth 5)).data.order
$warehouses=(Invoke-RestMethod -Uri ($fixture.apiUrl+'/spare-parts/warehouses') -Headers $headers).data
if($warehouses.Count -eq 0){throw 'Verification schema must contain its base warehouse.'}
$payload=@{warehouseId=$warehouses[0].id;name='Lọc dầu động cơ';manufacturer='Toyota';unitPrice=50000;minStockLevel=0}|ConvertTo-Json
$part=(Invoke-RestMethod -Method Post -Uri ($fixture.apiUrl+'/spare-parts') -Headers $headers -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($payload))).data
$fixture|Add-Member -Force -NotePropertyName quotationOrderId -NotePropertyValue $order.id
$fixture|Add-Member -Force -NotePropertyName quotationPartId -NotePropertyValue $part.id
$fixture|ConvertTo-Json -Depth 10|Set-Content -LiteralPath $FixturePath -Encoding utf8
Write-Output "Quotation prerequisite ready: repair order $($order.id), part $($part.id)."
Write-Output 'Reception is a SQL fixture for Phase C only; this does not claim the reception UI has passed.'
