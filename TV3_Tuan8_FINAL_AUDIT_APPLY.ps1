<#
  TV3_Tuan8_FINAL_AUDIT_APPLY.ps1 - Sua loi audit Tuan 8 (TV3 Hoang Van Cam)
   A. KTV chi xem chi tiet phieu xuat lien quan den minh (403 neu khong)
   B. Chong xac nhan thuc dung trung dong thoi (khoa dong ChiTietPhieuXuat, Java + migration V003)
   C. Tai lieu setup database: README.md, backend/README.md, backend/database/migrations/README.md
  Chay tu repository root:   .\TV3_Tuan8_FINAL_AUDIT_APPLY.ps1      Tuy chon: -SkipBuild, -NoZip
  Chi va dung cac doan can thiet. Khong checkout/commit/push Git. Khong ghi de file cua nguoi khac.
#>
param(
    [switch]$SkipBuild,
    [switch]$NoZip
)

$ErrorActionPreference = "Stop"
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[Console]::OutputEncoding = $utf8NoBom
$script:Warnings = New-Object System.Collections.Generic.List[string]
$script:Results = [ordered]@{}

function Write-Step($m) { Write-Host ""; Write-Host "==> $m" -ForegroundColor Cyan }
function Write-Ok($m)   { Write-Host "    [OK]   $m" -ForegroundColor Green }
function Write-Warn2($m){ Write-Host "    [WARN] $m" -ForegroundColor Yellow; $script:Warnings.Add($m) }
function Stop-Fail($m)  { Write-Host ""; Write-Host "FAIL: $m" -ForegroundColor Red; exit 1 }

# ------------------------------------------------------------
# 1. XAC DINH REPOSITORY ROOT + KIEM TRA CAU TRUC (checkpoint Tuan 8 phai co san)
# ------------------------------------------------------------
Write-Step "Kiem tra repository"
$root = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$required = @(
    "backend/pom.xml",
    "backend/mvnw.cmd",
    "backend/database/QuanLyGaraOTo.sql",
    "backend/database/migrations/V002__warehouse_actual_used_and_stock_check.sql",
    "backend/src/main/java/com/gara/quanlygara/repository/StockIssueRepository.java",
    "backend/src/main/java/com/gara/quanlygara/repository/StockIssueItemRepository.java",
    "backend/src/main/java/com/gara/quanlygara/service/StockIssueService.java",
    "backend/src/main/java/com/gara/quanlygara/controller/StockIssueController.java",
    "backend/src/test/java/com/gara/quanlygara/service/StockIssueServiceTest.java",
    "backend/src/test/java/com/gara/quanlygara/controller/WarehouseApiTest.java",
    "frontend/package.json",
    "README.md",
    "backend/README.md"
)
$missing = @($required | Where-Object { -not (Test-Path -LiteralPath (Join-Path $root $_)) })
if ($missing.Count -gt 0) {
    Stop-Fail ("Khong dung repository root ($root). Thieu:`n  - " + ($missing -join "`n  - "))
}
Set-Location -LiteralPath $root
Write-Ok "Repository root: $root"

$service = [System.IO.File]::ReadAllText((Join-Path $root "backend/src/main/java/com/gara/quanlygara/service/StockIssueService.java"), $utf8NoBom)
if (-not $service.Contains("TV3-TUAN8")) { Stop-Fail "StockIssueService.java khong phai ban Tuan 8 do script tao. Hay ap dung TV3_Tuan8_Warehouse_APPLY.ps1 truoc." }
Write-Ok "Da co ma nguon kho Tuan 8; giu nguyen schema, khong tao bang moi"

foreach ($cmd in @("java")) {
    if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) { Stop-Fail "Khong tim thay lenh '$cmd' trong PATH." }
}
if (-not $SkipBuild) {
    foreach ($cmd in @("node", "npm")) {
        if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) { Stop-Fail "Khong tim thay lenh '$cmd' trong PATH (dung -SkipBuild neu chi muon ap dung file)." }
    }
}

# ------------------------------------------------------------
# 2. GIT (chi doc + tao/chuyen nhanh feature/cam-vehicle neu dang o main)
# ------------------------------------------------------------
Write-Step "Git (chi doc, khong checkout)"
if ((Get-Command git -ErrorAction SilentlyContinue) -and (Test-Path -LiteralPath (Join-Path $root ".git"))) {
    $branch = (git rev-parse --abbrev-ref HEAD).Trim()
    Write-Host "    Nhanh hien tai: $branch"
    if ($branch -ne "feature/cam-warehouse") { Write-Warn2 "Dang o nhanh '$branch', khong phai feature/cam-warehouse. Script KHONG tu chuyen nhanh." }
    $dirty = git status --short
    if ($dirty) { Write-Host "    Thay doi chua commit (se duoc giu nguyen):"; $dirty | ForEach-Object { Write-Host "      $_" } }
    $exclude = Join-Path $root ".git/info/exclude"
    if ((Test-Path -LiteralPath $exclude) -and -not (Select-String -LiteralPath $exclude -Pattern "^\.backup/?$" -Quiet)) {
        Add-Content -LiteralPath $exclude -Value ".backup/"
    }
} else {
    Write-Warn2 "Khong phai git repository (hoac chua cai git) - bo qua buoc git."
}

# ------------------------------------------------------------
# 3. HAM HO TRO: backup, ghi file, va file
# ------------------------------------------------------------
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupDir = Join-Path $root ".backup/vehicle-$stamp"

function Backup-RepoFile($rel) {
    $src = Join-Path $root $rel
    if (-not (Test-Path -LiteralPath $src)) { return }
    $dst = Join-Path $backupDir $rel
    New-Item -ItemType Directory -Force -Path (Split-Path $dst) | Out-Null
    if (-not (Test-Path -LiteralPath $dst)) { Copy-Item -LiteralPath $src -Destination $dst }
}

$script:Marker = "TV3-TUAN8"
# File mock cu cua nhom duoc phep thay (co backup) neu van la ban mock: duong dan -> chuoi nhan dang.
$script:Replaceable = @{ "frontend/src/pages/Inventory.tsx" = "mock/schemaData" }

function Get-RepositoryNames {
    $dir = Join-Path $root "backend/src/main/java/com/gara/quanlygara/repository"
    @(Get-ChildItem -LiteralPath $dir -Filter "*Repository.java" | ForEach-Object { $_.BaseName } | Sort-Object)
}

