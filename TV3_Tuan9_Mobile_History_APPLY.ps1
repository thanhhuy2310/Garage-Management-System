<#
  TV3_Tuan9_Mobile_History_APPLY.ps1 - Tuan 9 - TV3 Hoang Van Cam
  Mobile: tra cuu lich su sua chua, bao duong cua khach hang.
   Backend: GET /api/customers/me/history[?vehicleId=] va /{repairOrderId} (chi doc, customer lay tu JWT)
   Mobile (Flutter): HistoryService + HistoryScreen + HistoryDetailScreen noi vao route /history
  Chay tu repository root:   .\TV3_Tuan9_Mobile_History_APPLY.ps1
  Tuy chon: -SkipBuild, -NoZip, -BuildApk (flutter build apk --debug), -ForceZip (tao zip ke ca khi chua chay duoc Flutter)
  Khong doi schema SQL. Khong checkout/commit/push Git. Khong ghi de file cua nguoi khac.
#>
param(
    [switch]$SkipBuild,
    [switch]$NoZip,
    [switch]$BuildApk,
    [switch]$ForceZip
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
    "backend/src/main/java/com/gara/quanlygara/dto/ApiResponse.java",
    "backend/src/main/java/com/gara/quanlygara/exception/GlobalExceptionHandler.java",
    "backend/src/main/java/com/gara/quanlygara/config/SecurityConfig.java",
    "backend/src/main/java/com/gara/quanlygara/entity/Account.java",
    "backend/src/main/java/com/gara/quanlygara/entity/Vehicle.java",
    "backend/src/main/java/com/gara/quanlygara/security/StaffContext.java",
    "backend/src/test/java/com/gara/quanlygara/config/SecurityConfigTest.java",
    "mobile/pubspec.yaml",
    "mobile/lib/app/app.dart",
    "mobile/lib/app/app_controller.dart",
    "mobile/lib/app/app_routes.dart",
    "mobile/lib/app/app_theme.dart",
    "mobile/lib/core/constants/app_config.dart",
    "mobile/lib/core/utils/formatters.dart",
    "mobile/lib/core/widgets/feedback_states.dart",
    "mobile/lib/core/widgets/status_badge.dart",
    "mobile/lib/models/user_session.dart"
)
$missing = @($required | Where-Object { -not (Test-Path -LiteralPath (Join-Path $root $_)) })
if ($missing.Count -gt 0) {
    Stop-Fail ("Khong dung repository root ($root). Thieu:`n  - " + ($missing -join "`n  - "))
}
Set-Location -LiteralPath $root
Write-Ok "Repository root: $root"

