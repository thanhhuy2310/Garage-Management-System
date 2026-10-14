<#
  TV3_Tuan9_FINAL_AUDIT_APPLY.ps1 - Audit cuoi Tuan 9 (TV3 Hoang Van Cam)
   B1. Lich su: phan trang server-side (khong con TOP 200 cat am tham), danh sach xe loc rieng, Flutter "Tai them" + chong phan hoi cu
   B/C. Test lich su, integration test SQL Server that (RepairHistorySqlServerIT, khoa bang bien moi truong)
   A.   Tuan 7: khong cho sua/xoa tay dong ChiTietPhuTung da xac nhan thuc dung (tranh ghi de so thuc dung cua Tuan 8)
   E.   README.md, backend/README.md, mobile/README.md
  Chay tu repository root:   .\TV3_Tuan9_FINAL_AUDIT_APPLY.ps1
  Tuy chon: -SkipBuild, -NoZip, -BuildApk, -ForceZip, -RunSqlServerIT (can SQL Server that + DB_URL/DB_USERNAME/DB_PASSWORD)
  File Tuan 9 cua chinh script nay duoc thay CHI KHI chua bi sua tay (so khop ma bam), neu khong script dung va bao file nao khac.
  Khong checkout/commit/push Git. Khong sua file cua Huy/Trung.