# Thay placeholder trong file test moi bang @MockitoBean cho TAT CA repository hien co
# (test Spring khong co JPA nen moi repository phai duoc mock).
function Expand-MockBeans($content) {
    if (-not $content.Contains("//__MOCK_IMPORTS__")) { return $content }
    $names = Get-RepositoryNames
    $imports = ($names | ForEach-Object { "import com.gara.quanlygara.repository.$_;" }) -join "`n"
    $fields = ($names | ForEach-Object {
        $field = $_.Substring(0, 1).ToLower() + $_.Substring(1)
        "    @MockitoBean`n    private $_ $field;"
    }) -join "`n`n"
    return $content.Replace("//__MOCK_IMPORTS__", $imports).Replace("//__MOCK_FIELDS__", $fields)
}

function Write-RepoFile($rel, $content) {
    $path = Join-Path $root $rel
    $text = ((Expand-MockBeans $content) -replace "`r`n", "`n").TrimEnd("`n") + "`n"
    if (Test-Path -LiteralPath $path) {
        $existing = [System.IO.File]::ReadAllText($path, $utf8NoBom) -replace "`r`n", "`n"
        if ($existing -eq $text) { Write-Host "    = $rel (khong doi)"; return }
        $isMockPage = $script:Replaceable.ContainsKey($rel) -and $existing.Contains($script:Replaceable[$rel])
        if (-not $existing.Contains($script:Marker) -and -not $isMockPage) {
            Stop-Fail "File da ton tai va KHONG phai do script Tuan 7 tao: $rel`nKhong ghi de code cua nguoi khac. Hay gui file nay cho Claude de doi chieu/chinh script."
        }
        Backup-RepoFile $rel
        Write-Host "    ~ $rel (da backup)"
    } else {
        New-Item -ItemType Directory -Force -Path (Split-Path $path) | Out-Null
        Write-Host "    + $rel"
    }
    [System.IO.File]::WriteAllText($path, $text, $utf8NoBom)
}

# Them @MockitoBean cho cac repository moi vao CAC test Spring da co (do nhom viet) dang loai bo JPA,
# neu khong ApplicationContext khong len duoc khi co repository moi.
function Sync-MockBeans {
    $testDir = Join-Path $root "backend/src/test/java"
    $names = Get-RepositoryNames
    foreach ($file in Get-ChildItem -LiteralPath $testDir -Recurse -Filter "*.java") {
        $raw = [System.IO.File]::ReadAllText($file.FullName, $utf8NoBom)
        if (-not ($raw.Contains("JpaRepositoriesAutoConfiguration") -and $raw.Contains("@MockitoBean"))) { continue }
        if ($raw.Contains($script:Marker)) { continue }
        $crlf = $raw.Contains("`r`n")
        $text = $raw -replace "`r`n", "`n"
        $missing = @($names | Where-Object { $text -notmatch ("\b" + $_ + "\s+\w+;") })
        if ($missing.Count -eq 0) { continue }
        $rel = $file.FullName.Substring($root.Length).TrimStart('\', '/')
        $imports = [regex]::Matches($text, '(?m)^import com\.gara\.quanlygara\.repository\.\w+;[ \t]*$')
        $fields = [regex]::Matches($text, '(?m)^([ \t]*)private \w+Repository \w+;[ \t]*$')
        if ($imports.Count -eq 0 -or $fields.Count -eq 0) {
            Stop-Fail "Khong tu them duoc @MockitoBean vao $rel (khong tim thay import/field repository mau). Thieu: $($missing -join ', '). Gui file nay cho Claude."
        }
        Backup-RepoFile $rel
        $lastField = $fields[$fields.Count - 1]
        $indent = $lastField.Groups[1].Value
        $fieldText = ""
        foreach ($name in $missing) {
            $field = $name.Substring(0, 1).ToLower() + $name.Substring(1)
            $fieldText += "`n`n$indent@MockitoBean`n${indent}private $name $field;"
        }
        $text = $text.Insert($lastField.Index + $lastField.Length, $fieldText)
        $lastImport = $imports[$imports.Count - 1]
        $importText = ($missing | ForEach-Object { "`nimport com.gara.quanlygara.repository.$_;" }) -join ""
        $text = $text.Insert($lastImport.Index + $lastImport.Length, $importText)
        if ($crlf) { $text = $text -replace "`n", "`r`n" }
        [System.IO.File]::WriteAllText($file.FullName, $text, $utf8NoBom)
        Write-Host "    ~ $rel (them mock: $($missing -join ', '))"
    }
}

function Update-RepoFile($rel, $old, $new, $marker) {
    $path = Join-Path $root $rel
    if (-not (Test-Path -LiteralPath $path)) { Stop-Fail "Thieu file can va: $rel" }
    $raw = [System.IO.File]::ReadAllText($path, $utf8NoBom)
    if ($raw.Contains($marker)) { Write-Host "    = $rel (da va: $marker)"; return }
    $crlf = $raw.Contains("`r`n")
    $o = if ($crlf) { $old -replace "`r?`n", "`r`n" } else { $old -replace "`r`n", "`n" }
    $n = if ($crlf) { $new -replace "`r?`n", "`r`n" } else { $new -replace "`r`n", "`n" }
    $count = ([regex]::Matches($raw, [regex]::Escape($o))).Count
    if ($count -ne 1) {
        Stop-Fail "File $rel khac du kien (tim thay $count vi tri cho doan can va, can dung 1):`n$old`nDung lai, khong sua gi them. Gui file nay cho Claude de chinh script."
    }
    Backup-RepoFile $rel
    $idx = $raw.IndexOf($o, [System.StringComparison]::Ordinal)
    [System.IO.File]::WriteAllText($path, $raw.Substring(0, $idx) + $n + $raw.Substring($idx + $o.Length), $utf8NoBom)
    Write-Host "    ~ $rel (va, da backup)"
}

function Invoke-Native($title, $dir, $logName, [scriptblock]$command) {
    Write-Step $title
    New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
    $log = Join-Path $backupDir $logName
    Push-Location -LiteralPath $dir
    $prev = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        & $command 2>&1 | ForEach-Object { "$_" } | Tee-Object -FilePath $log
        $code = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $prev
        Pop-Location
    }
    if ($code -ne 0) {
        $script:Results[$title] = "FAIL (exit $code)"
        Write-Host ""
        Write-Host "Log day du: $log" -ForegroundColor Yellow
        Show-Summary
        exit 1
    }
    $script:Results[$title] = "PASS"
    Write-Ok "$title - PASS"
}

