param(
    [string]$Database='QuanLyGaraOTo_Verify_20261029',
    [string]$ApiUrl='http://127.0.0.1:8088/api',
    [string]$OutputPath=(Join-Path ([IO.Path]::GetTempPath()) 'garage-verify-session.json')
)
$ErrorActionPreference='Stop'
if ($Database -notmatch '^QuanLyGaraOTo_Verify_[0-9]{8}(_[a-zA-Z0-9]+)?$' -or $ApiUrl -notmatch '^http://127\.0\.0\.1:8088/api$') {
    throw 'This fixture is only for the isolated local verification server on port 8088.'
}
$tag=Get-Date -Format 'MMddHHmmss'
$password=[Guid]::NewGuid().ToString('N')+'aA!'
function Register-Person($name,$login,$phone) {
    $payload=@{fullName=$name;username=$login;phone=$phone;password=$password;email='';address='TP. Hồ Chí Minh'} | ConvertTo-Json
    $null=Invoke-RestMethod -Uri "$ApiUrl/auth/register" -Method Post -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($payload))
    $session=(Invoke-RestMethod -Uri "$ApiUrl/auth/login" -Method Post -ContentType 'application/json' -Body (@{username=$login;password=$password}|ConvertTo-Json)).data
    return @{username=$login;password=$password;id=$session.account.id;customerId=$session.account.customerId;token=$session.accessToken}
}
$customer=Register-Person 'Nguyễn Minh Anh' "minhanh.$tag" ('09'+$tag.Substring(2))
$other=Register-Person 'Lê Hoàng Nam' "hoangnam.$tag" ('08'+$tag.Substring(2))
$manager=Register-Person 'Trần Quang Huy' "quanghuy.$tag" ('07'+$tag.Substring(2))
$id=[int]$manager.id
# Only the newly registered account in the isolated DB is promoted to a staff fixture.
$sql=@"
SET XACT_ABORT ON;
IF DB_NAME() <> N'$Database' THROW 51000, 'Wrong verification database', 1;
IF NOT EXISTS(SELECT 1 FROM TaiKhoan WHERE MaTaiKhoan=$id AND TenDangNhap='quanghuy.$tag' AND VaiTro='CUSTOMER')
    THROW 51001, 'API and SQL fixture databases do not match', 1;
BEGIN TRANSACTION;
INSERT INTO NhanVien(HoTen,ChucVu) VALUES(N'Trần Quang Huy',N'QUAN_LY');
DECLARE @employee INT=SCOPE_IDENTITY();
UPDATE TaiKhoan SET MaNhanVien=@employee,MaKhachHang=NULL,VaiTro=N'MANAGER' WHERE MaTaiKhoan=$id;
COMMIT;
"@
$sqlPath=Join-Path ([IO.Path]::GetTempPath()) 'garage-verify-staff.sql'
Set-Content -LiteralPath $sqlPath -Value $sql -Encoding utf8
& sqlcmd -S localhost -E -C -I -f 65001 -d $Database -b -i $sqlPath
if($LASTEXITCODE -ne 0){throw 'Cannot prepare staff fixture.'}
$managerSession=(Invoke-RestMethod -Uri "$ApiUrl/auth/login" -Method Post -ContentType 'application/json' -Body (@{username=$manager.username;password=$password}|ConvertTo-Json)).data
$manager.token=$managerSession.accessToken
$managerHeaders=@{Authorization='Bearer '+$manager.token}
$customerHeaders=@{Authorization='Bearer '+$customer.token}
$vehicle=(Invoke-RestMethod -Uri "$ApiUrl/vehicles" -Method Post -Headers $customerHeaders -ContentType 'application/json' -Body (@{customerId=$customer.customerId;licensePlate=('51A-'+$tag.Substring(5));brand='Toyota';model='Vios';year=2021;mileage=25000}|ConvertTo-Json)).data
$servicePayload=@{name='Kiểm tra hệ thống phanh';type='KIEM_TRA';unitPrice=150000;description='Kiểm tra má phanh và dầu phanh';active=$true}|ConvertTo-Json
$service=(Invoke-RestMethod -Uri "$ApiUrl/services" -Method Post -Headers $managerHeaders -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($servicePayload))).data
$date=(Get-Date).Date.AddDays(15)
$day=if([int]$date.DayOfWeek -eq 0){7}else{[int]$date.DayOfWeek}
foreach($time in @('09:30','10:30')) {
    $null=Invoke-RestMethod -Uri "$ApiUrl/appointments/schedule" -Method Put -Headers $managerHeaders -ContentType 'application/json' -Body (@{dayOfWeek=$day;time=$time;capacity=1}|ConvertTo-Json)
}
@{apiUrl=$ApiUrl;database=$Database;customer=$customer;otherCustomer=$other;manager=$manager;vehicleId=$vehicle.id;plate=$vehicle.licensePlate;serviceId=$service.id;date=$date.ToString('yyyy-MM-dd');time='09:30';newTime='10:30'} |
    ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $OutputPath -Encoding utf8
Write-Output "Verification fixture saved locally: $OutputPath"
Write-Output 'Credentials are not printed or committed. These accounts exist only in the verification database.'