$sql = Get-Content -LiteralPath (Join-Path $root "backend/database/QuanLyGaraOTo.sql") -Raw
foreach ($table in @("PhieuSuaChua", "PhieuTiepNhan", "Xe", "ChiTietDichVu", "ChiTietPhuTung", "DichVu", "PhuTung")) {
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
# 4. PREFLIGHT: khong tao API/man hinh lich su song song voi code da co
# ------------------------------------------------------------
Write-Step "Preflight (tim code lich su da co)"
$javaRoot = Join-Path $root "backend/src/main/java"
$foreign = @()
foreach ($file in Get-ChildItem -LiteralPath $javaRoot -Recurse -Filter "*.java") {
    $norm = $file.FullName.Replace('\', '/')
    if ($norm.EndsWith("/quanlygara/controller/CustomerHistoryController.java")) { continue }
    $raw = [System.IO.File]::ReadAllText($file.FullName, $utf8NoBom)
    if ($raw -match 'me/history') { $foreign += "$norm  (da co endpoint me/history)" }
}
if ($foreign.Count -gt 0) {
    Stop-Fail ("Da co API lich su trong workspace - KHONG tao ban song song. Hay gui cac file sau cho Claude de tai su dung:`n  - " + ($foreign -join "`n  - "))
}
Write-Ok "Khong co API lich su khach hang trung (/api/customers/me/history)"


Write-Step 'Tao file Tuan 9 (API lich su + man hinh Flutter)'
Write-RepoFile 'backend/src/main/java/com/gara/quanlygara/dto/history/HistoryItemResponse.java' @'
// TV3-TUAN9
package com.gara.quanlygara.dto.history;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Một lượt sửa chữa/bảo dưỡng đã hoàn tất của khách hàng, tổng hợp từ PhieuSuaChua + PhieuTiepNhan + Xe
 * + ChiTietDichVu + ChiTietPhuTung (không có bảng lịch sử riêng).
 * category: BAO_DUONG | SUA_CHUA | BAO_DUONG_SUA_CHUA (suy ra từ DichVu.LoaiDichVu).
 */
public record HistoryItemResponse(
        Integer repairOrderId,
        Integer vehicleId,
        String licensePlate,
        String brand,
        String model,
        LocalDateTime createdAt,
        LocalDateTime startedAt,
        LocalDateTime completedAt,
        String category,
        String summary,
        int serviceCount,
        int partCount,
        BigDecimal totalCost,
        String result
) {
}
'@
Write-RepoFile 'backend/src/main/java/com/gara/quanlygara/dto/history/HistoryDetailResponse.java' @'
// TV3-TUAN9
package com.gara.quanlygara.dto.history;

import java.math.BigDecimal;
import java.util.List;

public record HistoryDetailResponse(
        HistoryItemResponse item,
        List<ServiceLine> services,
        List<PartLine> parts,
        BigDecimal serviceTotal,
        BigDecimal partsTotal
) {
    public record ServiceLine(
            Integer serviceId, String name, String type, Integer quantity, BigDecimal unitPrice, BigDecimal lineTotal) {
    }

    public record PartLine(
            Integer partId, String name, Integer quantity, BigDecimal unitPrice, BigDecimal lineTotal) {
    }
}
'@
Write-RepoFile 'backend/src/main/java/com/gara/quanlygara/repository/RepairHistoryRepository.java' @'
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
     * 8 KetQua, 9 tổng chi phí (dbo.fn_TinhTongChiPhiSuaChua). Mới nhất trước, tối đa 200 lượt.
     * vehicleId = 0 và repairOrderId = 0 nghĩa là không lọc. Chỉ lấy xe của đúng khách hàng và phiếu HOAN_TAT.
     */
    @Query(value = """
            SELECT TOP (200)
                   ps.MaPhieuSuaChua, xe.MaXe, xe.BienSo, xe.HangXe, xe.DongXe,
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
            """, nativeQuery = true)
    List<Object[]> findHistoryRows(
            @Param("customerId") Integer customerId,
            @Param("vehicleId") Integer vehicleId,
            @Param("repairOrderId") Integer repairOrderId);

    /** Cột: 0 MaPhieuSuaChua, 1 MaDichVu, 2 TenDichVu, 3 LoaiDichVu, 4 SoLuong, 5 DonGia. */
    @Query(value = """
            SELECT cd.MaPhieuSuaChua, cd.MaDichVu, dv.TenDichVu, dv.LoaiDichVu, cd.SoLuong, cd.DonGia
            FROM ChiTietDichVu cd
            JOIN DichVu dv ON dv.MaDichVu = cd.MaDichVu
            WHERE cd.MaPhieuSuaChua IN (:orderIds)
            ORDER BY cd.MaPhieuSuaChua, cd.MaDichVu
            """, nativeQuery = true)
    List<Object[]> findServiceLines(@Param("orderIds") Collection<Integer> orderIds);

    /** Cột: 0 MaPhieuSuaChua, 1 MaPhuTung, 2 TenPhuTung, 3 SoLuong, 4 DonGia. */
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
Write-RepoFile 'backend/src/main/java/com/gara/quanlygara/service/RepairHistoryService.java' @'
// TV3-TUAN9
package com.gara.quanlygara.service;

import com.gara.quanlygara.dto.history.HistoryDetailResponse;
import com.gara.quanlygara.dto.history.HistoryItemResponse;
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

    private static final int SUMMARY_SERVICES = 3;

    private final RepairHistoryRepository repository;

    public RepairHistoryService(RepairHistoryRepository repository) {
        this.repository = repository;
    }

    /** vehicleId null = mọi xe của khách hàng; xe không thuộc khách hàng => 404 (không tiết lộ xe có tồn tại hay không). */
    @Transactional(readOnly = true)
    public List<HistoryItemResponse> getHistory(Integer customerId, Integer vehicleId) {
        if (vehicleId != null) {
            if (vehicleId <= 0) throw new BadRequestException("Mã xe không hợp lệ.");
            if (repository.countOwnedVehicle(vehicleId, customerId) == 0) {
                throw new ResourceNotFoundException("Không tìm thấy xe.");
            }
        }
        List<Object[]> rows = repository.findHistoryRows(customerId, vehicleId == null ? 0 : vehicleId, 0);
        return build(rows).stream().map(Built::item).toList();
    }

    /** Phiếu không tồn tại, chưa hoàn tất hoặc của khách hàng khác đều trả 404 giống nhau. */
    @Transactional(readOnly = true)
    public HistoryDetailResponse getDetail(Integer customerId, Integer repairOrderId) {
        List<Object[]> rows = repository.findHistoryRows(customerId, 0, repairOrderId);
        List<Built> built = build(rows);
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
Write-RepoFile 'backend/src/main/java/com/gara/quanlygara/controller/CustomerHistoryController.java' @'
// TV3-TUAN9
package com.gara.quanlygara.controller;

import com.gara.quanlygara.dto.ApiResponse;
import com.gara.quanlygara.dto.history.HistoryDetailResponse;
import com.gara.quanlygara.dto.history.HistoryItemResponse;
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
    public ResponseEntity<ApiResponse<List<HistoryItemResponse>>> getHistory(
            @RequestParam(required = false) Integer vehicleId,
            Authentication authentication
    ) {
        return ResponseEntity.ok(ApiResponse.success("Lấy lịch sử sửa chữa thành công.",
                historyService.getHistory(customerId(authentication), vehicleId)));
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
Write-RepoFile 'backend/src/test/java/com/gara/quanlygara/service/RepairHistoryServiceTest.java' @'
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
    void historyKeepsTheNewestFirstOrderOfTheQueryAndBuildsSummaryAndCosts() {
        when(repository.findHistoryRows(CUSTOMER_ID, 0, 0)).thenReturn(rows(
                header(12, 1, "51G-123.45", Timestamp.valueOf("2026-09-20 10:00:00"), "1500000"),
                header(5, 2, "51A-456.78", Timestamp.valueOf("2026-06-01 09:00:00"), "300000")));
        when(repository.findServiceLines(any())).thenReturn(rows(
                service(12, 2, "Bảo dưỡng định kỳ", "BAO_DUONG", 1, "1200000"),
                service(5, 3, "Kiểm tra hệ thống phanh", "KIEM_TRA", 1, "300000")));
        when(repository.findPartLines(any())).thenReturn(rows(part(12, 9, "Lọc dầu", 1, "300000")));

        var items = service.getHistory(CUSTOMER_ID, null);

        assertEquals(List.of(12, 5), items.stream().map(item -> item.repairOrderId()).toList());
        assertEquals("51G-123.45", items.get(0).licensePlate());
        assertEquals("Bảo dưỡng định kỳ", items.get(0).summary());
        assertEquals(1, items.get(0).serviceCount());
        assertEquals(1, items.get(0).partCount());
        assertEquals(new BigDecimal("1500000.00"), items.get(0).totalCost());
        assertEquals("BAO_DUONG", items.get(0).category());
        assertEquals("SUA_CHUA", items.get(1).category());
        assertEquals(LocalDateTime.of(2026, 9, 20, 10, 0), items.get(0).completedAt());
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
        when(repository.findHistoryRows(CUSTOMER_ID, 0, 0)).thenReturn(rows(
                header(1, 1, "A", Timestamp.valueOf("2026-01-01 00:00:00"), "0"),
                header(2, 1, "A", Timestamp.valueOf("2026-01-02 00:00:00"), "0"),
                header(3, 1, "A", Timestamp.valueOf("2026-01-03 00:00:00"), "0")));
        when(repository.findServiceLines(any())).thenReturn(rows(
                service(1, 1, "A1", "SUA_CHUA", 1, "1"), service(1, 2, "A2", "SUA_CHUA", 1, "1"),
                service(1, 3, "A3", "SUA_CHUA", 1, "1"), service(1, 4, "A4", "SUA_CHUA", 1, "1")));
        when(repository.findPartLines(any())).thenReturn(rows(part(2, 9, "Bugi", 4, "180000")));

        var items = service.getHistory(CUSTOMER_ID, null);

        assertEquals("A1, A2, A3 và 1 hạng mục khác", items.get(0).summary());
        assertEquals("Thay phụ tùng: Bugi", items.get(1).summary());
        assertEquals("Đã kiểm tra, xe hoạt động tốt", items.get(2).summary());
    }

    @Test
    void emptyHistoryIsAnEmptyListWithoutLineQueries() {
        when(repository.findHistoryRows(CUSTOMER_ID, 0, 0)).thenReturn(new ArrayList<>());

        assertTrue(service.getHistory(CUSTOMER_ID, null).isEmpty());
        verify(repository, never()).findServiceLines(any());
        verify(repository, never()).findPartLines(any());
    }

    @Test
    void filteringByAVehicleOfAnotherCustomerIsRejectedBeforeAnyHistoryQuery() {
        when(repository.countOwnedVehicle(99, CUSTOMER_ID)).thenReturn(0L);

        assertThrows(ResourceNotFoundException.class, () -> service.getHistory(CUSTOMER_ID, 99));
        verify(repository, never()).findHistoryRows(any(), any(), any());
    }

    @Test
    void filteringByAnOwnedVehicleScopesTheQueryToThatVehicleAndCustomer() {
        when(repository.countOwnedVehicle(3, CUSTOMER_ID)).thenReturn(1L);
        when(repository.findHistoryRows(CUSTOMER_ID, 3, 0)).thenReturn(new ArrayList<>());

        assertTrue(service.getHistory(CUSTOMER_ID, 3).isEmpty());
        verify(repository).findHistoryRows(CUSTOMER_ID, 3, 0);
    }

    @Test
    void invalidVehicleIdIsABadRequest() {
        assertThrows(BadRequestException.class, () -> service.getHistory(CUSTOMER_ID, 0));
        assertThrows(BadRequestException.class, () -> service.getHistory(CUSTOMER_ID, -4));
    }

    @Test
    void detailReturnsOnlyThatOrderWithServicesPartsAndTotals() {
        when(repository.findHistoryRows(CUSTOMER_ID, 0, 12)).thenReturn(rows(
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
        assertEquals("Hoàn tất tốt", detail.item().result());
    }

    @Test
    void detailOfAnUnknownOrAnotherCustomersOrderIsNotFound() {
        when(repository.findHistoryRows(CUSTOMER_ID, 0, 77)).thenReturn(new ArrayList<>());

        assertThrows(ResourceNotFoundException.class, () -> service.getDetail(CUSTOMER_ID, 77));
        verify(repository, never()).findServiceLines(any());
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
    }

    @Test
    @WithMockUser(username = "khachA", roles = "CUSTOMER")
    void customerSeesOwnHistoryAndCustomerIdFromTheClientIsIgnored() throws Exception {
        account("khachA", AccountRole.CUSTOMER, 1);
        when(repairHistoryRepository.findHistoryRows(1, 0, 0)).thenReturn(rows(header(12, 3, "51G-123.45")));
        when(repairHistoryRepository.findServiceLines(any())).thenReturn(rows(
                new Object[]{12, 2, "Bảo dưỡng định kỳ", "BAO_DUONG", 1, new BigDecimal("1200000")}));
        when(repairHistoryRepository.findPartLines(any())).thenReturn(rows(
                new Object[]{12, 9, "Lọc dầu", 2, new BigDecimal("90000")}));

        // Client cố truyền customerId của người khác: bị bỏ qua, truy vấn luôn dùng customerId của JWT (1).
        mockMvc.perform(get("/api/customers/me/history").param("customerId", "2"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()").value(1))
                .andExpect(jsonPath("$.data[0].repairOrderId").value(12))
                .andExpect(jsonPath("$.data[0].licensePlate").value("51G-123.45"))
                .andExpect(jsonPath("$.data[0].category").value("BAO_DUONG"))
                .andExpect(jsonPath("$.data[0].totalCost").value(1380000.0));

        verify(repairHistoryRepository).findHistoryRows(1, 0, 0);
        verify(repairHistoryRepository, never()).findHistoryRows(2, 0, 0);
    }

    @Test
    @WithMockUser(username = "khachA", roles = "CUSTOMER")
    void customerWithNoHistoryGetsAnEmptyList() throws Exception {
        account("khachA", AccountRole.CUSTOMER, 1);
        when(repairHistoryRepository.findHistoryRows(1, 0, 0)).thenReturn(new ArrayList<>());

        mockMvc.perform(get("/api/customers/me/history"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()").value(0));
    }

    @Test
    @WithMockUser(username = "khachA", roles = "CUSTOMER")
    void customerCanFilterByOwnVehicle() throws Exception {
        account("khachA", AccountRole.CUSTOMER, 1);
        when(repairHistoryRepository.countOwnedVehicle(3, 1)).thenReturn(1L);
        when(repairHistoryRepository.findHistoryRows(1, 3, 0)).thenReturn(rows(header(12, 3, "51G-123.45")));
        when(repairHistoryRepository.findServiceLines(any())).thenReturn(new ArrayList<>());
        when(repairHistoryRepository.findPartLines(any())).thenReturn(new ArrayList<>());

        mockMvc.perform(get("/api/customers/me/history").param("vehicleId", "3"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[0].vehicleId").value(3));
    }

    @Test
    @WithMockUser(username = "khachA", roles = "CUSTOMER")
    void customerCannotFilterByAnotherCustomersVehicle() throws Exception {
        account("khachA", AccountRole.CUSTOMER, 1);
        when(repairHistoryRepository.countOwnedVehicle(50, 1)).thenReturn(0L);

        mockMvc.perform(get("/api/customers/me/history").param("vehicleId", "50"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.success").value(false));
        verify(repairHistoryRepository, never()).findHistoryRows(any(), any(), any());
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
    void detailOfTheCustomersOwnOrderHasServicesPartsAndTotals() throws Exception {
        account("khachA", AccountRole.CUSTOMER, 1);
        when(repairHistoryRepository.findHistoryRows(1, 0, 12)).thenReturn(rows(header(12, 3, "51G-123.45")));
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
        when(repairHistoryRepository.findHistoryRows(1, 0, 99)).thenReturn(new ArrayList<>());

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
        verify(repairHistoryRepository, never()).findHistoryRows(any(), any(), any());
    }

    @Test
    void swaggerListsTheHistoryApi() throws Exception {
        mockMvc.perform(get("/v3/api-docs"))
                .andExpect(status().isOk())
                .andExpect(content().string(containsString("/api/customers/me/history")));
    }
}
'@
Write-RepoFile 'mobile/lib/models/history.dart' @'
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
'@
Write-RepoFile 'mobile/lib/services/history_service.dart' @'
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
  Future<List<HistoryItem>> getHistory({int? vehicleId});

  Future<HistoryDetail> getHistoryDetail(int repairOrderId);
}

class ApiHistoryService implements HistoryService {
  ApiHistoryService({
    required this.tokenProvider,
    String? baseUrl,
    HttpClient? client,
  }) : _baseUrl = baseUrl ?? AppConfig.apiBaseUrl,
       _client = client ?? HttpClient();

  /// Trả về access token của phiên đăng nhập hiện tại (null khi chưa đăng nhập).
  final String? Function() tokenProvider;
  final String _baseUrl;
  final HttpClient _client;

  @override
  Future<List<HistoryItem>> getHistory({int? vehicleId}) async {
    final data = await _get(
      '/customers/me/history',
      query: vehicleId == null ? null : {'vehicleId': '$vehicleId'},
    );
    if (data is! List) {
      throw const HistoryException('Dữ liệu lịch sử không hợp lệ.');
    }
    return data
        .whereType<Map<String, dynamic>>()
        .map(HistoryItem.fromJson)
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
Write-RepoFile 'mobile/lib/screens/history/history_screen.dart' @'
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

class _VehicleOption {
  const _VehicleOption({required this.id, required this.plate});

  final int id;
  final String plate;
}

/// Lịch sử sửa chữa, bảo dưỡng đã hoàn tất của khách hàng, lấy từ Spring Boot API.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.service});

  final HistoryService service;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _loading = true;
  String? _error;
  List<HistoryItem> _items = const [];
  List<_VehicleOption> _vehicles = const [];
  int? _vehicleId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await widget.service.getHistory(vehicleId: _vehicleId);
      if (!mounted) return;
      setState(() {
        _items = items;
        // Danh sách xe để lọc lấy từ lịch sử chưa lọc của chính khách hàng.
        if (_vehicleId == null) _vehicles = _distinctVehicles(items);
      });
    } on HistoryException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Không thể tải lịch sử sửa chữa.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<_VehicleOption> _distinctVehicles(List<HistoryItem> items) {
    final seen = <int>{};
    return [
      for (final item in items)
        if (seen.add(item.vehicleId))
          _VehicleOption(id: item.vehicleId, plate: item.plate),
    ];
  }

  void _selectVehicle(int? vehicleId) {
    if (vehicleId == _vehicleId) return;
    setState(() => _vehicleId = vehicleId);
    _load();
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
      return _refreshable(ErrorState(message: _error!, onRetry: _load));
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
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, index) =>
            _HistoryCard(item: _items[index], onTap: () => _open(_items[index])),
      ),
    );
  }

  /// Cho phép kéo để làm mới ngay cả khi đang hiển thị trạng thái rỗng/lỗi.
  Widget _refreshable(Widget child) {
    return RefreshIndicator(
      onRefresh: _load,
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
Write-RepoFile 'mobile/lib/screens/history/history_detail_screen.dart' @'
// TV3-TUAN9
import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/feedback_states.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/history.dart';
import '../../services/history_service.dart';
import 'history_screen.dart' show historyCategoryPresentation;

/// Chi tiết một lượt sửa chữa/bảo dưỡng: tải lại từ API để backend kiểm tra quyền sở hữu.
class HistoryDetailScreen extends StatefulWidget {
  const HistoryDetailScreen({
    super.key,
    required this.service,
    required this.repairOrderId,
  });

  final HistoryService service;
  final int repairOrderId;

  @override
  State<HistoryDetailScreen> createState() => _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends State<HistoryDetailScreen> {
  bool _loading = true;
  String? _error;
  HistoryDetail? _detail;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final detail = await widget.service.getHistoryDetail(
        widget.repairOrderId,
      );
      if (mounted) setState(() => _detail = detail);
    } on HistoryException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Không thể tải chi tiết lịch sử.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;
    final Widget body;
    if (_loading) {
      body = const LoadingState(label: 'Đang tải chi tiết...');
    } else if (_error != null || detail == null) {
      body = ErrorState(
        message: _error ?? 'Không thể tải chi tiết lịch sử.',
        onRetry: _load,
      );
    } else {
      body = RefreshIndicator(
        onRefresh: _load,
        child: _DetailBody(detail: detail),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text('Phiếu #${widget.repairOrderId}')),
      body: SafeArea(top: false, child: body),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.detail});

  final HistoryDetail detail;

  @override
  Widget build(BuildContext context) {
    final item = detail.item;
    final (label, tone) = historyCategoryPresentation(item.category);
    final titleStyle = Theme.of(context).textTheme.titleMedium;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Phiếu sửa chữa #${item.repairOrderId}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    StatusBadge(label: label, tone: tone),
                  ],
                ),
                const SizedBox(height: 12),
                _InfoRow(label: 'Biển số', value: item.plate),
                if (item.vehicleName.isNotEmpty)
                  _InfoRow(label: 'Xe', value: item.vehicleName),
                _InfoRow(label: 'Ngày lập', value: _date(item.createdAt)),
                _InfoRow(label: 'Ngày bắt đầu', value: _date(item.startedAt)),
                _InfoRow(
                  label: 'Ngày hoàn thành',
                  value: _date(item.completedAt),
                ),
                if (item.result.isNotEmpty) ...[
                  const Divider(height: 24),
                  Text('Kết quả sửa chữa', style: titleStyle),
                  const SizedBox(height: 4),
                  Text(item.result),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Hạng mục dịch vụ', style: titleStyle),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: detail.services.isEmpty
                ? const Text(
                    'Không có hạng mục dịch vụ.',
                    style: TextStyle(color: AppColors.muted),
                  )
                : Column(
                    children: [
                      for (final line in detail.services)
                        _LineRow(
                          name: line.name,
                          quantity: line.quantity,
                          unitPrice: line.unitPrice,
                          lineTotal: line.lineTotal,
                        ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Phụ tùng đã thay', style: titleStyle),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: detail.parts.isEmpty
                ? const Text(
                    'Không thay phụ tùng.',
                    style: TextStyle(color: AppColors.muted),
                  )
                : Column(
                    children: [
                      for (final line in detail.parts)
                        _LineRow(
                          name: line.name,
                          quantity: line.quantity,
                          unitPrice: line.unitPrice,
                          lineTotal: line.lineTotal,
                        ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _InfoRow(
                  label: 'Tiền dịch vụ',
                  value: formatCurrency(detail.serviceTotal),
                ),
                _InfoRow(
                  label: 'Tiền phụ tùng',
                  value: formatCurrency(detail.partsTotal),
                ),
                const Divider(height: 24),
                _InfoRow(
                  label: 'Tổng chi phí',
                  value: formatCurrency(item.totalCost),
                  emphasize: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static String _date(DateTime? value) => value == null ? '—' : formatDate(value);
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
      fontSize: emphasize ? 16 : 14,
      color: emphasize ? AppColors.primary : AppColors.foreground,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: AppColors.muted)),
          ),
          const SizedBox(width: 12),
          Flexible(child: Text(value, style: style, textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}

class _LineRow extends StatelessWidget {
  const _LineRow({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });

  final String name;
  final int quantity;
  final int unitPrice;
  final int lineTotal;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(
                  '$quantity × ${formatCurrency(unitPrice)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            formatCurrency(lineTotal),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
'@
Write-RepoFile 'mobile/test/history_service_test.dart' @'
// TV3-TUAN9
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:garage_customer_mobile/models/history.dart';
import 'package:garage_customer_mobile/services/history_service.dart';

const _listPayload = {
  'success': true,
  'message': 'ok',
  'data': [
    {
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
    },
  ],
};

const _detailPayload = {
  'success': true,
  'message': 'ok',
  'data': {
    'item': {
      'repairOrderId': 12,
      'vehicleId': 3,
      'licensePlate': '51G-123.45',
      'brand': 'Toyota',
      'model': 'Camry',
      'category': 'BAO_DUONG_SUA_CHUA',
      'summary': 'x',
      'serviceCount': 1,
      'partCount': 1,
      'totalCost': 1380000.0,
      'result': '',
    },
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

Future<HttpServer> _serve(
  _Recorded recorded,
  int status,
  Object? body,
) async {
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

ApiHistoryService _service(HttpServer server, {String? token = 'tok'}) =>
    ApiHistoryService(
      tokenProvider: () => token,
      baseUrl: 'http://127.0.0.1:${server.port}/api',
    );

void main() {
  test('getHistory sends the bearer token and parses the response', () async {
    final recorded = _Recorded();
    final server = await _serve(recorded, 200, _listPayload);
    addTearDown(() => server.close(force: true));

    final items = await _service(server).getHistory();

    expect(recorded.method, 'GET');
    expect(recorded.path, '/api/customers/me/history');
    expect(recorded.query, isEmpty);
    expect(recorded.authorization, 'Bearer tok');
    expect(items, hasLength(1));
    expect(items.first.repairOrderId, 12);
    expect(items.first.plate, '51G-123.45');
    expect(items.first.vehicleName, 'Toyota Camry');
    expect(items.first.category, HistoryCategory.maintenance);
    expect(items.first.totalCost, 1380000);
    expect(items.first.date, DateTime(2026, 9, 20, 10));
  });

  test('getHistory passes the vehicle filter as a query parameter', () async {
    final recorded = _Recorded();
    final server = await _serve(recorded, 200, {'data': <Object>[]});
    addTearDown(() => server.close(force: true));

    final items = await _service(server).getHistory(vehicleId: 3);

    expect(recorded.query, 'vehicleId=3');
    expect(items, isEmpty);
  });

  test('getHistoryDetail parses services, parts and totals', () async {
    final recorded = _Recorded();
    final server = await _serve(recorded, 200, _detailPayload);
    addTearDown(() => server.close(force: true));

    final detail = await _service(server).getHistoryDetail(12);

    expect(recorded.path, '/api/customers/me/history/12');
    expect(detail.item.category, HistoryCategory.mixed);
    expect(detail.services.single.name, 'Bảo dưỡng định kỳ');
    expect(detail.parts.single.lineTotal, 180000);
    expect(detail.serviceTotal, 1200000);
    expect(detail.partsTotal, 180000);
  });

  test('a missing token fails before any request is made', () async {
    final recorded = _Recorded();
    final server = await _serve(recorded, 200, _listPayload);
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
    }
  });

  test('an invalid payload is reported instead of crashing', () async {
    final server = await _serve(_Recorded(), 200, '<html>oops</html>');
    addTearDown(() => server.close(force: true));
    await expectLater(
      _service(server).getHistory(),
      throwsA(isA<HistoryException>()),
    );

    final wrongShape = await _serve(_Recorded(), 200, {'data': 'not a list'});
    addTearDown(() => wrongShape.close(force: true));
    await expectLater(
      _service(wrongShape).getHistory(),
      throwsA(isA<HistoryException>()),
    );
  });

  test('a refused connection becomes a friendly error', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final service = _service(server);
    await server.close(force: true);

    await expectLater(
      service.getHistory(),
      throwsA(isA<HistoryException>()),
    );
  });
}
'@
Write-RepoFile 'mobile/test/history_screen_test.dart' @'
// TV3-TUAN9
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

/// Test double của giao diện HistoryService: ghi lại các lần gọi và trả dữ liệu cấu hình sẵn.
class _FakeHistoryService implements HistoryService {
  _FakeHistoryService({this.items = const [], this.failFirst = false});

  List<HistoryItem> items;
  bool failFirst;
  final List<int?> calls = [];
  int detailCalls = 0;

  @override
  Future<List<HistoryItem>> getHistory({int? vehicleId}) async {
    calls.add(vehicleId);
    if (failFirst) {
      failFirst = false;
      throw const HistoryException('Không thể kết nối đến hệ thống.');
    }
    return vehicleId == null
        ? items
        : items.where((item) => item.vehicleId == vehicleId).toList();
  }

  @override
  Future<HistoryDetail> getHistoryDetail(int repairOrderId) async {
    detailCalls++;
    return HistoryDetail(
      item: items.firstWhere((item) => item.repairOrderId == repairOrderId),
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
  }
}

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
    expect(service.calls, [null, null]);
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

    expect(service.calls.last, 2);
    expect(find.text('Phiếu #5'), findsOneWidget);
    expect(find.text('Phiếu #12'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Tất cả xe'));
    await tester.pumpAndSettle();

    expect(service.calls.last, isNull);
    expect(find.text('Phiếu #12'), findsOneWidget);
  });

  testWidgets('pull to refresh reloads the history', (tester) async {
    final service = _FakeHistoryService(items: [_item(12)]);
    await _pump(tester, service);
    expect(service.calls, hasLength(1));

    await tester.fling(find.byType(ListView).first, const Offset(0, 400), 1000);
    await tester.pumpAndSettle();

    expect(service.calls.length, greaterThanOrEqualTo(2));
  });

  testWidgets('opening a repair shows services, parts and totals from the API', (
    tester,
  ) async {
    final service = _FakeHistoryService(items: [_item(12)]);
    await _pump(tester, service);

    await tester.tap(find.text('Phiếu #12'));
    await tester.pumpAndSettle();

    expect(service.detailCalls, 1);
    expect(find.text('Thay dầu động cơ'), findsOneWidget);
    expect(find.text('Lọc dầu'), findsOneWidget);
    expect(find.text('2 × 90.000 ₫'), findsOneWidget);
    expect(find.text('180.000 ₫'), findsWidgets);
    await tester.scrollUntilVisible(find.text('Tổng chi phí'), 200);
    expect(find.text('Tổng chi phí'), findsOneWidget);
    expect(find.text('Hoàn tất tốt'), findsOneWidget);
  });
}
'@

Write-Step 'Noi route /history (chi sua app.dart, co backup)'
Update-RepoFile 'mobile/lib/app/app.dart' 'import ''../services/home_service.dart'';' 'import ''../services/history_service.dart'';
import ''../services/home_service.dart'';' 'services/history_service.dart'
Update-RepoFile 'mobile/lib/app/app.dart' 'import ''../screens/quotations/quotations_screen.dart'';' 'import ''../screens/history/history_screen.dart'';
import ''../screens/quotations/quotations_screen.dart'';' 'screens/history/history_screen.dart'
Update-RepoFile 'mobile/lib/app/app.dart' '    this.appointmentService,
' '    this.appointmentService,
    this.historyService,
' 'this.historyService,'
Update-RepoFile 'mobile/lib/app/app.dart' '  final AppointmentService? appointmentService;
' '  final AppointmentService? appointmentService;
  final HistoryService? historyService;
' 'final HistoryService? historyService;'
Update-RepoFile 'mobile/lib/app/app.dart' '  @override
  void dispose() {
    controller.dispose();' '  // Lịch sử sửa chữa gọi Spring Boot API thật bằng token của phiên đăng nhập hiện tại.
  late final HistoryService _historyService =
      widget.historyService ??
      ApiHistoryService(tokenProvider: () => controller.session?.accessToken);

  @override
  void dispose() {
    controller.dispose();' 'HistoryService _historyService ='
Update-RepoFile 'mobile/lib/app/app.dart' '      AppRoutes.history => RepairProgressScreen(
        controller: controller,
        historyOnly: true,
      ),
' '      AppRoutes.history => HistoryScreen(service: _historyService),
' 'HistoryScreen(service: _historyService)'

Write-Step 'Dong bo @MockitoBean cho cac test Spring da co'
Sync-MockBeans

$script:Results["Ap dung file"] = "PASS"
$script:FlutterRan = $false

# ============================================================
# 7. TEST + BUILD (backend + mobile; khong doi frontend web, schema SQL)
# ============================================================
if ($SkipBuild) {
    $script:Results["Backend test"] = "SKIPPED (-SkipBuild)"
    $script:Results["Backend package"] = "SKIPPED (-SkipBuild)"
    $script:Results["Flutter analyze/test"] = "SKIPPED (-SkipBuild)"
} else {
    Invoke-Native "Backend test" (Join-Path $root "backend") "backend-test.log" { .\mvnw.cmd test }
    Invoke-Native "Backend package" (Join-Path $root "backend") "backend-package.log" { .\mvnw.cmd clean package }

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
        Write-Warn2 "Khong co Flutter SDK trong PATH: chua chay flutter analyze/test. Cai Flutter hoac mo terminal co Flutter roi chay lai."
    }
}

Write-Host ""
Write-Host "Khong co thay doi SQL o Tuan 9. API lich su doc truc tiep PhieuSuaChua/PhieuTiepNhan/Xe/ChiTietDichVu/ChiTietPhuTung." -ForegroundColor Yellow
Write-Host "Can da chay migration V001-V003 (kho) tu Tuan 8 neu muon chay ung dung that." -ForegroundColor Yellow

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
        /XF *.log .env .env.local TV3_Tuan9_Mobile_History_FINAL.zip TV3_Tuan9_Mobile_History_APPLY.ps1 | Out-Null
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