function Show-Summary {
    Write-Host ""
    Write-Host "================ KET QUA ================" -ForegroundColor Cyan
    foreach ($k in $script:Results.Keys) {
        $v = $script:Results[$k]
        $color = if ($v -like "PASS*") { "Green" } elseif ($v -like "SKIPPED*") { "Yellow" } else { "Red" }
        Write-Host ("  {0,-34} {1}" -f $k, $v) -ForegroundColor $color
    }
    foreach ($w in $script:Warnings) { Write-Host "  WARN: $w" -ForegroundColor Yellow }
    Write-Host "  Backup file goc: $backupDir"
}

# ------------------------------------------------------------
# 4. HAM TAI LIEU (README): khoi co marker, khong ghi de noi dung khac
# ------------------------------------------------------------
function Set-DocBlock($rel, $id, $content, $pattern, $position) {
    $path = Join-Path $root $rel
    if (-not (Test-Path -LiteralPath $path)) { Write-Warn2 "Khong co $rel - bo qua khoi tai lieu '$id'."; return }
    $raw = [System.IO.File]::ReadAllText($path, $utf8NoBom)
    $crlf = $raw.Contains("`r`n")
    $text = $raw -replace "`r`n", "`n"
    $begin = "<!-- TV3-TUAN8-AUDIT:$id BEGIN -->"
    $end = "<!-- TV3-TUAN8-AUDIT:$id END -->"
    $block = $begin + "`n" + (($content -replace "`r`n", "`n").Trim("`n")) + "`n" + $end
    $i = $text.IndexOf($begin, [System.StringComparison]::Ordinal)
    if ($i -ge 0) {
        $j = $text.IndexOf($end, $i, [System.StringComparison]::Ordinal)
        if ($j -lt 0) { Write-Warn2 "${rel}: khoi '$id' co BEGIN nhung thieu END, bo qua."; return }
        $new = $text.Substring(0, $i) + $block + $text.Substring($j + $end.Length)
    } else {
        $m = if ($pattern) { [regex]::Match($text, $pattern) } else { $null }
        if ($m -and $m.Success -and $position -eq "after") { $new = $text.Insert($m.Index + $m.Length, "`n`n" + $block) }
        elseif ($m -and $m.Success -and $position -eq "before") { $new = $text.Insert($m.Index, $block + "`n`n") }
        else {
            $new = $text.TrimEnd("`n") + "`n`n" + $block + "`n"
            if ($pattern) { Write-Warn2 "${rel}: khong thay vi tri chen cho '$id', da them khoi o cuoi file." }
        }
    }
    if ($new -eq $text) { Write-Host "    = $rel (khoi '$id' khong doi)"; return }
    Backup-RepoFile $rel
    if ($crlf) { $new = $new -replace "`n", "`r`n" }
    [System.IO.File]::WriteAllText($path, $new, $utf8NoBom)
    Write-Host "    ~ $rel (khoi '$id', da backup)"
}

# Bo tu "kho" khoi cau liet ke "... chua co API day du" (nghiep vu kho da co API that tu Tuan 8).
function Remove-StaleWarehouseNote($rel) {
    $path = Join-Path $root $rel
    if (-not (Test-Path -LiteralPath $path)) { return }
    $raw = [System.IO.File]::ReadAllText($path, $utf8NoBom)
    $crlf = $raw.Contains("`r`n")
    $lines = ($raw -replace "`r`n", "`n").Split("`n")
    $changed = $false
    for ($k = 0; $k -lt $lines.Length; $k++) {
        $line = $lines[$k]
        if ($line -match 'chưa có API' -and $line -match '\bkho\b') {
            $fixed = $line -replace '\bkho,\s*', ''
            if ($fixed -match '\bkho\b') { $fixed = $fixed -replace ',?\s*\bkho\b', '' }
            if ($fixed -ne $line) { Write-Host "    ~ ${rel}:$($k + 1): $line  ->  $fixed"; $lines[$k] = $fixed; $changed = $true }
        }
    }
    if (-not $changed) { Write-Host "    = $rel (khong con cau 'kho chua co API')"; return }
    Backup-RepoFile $rel
    $new = $lines -join "`n"
    if ($crlf) { $new = $new -replace "`n", "`r`n" }
    [System.IO.File]::WriteAllText($path, $new, $utf8NoBom)
}


Write-Step 'Tao file moi (migration V003, tai lieu migrations)'
Write-RepoFile 'backend/database/migrations/V003__confirm_usage_row_lock.sql' @'
-- TV3-TUAN8
-- ============================================================
-- V003 - Tuan 8 audit (TV3): chong xac nhan thuc dung trung khi hai yeu cau den dong thoi
-- Chay SAU V002. Idempotent (CREATE OR ALTER). Khong doi bang/cot, khong them trigger/job.
-- sp_XacNhanSuDungPhuTung: khoa dong ChiTietPhieuXuat (UPDLOCK, HOLDLOCK) va kiem tra lai
-- DaXacNhanSuDung trong transaction, giong cach UI/API Spring Boot khoa dong (PESSIMISTIC_WRITE).
-- ============================================================
USE QuanLyGaraOTo;
GO