#>
param(
    [switch]$SkipBuild,
    [switch]$NoZip,
    [switch]$BuildApk,
    [switch]$ForceZip,
    [switch]$RunSqlServerIT
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
# 1. XAC DINH REPOSITORY ROOT + KIEM TRA CAU TRUC (checkpoint Tuan 9 phai co san)
# ------------------------------------------------------------
Write-Step "Kiem tra repository"
$root = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$required = @(
    "backend/pom.xml",
    "backend/mvnw.cmd",
    "backend/database/QuanLyGaraOTo.sql",
    "backend/src/main/java/com/gara/quanlygara/controller/CustomerHistoryController.java",
    "backend/src/main/java/com/gara/quanlygara/service/RepairHistoryService.java",
    "backend/src/main/java/com/gara/quanlygara/repository/RepairHistoryRepository.java",
    "backend/src/main/java/com/gara/quanlygara/service/RepairDetailService.java",
    "backend/src/main/java/com/gara/quanlygara/repository/StockIssueItemRepository.java",
    "backend/src/test/java/com/gara/quanlygara/service/RepairDetailServiceTest.java",
    "mobile/pubspec.yaml",
    "mobile/lib/app/app.dart",
    "mobile/lib/models/history.dart",
    "mobile/lib/services/history_service.dart",
    "mobile/lib/screens/history/history_screen.dart",
    "mobile/lib/screens/history/history_detail_screen.dart",
    "README.md",
    "backend/README.md",
    "mobile/README.md"
)
$missing = @($required | Where-Object { -not (Test-Path -LiteralPath (Join-Path $root $_)) })
if ($missing.Count -gt 0) {
    Stop-Fail ("Khong dung repository root ($root). Thieu:`n  - " + ($missing -join "`n  - "))
}
Set-Location -LiteralPath $root
Write-Ok "Repository root: $root"

$sql = Get-Content -LiteralPath (Join-Path $root "backend/database/QuanLyGaraOTo.sql") -Raw
foreach ($table in @("PhieuSuaChua", "PhieuTiepNhan", "Xe", "ChiTietDichVu", "ChiTietPhuTung", "DichVu", "PhuTung", "KhachHang", "TaiKhoan", "Kho")) {
    if ($sql -notmatch ("CREATE TABLE " + $table + "\s*\(")) {
        Stop-Fail "QuanLyGaraOTo.sql khong co bang $table nhu du kien. Khong tao bang lich su rieng; hay gui schema thuc te cho Claude."
    }
}
foreach ($column in @("NgayHoanThanh", "KetQua", "LoaiDichVu")) {
    if ($sql -notmatch $column) { Stop-Fail "QuanLyGaraOTo.sql khong co cot $column nhu du kien (can cho tong hop lich su)." }
}
if ($sql -notmatch "fn_TinhTongChiPhiSuaChua") { Stop-Fail "QuanLyGaraOTo.sql khong co ham dbo.fn_TinhTongChiPhiSuaChua." }
Write-Ok "Schema du de tong hop lich su tu PhieuSuaChua + PhieuTiepNhan + Xe + ChiTietDichVu + ChiTietPhuTung (khong tao bang lich su)"

foreach ($cmd in @("java")) {
    if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) { Stop-Fail "Khong tim thay lenh '$cmd' trong PATH." }
}
if (-not $SkipBuild) {
    foreach ($cmd in @()) {
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
    if ($branch -ne "feature/cam-mobile-history") { Write-Warn2 "Dang o nhanh '$branch', khong phai feature/cam-mobile-history. Script KHONG tu chuyen nhanh." }
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

$script:Marker = "TV3-TUAN9"
# File mock cu cua nhom duoc phep thay (co backup) neu van la ban mock: duong dan -> chuoi nhan dang.
$script:Replaceable = @{}

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
# 4. HAM: kiem tra file chua bi sua tay, tai lieu, bao cao ra soat mobile
# ------------------------------------------------------------
function Get-TextSha256($text) {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try { return (($sha.ComputeHash($utf8NoBom.GetBytes($text)) | ForEach-Object { $_.ToString("x2") }) -join "") }
    finally { $sha.Dispose() }
}

# Thay file Tuan 9 bang ban moi CHI KHI noi dung hien tai dung la ban Tuan 9 da sinh (chua bi sua tay).
function Replace-OwnedFile($rel, $expectedOldSha, $content) {
    $path = Join-Path $root $rel
    $text = ($content -replace "`r`n", "`n").TrimEnd("`n") + "`n"
    if (-not (Test-Path -LiteralPath $path)) {
        New-Item -ItemType Directory -Force -Path (Split-Path $path) | Out-Null
        [System.IO.File]::WriteAllText($path, $text, $utf8NoBom)
        Write-Host "    + $rel"
        return
    }
    $existing = ([System.IO.File]::ReadAllText($path, $utf8NoBom) -replace "`r`n", "`n").TrimEnd("`n") + "`n"
    if ($existing -eq $text) { Write-Host "    = $rel (khong doi)"; return }
    if ((Get-TextSha256 $existing) -ne $expectedOldSha) {
        Stop-Fail "File da duoc sua tay sau khi ap dung Tuan 9 nen khong tu thay the: $rel`nGui file nay cho Claude de gop thay doi thay vi ghi de (khong file nao bi sua trong lan chay nay neu day la file dau tien bi bao)."
    }
    Backup-RepoFile $rel
    [System.IO.File]::WriteAllText($path, $text, $utf8NoBom)
    Write-Host "    ~ $rel (da backup)"
}

# Chen/thay mot khoi tai lieu co marker; neu khong tim thay cau can thay thi them o cuoi file (co canh bao).
function Set-DocBlock($rel, $id, $content, $pattern, $position) {
    $path = Join-Path $root $rel
    if (-not (Test-Path -LiteralPath $path)) { Write-Warn2 "Khong co $rel - bo qua khoi tai lieu '$id'."; return }
    $raw = [System.IO.File]::ReadAllText($path, $utf8NoBom)
    $crlf = $raw.Contains("`r`n")
    $text = $raw -replace "`r`n", "`n"
    $begin = "<!-- TV3-TUAN9-AUDIT:$id BEGIN -->"
    $end = "<!-- TV3-TUAN9-AUDIT:$id END -->"
    $block = $begin + "`n" + (($content -replace "`r`n", "`n").Trim("`n")) + "`n" + $end
    $i = $text.IndexOf($begin, [System.StringComparison]::Ordinal)
    if ($i -ge 0) {
        $j = $text.IndexOf($end, $i, [System.StringComparison]::Ordinal)
        if ($j -lt 0) { Write-Warn2 "${rel}: khoi '$id' co BEGIN nhung thieu END, bo qua."; return }
        $new = $text.Substring(0, $i) + $block + $text.Substring($j + $end.Length)
    } else {
        $m = if ($pattern) { [regex]::Match($text, $pattern) } else { $null }
        if ($m -and $m.Success -and $position -eq "replace") { $new = $text.Substring(0, $m.Index) + $block + $text.Substring($m.Index + $m.Length) }
        elseif ($m -and $m.Success -and $position -eq "after") { $new = $text.Insert($m.Index + $m.Length, "`n`n" + $block) }
        elseif ($m -and $m.Success -and $position -eq "before") { $new = $text.Insert($m.Index, $block + "`n`n") }
        else {
            $new = $text.TrimEnd("`n") + "`n`n" + $block + "`n"
            if ($pattern) { Write-Warn2 "${rel}: khong thay cau can sua cho '$id' (README da duoc sua tay?), da them khoi o cuoi file - hay doc lai de bo cau cu." }
        }
    }
    if ($new -eq $text) { Write-Host "    = $rel (khoi '$id' khong doi)"; return }
    Backup-RepoFile $rel
    if ($crlf) { $new = $new -replace "`n", "`r`n" }
    [System.IO.File]::WriteAllText($path, $new, $utf8NoBom)
    Write-Host "    ~ $rel (khoi '$id', da backup)"
}

# Chi BAO CAO (khong sua file cua Huy/Trung): phan legacy historyOnly va cac service mobile con dung Mock.
function Write-MobileReport {
    Write-Step "Ra soat mobile (chi bao cao, khong sua file cua Huy/Trung)"
    $dart = @(Get-ChildItem -LiteralPath (Join-Path $root "mobile") -Recurse -Filter "*.dart" | Where-Object { $_.FullName -notmatch '[\\/](\.dart_tool|build)[\\/]' })
    $callers = @($dart | Select-String -Pattern 'historyOnly' | Where-Object { $_.Path -notmatch 'repair_progress_screen\.dart$' })
    if ($callers.Count -eq 0) {
        Write-Host "    historyOnly: khong con noi nao truyen gia tri (chi con khai bao trong repair_progress_screen.dart)."
        Write-Host "    -> Co the xoa phan legacy do; script KHONG tu xoa vi file thuoc luong theo doi sua chua cua Huy."
    } else {
        Write-Host "    historyOnly van con duoc goi tai (KHONG xoa):"
        $callers | ForEach-Object { Write-Host "      $($_.Path):$($_.LineNumber)" }
    }
    $mocks = @($dart | Where-Object { $_.FullName -match '[\\/]lib[\\/]app[\\/]' } | Select-String -Pattern '\bMock\w+Service\b' | ForEach-Object { $_.Matches.Value } | Sort-Object -Unique)
    if ($mocks.Count -gt 0) { Write-Host "    Dich vu mobile con dung Mock (README da ghi la du lieu mau/local): $($mocks -join ', ')" }
}


Write-Step 'Ap dung file thay the Tuan 9 (kiem tra file chua bi sua tay)'
Write-RepoFile 'backend/src/main/java/com/gara/quanlygara/dto/history/HistoryPageResponse.java' @'
// TV3-TUAN9
package com.gara.quanlygara.dto.history;

import java.util.List;

/** Một trang lịch sử; page bắt đầu từ 0 (giống Vehicle/SparePart). totalElements là tổng số lượt, không bị cắt. */
public record HistoryPageResponse(
        List<HistoryItemResponse> items,
        int page,
        int size,
        long totalElements,
        int totalPages
) {
}
'@
Write-RepoFile 'backend/src/main/java/com/gara/quanlygara/dto/history/HistoryVehicleResponse.java' @'
// TV3-TUAN9
package com.gara.quanlygara.dto.history;

/** Xe của khách hàng có ít nhất một lượt sửa chữa/bảo dưỡng đã hoàn tất (dùng làm bộ lọc ở mobile). */
public record HistoryVehicleResponse(
        Integer vehicleId,
        String licensePlate,
        String brand,
        String model,
        int completedCount
) {
}
'@
Replace-OwnedFile 'backend/src/main/java/com/gara/quanlygara/repository/RepairHistoryRepository.java' '14988e81c74fe7dbc134c893dad8a3b3f3c4614a26e09dadf33df491241f09fc' @'
// TV3-TUAN9
package com.gara.quanlygara.repository;

import com.gara.quanlygara.entity.Vehicle;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.Repository;
import org.springframework.data.repository.query.Param;

import java.util.Collection;
import java.util.List;

/**
 * Truy vấn CHỈ ĐỌC để tổng hợp lịch sử sửa chữa của khách hàng từ dữ liệu nghiệp vụ gốc.
 * Gắn với entity Vehicle có sẵn (không tạo entity/bảng mới cho PhieuSuaChua, PhieuTiepNhan của module khác);
 * kết quả là Object[] và được chuyển kiểu tường minh trong RepairHistoryService.
 */
public interface RepairHistoryRepository extends Repository<Vehicle, Integer> {

    /**
     * Cột: 0 MaPhieuSuaChua, 1 MaXe, 2 BienSo, 3 HangXe, 4 DongXe, 5 NgayLap, 6 NgayBatDau, 7 NgayHoanThanh,
     * 8 KetQua, 9 tổng chi phí (dbo.fn_TinhTongChiPhiSuaChua). Mới nhất trước; phân trang bằng OFFSET/FETCH
     * (không còn giới hạn cố định). vehicleId = 0 và repairOrderId = 0 nghĩa là không lọc.
     * Chỉ lấy xe của đúng khách hàng và phiếu HOAN_TAT.
     */
    @Query(value = """
            SELECT ps.MaPhieuSuaChua, xe.MaXe, xe.BienSo, xe.HangXe, xe.DongXe,
                   ps.NgayLap, ps.NgayBatDau, ps.NgayHoanThanh, ps.KetQua,
                   dbo.fn_TinhTongChiPhiSuaChua(ps.MaPhieuSuaChua)
            FROM PhieuSuaChua ps
            JOIN PhieuTiepNhan tn ON tn.MaTiepNhan = ps.MaTiepNhan
            JOIN Xe xe ON xe.MaXe = tn.MaXe
            WHERE xe.MaKhachHang = :customerId
              AND ps.TrangThai = N'HOAN_TAT'
              AND (:vehicleId = 0 OR xe.MaXe = :vehicleId)
              AND (:repairOrderId = 0 OR ps.MaPhieuSuaChua = :repairOrderId)
            ORDER BY COALESCE(ps.NgayHoanThanh, ps.NgayBatDau, ps.NgayLap) DESC, ps.MaPhieuSuaChua DESC
            OFFSET :offset ROWS FETCH NEXT :limit ROWS ONLY
            """, nativeQuery = true)
    List<Object[]> findHistoryRows(
            @Param("customerId") Integer customerId,
            @Param("vehicleId") Integer vehicleId,
            @Param("repairOrderId") Integer repairOrderId,
            @Param("offset") Integer offset,
            @Param("limit") Integer limit);

    /** Tổng số lượt (cùng điều kiện với findHistoryRows) để trả totalElements/totalPages. */
    @Query(value = """
            SELECT COUNT(1)
            FROM PhieuSuaChua ps
            JOIN PhieuTiepNhan tn ON tn.MaTiepNhan = ps.MaTiepNhan
            JOIN Xe xe ON xe.MaXe = tn.MaXe
            WHERE xe.MaKhachHang = :customerId
              AND ps.TrangThai = N'HOAN_TAT'
              AND (:vehicleId = 0 OR xe.MaXe = :vehicleId)
            """, nativeQuery = true)
    long countHistory(@Param("customerId") Integer customerId, @Param("vehicleId") Integer vehicleId);

    /** Cột: 0 MaXe, 1 BienSo, 2 HangXe, 3 DongXe, 4 số lượt hoàn tất. Toàn bộ xe có lịch sử của khách hàng (không phân trang). */
    @Query(value = """
            SELECT xe.MaXe, xe.BienSo, xe.HangXe, xe.DongXe, COUNT(ps.MaPhieuSuaChua)
            FROM Xe xe
            JOIN PhieuTiepNhan tn ON tn.MaXe = xe.MaXe
            JOIN PhieuSuaChua ps ON ps.MaTiepNhan = tn.MaTiepNhan AND ps.TrangThai = N'HOAN_TAT'
            WHERE xe.MaKhachHang = :customerId
            GROUP BY xe.MaXe, xe.BienSo, xe.HangXe, xe.DongXe
            ORDER BY xe.BienSo, xe.MaXe
            """, nativeQuery = true)
    List<Object[]> findHistoryVehicles(@Param("customerId") Integer customerId);

    /** Cột: 0 MaPhieuSuaChua, 1 MaDichVu, 2 TenDichVu, 3 LoaiDichVu, 4 SoLuong, 5 DonGia. */
    @Query(value = """
            SELECT cd.MaPhieuSuaChua, cd.MaDichVu, dv.TenDichVu, dv.LoaiDichVu, cd.SoLuong, cd.DonGia
            FROM ChiTietDichVu cd
            JOIN DichVu dv ON dv.MaDichVu = cd.MaDichVu
            WHERE cd.MaPhieuSuaChua IN (:orderIds)
            ORDER BY cd.MaPhieuSuaChua, cd.MaDichVu
            """, nativeQuery = true)
    List<Object[]> findServiceLines(@Param("orderIds") Collection<Integer> orderIds);

    /** Cột: 0 MaPhieuSuaChua, 1 MaPhuTung, 2 TenPhuTung, 3 SoLuong, 4 DonGia. SoLuong = tổng THỰC DÙNG đã xác nhận (Tuần 8). */
    @Query(value = """
            SELECT cp.MaPhieuSuaChua, cp.MaPhuTung, pt.TenPhuTung, cp.SoLuong, cp.DonGia
            FROM ChiTietPhuTung cp
            JOIN PhuTung pt ON pt.MaPhuTung = cp.MaPhuTung
            WHERE cp.MaPhieuSuaChua IN (:orderIds)
            ORDER BY cp.MaPhieuSuaChua, cp.MaPhuTung
            """, nativeQuery = true)
    List<Object[]> findPartLines(@Param("orderIds") Collection<Integer> orderIds);

    @Query(value = "SELECT COUNT(1) FROM Xe WHERE MaXe = :vehicleId AND MaKhachHang = :customerId", nativeQuery = true)
    long countOwnedVehicle(@Param("vehicleId") Integer vehicleId, @Param("customerId") Integer customerId);
}
'@
Replace-OwnedFile 'backend/src/main/java/com/gara/quanlygara/service/RepairHistoryService.java' 'e0ad85710ab91758a4d58a84760bd94b9f0a35829dfe52be8bfefcf6fe84f69c' @'
// TV3-TUAN9
package com.gara.quanlygara.service;

import com.gara.quanlygara.dto.history.HistoryDetailResponse;
import com.gara.quanlygara.dto.history.HistoryItemResponse;
import com.gara.quanlygara.dto.history.HistoryPageResponse;
import com.gara.quanlygara.dto.history.HistoryVehicleResponse;
import com.gara.quanlygara.exception.BadRequestException;
import com.gara.quanlygara.exception.ResourceNotFoundException;
import com.gara.quanlygara.repository.RepairHistoryRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * Lịch sử sửa chữa/bảo dưỡng của khách hàng (chỉ đọc). customerId luôn do controller lấy từ JWT,
 * KHÔNG nhận từ client; mọi truy vấn đều lọc theo xe thuộc khách hàng đó.
 */
@Service
public class RepairHistoryService {

    public static final String MAINTENANCE = "BAO_DUONG";
    public static final String REPAIR = "SUA_CHUA";
    public static final String MIXED = "BAO_DUONG_SUA_CHUA";

    public static final int MAX_PAGE_SIZE = 50;

    private static final int SUMMARY_SERVICES = 3;

    private final RepairHistoryRepository repository;

    public RepairHistoryService(RepairHistoryRepository repository) {
        this.repository = repository;
    }

    /**
     * Một trang lịch sử, mới nhất trước. vehicleId null = mọi xe của khách hàng; xe không thuộc khách hàng => 404
     * (không tiết lộ xe có tồn tại hay không). totalElements/totalPages cho biết đầy đủ số lượt, không cắt âm thầm.
     */
    @Transactional(readOnly = true)
    public HistoryPageResponse getHistory(Integer customerId, Integer vehicleId, int page, int size) {
        if (vehicleId != null) {
            if (vehicleId <= 0) throw new BadRequestException("Mã xe không hợp lệ.");
            if (repository.countOwnedVehicle(vehicleId, customerId) == 0) {
                throw new ResourceNotFoundException("Không tìm thấy xe.");
            }
        }
        int pageIndex = Math.max(page, 0);
        int pageSize = Math.min(Math.max(size, 1), MAX_PAGE_SIZE);
        int vehicleFilter = vehicleId == null ? 0 : vehicleId;

        long total = repository.countHistory(customerId, vehicleFilter);
        int totalPages = (int) ((total + pageSize - 1) / pageSize);
        long offset = (long) pageIndex * pageSize;

        List<HistoryItemResponse> items = List.of();
        if (offset < total) {
            items = build(repository.findHistoryRows(customerId, vehicleFilter, 0, (int) offset, pageSize))
                    .stream().map(Built::item).toList();
        }
        return new HistoryPageResponse(items, pageIndex, pageSize, total, totalPages);
    }

    /** Toàn bộ xe có lịch sử của khách hàng (không phụ thuộc trang đang xem). */
    @Transactional(readOnly = true)
    public List<HistoryVehicleResponse> getVehicles(Integer customerId) {
        return repository.findHistoryVehicles(customerId).stream()
                .map(row -> new HistoryVehicleResponse(
                        toInt(row[0]), toText(row[1]), toText(row[2]), toText(row[3]), toInt(row[4])))
                .toList();
    }

    /** Phiếu không tồn tại, chưa hoàn tất hoặc của khách hàng khác đều trả 404 giống nhau. */
    @Transactional(readOnly = true)
    public HistoryDetailResponse getDetail(Integer customerId, Integer repairOrderId) {
        List<Built> built = build(repository.findHistoryRows(customerId, 0, repairOrderId, 0, 1));
        if (built.isEmpty()) {
            throw new ResourceNotFoundException("Không tìm thấy lịch sử sửa chữa.");
        }
        Built entry = built.get(0);
        BigDecimal serviceTotal = entry.services().stream().map(HistoryDetailResponse.ServiceLine::lineTotal)
                .reduce(BigDecimal.ZERO.setScale(2), BigDecimal::add);
        BigDecimal partsTotal = entry.parts().stream().map(HistoryDetailResponse.PartLine::lineTotal)
                .reduce(BigDecimal.ZERO.setScale(2), BigDecimal::add);
        return new HistoryDetailResponse(entry.item(), entry.services(), entry.parts(), serviceTotal, partsTotal);
    }

    private record Built(
            HistoryItemResponse item,
            List<HistoryDetailResponse.ServiceLine> services,
            List<HistoryDetailResponse.PartLine> parts
    ) {
    }

    private List<Built> build(List<Object[]> rows) {
        if (rows.isEmpty()) return List.of();
        List<Integer> orderIds = rows.stream().map(row -> toInt(row[0])).toList();

        Map<Integer, List<HistoryDetailResponse.ServiceLine>> services = new HashMap<>();
        for (Object[] row : repository.findServiceLines(orderIds)) {
            BigDecimal unitPrice = toDecimal(row[5]);
            int quantity = toInt(row[4]);
            services.computeIfAbsent(toInt(row[0]), key -> new ArrayList<>()).add(new HistoryDetailResponse.ServiceLine(
                    toInt(row[1]), toText(row[2]), toText(row[3]), quantity, unitPrice, lineTotal(unitPrice, quantity)));
        }
        Map<Integer, List<HistoryDetailResponse.PartLine>> parts = new HashMap<>();
        for (Object[] row : repository.findPartLines(orderIds)) {
            BigDecimal unitPrice = toDecimal(row[4]);
            int quantity = toInt(row[3]);
            parts.computeIfAbsent(toInt(row[0]), key -> new ArrayList<>()).add(new HistoryDetailResponse.PartLine(
                    toInt(row[1]), toText(row[2]), quantity, unitPrice, lineTotal(unitPrice, quantity)));
        }

        List<Built> result = new ArrayList<>();
        for (Object[] row : rows) {
            Integer orderId = toInt(row[0]);
            List<HistoryDetailResponse.ServiceLine> serviceLines = services.getOrDefault(orderId, List.of());
            List<HistoryDetailResponse.PartLine> partLines = parts.getOrDefault(orderId, List.of());
            String resultText = toText(row[8]);
            HistoryItemResponse item = new HistoryItemResponse(
                    orderId, toInt(row[1]), toText(row[2]), toText(row[3]), toText(row[4]),
                    toDateTime(row[5]), toDateTime(row[6]), toDateTime(row[7]),
                    category(serviceLines), summary(serviceLines, partLines, resultText),
                    serviceLines.size(), partLines.size(), toDecimal(row[9]), resultText);
            result.add(new Built(item, serviceLines, partLines));
        }
        return result;
    }

    /** Toàn bộ dịch vụ là BAO_DUONG => bảo dưỡng; có cả BAO_DUONG và loại khác => hỗn hợp; còn lại => sửa chữa. */
    static String category(List<HistoryDetailResponse.ServiceLine> services) {
        long maintenance = services.stream().filter(line -> MAINTENANCE.equalsIgnoreCase(line.type())).count();
        if (maintenance == 0) return REPAIR;
        return maintenance == services.size() ? MAINTENANCE : MIXED;
    }

    private static String summary(
            List<HistoryDetailResponse.ServiceLine> services, List<HistoryDetailResponse.PartLine> parts, String result
    ) {
        if (!services.isEmpty()) {
            String names = services.stream().limit(SUMMARY_SERVICES)
                    .map(HistoryDetailResponse.ServiceLine::name).collect(Collectors.joining(", "));
            int more = services.size() - SUMMARY_SERVICES;
            return more > 0 ? names + " và " + more + " hạng mục khác" : names;
        }
        if (!parts.isEmpty()) {
            return "Thay phụ tùng: " + parts.stream().limit(SUMMARY_SERVICES)
                    .map(HistoryDetailResponse.PartLine::name).collect(Collectors.joining(", "));
        }
        return result.isEmpty() ? "Không có hạng mục chi tiết" : result;
    }

    private static BigDecimal lineTotal(BigDecimal unitPrice, int quantity) {
        return unitPrice.multiply(BigDecimal.valueOf(quantity)).setScale(2, RoundingMode.HALF_UP);
    }

    // ---- Chuyển kiểu tường minh từ kết quả native (JDBC có thể trả Integer/Long/BigDecimal, Timestamp/LocalDateTime) ----

    static int toInt(Object value) {
        return value == null ? 0 : ((Number) value).intValue();
    }

    static BigDecimal toDecimal(Object value) {
        if (value == null) return BigDecimal.ZERO.setScale(2);
        BigDecimal decimal = value instanceof BigDecimal big ? big : new BigDecimal(value.toString());
        return decimal.setScale(2, RoundingMode.HALF_UP);
    }

    static String toText(Object value) {
        return value == null ? "" : value.toString();
    }

    static LocalDateTime toDateTime(Object value) {
        if (value == null) return null;
        if (value instanceof LocalDateTime dateTime) return dateTime;
        if (value instanceof Timestamp timestamp) return timestamp.toLocalDateTime();
        if (value instanceof Date date) return new Timestamp(date.getTime()).toLocalDateTime();
        return LocalDateTime.parse(value.toString().replace(' ', 'T'));
    }
}
'@
Replace-OwnedFile 'backend/src/main/java/com/gara/quanlygara/controller/CustomerHistoryController.java' '65aef68ea674eedbd05526ef78226863433aab706198873af19a5af666721266' @'
// TV3-TUAN9
package com.gara.quanlygara.controller;

import com.gara.quanlygara.dto.ApiResponse;
import com.gara.quanlygara.dto.history.HistoryDetailResponse;
import com.gara.quanlygara.dto.history.HistoryPageResponse;
import com.gara.quanlygara.dto.history.HistoryVehicleResponse;
import com.gara.quanlygara.security.StaffContext;
import com.gara.quanlygara.service.RepairHistoryService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * Lịch sử sửa chữa/bảo dưỡng của CHÍNH khách hàng đang đăng nhập. Không có tham số customerId:
 * khách hàng lấy từ tài khoản trong JWT, nên không thể xem dữ liệu của khách hàng khác.
 */
@RestController
@RequestMapping("/api/customers/me/history")
@PreAuthorize("hasRole('CUSTOMER')")
public class CustomerHistoryController {

    private final RepairHistoryService historyService;
    private final StaffContext accountContext;

    public CustomerHistoryController(RepairHistoryService historyService, StaffContext accountContext) {
        this.historyService = historyService;
        this.accountContext = accountContext;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<HistoryPageResponse>> getHistory(
            @RequestParam(required = false) Integer vehicleId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            Authentication authentication
    ) {
        return ResponseEntity.ok(ApiResponse.success("Lấy lịch sử sửa chữa thành công.",
                historyService.getHistory(customerId(authentication), vehicleId, page, size)));
    }

    // Danh sách xe để lọc: lấy riêng từ toàn bộ lịch sử của khách hàng, không phụ thuộc trang đang xem.
    @GetMapping("/vehicles")
    public ResponseEntity<ApiResponse<List<HistoryVehicleResponse>>> getVehicles(Authentication authentication) {
        return ResponseEntity.ok(ApiResponse.success("Lấy danh sách xe có lịch sử thành công.",
                historyService.getVehicles(customerId(authentication))));
    }

    @GetMapping("/{repairOrderId}")
    public ResponseEntity<ApiResponse<HistoryDetailResponse>> getDetail(
            @PathVariable Integer repairOrderId,
            Authentication authentication
    ) {
        return ResponseEntity.ok(ApiResponse.success("Lấy chi tiết lịch sử sửa chữa thành công.",
                historyService.getDetail(customerId(authentication), repairOrderId)));
    }

    private Integer customerId(Authentication authentication) {
        Integer customerId = accountContext.account(authentication).getCustomerId();
        if (customerId == null) {
            throw new AccessDeniedException("Tài khoản chưa liên kết với khách hàng.");
        }
        return customerId;
    }
}
'@
Replace-OwnedFile 'backend/src/test/java/com/gara/quanlygara/service/RepairHistoryServiceTest.java' 'bb10fb1faf87374c8c7dbae150c5a7ad1fa5bda77256f00ac2cb6e074c6e15ac' @'
// TV3-TUAN9
package com.gara.quanlygara.service;

import com.gara.quanlygara.dto.history.HistoryDetailResponse;
import com.gara.quanlygara.exception.BadRequestException;
import com.gara.quanlygara.exception.ResourceNotFoundException;
import com.gara.quanlygara.repository.RepairHistoryRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class RepairHistoryServiceTest {

    private static final int CUSTOMER_ID = 7;

    @Mock
    private RepairHistoryRepository repository;

    private RepairHistoryService service;

    @BeforeEach
    void setUp() {
        service = new RepairHistoryService(repository);
        lenient().when(repository.findServiceLines(any())).thenReturn(new ArrayList<>());
        lenient().when(repository.findPartLines(any())).thenReturn(new ArrayList<>());
    }

    @Test
    void firstPageKeepsTheNewestFirstOrderAndBuildsSummaryCostsAndMetadata() {
        when(repository.countHistory(CUSTOMER_ID, 0)).thenReturn(2L);
        when(repository.findHistoryRows(CUSTOMER_ID, 0, 0, 0, 10)).thenReturn(rows(
                header(12, 1, "51G-123.45", Timestamp.valueOf("2026-09-20 10:00:00"), "1500000"),
                header(5, 2, "51A-456.78", Timestamp.valueOf("2026-06-01 09:00:00"), "300000")));
        when(repository.findServiceLines(any())).thenReturn(rows(
                service(12, 2, "Bảo dưỡng định kỳ", "BAO_DUONG", 1, "1200000"),
                service(5, 3, "Kiểm tra hệ thống phanh", "KIEM_TRA", 1, "300000")));
        when(repository.findPartLines(any())).thenReturn(rows(part(12, 9, "Lọc dầu", 1, "300000")));

        var page = service.getHistory(CUSTOMER_ID, null, 0, 10);

        assertEquals(List.of(12, 5), page.items().stream().map(item -> item.repairOrderId()).toList());
        assertEquals(0, page.page());
        assertEquals(10, page.size());
        assertEquals(2, page.totalElements());
        assertEquals(1, page.totalPages());
        assertEquals("51G-123.45", page.items().get(0).licensePlate());
        assertEquals("Bảo dưỡng định kỳ", page.items().get(0).summary());
        assertEquals(1, page.items().get(0).serviceCount());
        assertEquals(1, page.items().get(0).partCount());
        assertEquals(new BigDecimal("1500000.00"), page.items().get(0).totalCost());
        assertEquals("BAO_DUONG", page.items().get(0).category());
        assertEquals("SUA_CHUA", page.items().get(1).category());
        assertEquals(LocalDateTime.of(2026, 9, 20, 10, 0), page.items().get(0).completedAt());
    }

    @Test
    void laterPagesUseTheRightOffset() {
        when(repository.countHistory(CUSTOMER_ID, 0)).thenReturn(12L);
        when(repository.findHistoryRows(CUSTOMER_ID, 0, 0, 10, 5)).thenReturn(rows(
                header(3, 1, "A", Timestamp.valueOf("2026-01-02 00:00:00"), "0"),
                header(2, 1, "A", Timestamp.valueOf("2026-01-01 00:00:00"), "0")));

        var page = service.getHistory(CUSTOMER_ID, null, 2, 5);

        verify(repository).findHistoryRows(CUSTOMER_ID, 0, 0, 10, 5);
        assertEquals(2, page.page());
        assertEquals(12, page.totalElements());
        assertEquals(3, page.totalPages());
        assertEquals(2, page.items().size());
    }

    @Test
    void historyLongerThan200IsNeverSilentlyTruncated() {
        when(repository.countHistory(CUSTOMER_ID, 0)).thenReturn(250L);
        when(repository.findHistoryRows(CUSTOMER_ID, 0, 0, 240, 10)).thenReturn(rows(
                header(1, 1, "A", Timestamp.valueOf("2026-01-01 00:00:00"), "0")));

        var last = service.getHistory(CUSTOMER_ID, null, 24, 10);

        assertEquals(250, last.totalElements());
        assertEquals(25, last.totalPages());
        assertEquals(1, last.items().size());
        // Mỗi truy vấn chỉ lấy đúng một trang: không có TOP/giới hạn cố định nào cắt dữ liệu.
        verify(repository).findHistoryRows(CUSTOMER_ID, 0, 0, 240, 10);
    }

    @Test
    void pageBeyondTheEndIsEmptyWithoutARowQuery() {
        when(repository.countHistory(CUSTOMER_ID, 0)).thenReturn(5L);

        var page = service.getHistory(CUSTOMER_ID, null, 3, 10);

        assertTrue(page.items().isEmpty());
        assertEquals(5, page.totalElements());
        verify(repository, never()).findHistoryRows(any(), any(), any(), any(), any());
    }

    @Test
    void pageAndSizeAreClamped() {
        when(repository.countHistory(CUSTOMER_ID, 0)).thenReturn(500L);
        when(repository.findHistoryRows(CUSTOMER_ID, 0, 0, 0, 50)).thenReturn(new ArrayList<>());

        var page = service.getHistory(CUSTOMER_ID, null, -3, 1000);

        assertEquals(0, page.page());
        assertEquals(50, page.size());
        assertEquals(10, page.totalPages());
        verify(repository).findHistoryRows(CUSTOMER_ID, 0, 0, 0, 50);
    }

    @Test
    void categoryIsMaintenanceOnlyWhenEveryServiceIsMaintenance() {
        var maintenance = new HistoryDetailResponse.ServiceLine(1, "Thay dầu", "BAO_DUONG", 1, BigDecimal.ONE, BigDecimal.ONE);
        var repair = new HistoryDetailResponse.ServiceLine(2, "Thay má phanh", "SUA_CHUA", 1, BigDecimal.ONE, BigDecimal.ONE);

        assertEquals("BAO_DUONG", RepairHistoryService.category(List.of(maintenance)));
        assertEquals("BAO_DUONG_SUA_CHUA", RepairHistoryService.category(List.of(maintenance, repair)));
        assertEquals("SUA_CHUA", RepairHistoryService.category(List.of(repair)));
        assertEquals("SUA_CHUA", RepairHistoryService.category(List.of()));
    }

    @Test
    void summaryMentionsMoreServicesAndFallsBackToPartsOrResult() {
        when(repository.countHistory(CUSTOMER_ID, 0)).thenReturn(3L);
        when(repository.findHistoryRows(CUSTOMER_ID, 0, 0, 0, 10)).thenReturn(rows(
                header(1, 1, "A", Timestamp.valueOf("2026-01-01 00:00:00"), "0"),
                header(2, 1, "A", Timestamp.valueOf("2026-01-02 00:00:00"), "0"),
                header(3, 1, "A", Timestamp.valueOf("2026-01-03 00:00:00"), "0")));
        when(repository.findServiceLines(any())).thenReturn(rows(
                service(1, 1, "A1", "SUA_CHUA", 1, "1"), service(1, 2, "A2", "SUA_CHUA", 1, "1"),
                service(1, 3, "A3", "SUA_CHUA", 1, "1"), service(1, 4, "A4", "SUA_CHUA", 1, "1")));
        when(repository.findPartLines(any())).thenReturn(rows(part(2, 9, "Bugi", 4, "180000")));

        var items = service.getHistory(CUSTOMER_ID, null, 0, 10).items();

        assertEquals("A1, A2, A3 và 1 hạng mục khác", items.get(0).summary());
        assertEquals("Thay phụ tùng: Bugi", items.get(1).summary());
        assertEquals("Đã kiểm tra, xe hoạt động tốt", items.get(2).summary());
    }

    @Test
    void emptyHistoryIsAnEmptyPageWithoutRowOrLineQueries() {
        when(repository.countHistory(CUSTOMER_ID, 0)).thenReturn(0L);

        var page = service.getHistory(CUSTOMER_ID, null, 0, 10);

        assertTrue(page.items().isEmpty());
        assertEquals(0, page.totalElements());
        assertEquals(0, page.totalPages());
        verify(repository, never()).findHistoryRows(any(), any(), any(), any(), any());
        verify(repository, never()).findServiceLines(any());
    }

    @Test
    void filteringByAVehicleOfAnotherCustomerIsRejectedBeforeAnyHistoryQuery() {
        when(repository.countOwnedVehicle(99, CUSTOMER_ID)).thenReturn(0L);

        assertThrows(ResourceNotFoundException.class, () -> service.getHistory(CUSTOMER_ID, 99, 0, 10));
        verify(repository, never()).countHistory(any(), any());
        verify(repository, never()).findHistoryRows(any(), any(), any(), any(), any());
    }

    @Test
    void filteringByAnOwnedVehicleScopesCountAndRowsToThatVehicleAndCustomer() {
        when(repository.countOwnedVehicle(3, CUSTOMER_ID)).thenReturn(1L);
        when(repository.countHistory(CUSTOMER_ID, 3)).thenReturn(1L);
        when(repository.findHistoryRows(CUSTOMER_ID, 3, 0, 0, 10)).thenReturn(rows(
                header(12, 3, "A", Timestamp.valueOf("2026-01-01 00:00:00"), "0")));

        var page = service.getHistory(CUSTOMER_ID, 3, 0, 10);

        assertEquals(1, page.items().size());
        verify(repository).countHistory(CUSTOMER_ID, 3);
        verify(repository).findHistoryRows(CUSTOMER_ID, 3, 0, 0, 10);
    }

    @Test
    void invalidVehicleIdIsABadRequest() {
        assertThrows(BadRequestException.class, () -> service.getHistory(CUSTOMER_ID, 0, 0, 10));
        assertThrows(BadRequestException.class, () -> service.getHistory(CUSTOMER_ID, -4, 0, 10));
    }

    @Test
    void vehicleFilterListComesFromTheWholeHistoryNotFromAPage() {
        when(repository.findHistoryVehicles(CUSTOMER_ID)).thenReturn(rows(
                new Object[]{3, "51G-123.45", "Toyota", "Camry", 14L},
                new Object[]{4, "51A-456.78", null, "Vios", 1}));

        var vehicles = service.getVehicles(CUSTOMER_ID);

        assertEquals(2, vehicles.size());
        assertEquals(3, vehicles.get(0).vehicleId());
        assertEquals("51G-123.45", vehicles.get(0).licensePlate());
        assertEquals(14, vehicles.get(0).completedCount());
        assertEquals("", vehicles.get(1).brand());
        verify(repository, never()).findHistoryRows(any(), any(), any(), any(), any());
    }

    @Test
    void detailReturnsOnlyThatOrderWithServicesPartsAndTotalsThatAddUp() {
        when(repository.findHistoryRows(CUSTOMER_ID, 0, 12, 0, 1)).thenReturn(rows(
                header(12, 1, "51G-123.45", Timestamp.valueOf("2026-09-20 10:00:00"), "1380000")));
        when(repository.findServiceLines(any())).thenReturn(rows(
                service(12, 2, "Bảo dưỡng định kỳ", "BAO_DUONG", 1, "1200000")));
        when(repository.findPartLines(any())).thenReturn(rows(part(12, 9, "Lọc dầu", 2, "90000")));

        var detail = service.getDetail(CUSTOMER_ID, 12);

        assertEquals(12, detail.item().repairOrderId());
        assertEquals("Bảo dưỡng định kỳ", detail.services().get(0).name());
        assertEquals(new BigDecimal("1200000.00"), detail.serviceTotal());
        assertEquals(new BigDecimal("180000.00"), detail.parts().get(0).lineTotal());
        assertEquals(new BigDecimal("180000.00"), detail.partsTotal());
        assertEquals(detail.item().totalCost(), detail.serviceTotal().add(detail.partsTotal()));
        assertEquals("Hoàn tất tốt", detail.item().result());
    }

    @Test
    void detailOfAnUnknownOrAnotherCustomersOrderIsNotFound() {
        when(repository.findHistoryRows(CUSTOMER_ID, 0, 77, 0, 1)).thenReturn(new ArrayList<>());

        assertThrows(ResourceNotFoundException.class, () -> service.getDetail(CUSTOMER_ID, 77));
        verify(repository, never()).findServiceLines(any());
    }

    @Test
    void nullDatesAndResultDoNotBreakTheMapping() {
        when(repository.countHistory(CUSTOMER_ID, 0)).thenReturn(1L);
        when(repository.findHistoryRows(CUSTOMER_ID, 0, 0, 0, 10)).thenReturn(rows(
                new Object[]{4, 1, "51G-123.45", null, null, Timestamp.valueOf("2026-01-01 08:00:00"), null, null, null,
                        new BigDecimal("0")}));

        var item = service.getHistory(CUSTOMER_ID, null, 0, 10).items().get(0);

        assertNull(item.startedAt());
        assertNull(item.completedAt());
        assertEquals("", item.result());
        assertEquals("", item.brand());
        assertEquals(LocalDateTime.of(2026, 1, 1, 8, 0), item.createdAt());
        assertEquals("Không có hạng mục chi tiết", item.summary());
    }

    @Test
    void datesAcceptTimestampLocalDateTimeAndNull() {
        assertEquals(LocalDateTime.of(2026, 1, 2, 3, 4, 5), RepairHistoryService.toDateTime(Timestamp.valueOf("2026-01-02 03:04:05")));
        assertEquals(LocalDateTime.of(2026, 1, 2, 3, 4, 5), RepairHistoryService.toDateTime(LocalDateTime.of(2026, 1, 2, 3, 4, 5)));
        assertNull(RepairHistoryService.toDateTime(null));
    }

    // ------------------------------------------------------------------ helpers

    private List<Object[]> rows(Object[]... rows) {
        return new ArrayList<>(Arrays.asList(rows));
    }

    private Object[] header(int orderId, int vehicleId, String plate, Timestamp completed, String total) {
        String result = orderId == 12 ? "Hoàn tất tốt" : orderId == 3 ? "Đã kiểm tra, xe hoạt động tốt" : null;
        return new Object[]{orderId, vehicleId, plate, "Toyota", "Camry",
                Timestamp.valueOf("2026-09-18 08:00:00"), Timestamp.valueOf("2026-09-19 08:00:00"), completed,
                result, new BigDecimal(total)};
    }

    private Object[] service(int orderId, int serviceId, String name, String type, int quantity, String price) {
        return new Object[]{orderId, serviceId, name, type, quantity, new BigDecimal(price)};
    }

    private Object[] part(int orderId, int partId, String name, int quantity, String price) {
        return new Object[]{orderId, partId, name, quantity, new BigDecimal(price)};
    }
}
'@
Write-RepoFile 'backend/src/test/java/com/gara/quanlygara/controller/CustomerHistoryApiTest.java' @'
// TV3-TUAN9
package com.gara.quanlygara.controller;

import com.gara.quanlygara.entity.Account;
import com.gara.quanlygara.entity.AccountRole;
//__MOCK_IMPORTS__
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.math.BigDecimal;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Optional;

import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.not;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest(properties = {
        "app.jwt.secret=a-test-secret-that-is-at-least-32-characters",
        "spring.autoconfigure.exclude="
                + "org.springframework.boot.autoconfigure.jdbc.DataSourceAutoConfiguration,"
                + "org.springframework.boot.autoconfigure.orm.jpa.HibernateJpaAutoConfiguration,"
                + "org.springframework.boot.autoconfigure.data.jpa.JpaRepositoriesAutoConfiguration"
})
@AutoConfigureMockMvc
class CustomerHistoryApiTest {

    @Autowired
    private MockMvc mockMvc;

//__MOCK_FIELDS__

    private void account(String username, AccountRole role, Integer customerId) {
        Account account = new Account();
        account.setId(1);
        account.setUsername(username);
        account.setPasswordHash("hash");
        account.setRole(role);
        account.setActive(true);
        account.setCustomerId(customerId);
        when(accountRepository.findByUsername(username)).thenReturn(Optional.of(account));
    }

    private List<Object[]> rows(Object[]... rows) {
        return new ArrayList<>(Arrays.asList(rows));
    }

    private Object[] header(int orderId, int vehicleId, String plate) {
        return new Object[]{orderId, vehicleId, plate, "Toyota", "Camry",
                Timestamp.valueOf("2026-09-18 08:00:00"), Timestamp.valueOf("2026-09-19 08:00:00"),
                Timestamp.valueOf("2026-09-20 10:00:00"), "Hoàn tất tốt", new BigDecimal("1380000")};
    }

    @Test
    void historyRequiresJwt() throws Exception {
        mockMvc.perform(get("/api/customers/me/history")).andExpect(status().isUnauthorized());
    }

    @Test
    @WithMockUser(roles = "MANAGER")
    void managerCannotUseTheCustomerHistoryApi() throws Exception {
        mockMvc.perform(get("/api/customers/me/history")).andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(roles = "RECEPTIONIST")
    void receptionistCannotUseTheCustomerHistoryApi() throws Exception {
        mockMvc.perform(get("/api/customers/me/history/1")).andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(roles = "TECHNICIAN")
    void technicianCannotUseTheCustomerHistoryApi() throws Exception {
        mockMvc.perform(get("/api/customers/me/history")).andExpect(status().isForbidden());
        mockMvc.perform(get("/api/customers/me/history/vehicles")).andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(username = "khachA", roles = "CUSTOMER")
    void customerSeesOwnHistoryPageAndCustomerIdFromTheClientIsIgnored() throws Exception {
        account("khachA", AccountRole.CUSTOMER, 1);
        when(repairHistoryRepository.countHistory(1, 0)).thenReturn(23L);
        when(repairHistoryRepository.findHistoryRows(1, 0, 0, 0, 10)).thenReturn(rows(header(12, 3, "51G-123.45")));
        when(repairHistoryRepository.findServiceLines(any())).thenReturn(rows(
                new Object[]{12, 2, "Bảo dưỡng định kỳ", "BAO_DUONG", 1, new BigDecimal("1200000")}));
        when(repairHistoryRepository.findPartLines(any())).thenReturn(rows(
                new Object[]{12, 9, "Lọc dầu", 2, new BigDecimal("90000")}));

        // Client cố truyền customerId của người khác: bị bỏ qua, truy vấn luôn dùng customerId của JWT (1).
        mockMvc.perform(get("/api/customers/me/history").param("customerId", "2"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.items.length()").value(1))
                .andExpect(jsonPath("$.data.items[0].repairOrderId").value(12))
                .andExpect(jsonPath("$.data.items[0].licensePlate").value("51G-123.45"))
                .andExpect(jsonPath("$.data.items[0].category").value("BAO_DUONG"))
                .andExpect(jsonPath("$.data.items[0].totalCost").value(1380000.0))
                .andExpect(jsonPath("$.data.page").value(0))
                .andExpect(jsonPath("$.data.size").value(10))
                .andExpect(jsonPath("$.data.totalElements").value(23))
                .andExpect(jsonPath("$.data.totalPages").value(3));

        verify(repairHistoryRepository).findHistoryRows(1, 0, 0, 0, 10);
        verify(repairHistoryRepository, never()).findHistoryRows(2, 0, 0, 0, 10);
    }

    @Test
    @WithMockUser(username = "khachA", roles = "CUSTOMER")
    void customerCanRequestALaterPage() throws Exception {
        account("khachA", AccountRole.CUSTOMER, 1);
        when(repairHistoryRepository.countHistory(1, 0)).thenReturn(23L);
        when(repairHistoryRepository.findHistoryRows(1, 0, 0, 20, 10)).thenReturn(rows(header(2, 3, "51G-123.45")));
        when(repairHistoryRepository.findServiceLines(any())).thenReturn(new ArrayList<>());
        when(repairHistoryRepository.findPartLines(any())).thenReturn(new ArrayList<>());

        mockMvc.perform(get("/api/customers/me/history").param("page", "2").param("size", "10"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.page").value(2))
                .andExpect(jsonPath("$.data.items[0].repairOrderId").value(2));
    }

    @Test
    @WithMockUser(username = "khachA", roles = "CUSTOMER")
    void customerWithNoHistoryGetsAnEmptyPage() throws Exception {
        account("khachA", AccountRole.CUSTOMER, 1);
        when(repairHistoryRepository.countHistory(1, 0)).thenReturn(0L);

        mockMvc.perform(get("/api/customers/me/history"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.items.length()").value(0))
                .andExpect(jsonPath("$.data.totalElements").value(0));
    }

    @Test
    @WithMockUser(username = "khachA", roles = "CUSTOMER")
    void customerCanFilterByOwnVehicle() throws Exception {
        account("khachA", AccountRole.CUSTOMER, 1);
        when(repairHistoryRepository.countOwnedVehicle(3, 1)).thenReturn(1L);
        when(repairHistoryRepository.countHistory(1, 3)).thenReturn(1L);
        when(repairHistoryRepository.findHistoryRows(1, 3, 0, 0, 10)).thenReturn(rows(header(12, 3, "51G-123.45")));
        when(repairHistoryRepository.findServiceLines(any())).thenReturn(new ArrayList<>());
        when(repairHistoryRepository.findPartLines(any())).thenReturn(new ArrayList<>());

        mockMvc.perform(get("/api/customers/me/history").param("vehicleId", "3"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.items[0].vehicleId").value(3));
    }

    @Test
    @WithMockUser(username = "khachA", roles = "CUSTOMER")
    void customerCannotFilterByAnotherCustomersVehicle() throws Exception {
        account("khachA", AccountRole.CUSTOMER, 1);
        when(repairHistoryRepository.countOwnedVehicle(50, 1)).thenReturn(0L);

        mockMvc.perform(get("/api/customers/me/history").param("vehicleId", "50"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.success").value(false));
        verify(repairHistoryRepository, never()).findHistoryRows(any(), any(), any(), any(), any());
    }

    @Test
    @WithMockUser(username = "khachA", roles = "CUSTOMER")
    void invalidVehicleIdIsABadRequest() throws Exception {
        account("khachA", AccountRole.CUSTOMER, 1);

        mockMvc.perform(get("/api/customers/me/history").param("vehicleId", "0"))
                .andExpect(status().isBadRequest());
    }

    @Test
    @WithMockUser(username = "khachA", roles = "CUSTOMER")
    void vehicleFilterListIsScopedToTheCustomerAndIndependentOfPages() throws Exception {
        account("khachA", AccountRole.CUSTOMER, 1);
        when(repairHistoryRepository.findHistoryVehicles(1)).thenReturn(rows(
                new Object[]{3, "51G-123.45", "Toyota", "Camry", 14L},
                new Object[]{4, "51A-456.78", "Kia", "Seltos", 2}));

        mockMvc.perform(get("/api/customers/me/history/vehicles"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()").value(2))
                .andExpect(jsonPath("$.data[0].vehicleId").value(3))
                .andExpect(jsonPath("$.data[0].completedCount").value(14))
                .andExpect(jsonPath("$.data[1].licensePlate").value("51A-456.78"));
        verify(repairHistoryRepository).findHistoryVehicles(1);
    }

    @Test
    @WithMockUser(username = "khachA", roles = "CUSTOMER")
    void detailOfTheCustomersOwnOrderHasServicesPartsAndTotals() throws Exception {
        account("khachA", AccountRole.CUSTOMER, 1);
        when(repairHistoryRepository.findHistoryRows(1, 0, 12, 0, 1)).thenReturn(rows(header(12, 3, "51G-123.45")));
        when(repairHistoryRepository.findServiceLines(any())).thenReturn(rows(
                new Object[]{12, 2, "Bảo dưỡng định kỳ", "BAO_DUONG", 1, new BigDecimal("1200000")}));
        when(repairHistoryRepository.findPartLines(any())).thenReturn(rows(
                new Object[]{12, 9, "Lọc dầu", 2, new BigDecimal("90000")}));

        mockMvc.perform(get("/api/customers/me/history/12"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.item.repairOrderId").value(12))
                .andExpect(jsonPath("$.data.services[0].name").value("Bảo dưỡng định kỳ"))
                .andExpect(jsonPath("$.data.parts[0].lineTotal").value(180000.0))
                .andExpect(jsonPath("$.data.serviceTotal").value(1200000.0))
                .andExpect(jsonPath("$.data.partsTotal").value(180000.0));
    }

    @Test
    @WithMockUser(username = "khachA", roles = "CUSTOMER")
    void detailOfAnotherCustomersOrderIsNotFoundAndLeaksNothing() throws Exception {
        account("khachA", AccountRole.CUSTOMER, 1);
        // Phiếu 99 của khách hàng khác: truy vấn (lọc theo khách hàng A) không trả dòng nào.
        when(repairHistoryRepository.findHistoryRows(1, 0, 99, 0, 1)).thenReturn(new ArrayList<>());

        mockMvc.perform(get("/api/customers/me/history/99"))
                .andExpect(status().isNotFound())
                .andExpect(content().string(not(containsString("51G"))));
        verify(repairHistoryRepository, never()).findServiceLines(any());
    }

    @Test
    @WithMockUser(username = "khachX", roles = "CUSTOMER")
    void customerAccountWithoutALinkedCustomerIsForbidden() throws Exception {
        account("khachX", AccountRole.CUSTOMER, null);

        mockMvc.perform(get("/api/customers/me/history")).andExpect(status().isForbidden());
        mockMvc.perform(get("/api/customers/me/history/vehicles")).andExpect(status().isForbidden());
        verify(repairHistoryRepository, never()).countHistory(any(), any());
    }

    @Test
    void swaggerListsTheHistoryApi() throws Exception {
        mockMvc.perform(get("/v3/api-docs"))
                .andExpect(status().isOk())
                .andExpect(content().string(containsString("/api/customers/me/history")))
                .andExpect(content().string(containsString("/api/customers/me/history/vehicles")));
    }
}
'@
Write-RepoFile 'backend/src/test/java/com/gara/quanlygara/integration/RepairHistorySqlServerIT.java' @'
// TV3-TUAN9
package com.gara.quanlygara.integration;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.simple.SimpleJdbcInsert;
import org.springframework.test.context.transaction.AfterTransaction;
import org.springframework.test.context.transaction.BeforeTransaction;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.RequestPostProcessor;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.sql.Timestamp;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Integration test trên SQL Server THẬT cho API lịch sử: chạy native SQL và dbo.fn_TinhTongChiPhiSuaChua trên schema thật.
 *
 * Không chạy trong ".\mvnw.cmd test" (tên *IT không thuộc mẫu của surefire) và còn bị khóa bởi biến môi trường,
 * để test thường không phụ thuộc SQL Server. Chạy:
 *   $env:RUN_SQLSERVER_IT = "true"     # cùng DB_URL / DB_USERNAME / DB_PASSWORD như khi chạy backend (hoặc file backend/.env)
 *   .\mvnw.cmd -Dtest=RepairHistorySqlServerIT test
 *
 * Toàn bộ dữ liệu test nằm trong transaction của test và bị ROLLBACK; @AfterTransaction kiểm tra số dòng các bảng
 * không đổi. Dữ liệu dùng mã duy nhất theo thời gian, không phụ thuộc ID của dữ liệu mẫu.
 */
@EnabledIfEnvironmentVariable(named = "RUN_SQLSERVER_IT", matches = "true")
@SpringBootTest(properties = "app.jwt.secret=it-secret-that-is-at-least-32-characters-long")
@AutoConfigureMockMvc
@Transactional
class RepairHistorySqlServerIT {

    private static final List<String> TABLES = List.of(
            "KhachHang", "TaiKhoan", "Xe", "PhieuTiepNhan", "PhieuSuaChua", "DichVu", "ChiTietDichVu",
            "PhuTung", "ChiTietPhuTung");

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private JdbcTemplate jdbc;

    private Map<String, Long> countsBefore;

    @BeforeTransaction
    void rememberRowCounts() {
        countsBefore = counts();
    }

    @AfterTransaction
    void seedDataIsUnchangedAfterRollback() {
        assertEquals(countsBefore, counts(), "Dữ liệu test phải được rollback hoàn toàn");
    }

    private Map<String, Long> counts() {
        Map<String, Long> result = new LinkedHashMap<>();
        for (String table : TABLES) {
            result.put(table, jdbc.queryForObject("SELECT COUNT_BIG(*) FROM " + table, Long.class));
        }
        return result;
    }

    // ------------------------------------------------------------------ dữ liệu test

    private int insert(String table, String keyColumn, Map<String, Object> values) {
        Number key = new SimpleJdbcInsert(jdbc).withTableName(table)
                .usingGeneratedKeyColumns(keyColumn).usingColumns(values.keySet().toArray(new String[0]))
                .executeAndReturnKey(values);
        return key.intValue();
    }

    private int customer(String tag, String name) {
        return insert("KhachHang", "MaKhachHang", Map.of("HoTen", name, "SoDienThoai", "09" + tag));
    }

    private void account(String username, int customerId) {
        insert("TaiKhoan", "MaTaiKhoan", Map.of(
                "TenDangNhap", username, "MatKhauHash", "it-not-a-real-hash", "VaiTro", "CUSTOMER", "MaKhachHang", customerId));
    }

    private int vehicle(int customerId, String plate) {
        return insert("Xe", "MaXe", Map.of("MaKhachHang", customerId, "BienSo", plate, "HangXe", "Toyota", "DongXe", "Camry"));
    }

    private int service(String tag, String type, String price) {
        return insert("DichVu", "MaDichVu", Map.of(
                "TenDichVu", "IT dich vu " + tag, "LoaiDichVu", type, "DonGia", new BigDecimal(price)));
    }

    private int part(String tag, String price) {
        Integer warehouse = jdbc.queryForObject("SELECT TOP 1 MaKho FROM Kho ORDER BY MaKho", Integer.class);
        return insert("PhuTung", "MaPhuTung", Map.of(
                "MaKho", warehouse, "TenPhuTung", "IT phu tung " + tag, "DonGia", new BigDecimal(price),
                "MucTonToiThieu", 0));
    }

    /** Tạo phiếu tiếp nhận + phiếu sửa chữa; completedAt = null thì không có ngày hoàn thành. */
    private int repairOrder(int vehicleId, String status, String completedAt, String result) {
        int reception = insert("PhieuTiepNhan", "MaTiepNhan", Map.of(
                "MaXe", vehicleId, "NgayTiepNhan", Timestamp.valueOf("2026-03-01 08:00:00")));
        Map<String, Object> values = new HashMap<>();
        values.put("MaTiepNhan", reception);
        values.put("NgayLap", Timestamp.valueOf("2026-03-01 09:00:00"));
        values.put("NgayBatDau", Timestamp.valueOf("2026-03-02 08:00:00"));
        if (completedAt != null) values.put("NgayHoanThanh", Timestamp.valueOf(completedAt));
        values.put("TrangThai", status);
        if (result != null) values.put("KetQua", result);
        return insert("PhieuSuaChua", "MaPhieuSuaChua", values);
    }

    private void serviceLine(int orderId, int serviceId, int quantity, String price) {
        jdbc.update("INSERT INTO ChiTietDichVu (MaPhieuSuaChua, MaDichVu, SoLuong, DonGia) VALUES (?, ?, ?, ?)",
                orderId, serviceId, quantity, new BigDecimal(price));
    }

    private void partLine(int orderId, int partId, int quantity, String price) {
        jdbc.update("INSERT INTO ChiTietPhuTung (MaPhieuSuaChua, MaPhuTung, SoLuong, DonGia) VALUES (?, ?, ?, ?)",
                orderId, partId, quantity, new BigDecimal(price));
    }

    private RequestPostProcessor asCustomer(String username) {
        return user(username).roles("CUSTOMER");
    }

    // ------------------------------------------------------------------ test

    @Test
    void historyListDetailAndOwnershipRunAgainstTheRealSchema() throws Exception {
        String tag = Long.toString(System.nanoTime()).substring(8);
        int customerA = customer(tag + "1", "IT Khach A " + tag);
        int customerB = customer(tag + "2", "IT Khach B " + tag);
        String usernameA = "it_hist_a_" + tag;
        account(usernameA, customerA);
        account("it_hist_b_" + tag, customerB);

        int vehicleA1 = vehicle(customerA, "IT" + tag + "A1");
        int vehicleA2 = vehicle(customerA, "IT" + tag + "A2");
        int vehicleA3 = vehicle(customerA, "IT" + tag + "A3");
        int vehicleB1 = vehicle(customerB, "IT" + tag + "B1");

        int maintenance = service(tag + "m", "BAO_DUONG", "300000");
        int repair = service(tag + "r", "SUA_CHUA", "500000");
        int partX = part(tag + "x", "90000");

        // A1: bảo dưỡng 2 x 300000 + phụ tùng 3 x 90000 = 870000, hoàn tất mới nhất.
        int doneNewest = repairOrder(vehicleA1, "HOAN_TAT", "2026-09-20 10:00:00", "Hoàn tất tốt");
        serviceLine(doneNewest, maintenance, 2, "300000");
        partLine(doneNewest, partX, 3, "90000");
        // A2: sửa chữa 1 x 500000, hoàn tất cũ hơn, KetQua NULL.
        int doneOlder = repairOrder(vehicleA2, "HOAN_TAT", "2026-06-01 09:00:00", null);
        serviceLine(doneOlder, repair, 1, "500000");
        // A3: chưa hoàn tất => KHÔNG được xuất hiện trong lịch sử.
        int inProgress = repairOrder(vehicleA3, "DANG_SUA", null, null);
        serviceLine(inProgress, repair, 1, "500000");
        // B1: của khách hàng khác.
        int otherCustomers = repairOrder(vehicleB1, "HOAN_TAT", "2026-09-25 10:00:00", "Của khách B");
        serviceLine(otherCustomers, repair, 1, "777000");

        // 1) Danh sách: đúng 2 lượt hoàn tất của A, mới nhất trước, tổng chi phí từ dbo.fn_TinhTongChiPhiSuaChua.
        mockMvc.perform(get("/api/customers/me/history").with(asCustomer(usernameA)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.totalElements").value(2))
                .andExpect(jsonPath("$.data.items.length()").value(2))
                .andExpect(jsonPath("$.data.items[0].repairOrderId").value(doneNewest))
                .andExpect(jsonPath("$.data.items[0].vehicleId").value(vehicleA1))
                .andExpect(jsonPath("$.data.items[0].category").value("BAO_DUONG"))
                .andExpect(jsonPath("$.data.items[0].serviceCount").value(1))
                .andExpect(jsonPath("$.data.items[0].partCount").value(1))
                .andExpect(jsonPath("$.data.items[0].totalCost").value(870000.0))
                .andExpect(jsonPath("$.data.items[1].repairOrderId").value(doneOlder))
                .andExpect(jsonPath("$.data.items[1].category").value("SUA_CHUA"))
                .andExpect(jsonPath("$.data.items[1].totalCost").value(500000.0))
                .andExpect(jsonPath("$.data.items[1].result").value(""));

        // 2) Chi tiết: dịch vụ, phụ tùng và tổng khớp nhau và khớp function SQL.
        mockMvc.perform(get("/api/customers/me/history/" + doneNewest).with(asCustomer(usernameA)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.item.totalCost").value(870000.0))
                .andExpect(jsonPath("$.data.services.length()").value(1))
                .andExpect(jsonPath("$.data.services[0].lineTotal").value(600000.0))
                .andExpect(jsonPath("$.data.parts.length()").value(1))
                .andExpect(jsonPath("$.data.parts[0].quantity").value(3))
                .andExpect(jsonPath("$.data.parts[0].lineTotal").value(270000.0))
                .andExpect(jsonPath("$.data.serviceTotal").value(600000.0))
                .andExpect(jsonPath("$.data.partsTotal").value(270000.0));

        // 3) Phiếu chưa hoàn tất và phiếu của khách hàng khác: 404 như nhau.
        mockMvc.perform(get("/api/customers/me/history/" + inProgress).with(asCustomer(usernameA)))
                .andExpect(status().isNotFound());
        mockMvc.perform(get("/api/customers/me/history/" + otherCustomers).with(asCustomer(usernameA)))
                .andExpect(status().isNotFound());

        // 4) Lọc theo xe: xe của mình OK, xe của khách khác 404.
        mockMvc.perform(get("/api/customers/me/history").param("vehicleId", String.valueOf(vehicleA2)).with(asCustomer(usernameA)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.totalElements").value(1))
                .andExpect(jsonPath("$.data.items[0].repairOrderId").value(doneOlder));
        mockMvc.perform(get("/api/customers/me/history").param("vehicleId", String.valueOf(vehicleB1)).with(asCustomer(usernameA)))
                .andExpect(status().isNotFound());

        // 5) Danh sách xe để lọc: chỉ xe của A có lịch sử hoàn tất (không có A3, không có B1).
        mockMvc.perform(get("/api/customers/me/history/vehicles").with(asCustomer(usernameA)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()").value(2))
                .andExpect(jsonPath("$.data[?(@.vehicleId == " + vehicleA3 + ")]").isEmpty())
                .andExpect(jsonPath("$.data[?(@.vehicleId == " + vehicleB1 + ")]").isEmpty());

        // 6) Truyền customerId của người khác không đổi được dữ liệu.
        mockMvc.perform(get("/api/customers/me/history").param("customerId", String.valueOf(customerB)).with(asCustomer(usernameA)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.totalElements").value(2));
    }

    @Test
    void longHistoryIsPagedWithoutTruncationAtTwoHundred() throws Exception {
        String tag = Long.toString(System.nanoTime()).substring(8);
        int customerId = customer(tag + "3", "IT Khach Dai " + tag);
        String username = "it_hist_long_" + tag;
        account(username, customerId);
        int vehicleId = vehicle(customerId, "IT" + tag + "L");

        // 205 lượt hoàn tất, ngày hoàn thành tăng dần theo từng lượt để kiểm tra thứ tự mới nhất trước.
        jdbc.update("""
                INSERT INTO PhieuTiepNhan (MaXe, NgayTiepNhan)
                SELECT TOP (205) ?, DATEADD(MINUTE, ROW_NUMBER() OVER (ORDER BY (SELECT NULL)), '2025-01-01')
                FROM sys.all_objects
                """, vehicleId);
        jdbc.update("""
                INSERT INTO PhieuSuaChua (MaTiepNhan, NgayLap, NgayBatDau, NgayHoanThanh, TrangThai)
                SELECT MaTiepNhan, NgayTiepNhan, NgayTiepNhan, NgayTiepNhan, N'HOAN_TAT'
                FROM PhieuTiepNhan WHERE MaXe = ?
                """, vehicleId);
        Integer newestId = jdbc.queryForObject("""
                SELECT TOP 1 ps.MaPhieuSuaChua FROM PhieuSuaChua ps
                JOIN PhieuTiepNhan tn ON tn.MaTiepNhan = ps.MaTiepNhan
                WHERE tn.MaXe = ? ORDER BY ps.NgayHoanThanh DESC, ps.MaPhieuSuaChua DESC
                """, Integer.class, vehicleId);

        Set<Integer> seen = new HashSet<>();
        for (int page = 0; page < 5; page++) {
            String body = mockMvc.perform(get("/api/customers/me/history").param("page", String.valueOf(page)).param("size", "50")
                            .with(asCustomer(username)))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.data.totalElements").value(205))
                    .andExpect(jsonPath("$.data.totalPages").value(5))
                    .andReturn().getResponse().getContentAsString();
            JsonNode items = new ObjectMapper().readTree(body).path("data").path("items");
            assertEquals(page == 4 ? 5 : 50, items.size(), "Số dòng của trang " + page);
            if (page == 0) assertEquals(newestId.intValue(), items.get(0).path("repairOrderId").asInt());
            items.forEach(item -> assertTrue(seen.add(item.path("repairOrderId").asInt()), "Không trùng lượt giữa các trang"));
        }
        assertEquals(205, seen.size(), "Phải đọc đủ 205 lượt, không bị cắt ở 200");
    }
}
'@
Replace-OwnedFile 'mobile/lib/models/history.dart' '7da04e30608a1df4d79c6f0077665a15f18e58966b86950688324e7fbec82b70' @'
// TV3-TUAN9
/// Lượt sửa chữa/bảo dưỡng đã hoàn tất, tổng hợp từ dữ liệu nghiệp vụ gốc bởi backend
/// (GET /api/customers/me/history). Không có dữ liệu mock.
enum HistoryCategory { maintenance, repair, mixed }

int _asInt(Object? value) => value is num ? value.round() : 0;

String _asText(Object? value) => value?.toString() ?? '';

DateTime? _asDate(Object? value) =>
    value == null ? null : DateTime.tryParse(value.toString());

HistoryCategory _asCategory(Object? value) => switch (value?.toString()) {
  'BAO_DUONG' => HistoryCategory.maintenance,
  'BAO_DUONG_SUA_CHUA' => HistoryCategory.mixed,
  _ => HistoryCategory.repair,
};

class HistoryItem {
  const HistoryItem({
    required this.repairOrderId,
    required this.vehicleId,
    required this.plate,
    required this.brand,
    required this.model,
    required this.category,
    required this.summary,
    required this.serviceCount,
    required this.partCount,
    required this.totalCost,
    required this.result,
    this.createdAt,
    this.startedAt,
    this.completedAt,
  });

  factory HistoryItem.fromJson(Map<String, dynamic> json) => HistoryItem(
    repairOrderId: _asInt(json['repairOrderId']),
    vehicleId: _asInt(json['vehicleId']),
    plate: _asText(json['licensePlate']),
    brand: _asText(json['brand']),
    model: _asText(json['model']),
    category: _asCategory(json['category']),
    summary: _asText(json['summary']),
    serviceCount: _asInt(json['serviceCount']),
    partCount: _asInt(json['partCount']),
    totalCost: _asInt(json['totalCost']),
    result: _asText(json['result']),
    createdAt: _asDate(json['createdAt']),
    startedAt: _asDate(json['startedAt']),
    completedAt: _asDate(json['completedAt']),
  );

  final int repairOrderId;
  final int vehicleId;
  final String plate;
  final String brand;
  final String model;
  final HistoryCategory category;
  final String summary;
  final int serviceCount;
  final int partCount;
  final int totalCost;
  final String result;
  final DateTime? createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;

  String get vehicleName => [brand, model].where((part) => part.isNotEmpty).join(' ');

  /// Ngày hiển thị: hoàn thành, nếu chưa có thì bắt đầu, rồi đến ngày lập phiếu.
  DateTime? get date => completedAt ?? startedAt ?? createdAt;
}

class HistoryServiceLine {
  const HistoryServiceLine({
    required this.serviceId,
    required this.name,
    required this.type,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });

  factory HistoryServiceLine.fromJson(Map<String, dynamic> json) =>
      HistoryServiceLine(
        serviceId: _asInt(json['serviceId']),
        name: _asText(json['name']),
        type: _asText(json['type']),
        quantity: _asInt(json['quantity']),
        unitPrice: _asInt(json['unitPrice']),
        lineTotal: _asInt(json['lineTotal']),
      );

  final int serviceId;
  final String name;
  final String type;
  final int quantity;
  final int unitPrice;
  final int lineTotal;
}

class HistoryPartLine {
  const HistoryPartLine({
    required this.partId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });

  factory HistoryPartLine.fromJson(Map<String, dynamic> json) => HistoryPartLine(
    partId: _asInt(json['partId']),
    name: _asText(json['name']),
    quantity: _asInt(json['quantity']),
    unitPrice: _asInt(json['unitPrice']),
    lineTotal: _asInt(json['lineTotal']),
  );

  final int partId;
  final String name;
  final int quantity;
  final int unitPrice;
  final int lineTotal;
}

class HistoryDetail {
  const HistoryDetail({
    required this.item,
    required this.services,
    required this.parts,
    required this.serviceTotal,
    required this.partsTotal,
  });

  factory HistoryDetail.fromJson(Map<String, dynamic> json) {
    final item = json['item'];
    if (item is! Map<String, dynamic>) {
      throw const FormatException('Thiếu thông tin phiếu sửa chữa.');
    }
    List<T> lines<T>(Object? raw, T Function(Map<String, dynamic>) parse) =>
        raw is List ? raw.whereType<Map<String, dynamic>>().map(parse).toList() : <T>[];
    return HistoryDetail(
      item: HistoryItem.fromJson(item),
      services: lines(json['services'], HistoryServiceLine.fromJson),
      parts: lines(json['parts'], HistoryPartLine.fromJson),
      serviceTotal: _asInt(json['serviceTotal']),
      partsTotal: _asInt(json['partsTotal']),
    );
  }

  final HistoryItem item;
  final List<HistoryServiceLine> services;
  final List<HistoryPartLine> parts;
  final int serviceTotal;
  final int partsTotal;
}


/// Một trang lịch sử từ backend; page bắt đầu từ 0. totalElements là tổng số lượt (không bị cắt).
class HistoryPage {
  const HistoryPage({
    required this.items,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
  });

  factory HistoryPage.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    return HistoryPage(
      items: raw is List
          ? raw.whereType<Map<String, dynamic>>().map(HistoryItem.fromJson).toList()
          : <HistoryItem>[],
      page: _asInt(json['page']),
      size: _asInt(json['size']),
      totalElements: _asInt(json['totalElements']),
      totalPages: _asInt(json['totalPages']),
    );
  }

  final List<HistoryItem> items;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;

  bool get hasMore => page + 1 < totalPages;
}

/// Xe có lịch sử hoàn tất của khách hàng, dùng làm bộ lọc (lấy từ toàn bộ lịch sử, không chỉ trang đầu).
class HistoryVehicle {
  const HistoryVehicle({
    required this.id,
    required this.plate,
    required this.brand,
    required this.model,
    required this.completedCount,
  });

  factory HistoryVehicle.fromJson(Map<String, dynamic> json) => HistoryVehicle(
    id: _asInt(json['vehicleId']),
    plate: _asText(json['licensePlate']),
    brand: _asText(json['brand']),
    model: _asText(json['model']),
    completedCount: _asInt(json['completedCount']),
  );

  final int id;
  final String plate;
  final String brand;
  final String model;
  final int completedCount;
}
'@
Replace-OwnedFile 'mobile/lib/services/history_service.dart' '15c254c7b1533d005be2001d6f2366fc93e0ce70f6d6c41115cba228c6fe4e84' @'
// TV3-TUAN9
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../core/constants/app_config.dart';
import '../models/history.dart';

class HistoryException implements Exception {
  const HistoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Tra cứu lịch sử sửa chữa, bảo dưỡng của khách hàng đang đăng nhập.
/// Backend lấy khách hàng từ JWT nên client không (và không thể) chọn customerId.
abstract interface class HistoryService {
  /// Một trang lịch sử, mới nhất trước. page bắt đầu từ 0.
  Future<HistoryPage> getHistory({int? vehicleId, int page = 0, int size = 10});

  /// Toàn bộ xe có lịch sử hoàn tất của khách hàng (để lọc), không phụ thuộc trang.
  Future<List<HistoryVehicle>> getHistoryVehicles();

  Future<HistoryDetail> getHistoryDetail(int repairOrderId);
}

class ApiHistoryService implements HistoryService {
  ApiHistoryService({
    required this.tokenProvider,
    String? baseUrl,
    HttpClient? client,
  }) : _baseUrl = (baseUrl ?? AppConfig.apiBaseUrl).replaceAll(RegExp(r'/+$'), ''),
       _client = client ?? HttpClient();

  /// Trả về access token của phiên đăng nhập hiện tại (null khi chưa đăng nhập).
  final String? Function() tokenProvider;
  final String _baseUrl;
  final HttpClient _client;

  @override
  Future<HistoryPage> getHistory({
    int? vehicleId,
    int page = 0,
    int size = 10,
  }) async {
    final data = await _get(
      '/customers/me/history',
      query: {
        'page': '$page',
        'size': '$size',
        if (vehicleId != null) 'vehicleId': '$vehicleId',
      },
    );
    if (data is! Map<String, dynamic>) {
      throw const HistoryException('Dữ liệu lịch sử không hợp lệ.');
    }
    return HistoryPage.fromJson(data);
  }

  @override
  Future<List<HistoryVehicle>> getHistoryVehicles() async {
    final data = await _get('/customers/me/history/vehicles');
    if (data is! List) {
      throw const HistoryException('Dữ liệu xe không hợp lệ.');
    }
    return data
        .whereType<Map<String, dynamic>>()
        .map(HistoryVehicle.fromJson)
        .toList();
  }

  @override
  Future<HistoryDetail> getHistoryDetail(int repairOrderId) async {
    final data = await _get('/customers/me/history/$repairOrderId');
    if (data is! Map<String, dynamic>) {
      throw const HistoryException('Dữ liệu lịch sử không hợp lệ.');
    }
    try {
      return HistoryDetail.fromJson(data);
    } on FormatException {
      throw const HistoryException('Dữ liệu lịch sử không hợp lệ.');
    }
  }

  Future<Object?> _get(String path, {Map<String, String>? query}) async {
    final token = tokenProvider();
    if (token == null || token.isEmpty) {
      throw const HistoryException(
        'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
      );
    }
    try {
      var uri = Uri.parse('$_baseUrl$path');
      if (query != null) uri = uri.replace(queryParameters: query);
      final request = await _client.getUrl(uri);
      request.headers
        ..set(HttpHeaders.authorizationHeader, 'Bearer $token')
        ..set(HttpHeaders.acceptHeader, ContentType.json.mimeType);
      final response = await request.close().timeout(
        const Duration(seconds: 12),
      );
      final body = await utf8.decoder.bind(response).join();
      final decoded = body.trim().isEmpty ? null : jsonDecode(body);
      final payload = decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{};
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HistoryException(_errorMessage(response.statusCode, payload));
      }
      return payload['data'];
    } on HistoryException {
      rethrow;
    } on TimeoutException {
      throw const HistoryException(
        'Kết nối bị gián đoạn. Vui lòng kiểm tra mạng và thử lại.',
      );
    } on SocketException {
      throw const HistoryException(
        'Không thể kết nối đến hệ thống. Vui lòng kiểm tra mạng và thử lại.',
      );
    } on HttpException {
      throw const HistoryException(
        'Không thể kết nối đến hệ thống. Vui lòng thử lại.',
      );
    } on FormatException {
      throw const HistoryException(
        'Không thể xử lý dữ liệu lịch sử. Vui lòng thử lại.',
      );
    }
  }

  String _errorMessage(int statusCode, Map<String, dynamic> payload) {
    final message = payload['message']?.toString();
    return switch (statusCode) {
      401 => 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
      403 => 'Bạn không có quyền xem lịch sử này.',
      404 => message ?? 'Không tìm thấy dữ liệu lịch sử.',
      _ => message ?? 'Không thể tải lịch sử. Vui lòng thử lại.',
    };
  }
}
'@
Replace-OwnedFile 'mobile/lib/screens/history/history_screen.dart' '85075ca535bc92c740580693ededf4693667d1620f29a2150ed7af2e6eb99834' @'
// TV3-TUAN9
import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/feedback_states.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/history.dart';
import '../../services/history_service.dart';
import 'history_detail_screen.dart';

(String, AppStatusTone) historyCategoryPresentation(HistoryCategory category) =>
    switch (category) {
      HistoryCategory.maintenance => ('Bảo dưỡng', AppStatusTone.info),
      HistoryCategory.repair => ('Sửa chữa', AppStatusTone.neutral),
      HistoryCategory.mixed => ('Bảo dưỡng & sửa chữa', AppStatusTone.info),
    };

/// Lịch sử sửa chữa, bảo dưỡng đã hoàn tất của khách hàng, lấy từ Spring Boot API theo từng trang.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.service});

  final HistoryService service;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static const _pageSize = 10;

  // Mỗi lần tải lại (đổi bộ lọc, làm mới) tăng số này; phản hồi của yêu cầu cũ bị bỏ qua.
  int _requestId = 0;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  String? _moreError;
  List<HistoryItem> _items = const [];
  List<HistoryVehicle> _vehicles = const [];
  int? _vehicleId;
  int _nextPage = 0;
  int _total = 0;
  bool _hasMore = false;

  @override
  void initState() {
    super.initState();
    _reload();
    _loadVehicles();
  }

  /// Danh sách xe để lọc lấy riêng từ toàn bộ lịch sử của khách hàng, không phải từ trang đầu.
  Future<void> _loadVehicles() async {
    try {
      final vehicles = await widget.service.getHistoryVehicles();
      if (mounted) setState(() => _vehicles = vehicles);
    } on HistoryException catch (_) {
      // Bộ lọc xe không bắt buộc: lịch sử vẫn hiển thị khi chưa tải được danh sách xe.
    } catch (_) {
      // Như trên.
    }
  }

  Future<void> _reload({bool showLoading = true}) async {
    final requestId = ++_requestId;
    setState(() {
      _loadingMore = false;
      _moreError = null;
      if (showLoading) {
        _loading = true;
        _error = null;
      }
    });
    try {
      final page = await widget.service.getHistory(
        vehicleId: _vehicleId,
        page: 0,
        size: _pageSize,
      );
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _items = page.items;
        _nextPage = 1;
        _total = page.totalElements;
        _hasMore = page.hasMore;
        _loading = false;
        _error = null;
      });
    } on HistoryException catch (error) {
      _fail(requestId, error.message);
    } catch (_) {
      _fail(requestId, 'Không thể tải lịch sử sửa chữa.');
    }
  }

  void _fail(int requestId, String message) {
    if (!mounted || requestId != _requestId) return;
    setState(() {
      _loading = false;
      if (_items.isEmpty) _error = message;
    });
    if (_items.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || !_hasMore) return;
    final requestId = _requestId;
    setState(() {
      _loadingMore = true;
      _moreError = null;
    });
    try {
      final page = await widget.service.getHistory(
        vehicleId: _vehicleId,
        page: _nextPage,
        size: _pageSize,
      );
      if (!mounted || requestId != _requestId) return;
      setState(() {
        // Loại trùng phòng khi dữ liệu mới phát sinh làm lệch ranh giới giữa các trang.
        final known = _items.map((item) => item.repairOrderId).toSet();
        _items = [
          ..._items,
          ...page.items.where((item) => !known.contains(item.repairOrderId)),
        ];
        _nextPage += 1;
        _total = page.totalElements;
        _hasMore = page.hasMore;
        _loadingMore = false;
      });
    } on HistoryException catch (error) {
      _failMore(requestId, error.message);
    } catch (_) {
      _failMore(requestId, 'Không thể tải thêm lịch sử.');
    }
  }

  void _failMore(int requestId, String message) {
    if (!mounted || requestId != _requestId) return;
    setState(() {
      _loadingMore = false;
      _moreError = message;
    });
  }

  void _selectVehicle(int? vehicleId) {
    if (vehicleId == _vehicleId) return;
    setState(() {
      _vehicleId = vehicleId;
      _items = const [];
      _hasMore = false;
      _total = 0;
    });
    _reload();
  }

  Future<void> _refresh() async {
    _loadVehicles();
    await _reload(showLoading: false);
  }

  void _open(HistoryItem item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HistoryDetailScreen(
          service: widget.service,
          repairOrderId: item.repairOrderId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử sửa chữa')),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            if (_vehicles.length > 1) _buildVehicleFilter(),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleFilter() {
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: const Text('Tất cả xe'),
              selected: _vehicleId == null,
              onSelected: (_) => _selectVehicle(null),
            ),
          ),
          for (final vehicle in _vehicles)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(vehicle.plate),
                selected: _vehicleId == vehicle.id,
                onSelected: (_) => _selectVehicle(vehicle.id),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) return const LoadingState(label: 'Đang tải lịch sử...');
    if (_error != null) {
      return _refreshable(ErrorState(message: _error!, onRetry: _reload));
    }
    if (_items.isEmpty) {
      return _refreshable(
        EmptyState(
          icon: Icons.history,
          title: 'Chưa có lịch sử sửa chữa',
          message: _vehicleId == null
              ? 'Các lượt sửa chữa, bảo dưỡng đã hoàn tất sẽ hiển thị tại đây.'
              : 'Xe này chưa có lượt sửa chữa, bảo dưỡng nào hoàn tất.',
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        // 0: dòng tổng số; 1..n: các lượt; cuối: nút/trạng thái tải thêm.
        itemCount: _items.length + 2,
        itemBuilder: (_, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Hiển thị ${_items.length}/$_total lượt',
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            );
          }
          if (index == _items.length + 1) return _buildFooter();
          final item = _items[index - 1];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _HistoryCard(item: item, onTap: () => _open(item)),
          );
        },
      ),
    );
  }

  Widget _buildFooter() {
    if (_loadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_moreError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Text(
              _moreError!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted),
            ),
            TextButton(onPressed: _loadMore, child: const Text('Thử lại')),
          ],
        ),
      );
    }
    if (_hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: OutlinedButton(
          onPressed: _loadMore,
          child: const Text('Tải thêm'),
        ),
      );
    }
    return const SizedBox(height: 8);
  }

  /// Cho phép kéo để làm mới ngay cả khi đang hiển thị trạng thái rỗng/lỗi.
  Widget _refreshable(Widget child) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: LayoutBuilder(
        builder: (context, constraints) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [SizedBox(height: constraints.maxHeight, child: child)],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.item, required this.onTap});

  final HistoryItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (label, tone) = historyCategoryPresentation(item.category);
    final date = item.date;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Phiếu #${item.repairOrderId}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  StatusBadge(label: label, tone: tone),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                item.vehicleName.isEmpty
                    ? item.plate
                    : '${item.plate} · ${item.vehicleName}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                item.summary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      date == null ? '—' : 'Hoàn thành: ${formatDate(date)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                  Text(
                    formatCurrency(item.totalCost),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.muted),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
'@
Replace-OwnedFile 'mobile/test/history_service_test.dart' '226cbc1b701994c60db2a16dd5b4c01002d8e065a0f91902e10d4d8dfa8cbc1b' @'
// TV3-TUAN9
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:garage_customer_mobile/models/history.dart';
import 'package:garage_customer_mobile/services/history_service.dart';

const _item = {
  'repairOrderId': 12,
  'vehicleId': 3,
  'licensePlate': '51G-123.45',
  'brand': 'Toyota',
  'model': 'Camry',
  'createdAt': '2026-09-18T08:00:00',
  'startedAt': '2026-09-19T08:00:00',
  'completedAt': '2026-09-20T10:00:00',
  'category': 'BAO_DUONG',
  'summary': 'Bảo dưỡng định kỳ',
  'serviceCount': 1,
  'partCount': 1,
  'totalCost': 1380000.0,
  'result': 'Hoàn tất tốt',
};

const _pagePayload = {
  'success': true,
  'message': 'ok',
  'data': {
    'items': [_item],
    'page': 0,
    'size': 10,
    'totalElements': 23,
    'totalPages': 3,
  },
};

final _detailPayload = {
  'success': true,
  'message': 'ok',
  'data': {
    'item': {..._item, 'category': 'BAO_DUONG_SUA_CHUA', 'result': null},
    'services': [
      {
        'serviceId': 2,
        'name': 'Bảo dưỡng định kỳ',
        'type': 'BAO_DUONG',
        'quantity': 1,
        'unitPrice': 1200000.0,
        'lineTotal': 1200000.0,
      },
    ],
    'parts': [
      {
        'partId': 9,
        'name': 'Lọc dầu',
        'quantity': 2,
        'unitPrice': 90000.0,
        'lineTotal': 180000.0,
      },
    ],
    'serviceTotal': 1200000.0,
    'partsTotal': 180000.0,
  },
};

class _Recorded {
  String? method;
  String? path;
  String? query;
  String? authorization;
}

Future<HttpServer> _serve(_Recorded recorded, int status, Object? body) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((request) async {
    recorded
      ..method = request.method
      ..path = request.uri.path
      ..query = request.uri.query
      ..authorization = request.headers.value(HttpHeaders.authorizationHeader);
    request.response.statusCode = status;
    request.response.headers.contentType = ContentType.json;
    request.response.write(body is String ? body : jsonEncode(body));
    await request.response.close();
  });
  return server;
}

ApiHistoryService _service(
  HttpServer server, {
  String? token = 'tok',
  String suffix = '',
}) => ApiHistoryService(
  tokenProvider: () => token,
  baseUrl: 'http://127.0.0.1:${server.port}/api$suffix',
);

void main() {
  test('getHistory sends the bearer token and the page parameters', () async {
    final recorded = _Recorded();
    final server = await _serve(recorded, 200, _pagePayload);
    addTearDown(() => server.close(force: true));

    final page = await _service(server).getHistory(page: 1, size: 5);

    expect(recorded.method, 'GET');
    expect(recorded.path, '/api/customers/me/history');
    expect(Uri.splitQueryString(recorded.query!), {'page': '1', 'size': '5'});
    expect(recorded.authorization, 'Bearer tok');
    expect(page.items, hasLength(1));
    expect(page.totalElements, 23);
    expect(page.totalPages, 3);
    expect(page.hasMore, isTrue);
    final item = page.items.single;
    expect(item.repairOrderId, 12);
    expect(item.plate, '51G-123.45');
    expect(item.vehicleName, 'Toyota Camry');
    expect(item.category, HistoryCategory.maintenance);
    expect(item.totalCost, 1380000);
    expect(item.date, DateTime(2026, 9, 20, 10));
  });

  test('the last page reports that there is nothing more to load', () async {
    final server = await _serve(_Recorded(), 200, {
      'data': {
        'items': <Object>[],
        'page': 2,
        'size': 10,
        'totalElements': 23,
        'totalPages': 3,
      },
    });
    addTearDown(() => server.close(force: true));

    final page = await _service(server).getHistory(page: 2);

    expect(page.hasMore, isFalse);
  });

  test('getHistory passes the vehicle filter next to the page', () async {
    final recorded = _Recorded();
    final server = await _serve(recorded, 200, _pagePayload);
    addTearDown(() => server.close(force: true));

    await _service(server).getHistory(vehicleId: 3);

    expect(Uri.splitQueryString(recorded.query!), {
      'page': '0',
      'size': '10',
      'vehicleId': '3',
    });
  });

  test('getHistoryVehicles reads the dedicated vehicle endpoint', () async {
    final recorded = _Recorded();
    final server = await _serve(recorded, 200, {
      'data': [
        {
          'vehicleId': 3,
          'licensePlate': '51G-123.45',
          'brand': 'Toyota',
          'model': 'Camry',
          'completedCount': 14,
        },
        {'vehicleId': 4, 'licensePlate': '51A-456.78', 'brand': null},
      ],
    });
    addTearDown(() => server.close(force: true));

    final vehicles = await _service(server).getHistoryVehicles();

    expect(recorded.path, '/api/customers/me/history/vehicles');
    expect(recorded.authorization, 'Bearer tok');
    expect(vehicles.map((v) => v.id), [3, 4]);
    expect(vehicles.first.completedCount, 14);
    expect(vehicles.last.brand, '');
  });

  test('getHistoryDetail parses services, parts, totals and a null result', () async {
    final recorded = _Recorded();
    final server = await _serve(recorded, 200, _detailPayload);
    addTearDown(() => server.close(force: true));

    final detail = await _service(server).getHistoryDetail(12);

    expect(recorded.path, '/api/customers/me/history/12');
    expect(detail.item.category, HistoryCategory.mixed);
    expect(detail.item.result, isEmpty);
    expect(detail.services.single.name, 'Bảo dưỡng định kỳ');
    expect(detail.parts.single.lineTotal, 180000);
    expect(detail.serviceTotal, 1200000);
    expect(detail.partsTotal, 180000);
  });

  test('decimal money from SQL Server is rounded consistently to whole dong', () {
    final item = HistoryItem.fromJson({..._item, 'totalCost': 1380000.49});
    final line = HistoryServiceLine.fromJson({
      'serviceId': 1,
      'name': 'x',
      'type': 'y',
      'quantity': 1,
      'unitPrice': 1000.5,
      'lineTotal': 1000.5,
    });

    expect(item.totalCost, 1380000);
    expect(line.lineTotal, 1001);
  });

  test('null dates and result do not break parsing', () {
    final item = HistoryItem.fromJson({
      'repairOrderId': 4,
      'vehicleId': 1,
      'licensePlate': '51G-123.45',
      'category': 'SUA_CHUA',
      'summary': '',
      'totalCost': 0,
    });

    expect(item.date, isNull);
    expect(item.result, isEmpty);
    expect(item.vehicleName, isEmpty);
    expect(item.category, HistoryCategory.repair);
  });

  test('a trailing slash in the base URL does not produce a double slash', () async {
    final recorded = _Recorded();
    final server = await _serve(recorded, 200, _pagePayload);
    addTearDown(() => server.close(force: true));

    await _service(server, suffix: '/').getHistory();

    expect(recorded.path, '/api/customers/me/history');
  });

  test('a missing token fails before any request is made', () async {
    final recorded = _Recorded();
    final server = await _serve(recorded, 200, _pagePayload);
    addTearDown(() => server.close(force: true));

    await expectLater(
      _service(server, token: null).getHistory(),
      throwsA(isA<HistoryException>()),
    );
    expect(recorded.method, isNull);
  });

  test('401, 403 and 404 map to clear messages', () async {
    final cases = <int, String>{
      401: 'Phiên đăng nhập đã hết hạn',
      403: 'không có quyền',
      404: 'Không tìm thấy xe.',
    };
    for (final entry in cases.entries) {
      final server = await _serve(_Recorded(), entry.key, {
        'success': false,
        'message': 'Không tìm thấy xe.',
      });
      addTearDown(() => server.close(force: true));

      await expectLater(
        _service(server).getHistory(),
        throwsA(
          isA<HistoryException>().having(
            (error) => error.message,
            'message',
            contains(entry.value),
          ),
        ),
      );
      await expectLater(
        _service(server).getHistoryDetail(1),
        throwsA(isA<HistoryException>()),
      );
    }
  });

  test('an invalid payload is reported instead of crashing', () async {
    final html = await _serve(_Recorded(), 200, '<html>oops</html>');
    addTearDown(() => html.close(force: true));
    await expectLater(
      _service(html).getHistory(),
      throwsA(isA<HistoryException>()),
    );

    final wrongShape = await _serve(_Recorded(), 200, {'data': 'not a page'});
    addTearDown(() => wrongShape.close(force: true));
    await expectLater(
      _service(wrongShape).getHistory(),
      throwsA(isA<HistoryException>()),
    );
    await expectLater(
      _service(wrongShape).getHistoryVehicles(),
      throwsA(isA<HistoryException>()),
    );
  });

  test('a refused connection becomes a friendly error', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final service = _service(server);
    await server.close(force: true);

    await expectLater(service.getHistory(), throwsA(isA<HistoryException>()));
  });
}
'@
Replace-OwnedFile 'mobile/test/history_screen_test.dart' 'ba431a4aaa3001b578ad140d6af481179510f2d1bdfd071fa36bc24d5ed663a1' @'
// TV3-TUAN9
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garage_customer_mobile/app/app_theme.dart';
import 'package:garage_customer_mobile/models/history.dart';
import 'package:garage_customer_mobile/screens/history/history_screen.dart';
import 'package:garage_customer_mobile/services/history_service.dart';

HistoryItem _item(
  int id, {
  int vehicleId = 1,
  String plate = '51G-123.45',
  HistoryCategory category = HistoryCategory.maintenance,
  String summary = 'Bảo dưỡng định kỳ',
  int total = 1380000,
}) => HistoryItem(
  repairOrderId: id,
  vehicleId: vehicleId,
  plate: plate,
  brand: 'Toyota',
  model: 'Camry',
  category: category,
  summary: summary,
  serviceCount: 1,
  partCount: 0,
  totalCost: total,
  result: 'Hoàn tất tốt',
  completedAt: DateTime(2026, 9, 20),
);

HistoryPage _page(List<HistoryItem> items, {int page = 0, int? total, int size = 10}) {
  final count = total ?? items.length;
  return HistoryPage(
    items: items,
    page: page,
    size: size,
    totalElements: count,
    totalPages: (count + size - 1) ~/ size,
  );
}

List<HistoryVehicle> _vehiclesOf(List<HistoryItem> items) {
  final seen = <int>{};
  return [
    for (final item in items)
      if (seen.add(item.vehicleId))
        HistoryVehicle(
          id: item.vehicleId,
          plate: item.plate,
          brand: item.brand,
          model: item.model,
          completedCount: 1,
        ),
  ];
}

HistoryDetail _detailOf(HistoryItem item) => HistoryDetail(
  item: item,
  services: const [
    HistoryServiceLine(
      serviceId: 2,
      name: 'Thay dầu động cơ',
      type: 'BAO_DUONG',
      quantity: 1,
      unitPrice: 450000,
      lineTotal: 450000,
    ),
  ],
  parts: const [
    HistoryPartLine(
      partId: 9,
      name: 'Lọc dầu',
      quantity: 2,
      unitPrice: 90000,
      lineTotal: 180000,
    ),
  ],
  serviceTotal: 450000,
  partsTotal: 180000,
);

/// Test double của giao diện HistoryService: phân trang/lọc trên dữ liệu cấu hình sẵn và ghi lại các lần gọi.
class _FakeHistoryService implements HistoryService {
  _FakeHistoryService({this.items = const [], this.failFirst = false});

  List<HistoryItem> items;
  bool failFirst;
  final List<({int? vehicleId, int page})> calls = [];
  int detailCalls = 0;

  @override
  Future<HistoryPage> getHistory({
    int? vehicleId,
    int page = 0,
    int size = 10,
  }) async {
    calls.add((vehicleId: vehicleId, page: page));
    if (failFirst) {
      failFirst = false;
      throw const HistoryException('Không thể kết nối đến hệ thống.');
    }
    final filtered = vehicleId == null
        ? items
        : items.where((item) => item.vehicleId == vehicleId).toList();
    final start = page * size;
    final slice = start >= filtered.length
        ? <HistoryItem>[]
        : filtered.sublist(start, min(start + size, filtered.length));
    return _page(slice, page: page, total: filtered.length, size: size);
  }

  @override
  Future<List<HistoryVehicle>> getHistoryVehicles() async => _vehiclesOf(items);

  @override
  Future<HistoryDetail> getHistoryDetail(int repairOrderId) async {
    detailCalls++;
    return _detailOf(
      items.firstWhere((item) => item.repairOrderId == repairOrderId),
    );
  }
}

/// Mỗi lần gọi getHistory trả về một Completer để test chủ động quyết định thời điểm phản hồi.
class _ControlledService implements HistoryService {
  final List<int?> requested = [];
  final List<Completer<HistoryPage>> pending = [];

  @override
  Future<HistoryPage> getHistory({
    int? vehicleId,
    int page = 0,
    int size = 10,
  }) {
    requested.add(vehicleId);
    final completer = Completer<HistoryPage>();
    pending.add(completer);
    return completer.future;
  }

  @override
  Future<List<HistoryVehicle>> getHistoryVehicles() async => const [
    HistoryVehicle(id: 1, plate: '51G-123.45', brand: 'Toyota', model: 'Camry', completedCount: 1),
    HistoryVehicle(id: 2, plate: '51A-456.78', brand: 'Kia', model: 'Seltos', completedCount: 1),
  ];

  @override
  Future<HistoryDetail> getHistoryDetail(int repairOrderId) =>
      throw UnimplementedError();
}

// Danh sách chính (cuộn dọc); hàng chip lọc xe cuộn ngang nên không được dùng làm đích cuộn.
final _mainList = find.byWidgetPredicate(
  (widget) => widget is Scrollable && widget.axisDirection == AxisDirection.down,
);

Future<void> _pump(WidgetTester tester, HistoryService service) async {
  await tester.pumpWidget(
    MaterialApp(theme: AppTheme.light, home: HistoryScreen(service: service)),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows completed repairs from the service, newest first', (
    tester,
  ) async {
    final service = _FakeHistoryService(
      items: [
        _item(12, summary: 'Bảo dưỡng định kỳ'),
        _item(
          5,
          summary: 'Thay má phanh trước',
          category: HistoryCategory.repair,
          total: 500000,
        ),
      ],
    );

    await _pump(tester, service);

    expect(find.text('Phiếu #12'), findsOneWidget);
    expect(find.text('Phiếu #5'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Phiếu #12')).dy,
      lessThan(tester.getTopLeft(find.text('Phiếu #5')).dy),
    );
    expect(find.text('Bảo dưỡng'), findsOneWidget);
    expect(find.text('Sửa chữa'), findsOneWidget);
    expect(find.text('1.380.000 ₫'), findsOneWidget);
    expect(find.text('Hoàn thành: 20/09/2026'), findsNWidgets(2));
    expect(find.text('Hiển thị 2/2 lượt'), findsOneWidget);
    expect(find.text('Tải thêm'), findsNothing);
  });

  testWidgets('shows the empty state when there is no history', (tester) async {
    await _pump(tester, _FakeHistoryService());

    expect(find.text('Chưa có lịch sử sửa chữa'), findsOneWidget);
  });

  testWidgets('shows an error and retries', (tester) async {
    final service = _FakeHistoryService(items: [_item(12)], failFirst: true);

    await _pump(tester, service);
    expect(find.text('Không thể kết nối đến hệ thống.'), findsOneWidget);

    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();

    expect(find.text('Phiếu #12'), findsOneWidget);
    expect(service.calls.map((call) => call.page), [0, 0]);
  });

  testWidgets('lets the customer filter by vehicle', (tester) async {
    final service = _FakeHistoryService(
      items: [
        _item(12, vehicleId: 1, plate: '51G-123.45'),
        _item(5, vehicleId: 2, plate: '51A-456.78', summary: 'Kiểm tra phanh'),
      ],
    );

    await _pump(tester, service);
    expect(find.text('Phiếu #12'), findsOneWidget);
    expect(find.text('Phiếu #5'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, '51A-456.78'));
    await tester.pumpAndSettle();

    expect(service.calls.last.vehicleId, 2);
    expect(service.calls.last.page, 0);
    expect(find.text('Phiếu #5'), findsOneWidget);
    expect(find.text('Phiếu #12'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Tất cả xe'));
    await tester.pumpAndSettle();

    expect(service.calls.last.vehicleId, isNull);
    expect(find.text('Phiếu #12'), findsOneWidget);
  });

  testWidgets('loads the next page on demand and keeps the order', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    final service = _FakeHistoryService(
      items: [for (var id = 100; id > 88; id--) _item(id)],
    );

    await _pump(tester, service);
    expect(find.text('Hiển thị 10/12 lượt'), findsOneWidget);
    expect(service.calls.map((call) => call.page), [0]);

    await tester.scrollUntilVisible(
      find.text('Tải thêm'),
      300,
      scrollable: _mainList.first,
    );
    await tester.tap(find.text('Tải thêm'));
    await tester.pumpAndSettle();

    expect(service.calls.map((call) => call.page), [0, 1]);
    await tester.scrollUntilVisible(
      find.text('Phiếu #89'),
      300,
      scrollable: _mainList.first,
    );
    expect(find.text('Phiếu #89'), findsOneWidget);
    expect(find.text('Tải thêm'), findsNothing);
  });

  testWidgets('changing the vehicle filter resets to the first page', (tester) async {
    final service = _FakeHistoryService(
      items: [
        for (var id = 100; id > 88; id--) _item(id, vehicleId: 1, plate: '51G-123.45'),
        _item(5, vehicleId: 2, plate: '51A-456.78'),
      ],
    );

    await _pump(tester, service);
    await tester.scrollUntilVisible(
      find.text('Tải thêm'),
      300,
      scrollable: _mainList.first,
    );
    await tester.tap(find.text('Tải thêm'));
    await tester.pumpAndSettle();
    expect(service.calls.map((call) => call.page), [0, 1]);

    await tester.tap(find.widgetWithText(ChoiceChip, '51A-456.78'));
    await tester.pumpAndSettle();

    expect(service.calls.last.vehicleId, 2);
    expect(service.calls.last.page, 0);
    expect(find.text('Phiếu #5'), findsOneWidget);
    expect(find.text('Phiếu #100'), findsNothing);
  });

  testWidgets('pull to refresh reloads from the first page', (tester) async {
      final service = _FakeHistoryService(items: [_item(12)]);
      await _pump(tester, service);
      expect(service.calls, hasLength(1));

      final refresh = tester.widget<RefreshIndicator>(find.byType(RefreshIndicator));
      await refresh.onRefresh();
      await tester.pumpAndSettle();

      expect(service.calls.length, greaterThanOrEqualTo(2));
      expect(service.calls.last.page, 0);
    });

  testWidgets('a late response for an old filter never overwrites the new list', (
    tester,
  ) async {
    final service = _ControlledService();
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: HistoryScreen(service: service)),
    );
    await tester.pump();
    service.pending[0].complete(
      _page([_item(12, vehicleId: 1), _item(5, vehicleId: 2, plate: '51A-456.78')]),
    );
    await tester.pump();

    // Người dùng đổi bộ lọc liên tục: xe 1 rồi xe 2.
    await tester.tap(find.widgetWithText(ChoiceChip, '51G-123.45'));
    await tester.pump();
    await tester.tap(find.widgetWithText(ChoiceChip, '51A-456.78'));
    await tester.pump();
    expect(service.requested, [null, 1, 2]);

    // Phản hồi của xe 2 (mới nhất) về trước, phản hồi trễ của xe 1 về sau.
    service.pending[2].complete(_page([_item(5, vehicleId: 2, plate: '51A-456.78')]));
    await tester.pump();
    service.pending[1].complete(_page([_item(12, vehicleId: 1)]));
    await tester.pump();

    expect(find.text('Phiếu #5'), findsOneWidget);
    expect(find.text('Phiếu #12'), findsNothing);
  });

  testWidgets('opening a repair shows services, parts and totals from the API', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    final service = _FakeHistoryService(items: [_item(12)]);
    await _pump(tester, service);

    await tester.tap(find.text('Phiếu #12'));
    await tester.pumpAndSettle();

    expect(service.detailCalls, 1);
    expect(find.text('Thay dầu động cơ'), findsOneWidget);
    expect(find.text('Lọc dầu'), findsOneWidget);
    expect(find.text('2 × 90.000 ₫'), findsOneWidget);
    expect(find.text('180.000 ₫'), findsWidgets);
    expect(find.text('Tổng chi phí'), findsOneWidget);
    expect(find.text('Hoàn tất tốt'), findsOneWidget);
  });
}
'@

Write-Step 'Va code Tuan 7 (khong cho sua/xoa tay dong phu tung da xac nhan thuc dung)'
Update-RepoFile 'backend/src/main/java/com/gara/quanlygara/service/RepairDetailService.java' 'import com.gara.quanlygara.repository.SparePartRepository;' 'import com.gara.quanlygara.repository.SparePartRepository;
import com.gara.quanlygara.repository.StockIssueItemRepository;' 'repository.StockIssueItemRepository;'
Update-RepoFile 'backend/src/main/java/com/gara/quanlygara/service/RepairDetailService.java' '    private final SparePartRepository sparePartRepository;

    public RepairDetailService(
            RepairServiceItemRepository serviceItemRepository,
            RepairPartItemRepository partItemRepository,
            SparePartRepository sparePartRepository
    ) {
        this.serviceItemRepository = serviceItemRepository;
        this.partItemRepository = partItemRepository;
        this.sparePartRepository = sparePartRepository;
    }
' '    private final SparePartRepository sparePartRepository;
    private final StockIssueItemRepository stockIssueItemRepository;

    public RepairDetailService(
            RepairServiceItemRepository serviceItemRepository,
            RepairPartItemRepository partItemRepository,
            SparePartRepository sparePartRepository,
            StockIssueItemRepository stockIssueItemRepository
    ) {
        this.serviceItemRepository = serviceItemRepository;
        this.partItemRepository = partItemRepository;
        this.sparePartRepository = sparePartRepository;
        this.stockIssueItemRepository = stockIssueItemRepository;
    }
' 'StockIssueItemRepository stockIssueItemRepository;'
Update-RepoFile 'backend/src/main/java/com/gara/quanlygara/service/RepairDetailService.java' '            case SPARE_PART -> {
                RepairPartItem item = partItemRepository
                        .findById(new RepairPartItem.Key(repairOrderId, itemId))
                        .orElseThrow(this::itemNotFound);
                item.setQuantity(request.quantity());
' '            case SPARE_PART -> {
                requireNoConfirmedUsage(repairOrderId, itemId);
                RepairPartItem item = partItemRepository
                        .findById(new RepairPartItem.Key(repairOrderId, itemId))
                        .orElseThrow(this::itemNotFound);
                item.setQuantity(request.quantity());
' 'requireNoConfirmedUsage(repairOrderId, itemId);
                RepairPartItem item = partItemRepository
                        .findById(new RepairPartItem.Key(repairOrderId, itemId))
                        .orElseThrow(this::itemNotFound);
                item.setQuantity'
Update-RepoFile 'backend/src/main/java/com/gara/quanlygara/service/RepairDetailService.java' '            case SPARE_PART -> {
                RepairPartItem item = partItemRepository
                        .findById(new RepairPartItem.Key(repairOrderId, itemId))
                        .orElseThrow(this::itemNotFound);
                partItemRepository.delete(item);
' '            case SPARE_PART -> {
                requireNoConfirmedUsage(repairOrderId, itemId);
                RepairPartItem item = partItemRepository
                        .findById(new RepairPartItem.Key(repairOrderId, itemId))
                        .orElseThrow(this::itemNotFound);
                partItemRepository.delete(item);
' 'requireNoConfirmedUsage(repairOrderId, itemId);
                RepairPartItem item = partItemRepository
                        .findById(new RepairPartItem.Key(repairOrderId, itemId))
                        .orElseThrow(this::itemNotFound);
                partItemRepository.delete'
Update-RepoFile 'backend/src/main/java/com/gara/quanlygara/service/RepairDetailService.java' '    private String requireOrderStatus(Integer repairOrderId) {' '    // Tuần 8: ChiTietPhuTung.SoLuong = tổng số lượng THỰC DÙNG đã được KTV xác nhận. Không cho sửa/xóa tay dòng đó,
    // nếu không số lượng dự kiến sẽ ghi đè số thực dùng (và làm lệch chi phí so với tồn kho đã trừ).
    private void requireNoConfirmedUsage(Integer repairOrderId, Integer sparePartId) {
        if (stockIssueItemRepository.sumConfirmedActual(repairOrderId, sparePartId) > 0) {
            throw new ConflictException("Phụ tùng đã được kỹ thuật viên xác nhận thực dùng, không thể sửa hoặc xóa hạng mục này.");
        }
    }

    private String requireOrderStatus(Integer repairOrderId) {' 'private void requireNoConfirmedUsage'
Update-RepoFile 'backend/src/test/java/com/gara/quanlygara/service/RepairDetailServiceTest.java' 'import com.gara.quanlygara.repository.SparePartRepository;' 'import com.gara.quanlygara.repository.SparePartRepository;
import com.gara.quanlygara.repository.StockIssueItemRepository;' 'repository.StockIssueItemRepository;'
Update-RepoFile 'backend/src/test/java/com/gara/quanlygara/service/RepairDetailServiceTest.java' '    @Mock
    private SparePartRepository sparePartRepository;
' '    @Mock
    private SparePartRepository sparePartRepository;

    @Mock
    private StockIssueItemRepository stockIssueItemRepository;
' 'StockIssueItemRepository stockIssueItemRepository;'
Update-RepoFile 'backend/src/test/java/com/gara/quanlygara/service/RepairDetailServiceTest.java' 'service = new RepairDetailService(serviceItemRepository, partItemRepository, sparePartRepository);' 'service = new RepairDetailService(serviceItemRepository, partItemRepository, sparePartRepository, stockIssueItemRepository);' 'sparePartRepository, stockIssueItemRepository);'
Update-RepoFile 'backend/src/test/java/com/gara/quanlygara/service/RepairDetailServiceTest.java' '    private void openOrder(int id, String status) {' '    @Test
    void partLineWithConfirmedUsageCannotBeEditedByHand() {
        openOrder(1, "DANG_SUA");
        when(stockIssueItemRepository.sumConfirmedActual(1, 5)).thenReturn(3L);

        assertThrows(ConflictException.class,
                () -> service.update(1, RepairDetailType.SPARE_PART, 5, new RepairDetailUpdateRequest(9, null)));
        verify(partItemRepository, never()).findById(any());
        verify(partItemRepository, never()).saveAndFlush(any(RepairPartItem.class));
    }

    @Test
    void partLineWithConfirmedUsageCannotBeDeleted() {
        openOrder(1, "DANG_SUA");
        when(stockIssueItemRepository.sumConfirmedActual(1, 5)).thenReturn(3L);

        assertThrows(ConflictException.class, () -> service.delete(1, RepairDetailType.SPARE_PART, 5));
        verify(partItemRepository, never()).delete(any(RepairPartItem.class));
    }

    @Test
    void partLineWithoutConfirmedUsageIsStillEditableAndDeletable() {
        openOrder(1, "DANG_SUA");
        RepairPartItem item = partItem(1, 5, 2, "180000.00");
        when(partItemRepository.findById(new RepairPartItem.Key(1, 5))).thenReturn(Optional.of(item));
        when(serviceItemRepository.findDetailRows(1)).thenReturn(List.of());
        when(partItemRepository.findDetailRows(1)).thenReturn(List.of(row(5, "Bugi", 6, "180000.00", null)));

        service.update(1, RepairDetailType.SPARE_PART, 5, new RepairDetailUpdateRequest(6, null));
        service.delete(1, RepairDetailType.SPARE_PART, 5);

        assertEquals(6, item.getQuantity());
        verify(partItemRepository).delete(item);
    }

    @Test
    void serviceLinesAreNotAffectedByTheConfirmedUsageGuard() {
        openOrder(1, "DANG_SUA");
        RepairServiceItem item = new RepairServiceItem();
        item.setRepairOrderId(1);
        item.setServiceId(3);
        item.setQuantity(1);
        item.setUnitPrice(new java.math.BigDecimal("300000.00"));
        when(serviceItemRepository.findById(new RepairServiceItem.Key(1, 3))).thenReturn(Optional.of(item));
        when(serviceItemRepository.findDetailRows(1)).thenReturn(List.of(row(3, "Kiểm tra phanh", 2, "300000.00", null)));
        when(partItemRepository.findDetailRows(1)).thenReturn(List.of());

        service.update(1, RepairDetailType.SERVICE, 3, new RepairDetailUpdateRequest(2, null));

        assertEquals(2, item.getQuantity());
        verify(stockIssueItemRepository, never()).sumConfirmedActual(any(), any());
    }

    private void openOrder(int id, String status) {' 'partLineWithConfirmedUsageCannotBeEditedByHand'

Write-Step 'Cap nhat tai lieu (README.md, backend/README.md, mobile/README.md)'
Set-DocBlock 'README.md' 'integration-status' @'
Backend đã kết nối SQL Server cho: đăng nhập, đăng ký, đổi mật khẩu, tài khoản, khách hàng, xe, phụ tùng, chi tiết phiếu sửa chữa, kho phụ tùng (tồn kho, nhập/xuất, kiểm kê, biến động) và lịch sử sửa chữa, bảo dưỡng của khách hàng. Website quản trị dùng các API này cho xe, phụ tùng, chi tiết phiếu sửa chữa và kho. Trên mobile, đăng nhập và lịch sử sửa chữa/bảo dưỡng gọi API thật; các màn hình mobile khác vẫn dùng dữ liệu mẫu hoặc dữ liệu lưu trên máy cho đến khi có API tương ứng.
'@ '(?m)^Các phần đăng nhập, đăng ký, đổi mật khẩu, tài khoản và khách hàng đã kết nối backend và SQL Server\..*$' 'replace'
Set-DocBlock 'backend/README.md' 'unlisted-api' @'
Các nghiệp vụ chưa được liệt kê trong mục này chưa có tài liệu API đầy đủ.
'@ '(?m)^Các nghiệp vụ .*chưa có API đầy đủ\.$' 'replace'
Set-DocBlock 'backend/README.md' 'history-api' @'
## API lịch sử sửa chữa của khách hàng (Tuần 9)

Chỉ tài khoản `CUSTOMER`. Backend xác định khách hàng từ tài khoản trong JWT; **không có tham số `customerId`** nên khách hàng không thể xem dữ liệu của người khác.

- `GET /api/customers/me/history`: lịch sử sửa chữa/bảo dưỡng đã hoàn tất (`HOAN_TAT`), mới nhất trước. Tham số: `page` (từ 0, mặc định 0), `size` (mặc định 10, tối đa 50), `vehicleId` (lọc theo xe). Trả `items`, `page`, `size`, `totalElements`, `totalPages` — `totalElements` luôn là tổng đầy đủ, không bị cắt.
- `GET /api/customers/me/history/vehicles`: danh sách xe của khách hàng có lịch sử hoàn tất, dùng làm bộ lọc (không phụ thuộc trang).
- `GET /api/customers/me/history/{repairOrderId}`: chi tiết một lượt (dịch vụ, phụ tùng thực dùng, chi phí).

Xe không thuộc khách hàng, phiếu chưa hoàn tất hoặc phiếu của khách hàng khác đều trả 404 giống nhau. Dữ liệu được tổng hợp từ `PhieuSuaChua`, `PhieuTiepNhan`, `Xe`, `ChiTietDichVu`, `ChiTietPhuTung`, `DichVu`, `PhuTung` và `dbo.fn_TinhTongChiPhiSuaChua`, không có bảng lịch sử riêng.

Integration test trên SQL Server thật (không chạy trong `mvnw test`): đặt `RUN_SQLSERVER_IT=true` cùng `DB_URL`/`DB_USERNAME`/`DB_PASSWORD`, rồi chạy `.\mvnw.cmd -Dtest=RepairHistorySqlServerIT test`. Dữ liệu test được rollback.
'@ '' 'end'
Set-DocBlock 'mobile/README.md' 'backend-status' @'
Trạng thái kết nối backend:

- **Đăng nhập** gọi API backend (`/api/auth`).
- **Lịch sử sửa chữa, bảo dưỡng** gọi API backend thật (`GET /api/customers/me/history`): phân trang ("Tải thêm"), lọc theo xe, màn chi tiết gọi `GET /api/customers/me/history/{repairOrderId}`. Địa chỉ backend lấy từ `API_BASE_URL` (mặc định `http://10.0.2.2:8080/api` cho Android Emulator; điện thoại thật dùng `--dart-define=API_BASE_URL=http://<IP máy tính>:8080/api`).
- **Các màn hình còn lại** hiện vẫn dùng dữ liệu mẫu hoặc dữ liệu lưu trong ứng dụng, chưa đồng bộ với database, trừ khi được ghi rõ ở trên là đã tích hợp.
'@ '(?m)^Đăng nhập đã gọi backend\..*$' 'replace'

Write-Step 'Dong bo @MockitoBean cho cac test Spring da co'
Sync-MockBeans

$script:Results["Ap dung file"] = "PASS"
$script:FlutterRan = $false
Write-MobileReport

# ============================================================
# 7. TEST + BUILD (backend, SQL Server IT tuy chon, frontend, mobile)
# ============================================================
if ($SkipBuild) {
    foreach ($name in @("Backend test", "Backend package", "SQL Server IT", "Frontend build", "Flutter analyze/test")) { $script:Results[$name] = "SKIPPED (-SkipBuild)" }
} else {
    Invoke-Native "Backend test" (Join-Path $root "backend") "backend-test.log" { .\mvnw.cmd test }
    Invoke-Native "Backend package" (Join-Path $root "backend") "backend-package.log" { .\mvnw.cmd clean package }

    if ($RunSqlServerIT) {
        $env:RUN_SQLSERVER_IT = "true"
        try {
            Invoke-Native "SQL Server IT (RepairHistorySqlServerIT)" (Join-Path $root "backend") "backend-sqlserver-it.log" { .\mvnw.cmd -Dtest=RepairHistorySqlServerIT test }
        } finally {
            Remove-Item Env:RUN_SQLSERVER_IT -ErrorAction SilentlyContinue
        }
    } else {
        $script:Results["SQL Server IT"] = "NOT RUN (dung -RunSqlServerIT va cau hinh DB that; mock test KHONG chung minh native SQL)"
        Write-Warn2 "Integration test SQL Server that chua chay: native SQL cua lich su chua duoc xac minh tren SQL Server."
    }

    $frontend = Join-Path $root "frontend"
    if ((Test-Path -LiteralPath (Join-Path $frontend "package.json")) -and (Get-Command npm -ErrorAction SilentlyContinue)) {
        Invoke-Native "Frontend npm install" $frontend "frontend-install.log" { npm install }
        Invoke-Native "Frontend build" $frontend "frontend-build.log" { npm run build }
        Invoke-Native "Frontend tsc --noEmit" $frontend "frontend-tsc.log" { npx tsc --noEmit }
    } else {
        $script:Results["Frontend build"] = "SKIPPED (khong co npm trong PATH)"
        Write-Warn2 "Khong co npm: chua chay frontend build/tsc."
    }

    $mobile = Join-Path $root "mobile"
    if (Get-Command flutter -ErrorAction SilentlyContinue) {
        Invoke-Native "Flutter pub get" $mobile "flutter-pub-get.log" { flutter pub get }
        Invoke-Native "Flutter analyze" $mobile "flutter-analyze.log" { flutter analyze }
        Invoke-Native "Flutter test" $mobile "flutter-test.log" { flutter test }
        $script:FlutterRan = $true
        if ($BuildApk) {
            Invoke-Native "Flutter build apk (debug)" $mobile "flutter-build-apk.log" { flutter build apk --debug }
        } else {
            $script:Results["Flutter build apk"] = "SKIPPED (dung -BuildApk de build)"
        }
    } else {
        $script:Results["Flutter analyze/test"] = "SKIPPED (khong tim thay lenh flutter trong PATH)"
        Write-Warn2 "Khong co Flutter SDK trong PATH: chua chay flutter analyze/test."
    }
}

# ============================================================
# 8. ZIP (chi khi build/test da chay thanh cong)
# ============================================================
if (-not $SkipBuild -and -not $NoZip -and ($script:FlutterRan -or $ForceZip)) {
    Write-Step "Tao TV3_Tuan9_Mobile_History_FINAL.zip"
    $zip = Join-Path $root "TV3_Tuan9_Mobile_History_FINAL.zip"
    $stage = Join-Path ([System.IO.Path]::GetTempPath()) "tv3-vehicle-$stamp"
    New-Item -ItemType Directory -Force -Path $stage | Out-Null
    robocopy $root $stage /E /NFL /NDL /NJH /NJS /NP `
        /XD target node_modules .idea .vscode .backup .git dist .dart_tool build .gradle `
        /XF *.log *.zip .env .env.local TV3_Tuan9_FINAL_AUDIT_APPLY.ps1 TV3_Tuan9_Mobile_History_APPLY.ps1 | Out-Null
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
Write-Host "  git add backend mobile"
Write-Host "  git commit -m `"feat(mobile): add repair and maintenance history`""
Write-Host "  git push -u origin feature/cam-mobile-history"