CREATE OR ALTER PROCEDURE dbo.sp_XacNhanSuDungPhuTung
    @MaPhieuXuat INT,
    @MaPhuTung INT,
    @MaKyThuatVien INT,
    @SoLuongThucDung INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @MaPhieuSuaChua INT;
    DECLARE @SoLuong INT;
    DECLARE @DonGia DECIMAL(18,2);
    DECLARE @DaXacNhan BIT;

    SELECT
        @MaPhieuSuaChua = px.MaPhieuSuaChua,
        @SoLuong = ct.SoLuong,
        @DonGia = COALESCE(ct.DonGia, pt.DonGia),
        @DaXacNhan = ct.DaXacNhanSuDung
    FROM ChiTietPhieuXuat ct
    INNER JOIN PhieuXuatKho px ON px.MaPhieuXuat = ct.MaPhieuXuat
    INNER JOIN PhuTung pt ON pt.MaPhuTung = ct.MaPhuTung
    WHERE ct.MaPhieuXuat = @MaPhieuXuat
      AND ct.MaPhuTung = @MaPhuTung;

    IF @SoLuong IS NULL
        THROW 50010, N'Khong tim thay chi tiet phieu xuat.', 1;

    IF @MaPhieuSuaChua IS NULL
        THROW 50011, N'Phieu xuat nay khong gan voi phieu sua chua.', 1;

    IF @DaXacNhan = 1
        THROW 50012, N'Phu tung nay da duoc xac nhan su dung.', 1;

    IF NOT EXISTS (
        SELECT 1
        FROM PhanCongKyThuatVien
        WHERE MaPhieuSuaChua = @MaPhieuSuaChua
          AND MaKyThuatVien = @MaKyThuatVien
    )
        THROW 50013, N'Ky thuat vien khong duoc phan cong cho phieu sua chua nay.', 1;

    IF NOT EXISTS (
        SELECT 1
        FROM BaoGia
        WHERE MaPhieuSuaChua = @MaPhieuSuaChua
          AND TrangThai = N'DA_XAC_NHAN'
    )
        THROW 50014, N'Bao gia chua duoc khach hang xac nhan.', 1;

    IF NOT EXISTS (
        SELECT 1
        FROM PhieuSuaChua
        WHERE MaPhieuSuaChua = @MaPhieuSuaChua
          AND TrangThai IN (N'DANG_SUA', N'CHO_PHU_TUNG')
    )
        THROW 50016, N'Phieu sua chua khong o trang thai cho phep xac nhan su dung phu tung.', 1;

    IF @SoLuongThucDung IS NULL
        SET @SoLuongThucDung = @SoLuong;

    IF @SoLuongThucDung < 0 OR @SoLuongThucDung > @SoLuong
        THROW 50017, N'So luong thuc dung phai tu 0 den so luong cap phat.', 1;

    BEGIN TRY
        BEGIN TRAN;

        -- Khoa dong chi tiet xuat va kiem tra lai trang thai TRONG transaction:
        -- hai yeu cau xac nhan dong thoi cung mot chi tiet chi co mot yeu cau thanh cong.
        SELECT @DaXacNhan = DaXacNhanSuDung
        FROM ChiTietPhieuXuat WITH (UPDLOCK, HOLDLOCK)
        WHERE MaPhieuXuat = @MaPhieuXuat
          AND MaPhuTung = @MaPhuTung;

        IF @DaXacNhan = 1
            THROW 50012, N'Phu tung nay da duoc xac nhan su dung.', 1;

        DECLARE @TonTruoc INT;
        DECLARE @TonSau INT;
        DECLARE @TongThucDung INT;

        SELECT @TonTruoc = SoLuongTon
        FROM PhuTung WITH (UPDLOCK, HOLDLOCK)
        WHERE MaPhuTung = @MaPhuTung;

        IF @TonTruoc < @SoLuongThucDung
            THROW 50015, N'So luong ton kho khong du de xac nhan su dung.', 1;

        SET @TonSau = @TonTruoc - @SoLuongThucDung;

        -- Chi tru ton theo so luong THUC DUNG (phan con lai la hoan tra, ton khong doi).
        IF @SoLuongThucDung > 0
            UPDATE PhuTung
            SET SoLuongTon = @TonSau
            WHERE MaPhuTung = @MaPhuTung;

        UPDATE ChiTietPhieuXuat
        SET
            DaXacNhanSuDung = 1,
            NgayXacNhan = SYSDATETIME(),
            MaKyThuatVienXacNhan = @MaKyThuatVien,
            SoLuongThucDung = @SoLuongThucDung,
            SoLuongHoanTra = @SoLuong - @SoLuongThucDung
        WHERE MaPhieuXuat = @MaPhieuXuat
          AND MaPhuTung = @MaPhuTung;

        -- ChiTietPhuTung.SoLuong = tong THUC DUNG da xac nhan cua (phieu sua chua, phu tung).
        -- Neu tong = 0 thi khong dong vao dong san co (rang buoc SoLuong > 0).
        SELECT @TongThucDung = COALESCE(SUM(ct.SoLuongThucDung), 0)
        FROM ChiTietPhieuXuat ct
        INNER JOIN PhieuXuatKho px ON px.MaPhieuXuat = ct.MaPhieuXuat
        WHERE px.MaPhieuSuaChua = @MaPhieuSuaChua
          AND ct.MaPhuTung = @MaPhuTung
          AND ct.DaXacNhanSuDung = 1;

        IF @TongThucDung > 0
        BEGIN
            IF EXISTS (
                SELECT 1
                FROM ChiTietPhuTung
                WHERE MaPhieuSuaChua = @MaPhieuSuaChua
                  AND MaPhuTung = @MaPhuTung
            )
                UPDATE ChiTietPhuTung
                SET SoLuong = @TongThucDung,
                    DonGia = @DonGia
                WHERE MaPhieuSuaChua = @MaPhieuSuaChua
                  AND MaPhuTung = @MaPhuTung;
            ELSE
                INSERT INTO ChiTietPhuTung (MaPhieuSuaChua, MaPhuTung, SoLuong, DonGia)
                VALUES (@MaPhieuSuaChua, @MaPhuTung, @TongThucDung, @DonGia);
        END

        -- BienDongKho.SoLuong (>0 theo CK_BienDongKho_SoLuong) = so luong thuc dung; thuc dung = 0 thi khong co bien dong.
        IF @SoLuongThucDung > 0
            INSERT INTO BienDongKho (
                MaPhuTung, MaPhieuNhap, MaPhieuXuat,
                ThoiGian, LoaiBienDong, SoLuong,
                SoLuongTruoc, SoLuongSau, GhiChu
            )
            VALUES (
                @MaPhuTung, NULL, @MaPhieuXuat,
                SYSDATETIME(), N'XUAT', @SoLuongThucDung,
                @TonTruoc, @TonSau,
                N'KTV xac nhan thuc dung ' + CONVERT(NVARCHAR(12), @SoLuongThucDung)
                    + N'/' + CONVERT(NVARCHAR(12), @SoLuong)
                    + N' (hoan tra ' + CONVERT(NVARCHAR(12), @SoLuong - @SoLuongThucDung) + N')'
            );

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH
END;
GO
'@
Write-RepoFile 'backend/database/migrations/README.md' @'
<!-- TV3-TUAN8 -->
# Database migrations

Thứ tự setup database (bắt buộc đủ ba bước đầu, theo đúng thứ tự):

| Bước | File | Mục đích |
|---|---|---|
| 1 | `../QuanLyGaraOTo.sql` | Tạo database `QuanLyGaraOTo`, bảng, ràng buộc, procedure gốc và dữ liệu mẫu |
| 2 | `V001__add_customer_status.sql` | Thêm trạng thái khách hàng (`KhachHang.TrangThai`) |
| 3 | `V002__warehouse_actual_used_and_stock_check.sql` | Kho Tuần 8: thêm `ChiTietPhieuXuat.SoLuongThucDung`/`SoLuongHoanTra`, tạo `PhieuKiemKe`/`ChiTietKiemKe`, sửa `sp_XacNhanSuDungPhuTung` (trừ tồn theo số lượng **thực dùng**) và `sp_KiemKeTonKho` (chỉ ghi nhận kiểm kê, **không** tự đổi tồn; chỉ MANAGER duyệt qua ứng dụng) |
| 4 | `V003__confirm_usage_row_lock.sql` | Khóa dòng chi tiết phiếu xuất khi xác nhận thực dùng, chặn xác nhận trùng đồng thời trong procedure |
| tùy chọn | `../Test_Warehouse.sql` | Kiểm thử nghiệp vụ kho trên SQL Server (tự dọn dữ liệu test, in bảng PASS/FAIL) |
| tùy chọn | `../Test_Vehicles.sql`, `../Test_SpareParts.sql` | Kiểm thử ràng buộc xe / phụ tùng (tự ROLLBACK) |

Các migration đều idempotent (chạy lại không lỗi, không mất dữ liệu). Không có migration nào đổi tên bảng/cột hiện có.

Nếu chưa chạy V002, các API kho (`/api/warehouse/*`, `/api/inventory`) sẽ lỗi vì thiếu cột/bảng của Tuần 8.

## Kiểm tra thủ công chống xác nhận trùng đồng thời (SSMS, hai cửa sổ)

Test tự động của Java chỉ chứng minh API dùng khóa dòng (`PESSIMISTIC_WRITE`) và request thứ hai bị từ chối sau khi request đầu hoàn tất.
Việc hai request thực sự chạy song song cần SQL Server thật:

1. Tạo một chi tiết phiếu xuất chưa xác nhận (xem `Test_Warehouse.sql`, mục T5).
2. Cửa sổ A: `BEGIN TRAN; EXEC dbo.sp_XacNhanSuDungPhuTung @MaPhieuXuat, @MaPhuTung, @MaKyThuatVien, 3;` — **chưa COMMIT**.
3. Cửa sổ B: chạy đúng lệnh trên. B phải chờ A.
4. COMMIT ở A. B phải kết thúc với lỗi 50012 ("đã được xác nhận sử dụng"); tồn kho chỉ giảm 3 một lần và chỉ có một dòng `BienDongKho` loại `XUAT`.
'@

Write-Step 'Va code Tuan 8 (chi cac doan can sua, co backup)'
Update-RepoFile 'backend/src/main/java/com/gara/quanlygara/repository/StockIssueRepository.java' '    List<Integer> findIdsRelatedToTechnician(@Param("technicianId") Integer technicianId);
' '    List<Integer> findIdsRelatedToTechnician(@Param("technicianId") Integer technicianId);

    // Một phiếu xuất có liên quan tới KTV không (cùng điều kiện với findIdsRelatedToTechnician).
    @Query(value = "SELECT COUNT(1) FROM PhieuXuatKho px WHERE px.MaPhieuXuat = :issueId "
            + "AND (px.MaKyThuatVienYeuCau = :technicianId "
            + "OR EXISTS (SELECT 1 FROM PhanCongKyThuatVien pc WHERE pc.MaPhieuSuaChua = px.MaPhieuSuaChua "
            + "AND pc.MaKyThuatVien = :technicianId))", nativeQuery = true)
    long countRelatedToTechnician(@Param("issueId") Integer issueId, @Param("technicianId") Integer technicianId);
' 'countRelatedToTechnician'
Update-RepoFile 'backend/src/main/java/com/gara/quanlygara/service/StockIssueService.java' '    public IssueResponse get(Integer id) {
        StockIssue issue = issueRepository.findById(id)' '    public IssueResponse get(Integer id) {
        return get(id, 0);
    }

    /** technicianId = 0: không giới hạn; khác 0: chỉ được xem phiếu liên quan tới KTV đó, ngược lại AccessDenied (403). */
    @Transactional(readOnly = true)
    public IssueResponse get(Integer id, int technicianId) {
        if (technicianId != 0 && issueRepository.countRelatedToTechnician(id, technicianId) == 0) {
            throw new AccessDeniedException("Bạn không có quyền xem phiếu xuất này.");
        }
        StockIssue issue = issueRepository.findById(id)' 'get(Integer id, int technicianId)'
Update-RepoFile 'backend/src/main/java/com/gara/quanlygara/controller/StockIssueController.java' '    public ResponseEntity<ApiResponse<IssueResponse>> get(@PathVariable Integer id) {
        return ResponseEntity.ok(ApiResponse.success("Lấy phiếu xuất thành công.", issueService.get(id)));' '    public ResponseEntity<ApiResponse<IssueResponse>> get(@PathVariable Integer id, Authentication authentication) {
        // Kỹ thuật viên chỉ xem được phiếu xuất liên quan tới mình; backend trả 403 nếu không liên quan.
        int technicianId = staffContext.isTechnician(authentication) ? staffContext.employeeId(authentication) : 0;
        return ResponseEntity.ok(ApiResponse.success("Lấy phiếu xuất thành công.", issueService.get(id, technicianId)));' 'issueService.get(id, technicianId)'
Update-RepoFile 'backend/src/main/java/com/gara/quanlygara/repository/StockIssueItemRepository.java' 'import com.gara.quanlygara.entity.StockIssueItem;' 'import com.gara.quanlygara.entity.StockIssueItem;
import jakarta.persistence.LockModeType;' 'LockModeType;'
Update-RepoFile 'backend/src/main/java/com/gara/quanlygara/repository/StockIssueItemRepository.java' 'import org.springframework.data.jpa.repository.JpaRepository;' 'import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;' 'repository.Lock;'
Update-RepoFile 'backend/src/main/java/com/gara/quanlygara/repository/StockIssueItemRepository.java' 'import java.util.List;' 'import java.util.List;
import java.util.Optional;' 'import java.util.Optional;'
Update-RepoFile 'backend/src/main/java/com/gara/quanlygara/repository/StockIssueItemRepository.java' '    List<StockIssueItem> findByIssueId(Integer issueId);' '    // Khóa dòng chi tiết (UPDLOCK) tới hết transaction và đọc lại trạng thái: hai xác nhận đồng thời của cùng một
    // chi tiết được tuần tự hóa, request đến sau thấy DaXacNhanSuDung = 1 và bị từ chối.
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT i FROM StockIssueItem i WHERE i.issueId = :issueId AND i.partId = :partId")
    Optional<StockIssueItem> findForUpdate(@Param("issueId") Integer issueId, @Param("partId") Integer partId);

    List<StockIssueItem> findByIssueId(Integer issueId);' 'findForUpdate'
Update-RepoFile 'backend/src/main/java/com/gara/quanlygara/service/StockIssueService.java' 'itemRepository.findById(new StockIssueItem.Key(issueId, partId))' 'itemRepository.findForUpdate(issueId, partId)' 'itemRepository.findForUpdate(issueId, partId)'
Update-RepoFile 'backend/src/test/java/com/gara/quanlygara/service/StockIssueServiceTest.java' 'import org.springframework.transaction.annotation.Transactional;' 'import org.springframework.transaction.annotation.Transactional;
import org.springframework.data.jpa.repository.Lock;
import jakarta.persistence.LockModeType;
import java.lang.reflect.Method;' 'import jakarta.persistence.LockModeType;'
Update-RepoFile 'backend/src/test/java/com/gara/quanlygara/service/StockIssueServiceTest.java' '        lenient().when(itemRepository.findById(new StockIssueItem.Key(ISSUE_ID, PART_ID))).thenReturn(Optional.of(item));' '        lenient().when(itemRepository.findForUpdate(ISSUE_ID, PART_ID)).thenReturn(Optional.of(item));' 'lenient().when(itemRepository.findForUpdate('
Update-RepoFile 'backend/src/test/java/com/gara/quanlygara/service/StockIssueServiceTest.java' '        when(itemRepository.findById(new StockIssueItem.Key(ISSUE_ID, PART_ID))).thenReturn(Optional.empty());' '        when(itemRepository.findForUpdate(ISSUE_ID, PART_ID)).thenReturn(Optional.empty());' 'when(itemRepository.findForUpdate(ISSUE_ID, PART_ID)).thenReturn(Optional.empty());'
Update-RepoFile 'backend/src/test/java/com/gara/quanlygara/service/StockIssueServiceTest.java' '        when(itemRepository.findById(new StockIssueItem.Key(ISSUE_ID, PART_ID))).thenReturn(Optional.of(item));' '        when(itemRepository.findForUpdate(ISSUE_ID, PART_ID)).thenReturn(Optional.of(item));' '        when(itemRepository.findForUpdate(ISSUE_ID, PART_ID)).thenReturn(Optional.of(item));'
Update-RepoFile 'backend/src/test/java/com/gara/quanlygara/service/StockIssueServiceTest.java' '    @Test
    void mutatingOperationsAreTransactional() throws Exception {' '    @Test
    void confirmLocksTheIssueItemRowInsteadOfAPlainRead() throws Exception {
        arrangeConfirm(5, 12, 3, null);

        service.confirmUsage(ISSUE_ID, PART_ID, new ConfirmUsageRequest(3, null), TECHNICIAN_ID, true);

        verify(itemRepository).findForUpdate(ISSUE_ID, PART_ID);
        verify(itemRepository, never()).findById(any());
        Method lockedRead = StockIssueItemRepository.class.getMethod("findForUpdate", Integer.class, Integer.class);
        assertEquals(LockModeType.PESSIMISTIC_WRITE, lockedRead.getAnnotation(Lock.class).value());
    }

    @Test
    void secondConfirmationOfTheSameItemNeverReducesStockOrWritesMovementTwice() {
        // Khóa dòng làm request thứ hai chờ rồi đọc lại trạng thái đã xác nhận; ở đây mô phỏng đúng bước đọc lại đó.
        // (Hai request chạy song song thật cần SQL Server: xem backend/database/migrations/README.md.)
        StockIssueItem item = arrangeConfirm(5, 12, 3, null);

        service.confirmUsage(ISSUE_ID, PART_ID, new ConfirmUsageRequest(3, null), TECHNICIAN_ID, true);
        assertThrows(ConflictException.class,
                () -> service.confirmUsage(ISSUE_ID, PART_ID, new ConfirmUsageRequest(3, null), TECHNICIAN_ID, true));

        verify(sparePartRepository, times(1)).updateStockQuantity(PART_ID, 9);
        verify(movementRepository, times(1)).save(any(StockMovement.class));
        verify(repairPartItemRepository, times(1)).saveAndFlush(any(RepairPartItem.class));
        assertTrue(item.isConfirmed());
    }

    @Test
    void technicianCanReadAnIssueRelatedToThem() {
        when(issueRepository.countRelatedToTechnician(ISSUE_ID, TECHNICIAN_ID)).thenReturn(1L);
        when(issueRepository.findById(ISSUE_ID)).thenReturn(Optional.of(issue()));
        when(itemRepository.findByIssueId(ISSUE_ID)).thenReturn(List.of(issueItem(5)));

        assertEquals(ISSUE_ID, service.get(ISSUE_ID, TECHNICIAN_ID).id());
    }

    @Test
    void technicianCannotReadAnUnrelatedIssueAndNoDataIsLoaded() {
        when(issueRepository.countRelatedToTechnician(ISSUE_ID, 99)).thenReturn(0L);

        assertThrows(AccessDeniedException.class, () -> service.get(ISSUE_ID, 99));
        verify(issueRepository, never()).findById(any());
        verify(itemRepository, never()).findByIssueId(any());
    }

    @Test
    void staffReadIssuesWithoutARelationCheck() {
        when(issueRepository.findById(ISSUE_ID)).thenReturn(Optional.of(issue()));
        when(itemRepository.findByIssueId(ISSUE_ID)).thenReturn(List.of());

        assertEquals(ISSUE_ID, service.get(ISSUE_ID).id());
        verify(issueRepository, never()).countRelatedToTechnician(any(), anyInt());
    }

    @Test
    void mutatingOperationsAreTransactional() throws Exception {' 'confirmLocksTheIssueItemRowInsteadOfAPlainRead'
Update-RepoFile 'backend/src/test/java/com/gara/quanlygara/controller/WarehouseApiTest.java' 'import static org.hamcrest.Matchers.containsString;' 'import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.not;' 'Matchers.not;'
Update-RepoFile 'backend/src/test/java/com/gara/quanlygara/controller/WarehouseApiTest.java' 'when(stockIssueItemRepository.findById(new StockIssueItem.Key(1, 5))).thenReturn(Optional.of(item));' 'when(stockIssueItemRepository.findForUpdate(1, 5)).thenReturn(Optional.of(item));' 'stockIssueItemRepository.findForUpdate(1, 5)'
Update-RepoFile 'backend/src/test/java/com/gara/quanlygara/controller/WarehouseApiTest.java' '    // ------------------------------------------------------------------ KIỂM KÊ' '    // ------------------------------------------------------------------ CHI TIẾT PHIẾU XUẤT THEO QUYỀN

    @Test
    @WithMockUser(username = "ktv", roles = "TECHNICIAN")
    void technicianReadsAnIssueRelatedToThem() throws Exception {
        account("ktv", AccountRole.TECHNICIAN, 2);
        stubIssueDetail();
        when(stockIssueRepository.countRelatedToTechnician(1, 2)).thenReturn(1L);

        mockMvc.perform(get("/api/warehouse/exports/1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.id").value(1))
                .andExpect(jsonPath("$.data.items[0].partId").value(5));
    }

    @Test
    @WithMockUser(username = "ktv", roles = "TECHNICIAN")
    void technicianGets403AndNoDataForAnUnrelatedIssue() throws Exception {
        account("ktv", AccountRole.TECHNICIAN, 2);
        stubIssueDetail();
        when(stockIssueRepository.countRelatedToTechnician(1, 2)).thenReturn(0L);

        mockMvc.perform(get("/api/warehouse/exports/1"))
                .andExpect(status().isForbidden())
                .andExpect(content().string(not(containsString("Thay bugi"))));
        verify(stockIssueRepository, never()).findById(any());
    }

    @Test
    @WithMockUser(username = "quanly", roles = "MANAGER")
    void managerReadsAnyIssue() throws Exception {
        account("quanly", AccountRole.MANAGER, 1);
        stubIssueDetail();

        mockMvc.perform(get("/api/warehouse/exports/1")).andExpect(status().isOk());
        verify(stockIssueRepository, never()).countRelatedToTechnician(any(), any());
    }

    @Test
    @WithMockUser(username = "kho", roles = "WAREHOUSE")
    void warehouseReadsAnyIssue() throws Exception {
        account("kho", AccountRole.WAREHOUSE, 7);
        stubIssueDetail();

        mockMvc.perform(get("/api/warehouse/exports/1")).andExpect(status().isOk());
        verify(stockIssueRepository, never()).countRelatedToTechnician(any(), any());
    }

    @Test
    @WithMockUser(username = "admin", roles = "ADMIN")
    void adminReadsAnyIssue() throws Exception {
        account("admin", AccountRole.ADMIN, null);
        stubIssueDetail();

        mockMvc.perform(get("/api/warehouse/exports/1")).andExpect(status().isOk());
        verify(stockIssueRepository, never()).countRelatedToTechnician(any(), any());
    }

    @Test
    @WithMockUser(roles = "CUSTOMER")
    void customerCannotReadIssues() throws Exception {
        mockMvc.perform(get("/api/warehouse/exports/1")).andExpect(status().isForbidden());
    }

    private void stubIssueDetail() {
        StockIssue issue = new StockIssue();
        issue.setId(1);
        issue.setRepairOrderId(9);
        issue.setReason("Thay bugi");
        StockIssueItem item = new StockIssueItem();
        item.setIssueId(1);
        item.setPartId(5);
        item.setQuantity(5);
        item.setUnitPrice(new BigDecimal("180000.00"));
        when(stockIssueRepository.findById(1)).thenReturn(Optional.of(issue));
        when(stockIssueItemRepository.findByIssueId(1)).thenReturn(List.of(item));
    }

    // ------------------------------------------------------------------ KIỂM KÊ' 'technicianReadsAnIssueRelatedToThem'

Write-Step 'Cap nhat tai lieu setup database'
Set-DocBlock 'README.md' 'db-setup' @'
### Cập nhật cấu trúc database (bắt buộc)

Sau khi chạy `QuanLyGaraOTo.sql`, chạy tiếp các migration trong `backend/database/migrations/` **theo thứ tự**:

1. `V001__add_customer_status.sql`
2. `V002__warehouse_actual_used_and_stock_check.sql` — bắt buộc cho kho (Tuần 8): thêm `SoLuongThucDung`, `SoLuongHoanTra`, bảng `PhieuKiemKe`/`ChiTietKiemKe`; sửa `sp_XacNhanSuDungPhuTung` (trừ tồn theo số lượng thực dùng) và `sp_KiemKeTonKho` (chỉ ghi nhận, không tự đổi tồn; chỉ MANAGER duyệt qua ứng dụng).
3. `V003__confirm_usage_row_lock.sql` — khóa dòng khi xác nhận thực dùng, chặn xác nhận trùng đồng thời.

Kiểm thử nghiệp vụ kho (tùy chọn): chạy `backend/database/Test_Warehouse.sql` trong SQL Server Management Studio, xem bảng PASS/FAIL (script tự dọn dữ liệu test).
Chi tiết từng file: `backend/database/migrations/README.md`.

Kho phụ tùng (tồn kho, nhập kho, xuất/cấp phát, xác nhận thực dùng, kiểm kê có phê duyệt, lịch sử biến động) **đã có API thật** từ Tuần 8; trang Kho trên website dùng API này, không còn dữ liệu mẫu.
'@ 'Script sẽ tạo database `QuanLyGaraOTo`[^\n]*' 'after'
Set-DocBlock 'backend/README.md' 'db-setup' @'
### Cập nhật cấu trúc database (bắt buộc)

Sau khi chạy `QuanLyGaraOTo.sql`, chạy tiếp các migration trong `backend/database/migrations/` **theo thứ tự**:

1. `V001__add_customer_status.sql`
2. `V002__warehouse_actual_used_and_stock_check.sql` — bắt buộc cho kho (Tuần 8): thêm `SoLuongThucDung`, `SoLuongHoanTra`, bảng `PhieuKiemKe`/`ChiTietKiemKe`; sửa `sp_XacNhanSuDungPhuTung` (trừ tồn theo số lượng thực dùng) và `sp_KiemKeTonKho` (chỉ ghi nhận, không tự đổi tồn; chỉ MANAGER duyệt qua ứng dụng).
3. `V003__confirm_usage_row_lock.sql` — khóa dòng khi xác nhận thực dùng, chặn xác nhận trùng đồng thời.

Kiểm thử nghiệp vụ kho (tùy chọn): chạy `backend/database/Test_Warehouse.sql` trong SQL Server Management Studio, xem bảng PASS/FAIL (script tự dọn dữ liệu test).
Chi tiết từng file: `backend/database/migrations/README.md`.

Kho phụ tùng (tồn kho, nhập kho, xuất/cấp phát, xác nhận thực dùng, kiểm kê có phê duyệt, lịch sử biến động) **đã có API thật** từ Tuần 8; trang Kho trên website dùng API này, không còn dữ liệu mẫu.
'@ '(?m)^## Các API đã có' 'before'
Set-DocBlock 'backend/README.md' 'warehouse-api' @'
## API kho (Tuần 8)

- `GET /api/inventory`, `GET /api/inventory/movements`: tồn kho (tìm theo mã/tên/hãng, lọc tình trạng) và lịch sử biến động.
- `GET|POST /api/warehouse/imports`, `GET /api/warehouse/imports/{id}`: nhập kho (mỗi chi tiết nhập tăng tồn đúng một lần).
- `GET|POST /api/warehouse/exports`, `GET /api/warehouse/exports/{id}`: xuất kho = **cấp phát**, chưa trừ tồn. Kỹ thuật viên chỉ xem phiếu liên quan đến mình.
- `POST /api/warehouse/exports/{issueId}/items/{partId}/confirm`: kỹ thuật viên xác nhận số lượng thực dùng; chỉ lúc này tồn mới giảm, theo số lượng thực dùng.
- `GET|POST /api/warehouse/checks`, `GET /api/warehouse/checks/{id}`, `PUT /api/warehouse/checks/{id}/items/{partId}`, `POST /api/warehouse/checks/{id}/approve|reject`: kiểm kê; chỉ MANAGER duyệt hoặc từ chối, tồn chỉ đổi sau khi duyệt.
'@ '' 'end'
Remove-StaleWarehouseNote 'README.md'
Remove-StaleWarehouseNote 'backend/README.md'

$script:Results["Ap dung file"] = "PASS"

# ============================================================
# 7. TEST + BUILD
# ============================================================
if ($SkipBuild) {
    $script:Results["Backend test"] = "SKIPPED (-SkipBuild)"
    $script:Results["Backend package"] = "SKIPPED (-SkipBuild)"
    $script:Results["Frontend build"] = "SKIPPED (-SkipBuild)"
} else {
    Invoke-Native "Backend test" (Join-Path $root "backend") "backend-test.log" { .\mvnw.cmd test }
    Invoke-Native "Backend package" (Join-Path $root "backend") "backend-package.log" { .\mvnw.cmd clean package }
    Invoke-Native "Frontend npm install" (Join-Path $root "frontend") "frontend-install.log" { npm install }
    Invoke-Native "Frontend build" (Join-Path $root "frontend") "frontend-build.log" { npm run build }

    # vite build khong kiem tra kieu TypeScript, nen chay tsc rieng (chi canh bao: co the co loi cu cua module khac).
    Write-Step "Frontend type-check (tsc --noEmit)"
    Push-Location -LiteralPath (Join-Path $root "frontend")
    $prev = $ErrorActionPreference; $ErrorActionPreference = "Continue"
    try { $tsc = & npx tsc --noEmit 2>&1 | ForEach-Object { "$_" }; $tscCode = $LASTEXITCODE } finally { $ErrorActionPreference = $prev; Pop-Location }
    if ($tscCode -eq 0) { $script:Results["Frontend tsc"] = "PASS"; Write-Ok "tsc PASS" }
    else {
        $vehicleErrors = @($tsc | Where-Object { $_ -match "warehouse|Warehouse|Inventory|inventory|App\.tsx" })
        if ($vehicleErrors.Count -gt 0) {
            $vehicleErrors | ForEach-Object { Write-Host "    $_" -ForegroundColor Red }
            $script:Results["Frontend tsc"] = "FAIL (loi lien quan Tuan 8)"
            Show-Summary
            exit 1
        }
        $script:Results["Frontend tsc"] = "WARN (loi khong thuoc Tuan 8)"
        Write-Warn2 "tsc bao loi o file khac Tuan 8 (co the co san tu truoc)."
    }
}

Write-Host ""
Write-Host "BUOC SQL (bat buoc truoc khi chay ung dung that; KHONG can cho build/test Java):" -ForegroundColor Yellow
Write-Host "  1. SSMS, theo thu tu (deu idempotent): V001, V002 roi V003__confirm_usage_row_lock.sql trong backend/database/migrations/" -ForegroundColor Yellow
Write-Host "  2. Tuy chon: backend/database/Test_Warehouse.sql (tu don dep) va kiem tra thu cong 2 cua so theo backend/database/migrations/README.md" -ForegroundColor Yellow

# ============================================================
# 8. ZIP (chi khi build/test da chay thanh cong)
# ============================================================
if (-not $SkipBuild -and -not $NoZip) {
    Write-Step "Tao TV3_Tuan8_Warehouse_FINAL.zip"
    $zip = Join-Path $root "TV3_Tuan8_Warehouse_FINAL.zip"
    $stage = Join-Path ([System.IO.Path]::GetTempPath()) "tv3-vehicle-$stamp"
    New-Item -ItemType Directory -Force -Path $stage | Out-Null
    robocopy $root $stage /E /NFL /NDL /NJH /NJS /NP `
        /XD target node_modules .idea .vscode .backup .git dist .dart_tool build .gradle `
        /XF *.log .env .env.local TV3_Tuan8_Warehouse_FINAL.zip TV3_Tuan8_FINAL_AUDIT_APPLY.ps1 TV3_Tuan8_Warehouse_APPLY.ps1 | Out-Null
    if ($LASTEXITCODE -ge 8) { Stop-Fail "robocopy that bai (ma $LASTEXITCODE)." }
    if (Test-Path -LiteralPath $zip) { Remove-Item -LiteralPath $zip -Force }
    Compress-Archive -Path (Join-Path $stage "*") -DestinationPath $zip
    Remove-Item -LiteralPath $stage -Recurse -Force
    $script:Results["ZIP"] = "PASS ($zip)"
    Write-Ok $zip
}

Show-Summary
Write-Host ""
Write-Host "SUCCESS" -ForegroundColor Green
Write-Host "Lenh Git de ban tu chay (khong merge vao main):"
Write-Host "  git status"
Write-Host "  git add backend frontend"
Write-Host "  git commit -m `"fix(warehouse): audit fixes - technician issue access, confirm row lock, database setup docs`""
Write-Host "  git push -u origin feature/cam-warehouse"
