<#
  TV3_Tuan8_Warehouse_APPLY.ps1 - Tuan 8 - TV3 Hoang Van Cam
  Quan ly kho phu tung: ton kho, nhap kho, xuat kho (cap phat), xac nhan thuc dung, kiem ke co phe duyet, bien dong kho.
  Chay tu repository root:   .\TV3_Tuan8_Warehouse_APPLY.ps1
  Tuy chon: -SkipBuild (chi ap dung file), -NoZip (khong tao zip)
  KHONG tu chay SQL: hay chay backend/database/migrations/V002__*.sql trong SSMS (xem huong dan cuoi script).
  Khong checkout/commit/push Git. Khong ghi de file cua nguoi khac.
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
# 1. XAC DINH REPOSITORY ROOT + KIEM TRA CAU TRUC (checkpoint Tuan 6 + 7 phai co san)
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
    "backend/src/main/java/com/gara/quanlygara/entity/SparePart.java",
    "backend/src/main/java/com/gara/quanlygara/entity/RepairPartItem.java",
    "backend/src/main/java/com/gara/quanlygara/repository/SparePartRepository.java",
    "backend/src/main/java/com/gara/quanlygara/repository/RepairPartItemRepository.java",
    "backend/src/main/java/com/gara/quanlygara/repository/RepairServiceItemRepository.java",
    "backend/src/test/java/com/gara/quanlygara/config/SecurityConfigTest.java",
    "frontend/package.json",
    "frontend/src/api/client.ts",
    "frontend/src/api/session.ts",
    "frontend/src/api/errors.ts",
    "frontend/src/api/spareParts.ts",
    "frontend/src/components/ui.tsx",
    "frontend/src/App.tsx",
    "frontend/src/pages/Inventory.tsx"
)
$missing = @($required | Where-Object { -not (Test-Path -LiteralPath (Join-Path $root $_)) })
if ($missing.Count -gt 0) {
    Stop-Fail ("Khong dung repository root ($root). Thieu:`n  - " + ($missing -join "`n  - "))
}
Set-Location -LiteralPath $root
Write-Ok "Repository root: $root"

$sql = Get-Content -LiteralPath (Join-Path $root "backend/database/QuanLyGaraOTo.sql") -Raw
foreach ($table in @("Kho", "PhuTung", "PhieuNhapKho", "ChiTietPhieuNhap", "PhieuXuatKho", "ChiTietPhieuXuat", "BienDongKho", "PhieuSuaChua", "PhanCongKyThuatVien", "BaoGia", "NhanVien")) {
    if ($sql -notmatch ("CREATE TABLE " + $table + "\s*\(")) {
        Stop-Fail "QuanLyGaraOTo.sql khong co bang $table nhu du kien. Khong tao bang song song; hay gui schema thuc te cho Claude."
    }
}
foreach ($proc in @("sp_ThemChiTietPhieuNhap", "sp_XacNhanSuDungPhuTung", "sp_KiemKeTonKho")) {
    if ($sql -notmatch ("PROCEDURE dbo\." + $proc)) { Stop-Fail "QuanLyGaraOTo.sql khong co procedure $proc nhu du kien." }
}
Write-Ok "Schema kho khop (PhuTung, PhieuNhapKho, PhieuXuatKho, BienDongKho, ...); giu nguyen QuanLyGaraOTo.sql"
$sparePart = [System.IO.File]::ReadAllText((Join-Path $root "backend/src/main/java/com/gara/quanlygara/repository/SparePartRepository.java"), $utf8NoBom)
if (-not $sparePart.Contains("TV3-TUAN7")) { Stop-Fail "SparePartRepository.java khong phai ban Tuan 7 do script tao. Hay ap dung Tuan 7 truoc." }

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
# 4. PREFLIGHT: khong tao module/bang song song voi code cua Huy/Trung
# ------------------------------------------------------------
Write-Step "Preflight (tim code kho da co)"
$javaRoot = Join-Path $root "backend/src/main/java"
$mine = @("entity/StockMovement.java", "entity/StockReceipt.java", "entity/StockReceiptItem.java", "entity/StockIssue.java", "entity/StockIssueItem.java", "entity/InventoryCheck.java", "entity/InventoryCheckItem.java", "controller/InventoryController.java", "controller/StockReceiptController.java", "controller/StockIssueController.java", "controller/InventoryCheckController.java")
$foreign = @()
foreach ($file in Get-ChildItem -LiteralPath $javaRoot -Recurse -Filter "*.java") {
    $norm = $file.FullName.Replace('\', '/')
    if ($mine | Where-Object { $norm.EndsWith("/quanlygara/" + $_) }) { continue }
    $raw = [System.IO.File]::ReadAllText($file.FullName, $utf8NoBom)
    if ($raw -match '@Table\s*\(\s*name\s*=\s*"(PhieuNhapKho|ChiTietPhieuNhap|PhieuXuatKho|ChiTietPhieuXuat|BienDongKho|PhieuKiemKe|ChiTietKiemKe)"') { $foreign += "$norm  (entity da map bang $($Matches[1]))" }
    elseif ($raw -match '"/api/(inventory|warehouse)') { $foreign += "$norm  (da co endpoint kho)" }
}
if ($foreign.Count -gt 0) {
    Stop-Fail ("Da co implementation kho trong workspace - KHONG tao ban song song. Hay gui cac file sau cho Claude de tai su dung thay vi tao moi:`n  - " + ($foreign -join "`n  - "))
}
Write-Ok "Khong co entity/endpoint kho trung (PhieuNhapKho, PhieuXuatKho, BienDongKho, PhieuKiemKe, /api/inventory, /api/warehouse)"


Write-Step 'Tao / cap nhat file Tuan 8 (kho phu tung)'
Write-RepoFile 'backend/src/main/java/com/gara/quanlygara/entity/StockMovement.java' @'
// TV3-TUAN8
package com.gara.quanlygara.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.time.LocalDateTime;

/** Lịch sử biến động kho: bảng BienDongKho (bảng lịch sử duy nhất). */
@Entity
@Table(name = "BienDongKho")
public class StockMovement {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "MaBienDong")
    private Long id;

    @Column(name = "MaPhuTung", nullable = false)
    private Integer partId;

    @Column(name = "MaPhieuNhap")
    private Integer receiptId;

    @Column(name = "MaPhieuXuat")
    private Integer issueId;

    @Column(name = "ThoiGian", nullable = false)
    private LocalDateTime movedAt;

    /** NHAP, XUAT hoặc KIEM_KE (ràng buộc CK_BienDongKho_Loai). */
    @Column(name = "LoaiBienDong", nullable = false, length = 20)
    private String type;

    @Column(name = "SoLuong", nullable = false)
    private Integer quantity;

    @Column(name = "SoLuongTruoc")
    private Integer quantityBefore;

    @Column(name = "SoLuongSau")
    private Integer quantityAfter;

    @Column(name = "GhiChu", length = 500)
    private String note;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Integer getPartId() { return partId; }
    public void setPartId(Integer partId) { this.partId = partId; }
    public Integer getReceiptId() { return receiptId; }
    public void setReceiptId(Integer receiptId) { this.receiptId = receiptId; }
    public Integer getIssueId() { return issueId; }
    public void setIssueId(Integer issueId) { this.issueId = issueId; }
    public LocalDateTime getMovedAt() { return movedAt; }
    public void setMovedAt(LocalDateTime movedAt) { this.movedAt = movedAt; }
    public String getType() { return type; }
    public void setType(String type) { this.type = type; }
    public Integer getQuantity() { return quantity; }
    public void setQuantity(Integer quantity) { this.quantity = quantity; }
    public Integer getQuantityBefore() { return quantityBefore; }
    public void setQuantityBefore(Integer quantityBefore) { this.quantityBefore = quantityBefore; }
    public Integer getQuantityAfter() { return quantityAfter; }
    public void setQuantityAfter(Integer quantityAfter) { this.quantityAfter = quantityAfter; }
    public String getNote() { return note; }
    public void setNote(String note) { this.note = note; }
}
'@
Write-RepoFile 'backend/src/main/java/com/gara/quanlygara/entity/StockReceipt.java' @'
// TV3-TUAN8
package com.gara.quanlygara.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.time.LocalDateTime;

/** Phiếu nhập kho: bảng PhieuNhapKho. */
@Entity
@Table(name = "PhieuNhapKho")
public class StockReceipt {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "MaPhieuNhap")
    private Integer id;

    @Column(name = "NgayNhap", nullable = false)
    private LocalDateTime receiptDate;

    @Column(name = "NhaCungCap", nullable = false, length = 200)
    private String supplier;

    @Column(name = "MaNhanVienKho", nullable = false)
    private Integer warehouseStaffId;

    @Column(name = "GhiChu", length = 500)
    private String note;

    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }
    public LocalDateTime getReceiptDate() { return receiptDate; }
    public void setReceiptDate(LocalDateTime receiptDate) { this.receiptDate = receiptDate; }
    public String getSupplier() { return supplier; }
    public void setSupplier(String supplier) { this.supplier = supplier; }
    public Integer getWarehouseStaffId() { return warehouseStaffId; }
    public void setWarehouseStaffId(Integer warehouseStaffId) { this.warehouseStaffId = warehouseStaffId; }
    public String getNote() { return note; }
    public void setNote(String note) { this.note = note; }
}
'@
Write-RepoFile 'backend/src/main/java/com/gara/quanlygara/entity/StockReceiptItem.java' @'
// TV3-TUAN8
package com.gara.quanlygara.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.IdClass;
import jakarta.persistence.Table;

import java.io.Serializable;
import java.math.BigDecimal;
import java.util.Objects;

/** Chi tiết phiếu nhập: bảng ChiTietPhieuNhap (ThanhTien là cột tính toán nên không ánh xạ). */
@Entity
@Table(name = "ChiTietPhieuNhap")
@IdClass(StockReceiptItem.Key.class)
public class StockReceiptItem {

    @Id
    @Column(name = "MaPhieuNhap")
    private Integer receiptId;

    @Id
    @Column(name = "MaPhuTung")
    private Integer partId;

    @Column(name = "SoLuong", nullable = false)
    private Integer quantity;

    @Column(name = "DonGiaNhap", nullable = false, precision = 18, scale = 2)
    private BigDecimal unitPrice;

    public static class Key implements Serializable {
        private Integer receiptId;
        private Integer partId;

        public Key() {
        }

        public Key(Integer receiptId, Integer partId) {
            this.receiptId = receiptId;
            this.partId = partId;
        }

        @Override
        public boolean equals(Object other) {
            if (this == other) return true;
            if (!(other instanceof Key key)) return false;
            return Objects.equals(receiptId, key.receiptId) && Objects.equals(partId, key.partId);
        }

        @Override
        public int hashCode() {
            return Objects.hash(receiptId, partId);
        }
    }

    public Integer getReceiptId() { return receiptId; }
    public void setReceiptId(Integer receiptId) { this.receiptId = receiptId; }
    public Integer getPartId() { return partId; }
    public void setPartId(Integer partId) { this.partId = partId; }
    public Integer getQuantity() { return quantity; }
    public void setQuantity(Integer quantity) { this.quantity = quantity; }
    public BigDecimal getUnitPrice() { return unitPrice; }
    public void setUnitPrice(BigDecimal unitPrice) { this.unitPrice = unitPrice; }
}
'@
Write-RepoFile 'backend/src/main/java/com/gara/quanlygara/entity/StockIssue.java' @'
// TV3-TUAN8
package com.gara.quanlygara.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.time.LocalDateTime;

/** Phiếu xuất kho (cấp phát phụ tùng): bảng PhieuXuatKho. Tạo phiếu KHÔNG giảm tồn. */
@Entity
@Table(name = "PhieuXuatKho")
public class StockIssue {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "MaPhieuXuat")
    private Integer id;

    @Column(name = "MaPhieuSuaChua")
    private Integer repairOrderId;

    @Column(name = "MaNhanVienKho", nullable = false)
    private Integer warehouseStaffId;

    @Column(name = "MaKyThuatVienYeuCau")
    private Integer requestedTechnicianId;

    @Column(name = "NgayXuat", nullable = false)
    private LocalDateTime issueDate;

    @Column(name = "LyDo", nullable = false, length = 500)
    private String reason;

    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }
    public Integer getRepairOrderId() { return repairOrderId; }
    public void setRepairOrderId(Integer repairOrderId) { this.repairOrderId = repairOrderId; }
    public Integer getWarehouseStaffId() { return warehouseStaffId; }
    public void setWarehouseStaffId(Integer warehouseStaffId) { this.warehouseStaffId = warehouseStaffId; }
    public Integer getRequestedTechnicianId() { return requestedTechnicianId; }
    public void setRequestedTechnicianId(Integer requestedTechnicianId) { this.requestedTechnicianId = requestedTechnicianId; }
    public LocalDateTime getIssueDate() { return issueDate; }
    public void setIssueDate(LocalDateTime issueDate) { this.issueDate = issueDate; }
    public String getReason() { return reason; }
    public void setReason(String reason) { this.reason = reason; }
}
'@
Write-RepoFile 'backend/src/main/java/com/gara/quanlygara/entity/StockIssueItem.java' @'
// TV3-TUAN8
package com.gara.quanlygara.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.IdClass;
import jakarta.persistence.Table;

import java.io.Serializable;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Objects;

/**
 * Chi tiết phiếu xuất: bảng ChiTietPhieuXuat.
 * quantity (SoLuong) = số lượng CẤP PHÁT; actualUsedQuantity = KTV xác nhận thực dùng;
 * returnedQuantity = quantity - actualUsedQuantity. Chỉ lúc xác nhận thực dùng mới giảm tồn.
 */
@Entity
@Table(name = "ChiTietPhieuXuat")
@IdClass(StockIssueItem.Key.class)
public class StockIssueItem {

    @Id
    @Column(name = "MaPhieuXuat")
    private Integer issueId;

    @Id
    @Column(name = "MaPhuTung")
    private Integer partId;

    @Column(name = "SoLuong", nullable = false)
    private Integer quantity;

    @Column(name = "DonGia", precision = 18, scale = 2)
    private BigDecimal unitPrice;

    @Column(name = "DaXacNhanSuDung", nullable = false)
    private boolean confirmed;

    @Column(name = "NgayXacNhan")
    private LocalDateTime confirmedAt;

    @Column(name = "MaKyThuatVienXacNhan")
    private Integer confirmedTechnicianId;

    @Column(name = "SoLuongThucDung")
    private Integer actualUsedQuantity;

    @Column(name = "SoLuongHoanTra")
    private Integer returnedQuantity;

    public static class Key implements Serializable {
        private Integer issueId;
        private Integer partId;

        public Key() {
        }

        public Key(Integer issueId, Integer partId) {
            this.issueId = issueId;
            this.partId = partId;
        }

        @Override
        public boolean equals(Object other) {
            if (this == other) return true;
            if (!(other instanceof Key key)) return false;
            return Objects.equals(issueId, key.issueId) && Objects.equals(partId, key.partId);
        }

        @Override
        public int hashCode() {
            return Objects.hash(issueId, partId);
        }
    }

    public Integer getIssueId() { return issueId; }
    public void setIssueId(Integer issueId) { this.issueId = issueId; }
    public Integer getPartId() { return partId; }
    public void setPartId(Integer partId) { this.partId = partId; }
    public Integer getQuantity() { return quantity; }
    public void setQuantity(Integer quantity) { this.quantity = quantity; }
    public BigDecimal getUnitPrice() { return unitPrice; }
    public void setUnitPrice(BigDecimal unitPrice) { this.unitPrice = unitPrice; }
    public boolean isConfirmed() { return confirmed; }
    public void setConfirmed(boolean confirmed) { this.confirmed = confirmed; }
    public LocalDateTime getConfirmedAt() { return confirmedAt; }
    public void setConfirmedAt(LocalDateTime confirmedAt) { this.confirmedAt = confirmedAt; }
    public Integer getConfirmedTechnicianId() { return confirmedTechnicianId; }
    public void setConfirmedTechnicianId(Integer confirmedTechnicianId) { this.confirmedTechnicianId = confirmedTechnicianId; }
    public Integer getActualUsedQuantity() { return actualUsedQuantity; }
    public void setActualUsedQuantity(Integer actualUsedQuantity) { this.actualUsedQuantity = actualUsedQuantity; }
    public Integer getReturnedQuantity() { return returnedQuantity; }
    public void setReturnedQuantity(Integer returnedQuantity) { this.returnedQuantity = returnedQuantity; }
}
'@
Write-RepoFile 'backend/src/main/java/com/gara/quanlygara/entity/InventoryCheck.java' @'
// TV3-TUAN8
package com.gara.quanlygara.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.time.LocalDateTime;

/** Phiên kiểm kê: bảng PhieuKiemKe (migration V002). */
@Entity
@Table(name = "PhieuKiemKe")
public class InventoryCheck {

    public static final String COUNTING = "DANG_KIEM_KE";
    public static final String PENDING_APPROVAL = "CHO_PHE_DUYET";
    public static final String COMPLETED = "DA_HOAN_TAT";
    public static final String REJECTED = "DA_TU_CHOI";

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "MaPhieuKiemKe")
    private Integer id;

    @Column(name = "NgayKiemKe", nullable = false)
    private LocalDateTime checkDate;

    @Column(name = "MaNhanVienKiemKe", nullable = false)
    private Integer createdBy;

    @Column(name = "MaNhanVienDuyet")
    private Integer approvedBy;

    @Column(name = "NgayDuyet")
    private LocalDateTime approvedAt;

    @Column(name = "TrangThai", nullable = false, length = 30)
    private String status;

    @Column(name = "GhiChu", length = 500)
    private String note;

    @Column(name = "LyDoDuyet", length = 500)
    private String decisionReason;

    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }
    public LocalDateTime getCheckDate() { return checkDate; }
    public void setCheckDate(LocalDateTime checkDate) { this.checkDate = checkDate; }
    public Integer getCreatedBy() { return createdBy; }
    public void setCreatedBy(Integer createdBy) { this.createdBy = createdBy; }
    public Integer getApprovedBy() { return approvedBy; }
    public void setApprovedBy(Integer approvedBy) { this.approvedBy = approvedBy; }
    public LocalDateTime getApprovedAt() { return approvedAt; }
    public void setApprovedAt(LocalDateTime approvedAt) { this.approvedAt = approvedAt; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public String getNote() { return note; }
    public void setNote(String note) { this.note = note; }
    public String getDecisionReason() { return decisionReason; }
    public void setDecisionReason(String decisionReason) { this.decisionReason = decisionReason; }
}
'@
Write-RepoFile 'backend/src/main/java/com/gara/quanlygara/entity/InventoryCheckItem.java' @'
// TV3-TUAN8
package com.gara.quanlygara.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.IdClass;
import jakarta.persistence.Table;

import java.io.Serializable;
import java.util.Objects;

/** Chi tiết kiểm kê: bảng ChiTietKiemKe (ChenhLech là cột tính toán; Java tính lại bằng difference()). */
@Entity
@Table(name = "ChiTietKiemKe")
@IdClass(InventoryCheckItem.Key.class)
public class InventoryCheckItem {

    @Id
    @Column(name = "MaPhieuKiemKe")
    private Integer checkId;

    @Id
    @Column(name = "MaPhuTung")
    private Integer partId;

    @Column(name = "SoLuongHeThong", nullable = false)
    private Integer systemQuantity;

    @Column(name = "SoLuongThucTe")
    private Integer actualQuantity;

    @Column(name = "LyDo", length = 500)
    private String reason;

    @Column(name = "DaDuyetDieuChinh", nullable = false)
    private boolean adjustmentApproved;

    public static class Key implements Serializable {
        private Integer checkId;
        private Integer partId;

        public Key() {
        }

        public Key(Integer checkId, Integer partId) {
            this.checkId = checkId;
            this.partId = partId;
        }

        @Override
        public boolean equals(Object other) {
            if (this == other) return true;
            if (!(other instanceof Key key)) return false;
            return Objects.equals(checkId, key.checkId) && Objects.equals(partId, key.partId);
        }

        @Override
        public int hashCode() {
            return Objects.hash(checkId, partId);
        }
    }

    /** Chênh lệch = thực tế - hệ thống; null nếu chưa nhập thực tế. */
    public Integer difference() {
        return actualQuantity == null ? null : actualQuantity - systemQuantity;
    }

    public Integer getCheckId() { return checkId; }
    public void setCheckId(Integer checkId) { this.checkId = checkId; }
    public Integer getPartId() { return partId; }
    public void setPartId(Integer partId) { this.partId = partId; }
    public Integer getSystemQuantity() { return systemQuantity; }
    public void setSystemQuantity(Integer systemQuantity) { this.systemQuantity = systemQuantity; }
    public Integer getActualQuantity() { return actualQuantity; }
    public void setActualQuantity(Integer actualQuantity) { this.actualQuantity = actualQuantity; }
    public String getReason() { return reason; }
    public void setReason(String reason) { this.reason = reason; }
    public boolean isAdjustmentApproved() { return adjustmentApproved; }
    public void setAdjustmentApproved(boolean adjustmentApproved) { this.adjustmentApproved = adjustmentApproved; }
}
'@
Write-RepoFile 'backend/src/main/java/com/gara/quanlygara/dto/warehouse/StockStatus.java' @'
// TV3-TUAN8
package com.gara.quanlygara.dto.warehouse;

/** Suy ra từ tồn và mức tối thiểu (cùng quy tắc dbo.fn_TrangThaiTonKho), không lưu trong CSDL. */
public enum StockStatus {
    CON_HANG,
    SAP_HET,
    HET_HANG;

    public static StockStatus of(int stockQuantity, int minStockLevel) {
        if (stockQuantity == 0) return HET_HANG;
        if (stockQuantity <= minStockLevel) return SAP_HET;
        return CON_HANG;
    }
}
'@
Write-RepoFile 'backend/src/main/java/com/gara/quanlygara/dto/warehouse/PageResponse.java' @'
// TV3-TUAN8
package com.gara.quanlygara.dto.warehouse;

import org.springframework.data.domain.Page;

import java.util.List;
import java.util.function.Function;

/** page bắt đầu từ 0, giống Spring Data. */
public record PageResponse<T>(List<T> items, int page, int size, long totalElements, int totalPages) {

    public static <S, T> PageResponse<T> of(Page<S> page, Function<S, T> mapper) {
        return new PageResponse<>(
                page.getContent().stream().map(mapper).toList(),
                page.getNumber(), page.getSize(), page.getTotalElements(), page.getTotalPages());
    }

    public static <T> PageResponse<T> of(Page<T> page) {
        return of(page, Function.identity());
    }
}
'@
Write-RepoFile 'backend/src/main/java/com/gara/quanlygara/dto/warehouse/InventoryItemResponse.java' @'
// TV3-TUAN8
package com.gara.quanlygara.dto.warehouse;

import com.gara.quanlygara.entity.SparePart;

import java.math.BigDecimal;

public record InventoryItemResponse(
        Integer id,
        Integer warehouseId,
        String name,
        String manufacturer,
        BigDecimal unitPrice,
        Integer stockQuantity,
        Integer minStockLevel,
        StockStatus stockStatus
) {
    public static InventoryItemResponse from(SparePart part) {
        int stock = part.getStockQuantity() == null ? 0 : part.getStockQuantity();
        return new InventoryItemResponse(
                part.getId(), part.getWarehouseId(), part.getName(), part.getManufacturer(),
                part.getUnitPrice(), stock, part.getMinStockLevel(),
                StockStatus.of(stock, part.getMinStockLevel()));
    }
}
'@
Write-RepoFile 'backend/src/main/java/com/gara/quanlygara/dto/warehouse/InventoryPageResponse.java' @'
// TV3-TUAN8
package com.gara.quanlygara.dto.warehouse;

import java.util.List;

/** lowStockCount = số phụ tùng SAP_HET hoặc HET_HANG trên toàn danh mục (không phụ thuộc bộ lọc). */
public record InventoryPageResponse(
        List<InventoryItemResponse> items,
        int page,
        int size,
        long totalElements,
        int totalPages,
        long lowStockCount
) {
}
'@
Write-RepoFile 'backend/src/main/java/com/gara/quanlygara/dto/warehouse/StockMovementResponse.java' @'
// TV3-TUAN8
package com.gara.quanlygara.dto.warehouse;

import java.time.LocalDateTime;

/** Đồng thời là đích của truy vấn JPQL constructor trong StockMovementRepository. */
public record StockMovementResponse(
        Long id,
        Integer partId,
        String partName,
        Integer receiptId,
        Integer issueId,
        LocalDateTime time,
        String type,
        Integer quantity,
        Integer quantityBefore,
        Integer quantityAfter,
        String note
) {
}
'@
Write-RepoFile 'backend/src/main/java/com/gara/quanlygara/dto/warehouse/ImportRequest.java' @'
// TV3-TUAN8
package com.gara.quanlygara.dto.warehouse;

import jakarta.validation.Valid;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

/** Tạo phiếu nhập kèm chi tiết trong một transaction. importDate bỏ trống = thời điểm hiện tại. */
public record ImportRequest(
        @NotBlank(message = "Nhà cung cấp không được để trống.")
        @Size(max = 200, message = "Nhà cung cấp không được vượt quá 200 ký tự.")
        String supplier,

        LocalDateTime importDate,

        @Size(max = 500, message = "Ghi chú không được vượt quá 500 ký tự.")
        String note,

        @NotEmpty(message = "Phiếu nhập phải có ít nhất một phụ tùng.")
        @Valid
        List<Item> items
) {
    public record Item(
            @NotNull(message = "Vui lòng chọn phụ tùng.")
            @Positive(message = "Mã phụ tùng không hợp lệ.")
            Integer partId,

            @NotNull(message = "Số lượng không được để trống.")
            @Min(value = 1, message = "Số lượng nhập phải lớn hơn 0.")
            Integer quantity,

            @NotNull(message = "Đơn giá nhập không được để trống.")
            @DecimalMin(value = "0", message = "Đơn giá nhập không được âm.")
            @Digits(integer = 16, fraction = 2, message = "Đơn giá tối đa 2 chữ số thập phân.")
            BigDecimal unitPrice
    ) {
    }
}
'@
Write-RepoFile 'backend/src/main/java/com/gara/quanlygara/dto/warehouse/ImportResponse.java' @'
// TV3-TUAN8
package com.gara.quanlygara.dto.warehouse;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

public record ImportResponse(
        Integer id,
        LocalDateTime importDate,
        String supplier,
        Integer warehouseStaffId,
        String note,
        List<Item> items,
        BigDecimal totalAmount
) {
    public record Item(Integer partId, String partName, Integer quantity, BigDecimal unitPrice, BigDecimal lineTotal) {
    }
}
'@
Write-RepoFile 'backend/src/main/java/com/gara/quanlygara/dto/warehouse/IssueRequest.java' @'
// TV3-TUAN8
package com.gara.quanlygara.dto.warehouse;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

import java.util.List;

/** Cấp phát phụ tùng cho một phiếu sửa chữa. Tạo phiếu xuất KHÔNG giảm tồn. */
public record IssueRequest(
        @NotNull(message = "Vui lòng chọn phiếu sửa chữa.")
        @Positive(message = "Mã phiếu sửa chữa không hợp lệ.")
        Integer repairOrderId,

        @Positive(message = "Mã kỹ thuật viên không hợp lệ.")
        Integer requestedTechnicianId,

        @NotBlank(message = "Lý do không được để trống.")
        @Size(max = 500, message = "Lý do không được vượt quá 500 ký tự.")
        String reason,

        @NotEmpty(message = "Phiếu xuất phải có ít nhất một phụ tùng.")
        @Valid
        List<Item> items
) {
    public record Item(
            @NotNull(message = "Vui lòng chọn phụ tùng.")
            @Positive(message = "Mã phụ tùng không hợp lệ.")
            Integer partId,

            @NotNull(message = "Số lượng cấp phát không được để trống.")
            @Min(value = 1, message = "Số lượng cấp phát phải lớn hơn 0.")
            Integer quantity
    ) {
    }
}
'@
Write-RepoFile 'backend/src/main/java/com/gara/quanlygara/dto/warehouse/IssueResponse.java' @'
// TV3-TUAN8
package com.gara.quanlygara.dto.warehouse;

import java.time.LocalDateTime;
import java.util.List;

public record IssueResponse(
        Integer id,
        Integer repairOrderId,
        Integer warehouseStaffId,
        Integer requestedTechnicianId,
        LocalDateTime issueDate,
        String reason,
        List<Item> items
) {
    /**
     * state: CHO_XAC_NHAN (đã cấp phát, chờ KTV xác nhận thực dùng, CHƯA trừ tồn) hoặc DA_XAC_NHAN.
     * stockAfter chỉ có khi đã xác nhận thực dùng > 0 (lấy từ biến động kho XUAT).
     */
    public record Item(
            Integer partId,
            String partName,
            Integer issuedQuantity,
            java.math.BigDecimal unitPrice,
            String state,
            LocalDateTime confirmedAt,
            Integer confirmedTechnicianId,
            Integer actualUsedQuantity,
            Integer returnedQuantity,
            Integer stockAfter
    ) {
    }
}
'@
Write-RepoFile 'backend/src/main/java/com/gara/quanlygara/dto/warehouse/ConfirmUsageRequest.java' @'
// TV3-TUAN8
package com.gara.quanlygara.dto.warehouse;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;

/**
 * KTV xác nhận số lượng phụ tùng thực dùng (0 <= actualUsed <= số cấp phát).
 * technicianId: bắt buộc khi người gọi là ADMIN/MANAGER; tài khoản TECHNICIAN luôn là chính họ.
 */
public record ConfirmUsageRequest(
        @NotNull(message = "Số lượng thực dùng không được để trống.")
        @Min(value = 0, message = "Số lượng thực dùng không được âm.")
        Integer actualUsed,

        @Positive(message = "Mã kỹ thuật viên không hợp lệ.")
        Integer technicianId
) {
}
'@
Write-RepoFile 'backend/src/main/java/com/gara/quanlygara/dto/warehouse/CheckCreateRequest.java' @'
// TV3-TUAN8
package com.gara.quanlygara.dto.warehouse;

import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

import java.util.List;

/** Tạo phiên kiểm kê cho các phụ tùng được chọn; hệ thống chụp (snapshot) tồn hiện tại. */
public record CheckCreateRequest(
        @Size(max = 500, message = "Ghi chú không được vượt quá 500 ký tự.")
        String note,

        @NotEmpty(message = "Vui lòng chọn ít nhất một phụ tùng để kiểm kê.")
        @Size(max = 200, message = "Một phiên kiểm kê tối đa 200 phụ tùng.")
        List<@NotNull(message = "Mã phụ tùng không hợp lệ.") @Positive(message = "Mã phụ tùng không hợp lệ.") Integer> partIds
) {
}
'@
Write-RepoFile 'backend/src/main/java/com/gara/quanlygara/dto/warehouse/CheckActualRequest.java' @'
// TV3-TUAN8
package com.gara.quanlygara.dto.warehouse;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record CheckActualRequest(
        @NotNull(message = "Số lượng thực tế không được để trống.")
        @Min(value = 0, message = "Số lượng thực tế không được âm.")
        Integer actualQuantity,

        @Size(max = 500, message = "Nguyên nhân không được vượt quá 500 ký tự.")
        String reason
) {
}
'@
Write-RepoFile 'backend/src/main/java/com/gara/quanlygara/dto/warehouse/CheckDecisionRequest.java' @'
// TV3-TUAN8
package com.gara.quanlygara.dto.warehouse;

import jakarta.validation.constraints.Size;

/** Lý do duyệt/từ chối. Từ chối bắt buộc có lý do (kiểm tra ở service). */
public record CheckDecisionRequest(
        @Size(max = 500, message = "Lý do không được vượt quá 500 ký tự.")
        String reason
) {
}
'@
Write-RepoFile 'backend/src/main/java/com/gara/quanlygara/dto/warehouse/CheckResponse.java' @'
// TV3-TUAN8
package com.gara.quanlygara.dto.warehouse;

import java.time.LocalDateTime;
import java.util.List;

public record CheckResponse(
        Integer id,
        LocalDateTime checkDate,
        Integer createdBy,
        Integer approvedBy,
        LocalDateTime approvedAt,
        String status,
        String note,
        String decisionReason,
        List<Item> items
) {
    public record Item(
            Integer partId,
            String partName,
            Integer systemQuantity,
            Integer actualQuantity,
            Integer difference,
            String reason,
            boolean adjustmentApproved
    ) {
    }
}
'@
Write-RepoFile 'backend/src/main/java/com/gara/quanlygara/dto/warehouse/CheckSummaryResponse.java' @'
// TV3-TUAN8
package com.gara.quanlygara.dto.warehouse;

import java.time.LocalDateTime;

public record CheckSummaryResponse(
        Integer id,
        LocalDateTime checkDate,
        Integer createdBy,
        Integer approvedBy,
        String status,
        String note,
        int itemCount,
        int differenceCount
) {
}
'@
Write-RepoFile 'backend/src/main/java/com/gara/quanlygara/repository/StockMovementRepository.java' @'
// TV3-TUAN8
package com.gara.quanlygara.repository;

import com.gara.quanlygara.dto.warehouse.StockMovementResponse;
import com.gara.quanlygara.entity.StockMovement;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;

public interface StockMovementRepository extends JpaRepository<StockMovement, Long> {

    // partId = 0 và type = 'ALL' nghĩa là không lọc (tránh tham số null trong JPQL).
    @Query(value = "SELECT new com.gara.quanlygara.dto.warehouse.StockMovementResponse("
            + "m.id, m.partId, p.name, m.receiptId, m.issueId, m.movedAt, m.type, m.quantity, "
            + "m.quantityBefore, m.quantityAfter, m.note) "
            + "FROM StockMovement m, SparePart p "
            + "WHERE p.id = m.partId AND (:partId = 0 OR m.partId = :partId) "
            + "AND (:type = 'ALL' OR m.type = :type) ORDER BY m.id DESC",
            countQuery = "SELECT COUNT(m) FROM StockMovement m "
                    + "WHERE (:partId = 0 OR m.partId = :partId) AND (:type = 'ALL' OR m.type = :type)")
    Page<StockMovementResponse> search(@Param("partId") int partId, @Param("type") String type, Pageable pageable);

    Optional<StockMovement> findFirstByIssueIdAndPartIdAndTypeOrderByIdDesc(Integer issueId, Integer partId, String type);
}
'@
Write-RepoFile 'backend/src/main/java/com/gara/quanlygara/repository/StockReceiptRepository.java' @'
// TV3-TUAN8
package com.gara.quanlygara.repository;

import com.gara.quanlygara.entity.StockReceipt;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

public interface StockReceiptRepository extends JpaRepository<StockReceipt, Integer> {

    Page<StockReceipt> findAllByOrderByIdDesc(Pageable pageable);
}
'@
Write-RepoFile 'backend/src/main/java/com/gara/quanlygara/repository/StockReceiptItemRepository.java' @'
// TV3-TUAN8
package com.gara.quanlygara.repository;

import com.gara.quanlygara.entity.StockReceiptItem;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Collection;
import java.util.List;

public interface StockReceiptItemRepository extends JpaRepository<StockReceiptItem, StockReceiptItem.Key> {

    List<StockReceiptItem> findByReceiptId(Integer receiptId);

    List<StockReceiptItem> findByReceiptIdIn(Collection<Integer> receiptIds);
}
'@
Write-RepoFile 'backend/src/main/java/com/gara/quanlygara/repository/StockIssueRepository.java' @'
// TV3-TUAN8
package com.gara.quanlygara.repository;

import com.gara.quanlygara.entity.StockIssue;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Collection;
import java.util.List;

public interface StockIssueRepository extends JpaRepository<StockIssue, Integer> {

    Page<StockIssue> findAllByOrderByIdDesc(Pageable pageable);

    Page<StockIssue> findByIdInOrderByIdDesc(Collection<Integer> ids, Pageable pageable);

    // Phiếu xuất liên quan tới KTV: do họ yêu cầu hoặc họ được phân công cho phiếu sửa chữa (đọc bảng của Huy).
    @Query(value = "SELECT px.MaPhieuXuat FROM PhieuXuatKho px WHERE px.MaKyThuatVienYeuCau = :technicianId "
            + "OR EXISTS (SELECT 1 FROM PhanCongKyThuatVien pc WHERE pc.MaPhieuSuaChua = px.MaPhieuSuaChua "
            + "AND pc.MaKyThuatVien = :technicianId)", nativeQuery = true)
    List<Integer> findIdsRelatedToTechnician(@Param("technicianId") Integer technicianId);
}
'@
Write-RepoFile 'backend/src/main/java/com/gara/quanlygara/repository/StockIssueItemRepository.java' @'
// TV3-TUAN8
package com.gara.quanlygara.repository;

import com.gara.quanlygara.entity.StockIssueItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Collection;
import java.util.List;

public interface StockIssueItemRepository extends JpaRepository<StockIssueItem, StockIssueItem.Key> {

    List<StockIssueItem> findByIssueId(Integer issueId);

    List<StockIssueItem> findByIssueIdIn(Collection<Integer> issueIds);

    // Chỉ ĐỌC các bảng của module khác (Huy: PhanCongKyThuatVien; Trung: BaoGia).
    @Query(value = "SELECT COUNT(1) FROM PhanCongKyThuatVien WHERE MaPhieuSuaChua = :orderId "
            + "AND MaKyThuatVien = :technicianId", nativeQuery = true)
    long countAssignment(@Param("orderId") Integer orderId, @Param("technicianId") Integer technicianId);

    @Query(value = "SELECT COUNT(1) FROM BaoGia WHERE MaPhieuSuaChua = :orderId AND TrangThai = N'DA_XAC_NHAN'",
            nativeQuery = true)
    long countConfirmedQuotation(@Param("orderId") Integer orderId);

    // Số lượng đã cấp phát nhưng chưa xác nhận thực dùng (chưa trừ tồn): dùng để tính tồn khả dụng.
    @Query(value = "SELECT COALESCE(SUM(SoLuong), 0) FROM ChiTietPhieuXuat WHERE MaPhuTung = :partId "
            + "AND DaXacNhanSuDung = 0", nativeQuery = true)
    long sumPendingAllocation(@Param("partId") Integer partId);

    // Tổng thực dùng đã xác nhận của một phụ tùng trong một phiếu sửa chữa (qua mọi phiếu xuất).
    @Query(value = "SELECT COALESCE(SUM(ct.SoLuongThucDung), 0) FROM ChiTietPhieuXuat ct "
            + "JOIN PhieuXuatKho px ON px.MaPhieuXuat = ct.MaPhieuXuat "
            + "WHERE px.MaPhieuSuaChua = :orderId AND ct.MaPhuTung = :partId AND ct.DaXacNhanSuDung = 1",
            nativeQuery = true)
    long sumConfirmedActual(@Param("orderId") Integer orderId, @Param("partId") Integer partId);
}
'@
Write-RepoFile 'backend/src/main/java/com/gara/quanlygara/repository/InventoryCheckRepository.java' @'
// TV3-TUAN8
package com.gara.quanlygara.repository;

import com.gara.quanlygara.entity.InventoryCheck;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

public interface InventoryCheckRepository extends JpaRepository<InventoryCheck, Integer> {

    Page<InventoryCheck> findAllByOrderByIdDesc(Pageable pageable);
}
'@
Write-RepoFile 'backend/src/main/java/com/gara/quanlygara/repository/InventoryCheckItemRepository.java' @'
// TV3-TUAN8
package com.gara.quanlygara.repository;

import com.gara.quanlygara.entity.InventoryCheckItem;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Collection;
import java.util.List;

public interface InventoryCheckItemRepository extends JpaRepository<InventoryCheckItem, InventoryCheckItem.Key> {

    List<InventoryCheckItem> findByCheckIdOrderByPartId(Integer checkId);

    List<InventoryCheckItem> findByCheckIdIn(Collection<Integer> checkIds);
}
'@
Write-RepoFile 'backend/src/main/java/com/gara/quanlygara/service/StockLedger.java' @'
// TV3-TUAN8
package com.gara.quanlygara.service;

import com.gara.quanlygara.entity.StockMovement;
import com.gara.quanlygara.exception.ConflictException;
import com.gara.quanlygara.exception.ResourceNotFoundException;
import com.gara.quanlygara.repository.SparePartRepository;
import com.gara.quanlygara.repository.StockMovementRepository;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;

/**
 * Điểm DUY NHẤT trong ứng dụng ghi SoLuongTon và BienDongKho.
 * Luôn khóa dòng phụ tùng (UPDLOCK) trước khi đọc tồn, rồi mới ghi tồn mới + biến động trong cùng transaction
 * của service gọi (rollback toàn bộ nếu một bước lỗi).
 */
@Component
public class StockLedger {

    public static final String IN = "NHAP";
    public static final String OUT = "XUAT";
    public static final String COUNT = "KIEM_KE";

    private final SparePartRepository sparePartRepository;
    private final StockMovementRepository movementRepository;

    public StockLedger(SparePartRepository sparePartRepository, StockMovementRepository movementRepository) {
        this.sparePartRepository = sparePartRepository;
        this.movementRepository = movementRepository;
    }

    /** Khóa dòng phụ tùng cho tới hết transaction và trả về tồn hiện tại. */
    public int lock(Integer partId) {
        return sparePartRepository.lockStockQuantity(partId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy phụ tùng."));
    }

    /** Đặt tồn mới và ghi một dòng BienDongKho. quantity là số lượng của biến động (theo CK_BienDongKho_SoLuong). */
    public StockMovement apply(
            Integer partId, int before, int after, String type, int quantity,
            Integer receiptId, Integer issueId, String note
    ) {
        if (after < 0) {
            throw new ConflictException("Số lượng tồn kho không đủ.");
        }
        if (sparePartRepository.updateStockQuantity(partId, after) != 1) {
            throw new ConflictException("Không thể cập nhật tồn kho của phụ tùng " + partId + ".");
        }

        StockMovement movement = new StockMovement();
        movement.setPartId(partId);
        movement.setReceiptId(receiptId);
        movement.setIssueId(issueId);
        movement.setMovedAt(LocalDateTime.now());
        movement.setType(type);
        movement.setQuantity(quantity);
        movement.setQuantityBefore(before);
        movement.setQuantityAfter(after);
        movement.setNote(note);
        return movementRepository.save(movement);
    }
}
'@
Write-RepoFile 'backend/src/main/java/com/gara/quanlygara/security/StaffContext.java' @'
// TV3-TUAN8
package com.gara.quanlygara.security;

import com.gara.quanlygara.entity.Account;
import com.gara.quanlygara.entity.AccountRole;
import com.gara.quanlygara.exception.BadRequestException;
import com.gara.quanlygara.repository.AccountRepository;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Component;

/** Xác định nhân viên (MaNhanVien) và vai trò của tài khoản đang đăng nhập, từ JWT hiện có. */
@Component
public class StaffContext {

    private final AccountRepository accountRepository;

    public StaffContext(AccountRepository accountRepository) {
        this.accountRepository = accountRepository;
    }

    public Account account(Authentication authentication) {
        if (authentication == null) throw new AccessDeniedException("Chưa đăng nhập.");
        return accountRepository.findByUsername(authentication.getName())
                .orElseThrow(() -> new AccessDeniedException("Không xác định được tài khoản."));
    }

    public Integer employeeId(Authentication authentication) {
        Integer employeeId = account(authentication).getEmployeeId();
        if (employeeId == null) {
            throw new BadRequestException("Tài khoản chưa được liên kết với nhân viên.");
        }
        return employeeId;
    }

    public boolean isTechnician(Authentication authentication) {
        return account(authentication).getRole() == AccountRole.TECHNICIAN;
    }
}
'@
Write-RepoFile 'backend/src/main/java/com/gara/quanlygara/service/InventoryService.java' @'
// TV3-TUAN8
package com.gara.quanlygara.service;

import com.gara.quanlygara.dto.warehouse.InventoryItemResponse;
import com.gara.quanlygara.dto.warehouse.InventoryPageResponse;
import com.gara.quanlygara.dto.warehouse.PageResponse;
import com.gara.quanlygara.dto.warehouse.StockMovementResponse;
import com.gara.quanlygara.dto.warehouse.StockStatus;
import com.gara.quanlygara.entity.SparePart;
import com.gara.quanlygara.exception.BadRequestException;
import com.gara.quanlygara.repository.SparePartRepository;
import com.gara.quanlygara.repository.StockMovementRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Locale;
import java.util.Set;

/** Tồn kho (chỉ đọc) và lịch sử biến động. Không ghi tồn ở đây. */
@Service
public class InventoryService {

    private static final int MAX_PAGE_SIZE = 100;
    private static final Set<String> MOVEMENT_TYPES = Set.of("NHAP", "XUAT", "KIEM_KE");

    private final SparePartRepository sparePartRepository;
    private final StockMovementRepository movementRepository;

    public InventoryService(SparePartRepository sparePartRepository, StockMovementRepository movementRepository) {
        this.sparePartRepository = sparePartRepository;
        this.movementRepository = movementRepository;
    }

    @Transactional(readOnly = true)
    public InventoryPageResponse getStock(int page, int size, String search, String status) {
        Pageable pageable = pageable(page, size, Sort.by("name").and(Sort.by("id")));
        String keyword = search == null ? "" : search.trim();
        Page<SparePart> result = sparePartRepository.searchInventory(keyword, normalizeStatus(status), pageable);

        return new InventoryPageResponse(
                result.getContent().stream().map(InventoryItemResponse::from).toList(),
                result.getNumber(), result.getSize(), result.getTotalElements(), result.getTotalPages(),
                sparePartRepository.countAtOrBelowMinimum());
    }

    @Transactional(readOnly = true)
    public PageResponse<StockMovementResponse> getMovements(int page, int size, Integer partId, String type) {
        String normalizedType = "ALL";
        if (type != null && !type.isBlank() && !type.trim().equalsIgnoreCase("ALL")) {
            normalizedType = type.trim().toUpperCase(Locale.ROOT);
            if (!MOVEMENT_TYPES.contains(normalizedType)) {
                throw new BadRequestException("Loại biến động không hợp lệ.");
            }
        }
        Pageable pageable = pageable(page, size, Sort.unsorted());
        return PageResponse.of(movementRepository.search(partId == null ? 0 : partId, normalizedType, pageable));
    }

    private String normalizeStatus(String status) {
        if (status == null || status.isBlank() || status.trim().equalsIgnoreCase("ALL")) return "ALL";
        try {
            return StockStatus.valueOf(status.trim().toUpperCase(Locale.ROOT)).name();
        } catch (IllegalArgumentException exception) {
            throw new BadRequestException("Trạng thái tồn kho không hợp lệ.");
        }
    }

    private Pageable pageable(int page, int size, Sort sort) {
        return PageRequest.of(Math.max(page, 0), Math.min(Math.max(size, 1), MAX_PAGE_SIZE), sort);
    }
}
'@
Write-RepoFile 'backend/src/main/java/com/gara/quanlygara/service/StockReceiptService.java' @'
// TV3-TUAN8
package com.gara.quanlygara.service;

import com.gara.quanlygara.dto.warehouse.ImportRequest;
import com.gara.quanlygara.dto.warehouse.ImportResponse;
import com.gara.quanlygara.dto.warehouse.PageResponse;
import com.gara.quanlygara.entity.SparePart;
import com.gara.quanlygara.entity.StockReceipt;
import com.gara.quanlygara.entity.StockReceiptItem;
import com.gara.quanlygara.exception.BadRequestException;
import com.gara.quanlygara.exception.ResourceNotFoundException;
import com.gara.quanlygara.repository.SparePartRepository;
import com.gara.quanlygara.repository.StockReceiptItemRepository;
import com.gara.quanlygara.repository.StockReceiptRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Nhập kho: một ChiTietPhieuNhap = một lần tăng tồn (cùng ngữ nghĩa dbo.sp_ThemChiTietPhieuNhap).
 * Phiếu và các chi tiết được tạo trong một transaction; một dòng lỗi thì rollback toàn bộ.
 */
@Service
public class StockReceiptService {

    private static final int MAX_PAGE_SIZE = 100;

    private final StockReceiptRepository receiptRepository;
    private final StockReceiptItemRepository itemRepository;
    private final SparePartRepository sparePartRepository;
    private final StockLedger ledger;

    public StockReceiptService(
            StockReceiptRepository receiptRepository,
            StockReceiptItemRepository itemRepository,
            SparePartRepository sparePartRepository,
            StockLedger ledger
    ) {
        this.receiptRepository = receiptRepository;
        this.itemRepository = itemRepository;
        this.sparePartRepository = sparePartRepository;
        this.ledger = ledger;
    }

    @Transactional
    public ImportResponse create(ImportRequest request, Integer warehouseStaffId) {
        Set<Integer> seen = new HashSet<>();
        for (ImportRequest.Item item : request.items()) {
            if (!seen.add(item.partId())) {
                throw new BadRequestException("Phụ tùng " + item.partId() + " bị trùng trong phiếu nhập.");
            }
        }

        // Khóa theo thứ tự mã phụ tùng để tránh deadlock giữa các phiếu đồng thời.
        List<ImportRequest.Item> ordered = request.items().stream()
                .sorted(Comparator.comparing(ImportRequest.Item::partId)).toList();
        Map<Integer, String> names = new HashMap<>();
        for (ImportRequest.Item item : ordered) {
            SparePart part = sparePartRepository.findById(item.partId())
                    .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy phụ tùng " + item.partId() + "."));
            names.put(part.getId(), part.getName());
        }

        StockReceipt receipt = new StockReceipt();
        receipt.setReceiptDate(request.importDate() != null ? request.importDate() : LocalDateTime.now());
        receipt.setSupplier(request.supplier().trim());
        receipt.setWarehouseStaffId(warehouseStaffId);
        receipt.setNote(normalizeOptional(request.note()));
        receipt = receiptRepository.saveAndFlush(receipt);

        for (ImportRequest.Item item : ordered) {
            int before = ledger.lock(item.partId());
            int after;
            try {
                after = Math.addExact(before, item.quantity());
            } catch (ArithmeticException exception) {
                throw new BadRequestException("Số lượng nhập vượt giới hạn tồn kho.");
            }

            StockReceiptItem detail = new StockReceiptItem();
            detail.setReceiptId(receipt.getId());
            detail.setPartId(item.partId());
            detail.setQuantity(item.quantity());
            detail.setUnitPrice(item.unitPrice().setScale(2, RoundingMode.HALF_UP));
            itemRepository.save(detail);

            // Mỗi chi tiết nhập chỉ tăng tồn đúng một lần.
            ledger.apply(item.partId(), before, after, StockLedger.IN, item.quantity(),
                    receipt.getId(), null, "Nhập kho theo phiếu nhập");
        }
        return toResponse(receipt, itemRepository.findByReceiptId(receipt.getId()), names);
    }

    @Transactional(readOnly = true)
    public ImportResponse get(Integer id) {
        StockReceipt receipt = receiptRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy phiếu nhập kho."));
        List<StockReceiptItem> items = itemRepository.findByReceiptId(id);
        return toResponse(receipt, items, partNames(items));
    }

    @Transactional(readOnly = true)
    public PageResponse<ImportResponse> getAll(int page, int size) {
        Page<StockReceipt> receipts = receiptRepository.findAllByOrderByIdDesc(
                PageRequest.of(Math.max(page, 0), Math.min(Math.max(size, 1), MAX_PAGE_SIZE)));
        List<Integer> ids = receipts.getContent().stream().map(StockReceipt::getId).toList();
        List<StockReceiptItem> allItems = ids.isEmpty() ? List.of() : itemRepository.findByReceiptIdIn(ids);
        Map<Integer, String> names = partNames(allItems);
        Map<Integer, List<StockReceiptItem>> byReceipt = allItems.stream()
                .collect(Collectors.groupingBy(StockReceiptItem::getReceiptId));
        return PageResponse.of(receipts, receipt ->
                toResponse(receipt, byReceipt.getOrDefault(receipt.getId(), List.of()), names));
    }

    private Map<Integer, String> partNames(List<StockReceiptItem> items) {
        Set<Integer> ids = items.stream().map(StockReceiptItem::getPartId).collect(Collectors.toSet());
        Map<Integer, String> names = new HashMap<>();
        if (!ids.isEmpty()) {
            sparePartRepository.findAllById(ids).forEach(part -> names.put(part.getId(), part.getName()));
        }
        return names;
    }

    private ImportResponse toResponse(StockReceipt receipt, List<StockReceiptItem> items, Map<Integer, String> names) {
        List<ImportResponse.Item> lines = items.stream()
                .sorted(Comparator.comparing(StockReceiptItem::getPartId))
                .map(item -> new ImportResponse.Item(
                        item.getPartId(), names.getOrDefault(item.getPartId(), "Phụ tùng " + item.getPartId()),
                        item.getQuantity(), item.getUnitPrice(),
                        item.getUnitPrice().multiply(BigDecimal.valueOf(item.getQuantity())).setScale(2, RoundingMode.HALF_UP)))
                .toList();
        BigDecimal total = lines.stream().map(ImportResponse.Item::lineTotal)
                .reduce(BigDecimal.ZERO.setScale(2), BigDecimal::add);
        return new ImportResponse(receipt.getId(), receipt.getReceiptDate(), receipt.getSupplier(),
                receipt.getWarehouseStaffId(), receipt.getNote(), lines, total);
    }

    private String normalizeOptional(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }
}
'@
Write-RepoFile 'backend/src/main/java/com/gara/quanlygara/service/StockIssueService.java' @'
// TV3-TUAN8
package com.gara.quanlygara.service;

import com.gara.quanlygara.dto.warehouse.ConfirmUsageRequest;
import com.gara.quanlygara.dto.warehouse.IssueRequest;
import com.gara.quanlygara.dto.warehouse.IssueResponse;
import com.gara.quanlygara.dto.warehouse.PageResponse;
import com.gara.quanlygara.entity.RepairPartItem;
import com.gara.quanlygara.entity.SparePart;
import com.gara.quanlygara.entity.StockIssue;
import com.gara.quanlygara.entity.StockIssueItem;
import com.gara.quanlygara.exception.BadRequestException;
import com.gara.quanlygara.exception.ConflictException;
import com.gara.quanlygara.exception.ResourceNotFoundException;
import com.gara.quanlygara.repository.RepairPartItemRepository;
import com.gara.quanlygara.repository.RepairServiceItemRepository;
import com.gara.quanlygara.repository.SparePartRepository;
import com.gara.quanlygara.repository.StockIssueItemRepository;
import com.gara.quanlygara.repository.StockIssueRepository;
import com.gara.quanlygara.repository.StockMovementRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Xuất kho = cấp phát phụ tùng cho phiếu sửa chữa.
 *  - Tạo phiếu xuất: kiểm tra tồn khả dụng, ghi số lượng cấp phát, KHÔNG giảm tồn, KHÔNG ghi biến động.
 *  - KTV xác nhận thực dùng (0..cấp phát): đây là thao tác DUY NHẤT giảm tồn, theo số lượng thực dùng;
 *    phần còn lại (cấp phát - thực dùng) là hoàn trả. Cùng quy tắc với dbo.sp_XacNhanSuDungPhuTung.
 */
@Service
public class StockIssueService {

    public static final String PENDING = "CHO_XAC_NHAN";
    public static final String CONFIRMED = "DA_XAC_NHAN";

    // Cùng điều kiện với dbo.sp_XacNhanSuDungPhuTung (lỗi 50016).
    private static final Set<String> ISSUABLE_ORDER_STATUSES = Set.of("DANG_SUA", "CHO_PHU_TUNG");
    private static final int MAX_PAGE_SIZE = 100;

    private final StockIssueRepository issueRepository;
    private final StockIssueItemRepository itemRepository;
    private final SparePartRepository sparePartRepository;
    private final StockMovementRepository movementRepository;
    private final RepairPartItemRepository repairPartItemRepository;
    private final RepairServiceItemRepository repairServiceItemRepository;
    private final StockLedger ledger;

    public StockIssueService(
            StockIssueRepository issueRepository,
            StockIssueItemRepository itemRepository,
            SparePartRepository sparePartRepository,
            StockMovementRepository movementRepository,
            RepairPartItemRepository repairPartItemRepository,
            RepairServiceItemRepository repairServiceItemRepository,
            StockLedger ledger
    ) {
        this.issueRepository = issueRepository;
        this.itemRepository = itemRepository;
        this.sparePartRepository = sparePartRepository;
        this.movementRepository = movementRepository;
        this.repairPartItemRepository = repairPartItemRepository;
        this.repairServiceItemRepository = repairServiceItemRepository;
        this.ledger = ledger;
    }

    @Transactional
    public IssueResponse create(IssueRequest request, Integer warehouseStaffId) {
        Set<Integer> seen = new HashSet<>();
        for (IssueRequest.Item item : request.items()) {
            if (!seen.add(item.partId())) {
                throw new BadRequestException("Phụ tùng " + item.partId() + " bị trùng trong phiếu xuất.");
            }
        }

        String orderStatus = repairServiceItemRepository.findRepairOrderStatus(request.repairOrderId())
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy phiếu sửa chữa."));
        if (orderStatus == null || !ISSUABLE_ORDER_STATUSES.contains(orderStatus.trim())) {
            throw new ConflictException("Phiếu sửa chữa không ở trạng thái cho phép cấp phát phụ tùng.");
        }
        if (request.requestedTechnicianId() != null
                && itemRepository.countAssignment(request.repairOrderId(), request.requestedTechnicianId()) == 0) {
            throw new ConflictException("Kỹ thuật viên chưa được phân công cho phiếu sửa chữa này.");
        }

        List<IssueRequest.Item> ordered = request.items().stream()
                .sorted(Comparator.comparing(IssueRequest.Item::partId)).toList();
        Map<Integer, SparePart> parts = new HashMap<>();
        for (IssueRequest.Item item : ordered) {
            SparePart part = sparePartRepository.findById(item.partId())
                    .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy phụ tùng " + item.partId() + "."));
            parts.put(part.getId(), part);
        }

        // Kiểm tra tồn khả dụng = tồn - phần đã cấp phát chưa xác nhận. Khóa dòng phụ tùng để tuần tự hóa các phiếu đồng thời.
        for (IssueRequest.Item item : ordered) {
            int stock = ledger.lock(item.partId());
            long pending = itemRepository.sumPendingAllocation(item.partId());
            long available = stock - pending;
            if (available < item.quantity()) {
                throw new ConflictException("Không đủ tồn khả dụng cho '" + parts.get(item.partId()).getName()
                        + "': tồn " + stock + ", đã cấp phát chờ xác nhận " + pending
                        + ", yêu cầu " + item.quantity() + ".");
            }
        }

        StockIssue issue = new StockIssue();
        issue.setRepairOrderId(request.repairOrderId());
        issue.setWarehouseStaffId(warehouseStaffId);
        issue.setRequestedTechnicianId(request.requestedTechnicianId());
        issue.setIssueDate(LocalDateTime.now());
        issue.setReason(request.reason().trim());
        issue = issueRepository.saveAndFlush(issue);

        for (IssueRequest.Item item : ordered) {
            StockIssueItem detail = new StockIssueItem();
            detail.setIssueId(issue.getId());
            detail.setPartId(item.partId());
            detail.setQuantity(item.quantity());
            detail.setUnitPrice(parts.get(item.partId()).getUnitPrice());
            detail.setConfirmed(false);
            itemRepository.save(detail);
        }
        // Không gọi ledger.apply: cấp phát KHÔNG giảm tồn và không ghi BienDongKho.
        return toResponse(issue, itemRepository.findByIssueId(issue.getId()), names(parts));
    }

    @Transactional
    public IssueResponse.Item confirmUsage(
            Integer issueId, Integer partId, ConfirmUsageRequest request,
            Integer callerEmployeeId, boolean callerIsTechnician
    ) {
        StockIssueItem item = itemRepository.findById(new StockIssueItem.Key(issueId, partId))
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy chi tiết phiếu xuất."));
        if (item.isConfirmed()) {
            throw new ConflictException("Phụ tùng này đã được xác nhận sử dụng.");
        }
        StockIssue issue = issueRepository.findById(issueId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy phiếu xuất kho."));
        Integer orderId = issue.getRepairOrderId();
        if (orderId == null) {
            throw new ConflictException("Phiếu xuất này không gắn với phiếu sửa chữa.");
        }

        Integer technicianId = resolveTechnician(request, callerEmployeeId, callerIsTechnician);
        if (itemRepository.countAssignment(orderId, technicianId) == 0) {
            throw new ConflictException("Kỹ thuật viên không được phân công cho phiếu sửa chữa này.");
        }
        if (itemRepository.countConfirmedQuotation(orderId) == 0) {
            throw new ConflictException("Báo giá chưa được khách hàng xác nhận.");
        }
        String orderStatus = repairServiceItemRepository.findRepairOrderStatus(orderId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy phiếu sửa chữa."));
        if (orderStatus == null || !ISSUABLE_ORDER_STATUSES.contains(orderStatus.trim())) {
            throw new ConflictException("Phiếu sửa chữa không ở trạng thái cho phép xác nhận sử dụng phụ tùng.");
        }

        int issued = item.getQuantity();
        int actual = request.actualUsed();
        if (actual < 0 || actual > issued) {
            throw new BadRequestException("Số lượng thực dùng phải từ 0 đến số lượng cấp phát (" + issued + ").");
        }

        Integer stockAfter = null;
        if (actual > 0) {
            int before = ledger.lock(partId);
            if (before < actual) {
                throw new ConflictException("Số lượng tồn kho không đủ để xác nhận sử dụng.");
            }
            stockAfter = before - actual;
            // Tồn giảm theo SỐ LƯỢNG THỰC DÙNG, không phải số cấp phát.
            ledger.apply(partId, before, stockAfter, StockLedger.OUT, actual, null, issueId,
                    "KTV xác nhận thực dùng " + actual + "/" + issued + " (hoàn trả " + (issued - actual) + ")");
        }

        item.setConfirmed(true);
        item.setConfirmedAt(LocalDateTime.now());
        item.setConfirmedTechnicianId(technicianId);
        item.setActualUsedQuantity(actual);
        item.setReturnedQuantity(issued - actual);
        itemRepository.saveAndFlush(item);

        syncRepairPartLine(orderId, partId, item);

        SparePart part = sparePartRepository.findById(partId).orElse(null);
        return toItem(item, part == null ? "Phụ tùng " + partId : part.getName(), stockAfter);
    }

    @Transactional(readOnly = true)
    public IssueResponse get(Integer id) {
        StockIssue issue = issueRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy phiếu xuất kho."));
        List<StockIssueItem> items = itemRepository.findByIssueId(id);
        return toResponse(issue, items, partNames(items));
    }

    /** technicianId = 0: tất cả phiếu; khác 0: chỉ phiếu liên quan tới kỹ thuật viên đó. */
    @Transactional(readOnly = true)
    public PageResponse<IssueResponse> getAll(int page, int size, int technicianId) {
        PageRequest pageable = PageRequest.of(Math.max(page, 0), Math.min(Math.max(size, 1), MAX_PAGE_SIZE));
        Page<StockIssue> issues;
        if (technicianId == 0) {
            issues = issueRepository.findAllByOrderByIdDesc(pageable);
        } else {
            List<Integer> ids = issueRepository.findIdsRelatedToTechnician(technicianId);
            if (ids.isEmpty()) {
                return new PageResponse<>(List.of(), pageable.getPageNumber(), pageable.getPageSize(), 0, 0);
            }
            issues = issueRepository.findByIdInOrderByIdDesc(ids, pageable);
        }

        List<Integer> issueIds = issues.getContent().stream().map(StockIssue::getId).toList();
        List<StockIssueItem> allItems = issueIds.isEmpty() ? List.of() : itemRepository.findByIssueIdIn(issueIds);
        Map<Integer, String> names = partNames(allItems);
        Map<Integer, List<StockIssueItem>> byIssue = allItems.stream()
                .collect(Collectors.groupingBy(StockIssueItem::getIssueId));
        return PageResponse.of(issues, issue ->
                toResponse(issue, byIssue.getOrDefault(issue.getId(), List.of()), names));
    }

    private Integer resolveTechnician(ConfirmUsageRequest request, Integer callerEmployeeId, boolean callerIsTechnician) {
        if (callerIsTechnician) {
            if (request.technicianId() != null && !request.technicianId().equals(callerEmployeeId)) {
                throw new AccessDeniedException("Kỹ thuật viên chỉ được xác nhận với tài khoản của chính mình.");
            }
            return callerEmployeeId;
        }
        if (request.technicianId() == null) {
            throw new BadRequestException("Vui lòng chọn kỹ thuật viên xác nhận.");
        }
        return request.technicianId();
    }

    /**
     * ChiTietPhuTung.SoLuong của (phiếu sửa chữa, phụ tùng) = tổng số lượng THỰC DÙNG đã xác nhận
     * (không phải số cấp phát), đồng thời thay thế số lượng dự kiến do người dùng nhập ở Tuần 7.
     * Nếu tổng thực dùng = 0 thì không đụng tới dòng sẵn có (ràng buộc SoLuong > 0, và không xóa dữ liệu người dùng).
     */
    private void syncRepairPartLine(Integer orderId, Integer partId, StockIssueItem item) {
        long total = itemRepository.sumConfirmedActual(orderId, partId);
        if (total <= 0) return;

        BigDecimal unitPrice = item.getUnitPrice();
        if (unitPrice == null) {
            unitPrice = sparePartRepository.findById(partId).map(SparePart::getUnitPrice).orElse(null);
        }
        if (unitPrice == null) {
            throw new ConflictException("Không xác định được đơn giá phụ tùng.");
        }

        RepairPartItem line = repairPartItemRepository.findById(new RepairPartItem.Key(orderId, partId))
                .orElseGet(() -> {
                    RepairPartItem created = new RepairPartItem();
                    created.setRepairOrderId(orderId);
                    created.setSparePartId(partId);
                    return created;
                });
        line.setQuantity((int) total);
        line.setUnitPrice(unitPrice.setScale(2, RoundingMode.HALF_UP));
        repairPartItemRepository.saveAndFlush(line);
    }

    private Map<Integer, String> names(Map<Integer, SparePart> parts) {
        Map<Integer, String> names = new HashMap<>();
        parts.forEach((id, part) -> names.put(id, part.getName()));
        return names;
    }

    private Map<Integer, String> partNames(List<StockIssueItem> items) {
        Set<Integer> ids = items.stream().map(StockIssueItem::getPartId).collect(Collectors.toSet());
        Map<Integer, String> names = new HashMap<>();
        if (!ids.isEmpty()) {
            sparePartRepository.findAllById(ids).forEach(part -> names.put(part.getId(), part.getName()));
        }
        return names;
    }

    private IssueResponse toResponse(StockIssue issue, List<StockIssueItem> items, Map<Integer, String> names) {
        List<IssueResponse.Item> lines = items.stream()
                .sorted(Comparator.comparing(StockIssueItem::getPartId))
                .map(item -> toItem(item, names.getOrDefault(item.getPartId(), "Phụ tùng " + item.getPartId()),
                        stockAfter(item)))
                .toList();
        return new IssueResponse(issue.getId(), issue.getRepairOrderId(), issue.getWarehouseStaffId(),
                issue.getRequestedTechnicianId(), issue.getIssueDate(), issue.getReason(), lines);
    }

    private Integer stockAfter(StockIssueItem item) {
        if (!item.isConfirmed() || item.getActualUsedQuantity() == null || item.getActualUsedQuantity() == 0) return null;
        return movementRepository
                .findFirstByIssueIdAndPartIdAndTypeOrderByIdDesc(item.getIssueId(), item.getPartId(), StockLedger.OUT)
                .map(movement -> movement.getQuantityAfter())
                .orElse(null);
    }

    private IssueResponse.Item toItem(StockIssueItem item, String partName, Integer stockAfter) {
        return new IssueResponse.Item(
                item.getPartId(), partName, item.getQuantity(), item.getUnitPrice(),
                item.isConfirmed() ? CONFIRMED : PENDING, item.getConfirmedAt(), item.getConfirmedTechnicianId(),
                item.getActualUsedQuantity(), item.getReturnedQuantity(), stockAfter);
    }
}
'@
Write-RepoFile 'backend/src/main/java/com/gara/quanlygara/service/InventoryCheckService.java' @'
// TV3-TUAN8
package com.gara.quanlygara.service;

import com.gara.quanlygara.dto.warehouse.CheckActualRequest;
import com.gara.quanlygara.dto.warehouse.CheckCreateRequest;
import com.gara.quanlygara.dto.warehouse.CheckResponse;
import com.gara.quanlygara.dto.warehouse.CheckSummaryResponse;
import com.gara.quanlygara.dto.warehouse.PageResponse;
import com.gara.quanlygara.entity.InventoryCheck;
import com.gara.quanlygara.entity.InventoryCheckItem;
import com.gara.quanlygara.entity.SparePart;
import com.gara.quanlygara.exception.BadRequestException;
import com.gara.quanlygara.exception.ConflictException;
import com.gara.quanlygara.exception.ResourceNotFoundException;
import com.gara.quanlygara.repository.InventoryCheckItemRepository;
import com.gara.quanlygara.repository.InventoryCheckRepository;
import com.gara.quanlygara.repository.SparePartRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Kiểm kê có phê duyệt:
 *   tạo phiên (snapshot tồn) -> nhập tồn thực tế -> tính chênh lệch
 *   -> mọi chênh lệch = 0: DA_HOAN_TAT; có chênh lệch: CHO_PHE_DUYET.
 * Tồn kho CHỈ đổi khi MANAGER phê duyệt (approve). Nhập thực tế/từ chối không bao giờ đổi tồn.
 */
@Service
public class InventoryCheckService {

    private static final int MAX_PAGE_SIZE = 100;

    private final InventoryCheckRepository checkRepository;
    private final InventoryCheckItemRepository itemRepository;
    private final SparePartRepository sparePartRepository;
    private final StockLedger ledger;

    public InventoryCheckService(
            InventoryCheckRepository checkRepository,
            InventoryCheckItemRepository itemRepository,
            SparePartRepository sparePartRepository,
            StockLedger ledger
    ) {
        this.checkRepository = checkRepository;
        this.itemRepository = itemRepository;
        this.sparePartRepository = sparePartRepository;
        this.ledger = ledger;
    }

    @Transactional
    public CheckResponse create(CheckCreateRequest request, Integer staffId) {
        Set<Integer> seen = new HashSet<>();
        for (Integer partId : request.partIds()) {
            if (!seen.add(partId)) {
                throw new BadRequestException("Phụ tùng " + partId + " bị trùng trong phiên kiểm kê.");
            }
        }
        List<Integer> ordered = request.partIds().stream().sorted().toList();
        for (Integer partId : ordered) {
            if (!sparePartRepository.existsById(partId)) {
                throw new ResourceNotFoundException("Không tìm thấy phụ tùng " + partId + ".");
            }
        }

        InventoryCheck check = new InventoryCheck();
        check.setCheckDate(LocalDateTime.now());
        check.setCreatedBy(staffId);
        check.setStatus(InventoryCheck.COUNTING);
        check.setNote(request.note() == null || request.note().isBlank() ? null : request.note().trim());
        check = checkRepository.saveAndFlush(check);

        for (Integer partId : ordered) {
            InventoryCheckItem item = new InventoryCheckItem();
            item.setCheckId(check.getId());
            item.setPartId(partId);
            item.setSystemQuantity(ledger.lock(partId)); // snapshot tồn hệ thống
            item.setAdjustmentApproved(false);
            itemRepository.save(item);
        }
        return get(check.getId());
    }

    /** Nhập tồn thực tế cho một phụ tùng; khi đã nhập đủ thì phiên tự chuyển trạng thái. Không đổi tồn. */
    @Transactional
    public CheckResponse setActual(Integer checkId, Integer partId, CheckActualRequest request) {
        InventoryCheck check = findCheck(checkId);
        if (!InventoryCheck.COUNTING.equals(check.getStatus())) {
            throw new ConflictException("Phiên kiểm kê không còn ở trạng thái đang kiểm kê.");
        }
        InventoryCheckItem item = itemRepository.findById(new InventoryCheckItem.Key(checkId, partId))
                .orElseThrow(() -> new ResourceNotFoundException("Phụ tùng không thuộc phiên kiểm kê này."));
        if (request.actualQuantity() == null || request.actualQuantity() < 0) {
            throw new BadRequestException("Số lượng thực tế không được âm.");
        }
        item.setActualQuantity(request.actualQuantity());
        item.setReason(request.reason() == null || request.reason().isBlank() ? null : request.reason().trim());
        itemRepository.saveAndFlush(item);

        List<InventoryCheckItem> items = itemRepository.findByCheckIdOrderByPartId(checkId);
        if (items.stream().allMatch(i -> i.getActualQuantity() != null)) {
            boolean hasDifference = items.stream().anyMatch(i -> i.difference() != 0);
            check.setStatus(hasDifference ? InventoryCheck.PENDING_APPROVAL : InventoryCheck.COMPLETED);
            checkRepository.saveAndFlush(check);
        }
        return get(checkId);
    }

    /** Chỉ MANAGER (kiểm tra ở controller): mới đặt tồn = thực tế và ghi biến động KIEM_KE. */
    @Transactional
    public CheckResponse approve(Integer checkId, String reason, Integer approverId) {
        InventoryCheck check = findCheck(checkId);
        requirePendingApproval(check);
        List<InventoryCheckItem> items = itemRepository.findByCheckIdOrderByPartId(checkId);
        Map<Integer, String> names = partNames(items);

        for (InventoryCheckItem item : items) {
            Integer difference = item.difference();
            if (difference == null || difference == 0) continue;

            int current = ledger.lock(item.getPartId());
            if (current != item.getSystemQuantity()) {
                throw new ConflictException("Tồn kho của '" + names.get(item.getPartId())
                        + "' đã thay đổi kể từ lúc kiểm kê (hệ thống " + item.getSystemQuantity()
                        + ", hiện tại " + current + "). Hãy tạo phiên kiểm kê mới.");
            }
            ledger.apply(item.getPartId(), current, item.getActualQuantity(), StockLedger.COUNT,
                    Math.abs(difference), null, null, "Điều chỉnh tồn sau kiểm kê #" + checkId);
            item.setAdjustmentApproved(true);
            itemRepository.save(item);
        }

        check.setStatus(InventoryCheck.COMPLETED);
        check.setApprovedBy(approverId);
        check.setApprovedAt(LocalDateTime.now());
        check.setDecisionReason(normalize(reason));
        checkRepository.saveAndFlush(check);
        return get(checkId);
    }

    /** Từ chối: tồn không đổi; giữ lý do và trạng thái DA_TU_CHOI. */
    @Transactional
    public CheckResponse reject(Integer checkId, String reason, Integer approverId) {
        InventoryCheck check = findCheck(checkId);
        requirePendingApproval(check);
        String normalized = normalize(reason);
        if (normalized == null) {
            throw new BadRequestException("Vui lòng nhập lý do từ chối.");
        }
        check.setStatus(InventoryCheck.REJECTED);
        check.setApprovedBy(approverId);
        check.setApprovedAt(LocalDateTime.now());
        check.setDecisionReason(normalized);
        checkRepository.saveAndFlush(check);
        return get(checkId);
    }

    @Transactional(readOnly = true)
    public CheckResponse get(Integer checkId) {
        InventoryCheck check = findCheck(checkId);
        List<InventoryCheckItem> items = itemRepository.findByCheckIdOrderByPartId(checkId);
        Map<Integer, String> names = partNames(items);
        List<CheckResponse.Item> lines = items.stream()
                .map(item -> new CheckResponse.Item(
                        item.getPartId(), names.getOrDefault(item.getPartId(), "Phụ tùng " + item.getPartId()),
                        item.getSystemQuantity(), item.getActualQuantity(), item.difference(),
                        item.getReason(), item.isAdjustmentApproved()))
                .toList();
        return new CheckResponse(check.getId(), check.getCheckDate(), check.getCreatedBy(), check.getApprovedBy(),
                check.getApprovedAt(), check.getStatus(), check.getNote(), check.getDecisionReason(), lines);
    }

    @Transactional(readOnly = true)
    public PageResponse<CheckSummaryResponse> getAll(int page, int size) {
        Page<InventoryCheck> checks = checkRepository.findAllByOrderByIdDesc(
                PageRequest.of(Math.max(page, 0), Math.min(Math.max(size, 1), MAX_PAGE_SIZE)));
        List<Integer> ids = checks.getContent().stream().map(InventoryCheck::getId).toList();
        Map<Integer, List<InventoryCheckItem>> byCheck = ids.isEmpty() ? Map.of()
                : itemRepository.findByCheckIdIn(ids).stream()
                        .collect(Collectors.groupingBy(InventoryCheckItem::getCheckId));
        return PageResponse.of(checks, check -> {
            List<InventoryCheckItem> items = byCheck.getOrDefault(check.getId(), List.of());
            int differences = (int) items.stream().filter(i -> i.difference() != null && i.difference() != 0).count();
            return new CheckSummaryResponse(check.getId(), check.getCheckDate(), check.getCreatedBy(),
                    check.getApprovedBy(), check.getStatus(), check.getNote(), items.size(), differences);
        });
    }

    private InventoryCheck findCheck(Integer id) {
        return checkRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy phiên kiểm kê."));
    }

    private void requirePendingApproval(InventoryCheck check) {
        if (!InventoryCheck.PENDING_APPROVAL.equals(check.getStatus())) {
            throw new ConflictException("Phiên kiểm kê không ở trạng thái chờ phê duyệt.");
        }
    }

    private Map<Integer, String> partNames(List<InventoryCheckItem> items) {
        Set<Integer> ids = items.stream().map(InventoryCheckItem::getPartId).collect(Collectors.toSet());
        Map<Integer, String> names = new HashMap<>();
        if (!ids.isEmpty()) {
            for (SparePart part : sparePartRepository.findAllById(ids)) names.put(part.getId(), part.getName());
        }
        return names;
    }

    private String normalize(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }
}
'@
Write-RepoFile 'backend/src/main/java/com/gara/quanlygara/controller/InventoryController.java' @'
// TV3-TUAN8
package com.gara.quanlygara.controller;

import com.gara.quanlygara.dto.ApiResponse;
import com.gara.quanlygara.dto.warehouse.InventoryPageResponse;
import com.gara.quanlygara.dto.warehouse.PageResponse;
import com.gara.quanlygara.dto.warehouse.StockMovementResponse;
import com.gara.quanlygara.service.InventoryService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/inventory")
@PreAuthorize("hasAnyRole('ADMIN', 'MANAGER', 'WAREHOUSE')")
public class InventoryController {

    private final InventoryService inventoryService;

    public InventoryController(InventoryService inventoryService) {
        this.inventoryService = inventoryService;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<InventoryPageResponse>> getStock(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(required = false) String search,
            @RequestParam(required = false) String status
    ) {
        return ResponseEntity.ok(ApiResponse.success("Lấy tồn kho thành công.",
                inventoryService.getStock(page, size, search, status)));
    }

    @GetMapping("/movements")
    public ResponseEntity<ApiResponse<PageResponse<StockMovementResponse>>> getMovements(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) Integer partId,
            @RequestParam(required = false) String type
    ) {
        return ResponseEntity.ok(ApiResponse.success("Lấy lịch sử biến động kho thành công.",
                inventoryService.getMovements(page, size, partId, type)));
    }
}
'@
Write-RepoFile 'backend/src/main/java/com/gara/quanlygara/controller/StockReceiptController.java' @'
// TV3-TUAN8
package com.gara.quanlygara.controller;

import com.gara.quanlygara.dto.ApiResponse;
import com.gara.quanlygara.dto.warehouse.ImportRequest;
import com.gara.quanlygara.dto.warehouse.ImportResponse;
import com.gara.quanlygara.dto.warehouse.PageResponse;
import com.gara.quanlygara.security.StaffContext;
import com.gara.quanlygara.service.StockReceiptService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/warehouse/imports")
@PreAuthorize("hasAnyRole('ADMIN', 'MANAGER', 'WAREHOUSE')")
public class StockReceiptController {

    private final StockReceiptService receiptService;
    private final StaffContext staffContext;

    public StockReceiptController(StockReceiptService receiptService, StaffContext staffContext) {
        this.receiptService = receiptService;
        this.staffContext = staffContext;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<PageResponse<ImportResponse>>> getAll(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size
    ) {
        return ResponseEntity.ok(ApiResponse.success("Lấy danh sách phiếu nhập thành công.",
                receiptService.getAll(page, size)));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<ImportResponse>> get(@PathVariable Integer id) {
        return ResponseEntity.ok(ApiResponse.success("Lấy phiếu nhập thành công.", receiptService.get(id)));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<ImportResponse>> create(
            @Valid @RequestBody ImportRequest request, Authentication authentication
    ) {
        Integer staffId = staffContext.employeeId(authentication);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Nhập kho thành công.", receiptService.create(request, staffId)));
    }
}
'@
Write-RepoFile 'backend/src/main/java/com/gara/quanlygara/controller/StockIssueController.java' @'
// TV3-TUAN8
package com.gara.quanlygara.controller;

import com.gara.quanlygara.dto.ApiResponse;
import com.gara.quanlygara.dto.warehouse.ConfirmUsageRequest;
import com.gara.quanlygara.dto.warehouse.IssueRequest;
import com.gara.quanlygara.dto.warehouse.IssueResponse;
import com.gara.quanlygara.dto.warehouse.PageResponse;
import com.gara.quanlygara.security.StaffContext;
import com.gara.quanlygara.service.StockIssueService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/warehouse/exports")
@PreAuthorize("hasAnyRole('ADMIN', 'MANAGER', 'WAREHOUSE', 'TECHNICIAN')")
public class StockIssueController {

    private final StockIssueService issueService;
    private final StaffContext staffContext;

    public StockIssueController(StockIssueService issueService, StaffContext staffContext) {
        this.issueService = issueService;
        this.staffContext = staffContext;
    }

    // Kỹ thuật viên chỉ thấy các phiếu xuất liên quan tới mình.
    @GetMapping
    public ResponseEntity<ApiResponse<PageResponse<IssueResponse>>> getAll(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            Authentication authentication
    ) {
        int technicianId = staffContext.isTechnician(authentication) ? staffContext.employeeId(authentication) : 0;
        return ResponseEntity.ok(ApiResponse.success("Lấy danh sách phiếu xuất thành công.",
                issueService.getAll(page, size, technicianId)));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<IssueResponse>> get(@PathVariable Integer id) {
        return ResponseEntity.ok(ApiResponse.success("Lấy phiếu xuất thành công.", issueService.get(id)));
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER', 'WAREHOUSE')")
    public ResponseEntity<ApiResponse<IssueResponse>> create(
            @Valid @RequestBody IssueRequest request, Authentication authentication
    ) {
        Integer staffId = staffContext.employeeId(authentication);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Đã cấp phát phụ tùng, chờ kỹ thuật viên xác nhận thực dùng.",
                        issueService.create(request, staffId)));
    }

    @PostMapping("/{issueId}/items/{partId}/confirm")
    @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER', 'TECHNICIAN')")
    public ResponseEntity<ApiResponse<IssueResponse.Item>> confirmUsage(
            @PathVariable Integer issueId,
            @PathVariable Integer partId,
            @Valid @RequestBody ConfirmUsageRequest request,
            Authentication authentication
    ) {
        boolean technician = staffContext.isTechnician(authentication);
        // Với ADMIN/MANAGER người xác nhận lấy từ request nên không bắt buộc tài khoản liên kết nhân viên.
        Integer callerId = technician ? staffContext.employeeId(authentication) : null;
        return ResponseEntity.ok(ApiResponse.success("Đã xác nhận số lượng thực dùng.",
                issueService.confirmUsage(issueId, partId, request, callerId, technician)));
    }
}
'@
Write-RepoFile 'backend/src/main/java/com/gara/quanlygara/controller/InventoryCheckController.java' @'
// TV3-TUAN8
package com.gara.quanlygara.controller;

import com.gara.quanlygara.dto.ApiResponse;
import com.gara.quanlygara.dto.warehouse.CheckActualRequest;
import com.gara.quanlygara.dto.warehouse.CheckCreateRequest;
import com.gara.quanlygara.dto.warehouse.CheckDecisionRequest;
import com.gara.quanlygara.dto.warehouse.CheckResponse;
import com.gara.quanlygara.dto.warehouse.CheckSummaryResponse;
import com.gara.quanlygara.dto.warehouse.PageResponse;
import com.gara.quanlygara.security.StaffContext;
import com.gara.quanlygara.service.InventoryCheckService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/warehouse/checks")
@PreAuthorize("hasAnyRole('ADMIN', 'MANAGER', 'WAREHOUSE')")
public class InventoryCheckController {

    private static final String MANAGER_ONLY = "hasRole('MANAGER')";

    private final InventoryCheckService checkService;
    private final StaffContext staffContext;

    public InventoryCheckController(InventoryCheckService checkService, StaffContext staffContext) {
        this.checkService = checkService;
        this.staffContext = staffContext;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<PageResponse<CheckSummaryResponse>>> getAll(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size
    ) {
        return ResponseEntity.ok(ApiResponse.success("Lấy danh sách phiên kiểm kê thành công.",
                checkService.getAll(page, size)));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<CheckResponse>> get(@PathVariable Integer id) {
        return ResponseEntity.ok(ApiResponse.success("Lấy phiên kiểm kê thành công.", checkService.get(id)));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<CheckResponse>> create(
            @Valid @RequestBody CheckCreateRequest request, Authentication authentication
    ) {
        Integer staffId = staffContext.employeeId(authentication);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Đã tạo phiên kiểm kê.", checkService.create(request, staffId)));
    }

    @PutMapping("/{id}/items/{partId}")
    public ResponseEntity<ApiResponse<CheckResponse>> setActual(
            @PathVariable Integer id,
            @PathVariable Integer partId,
            @Valid @RequestBody CheckActualRequest request
    ) {
        return ResponseEntity.ok(ApiResponse.success("Đã ghi nhận số lượng thực tế.",
                checkService.setActual(id, partId, request)));
    }

    // Chỉ MANAGER được duyệt/từ chối điều chỉnh tồn kho.
    @PostMapping("/{id}/approve")
    @PreAuthorize(MANAGER_ONLY)
    public ResponseEntity<ApiResponse<CheckResponse>> approve(
            @PathVariable Integer id,
            @Valid @RequestBody(required = false) CheckDecisionRequest request,
            Authentication authentication
    ) {
        Integer approverId = staffContext.employeeId(authentication);
        return ResponseEntity.ok(ApiResponse.success("Đã phê duyệt điều chỉnh tồn kho.",
                checkService.approve(id, request == null ? null : request.reason(), approverId)));
    }

    @PostMapping("/{id}/reject")
    @PreAuthorize(MANAGER_ONLY)
    public ResponseEntity<ApiResponse<CheckResponse>> reject(
            @PathVariable Integer id,
            @Valid @RequestBody CheckDecisionRequest request,
            Authentication authentication
    ) {
        Integer approverId = staffContext.employeeId(authentication);
        return ResponseEntity.ok(ApiResponse.success("Đã từ chối điều chỉnh tồn kho.",
                checkService.reject(id, request.reason(), approverId)));
    }
}
'@
Write-RepoFile 'backend/database/migrations/V002__warehouse_actual_used_and_stock_check.sql' @'
-- TV3-TUAN8
-- ============================================================
-- V002 - Tuan 8 (TV3): kho phu tung - thuc dung & kiem ke co phe duyet
-- Chay MOT LAN tren database QuanLyGaraOTo da tao bang QuanLyGaraOTo.sql (+ V001).
-- Script idempotent: chay lai khong loi, khong mat du lieu.
--
-- 1. ChiTietPhieuXuat: them SoLuongThucDung, SoLuongHoanTra (giu nguyen SoLuong = so luong cap phat).
-- 2. Tao PhieuKiemKe / ChiTietKiemKe (kiem ke co phe duyet).
-- 3. Sua sp_XacNhanSuDungPhuTung: tru ton theo SO LUONG THUC DUNG, khong theo so cap phat.
-- 4. Sua sp_KiemKeTonKho: chi GHI NHAN kiem ke, KHONG cap nhat ton (chi MANAGER duyet qua ung dung).
-- Khong doi ten bang/cot cu. Khong them trigger/function/job.
-- ============================================================
USE QuanLyGaraOTo;
GO

-- ------------------------------------------------------------
-- 1. ChiTietPhieuXuat: thuc dung / hoan tra
-- ------------------------------------------------------------
IF COL_LENGTH('dbo.ChiTietPhieuXuat', 'SoLuongThucDung') IS NULL
    ALTER TABLE dbo.ChiTietPhieuXuat ADD SoLuongThucDung INT NULL;
IF COL_LENGTH('dbo.ChiTietPhieuXuat', 'SoLuongHoanTra') IS NULL
    ALTER TABLE dbo.ChiTietPhieuXuat ADD SoLuongHoanTra INT NULL;
GO

-- Dong da xac nhan theo ngu nghia cu (da tru du so cap phat): thuc dung = cap phat, hoan tra = 0.
UPDATE dbo.ChiTietPhieuXuat
SET SoLuongThucDung = SoLuong,
    SoLuongHoanTra = 0
WHERE DaXacNhanSuDung = 1
  AND SoLuongThucDung IS NULL;
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = N'CK_ChiTietPhieuXuat_ThucDung')
    ALTER TABLE dbo.ChiTietPhieuXuat WITH CHECK ADD CONSTRAINT CK_ChiTietPhieuXuat_ThucDung
        CHECK (
            (DaXacNhanSuDung = 0 AND SoLuongThucDung IS NULL AND SoLuongHoanTra IS NULL)
            OR
            (DaXacNhanSuDung = 1
                AND SoLuongThucDung IS NOT NULL AND SoLuongHoanTra IS NOT NULL
                AND SoLuongThucDung >= 0 AND SoLuongThucDung <= SoLuong
                AND SoLuongHoanTra = SoLuong - SoLuongThucDung)
        );
GO

-- ------------------------------------------------------------
-- 2. Kiem ke co phe duyet
-- ------------------------------------------------------------
IF OBJECT_ID(N'dbo.PhieuKiemKe', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.PhieuKiemKe (
        MaPhieuKiemKe     INT IDENTITY(1,1) PRIMARY KEY,
        NgayKiemKe        DATETIME2(0) NOT NULL,
        MaNhanVienKiemKe  INT NOT NULL,
        MaNhanVienDuyet   INT NULL,
        NgayDuyet         DATETIME2(0) NULL,
        TrangThai         NVARCHAR(30) NOT NULL,
        GhiChu            NVARCHAR(500) NULL,
        LyDoDuyet         NVARCHAR(500) NULL,

        CONSTRAINT FK_PhieuKiemKe_NhanVienKiemKe
            FOREIGN KEY (MaNhanVienKiemKe) REFERENCES dbo.NhanVien(MaNhanVien),
        CONSTRAINT FK_PhieuKiemKe_NhanVienDuyet
            FOREIGN KEY (MaNhanVienDuyet) REFERENCES dbo.NhanVien(MaNhanVien),
        CONSTRAINT CK_PhieuKiemKe_TrangThai
            CHECK (TrangThai IN (N'DANG_KIEM_KE', N'CHO_PHE_DUYET', N'DA_HOAN_TAT', N'DA_TU_CHOI')),
        -- Nguoi duyet va ngay duyet luon di cung nhau.
        CONSTRAINT CK_PhieuKiemKe_Duyet
            CHECK ((MaNhanVienDuyet IS NULL AND NgayDuyet IS NULL)
                   OR (MaNhanVienDuyet IS NOT NULL AND NgayDuyet IS NOT NULL))
    );
END
GO

IF OBJECT_ID(N'dbo.ChiTietKiemKe', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.ChiTietKiemKe (
        MaPhieuKiemKe     INT NOT NULL,
        MaPhuTung         INT NOT NULL,
        SoLuongHeThong    INT NOT NULL,
        SoLuongThucTe     INT NULL,
        ChenhLech AS (SoLuongThucTe - SoLuongHeThong) PERSISTED,
        LyDo              NVARCHAR(500) NULL,
        DaDuyetDieuChinh  BIT NOT NULL CONSTRAINT DF_ChiTietKiemKe_DaDuyet DEFAULT 0,

        CONSTRAINT PK_ChiTietKiemKe PRIMARY KEY (MaPhieuKiemKe, MaPhuTung),
        CONSTRAINT FK_ChiTietKiemKe_PhieuKiemKe
            FOREIGN KEY (MaPhieuKiemKe) REFERENCES dbo.PhieuKiemKe(MaPhieuKiemKe),
        CONSTRAINT FK_ChiTietKiemKe_PhuTung
            FOREIGN KEY (MaPhuTung) REFERENCES dbo.PhuTung(MaPhuTung),
        CONSTRAINT CK_ChiTietKiemKe_SoLuongHeThong CHECK (SoLuongHeThong >= 0),
        CONSTRAINT CK_ChiTietKiemKe_SoLuongThucTe CHECK (SoLuongThucTe IS NULL OR SoLuongThucTe >= 0)
    );
END
GO

-- ------------------------------------------------------------
-- 3. sp_XacNhanSuDungPhuTung: tru ton theo SO LUONG THUC DUNG
--    @SoLuongThucDung bo trong (NULL) = dung du so cap phat (tuong thich cac loi goi cu).
-- ------------------------------------------------------------
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

-- ------------------------------------------------------------
-- 4. sp_KiemKeTonKho: chi GHI NHAN kiem ke mot phu tung, KHONG bao gio cap nhat PhuTung.SoLuongTon.
--    Khong chenh lech -> DA_HOAN_TAT; co chenh lech -> CHO_PHE_DUYET (MANAGER duyet qua ung dung).
--    @MaNhanVienKiemKe bat buoc (cot NOT NULL); tham so de mac dinh NULL de giu chu ky goi cu cua seed.
-- ------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.sp_KiemKeTonKho
    @MaPhuTung INT,
    @SoLuongThucTe INT,
    @GhiChu NVARCHAR(500) = NULL,
    @MaNhanVienKiemKe INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @SoLuongThucTe < 0
        THROW 50020, N'So luong thuc te khong duoc am.', 1;

    IF NOT EXISTS (SELECT 1 FROM PhuTung WHERE MaPhuTung = @MaPhuTung)
        THROW 50021, N'Phu tung khong ton tai.', 1;

    IF @MaNhanVienKiemKe IS NULL
        THROW 50022, N'Can chi dinh nhan vien kiem ke.', 1;

    BEGIN TRY
        BEGIN TRAN;

        DECLARE @TonHeThong INT;
        DECLARE @MaPhieuKiemKe INT;

        SELECT @TonHeThong = SoLuongTon
        FROM PhuTung WITH (UPDLOCK, HOLDLOCK)
        WHERE MaPhuTung = @MaPhuTung;

        INSERT INTO PhieuKiemKe (NgayKiemKe, MaNhanVienKiemKe, TrangThai, GhiChu)
        VALUES (
            SYSDATETIME(), @MaNhanVienKiemKe,
            CASE WHEN @SoLuongThucTe = @TonHeThong THEN N'DA_HOAN_TAT' ELSE N'CHO_PHE_DUYET' END,
            COALESCE(@GhiChu, N'Kiem ke ton kho')
        );
        SET @MaPhieuKiemKe = SCOPE_IDENTITY();

        INSERT INTO ChiTietKiemKe (MaPhieuKiemKe, MaPhuTung, SoLuongHeThong, SoLuongThucTe)
        VALUES (@MaPhieuKiemKe, @MaPhuTung, @TonHeThong, @SoLuongThucTe);

        -- Co chenh lech: ton giu nguyen cho den khi MANAGER phe duyet.
        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH
END;
GO
'@
Write-RepoFile 'backend/database/Test_Warehouse.sql' @'
-- TV3-TUAN8
-- ============================================================
-- Test_Warehouse.sql - kho phu tung (Tuan 8 - TV3)
-- YEU CAU: da chay QuanLyGaraOTo.sql va migrations/V002__warehouse_actual_used_and_stock_check.sql.
-- Script KHONG bao boc mot transaction: cac procedure co THROW trong TRAN se ROLLBACK ca transaction ngoai.
-- Vi vay du lieu test dung nhan 'TEST-WH' va duoc don sach o cuoi script.
-- ============================================================
USE QuanLyGaraOTo;
GO

SET NOCOUNT ON;

IF OBJECT_ID(N'dbo.PhieuKiemKe', N'U') IS NULL OR COL_LENGTH('dbo.ChiTietPhieuXuat', 'SoLuongThucDung') IS NULL
BEGIN
    PRINT N'Chua chay migration V002. Dung lai.';
    RETURN;
END;

DECLARE @Result TABLE (Id INT IDENTITY(1,1), TestName NVARCHAR(200), Detail NVARCHAR(400), Result NVARCHAR(4));

DECLARE @kho INT, @nv INT, @order INT, @ktv INT;
DECLARE @pt INT, @phieuNhap INT, @phieuXuat INT, @phieuXuat2 INT, @pk INT;
DECLARE @ton INT, @ton2 INT, @n INT, @n2 INT, @err INT, @msg NVARCHAR(400);

SELECT TOP 1 @kho = MaKho FROM Kho ORDER BY MaKho;
SELECT TOP 1 @nv = MaNhanVien FROM NhanVien ORDER BY MaNhanVien;

-- Phieu sua chua dang sua, co phan cong KTV + bao gia da xac nhan (seed co san phieu 1, 2).
-- Khong doi trang thai phieu sua chua (tranh kich hoat trigger thong bao hoan tat).
SELECT TOP 1 @order = pc.MaPhieuSuaChua, @ktv = pc.MaKyThuatVien
FROM PhanCongKyThuatVien pc
INNER JOIN PhieuSuaChua ps ON ps.MaPhieuSuaChua = pc.MaPhieuSuaChua AND ps.TrangThai IN (N'DANG_SUA', N'CHO_PHU_TUNG')
INNER JOIN BaoGia bg ON bg.MaPhieuSuaChua = pc.MaPhieuSuaChua AND bg.TrangThai = N'DA_XAC_NHAN'
ORDER BY pc.MaPhieuSuaChua;

IF @kho IS NULL OR @nv IS NULL OR @order IS NULL
BEGIN
    PRINT N'Thieu du lieu mau: can Kho, NhanVien va 1 phieu sua chua DANG_SUA/CHO_PHU_TUNG co phan cong KTV + bao gia da xac nhan.';
    RETURN;
END;

INSERT INTO PhuTung (MaKho, TenPhuTung, HangSanXuat, DonGia, MucTonToiThieu)
VALUES (@kho, N'TEST-WH phu tung', N'TEST-WH', 100000, 5);
SET @pt = SCOPE_IDENTITY();

INSERT INTO PhieuNhapKho (NgayNhap, NhaCungCap, MaNhanVienKho, GhiChu)
VALUES (SYSDATETIME(), N'TEST-WH nha cung cap', @nv, N'TEST-WH');
SET @phieuNhap = SCOPE_IDENTITY();

-- T1: nhap kho 10 -> ton tang dung 1 lan, co bien dong NHAP
BEGIN TRY
    EXEC dbo.sp_ThemChiTietPhieuNhap @phieuNhap, @pt, 10, 100000;
    SELECT @ton = SoLuongTon FROM PhuTung WHERE MaPhuTung = @pt;
    SELECT @n = COUNT(*) FROM BienDongKho WHERE MaPhuTung = @pt AND MaPhieuNhap = @phieuNhap AND LoaiBienDong = N'NHAP' AND SoLuong = 10 AND SoLuongTruoc = 0 AND SoLuongSau = 10;
    INSERT INTO @Result VALUES (N'T1 nhap kho tang ton dung 1 lan', N'ton=' + CAST(@ton AS NVARCHAR(10)) + N', so bien dong NHAP=' + CAST(@n AS NVARCHAR(10)),
        CASE WHEN @ton = 10 AND @n = 1 THEN 'PASS' ELSE 'FAIL' END);
END TRY
BEGIN CATCH
    INSERT INTO @Result VALUES (N'T1 nhap kho', ERROR_MESSAGE(), 'FAIL');
END CATCH;

-- T2: nhap trung phu tung trong cung phieu -> 50005, ton khong doi
SET @err = NULL;
BEGIN TRY
    EXEC dbo.sp_ThemChiTietPhieuNhap @phieuNhap, @pt, 5, 100000;
END TRY
BEGIN CATCH
    SET @err = ERROR_NUMBER();
END CATCH;
SELECT @ton = SoLuongTon FROM PhuTung WHERE MaPhuTung = @pt;
INSERT INTO @Result VALUES (N'T2 nhap trung phu tung trong phieu', N'loi=' + COALESCE(CAST(@err AS NVARCHAR(10)), N'khong loi') + N', ton=' + CAST(@ton AS NVARCHAR(10)),
    CASE WHEN @err = 50005 AND @ton = 10 THEN 'PASS' ELSE 'FAIL' END);

-- T3: nhap so luong 0 -> 50001
SET @err = NULL;
BEGIN TRY
    EXEC dbo.sp_ThemChiTietPhieuNhap @phieuNhap, @pt, 0, 100000;
END TRY
BEGIN CATCH
    SET @err = ERROR_NUMBER();
END CATCH;
INSERT INTO @Result VALUES (N'T3 nhap so luong = 0', N'loi=' + COALESCE(CAST(@err AS NVARCHAR(10)), N'khong loi'), CASE WHEN @err = 50001 THEN 'PASS' ELSE 'FAIL' END);

-- T4: phu tung khong ton tai -> 50004
SET @err = NULL;
BEGIN TRY
    EXEC dbo.sp_ThemChiTietPhieuNhap @phieuNhap, -1, 1, 1;
END TRY
BEGIN CATCH
    SET @err = ERROR_NUMBER();
END CATCH;
INSERT INTO @Result VALUES (N'T4 nhap phu tung khong ton tai', N'loi=' + COALESCE(CAST(@err AS NVARCHAR(10)), N'khong loi'), CASE WHEN @err = 50004 THEN 'PASS' ELSE 'FAIL' END);

-- T5: cap phat 5 (tao phieu xuat) KHONG giam ton, KHONG co bien dong
INSERT INTO PhieuXuatKho (MaPhieuSuaChua, MaNhanVienKho, MaKyThuatVienYeuCau, NgayXuat, LyDo)
VALUES (@order, @nv, @ktv, SYSDATETIME(), N'TEST-WH cap phat');
SET @phieuXuat = SCOPE_IDENTITY();
INSERT INTO ChiTietPhieuXuat (MaPhieuXuat, MaPhuTung, SoLuong, DonGia) VALUES (@phieuXuat, @pt, 5, 100000);
SELECT @ton = SoLuongTon FROM PhuTung WHERE MaPhuTung = @pt;
SELECT @n = COUNT(*) FROM BienDongKho WHERE MaPhuTung = @pt AND MaPhieuXuat = @phieuXuat;
INSERT INTO @Result VALUES (N'T5 cap phat khong giam ton', N'ton=' + CAST(@ton AS NVARCHAR(10)) + N', bien dong=' + CAST(@n AS NVARCHAR(10)),
    CASE WHEN @ton = 10 AND @n = 0 THEN 'PASS' ELSE 'FAIL' END);

-- T6: thuc dung 6 > cap phat 5 -> 50017, ton khong doi, chua xac nhan
SET @err = NULL;
BEGIN TRY
    EXEC dbo.sp_XacNhanSuDungPhuTung @phieuXuat, @pt, @ktv, 6;
END TRY
BEGIN CATCH
    SET @err = ERROR_NUMBER();
END CATCH;
SELECT @ton = SoLuongTon FROM PhuTung WHERE MaPhuTung = @pt;
SELECT @n = DaXacNhanSuDung FROM ChiTietPhieuXuat WHERE MaPhieuXuat = @phieuXuat AND MaPhuTung = @pt;
INSERT INTO @Result VALUES (N'T6 thuc dung > cap phat bi tu choi', N'loi=' + COALESCE(CAST(@err AS NVARCHAR(10)), N'khong loi') + N', ton=' + CAST(@ton AS NVARCHAR(10)),
    CASE WHEN @err = 50017 AND @ton = 10 AND @n = 0 THEN 'PASS' ELSE 'FAIL' END);

-- T7: thuc dung am -> 50017
SET @err = NULL;
BEGIN TRY
    EXEC dbo.sp_XacNhanSuDungPhuTung @phieuXuat, @pt, @ktv, -1;
END TRY
BEGIN CATCH
    SET @err = ERROR_NUMBER();
END CATCH;
INSERT INTO @Result VALUES (N'T7 thuc dung am', N'loi=' + COALESCE(CAST(@err AS NVARCHAR(10)), N'khong loi'), CASE WHEN @err = 50017 THEN 'PASS' ELSE 'FAIL' END);

-- T8: cap phat 5, thuc dung 3 -> ton 10 -> 7, hoan tra 2, ChiTietPhuTung = 3, bien dong XUAT = 3
BEGIN TRY
    EXEC dbo.sp_XacNhanSuDungPhuTung @phieuXuat, @pt, @ktv, 3;
    SELECT @ton = SoLuongTon FROM PhuTung WHERE MaPhuTung = @pt;
    SELECT @n = SoLuongHoanTra FROM ChiTietPhieuXuat WHERE MaPhieuXuat = @phieuXuat AND MaPhuTung = @pt AND SoLuongThucDung = 3 AND DaXacNhanSuDung = 1;
    SELECT @n2 = SoLuong FROM ChiTietPhuTung WHERE MaPhieuSuaChua = @order AND MaPhuTung = @pt;
    SELECT @err = COUNT(*) FROM BienDongKho WHERE MaPhuTung = @pt AND MaPhieuXuat = @phieuXuat AND LoaiBienDong = N'XUAT' AND SoLuong = 3 AND SoLuongTruoc = 10 AND SoLuongSau = 7;
    INSERT INTO @Result VALUES (N'T8 cap phat 5 thuc dung 3: ton -3, hoan tra 2, ChiTietPhuTung = 3, bien dong XUAT = 3',
        N'ton=' + CAST(@ton AS NVARCHAR(10)) + N', hoan tra=' + COALESCE(CAST(@n AS NVARCHAR(10)), N'null') + N', ChiTietPhuTung=' + COALESCE(CAST(@n2 AS NVARCHAR(10)), N'null') + N', bien dong=' + CAST(@err AS NVARCHAR(10)),
        CASE WHEN @ton = 7 AND @n = 2 AND @n2 = 3 AND @err = 1 THEN 'PASS' ELSE 'FAIL' END);
END TRY
BEGIN CATCH
    INSERT INTO @Result VALUES (N'T8 xac nhan thuc dung', ERROR_MESSAGE(), 'FAIL');
END CATCH;

-- T9: xac nhan lan 2 -> 50012, ton khong doi
SET @err = NULL;
BEGIN TRY
    EXEC dbo.sp_XacNhanSuDungPhuTung @phieuXuat, @pt, @ktv, 3;
END TRY
BEGIN CATCH
    SET @err = ERROR_NUMBER();
END CATCH;
SELECT @ton = SoLuongTon FROM PhuTung WHERE MaPhuTung = @pt;
INSERT INTO @Result VALUES (N'T9 xac nhan lan 2 bi tu choi', N'loi=' + COALESCE(CAST(@err AS NVARCHAR(10)), N'khong loi') + N', ton=' + CAST(@ton AS NVARCHAR(10)),
    CASE WHEN @err = 50012 AND @ton = 7 THEN 'PASS' ELSE 'FAIL' END);

-- T10: thuc dung 0 -> ton khong doi, hoan tra = cap phat, khong co bien dong XUAT moi
INSERT INTO PhieuXuatKho (MaPhieuSuaChua, MaNhanVienKho, MaKyThuatVienYeuCau, NgayXuat, LyDo)
VALUES (@order, @nv, @ktv, SYSDATETIME(), N'TEST-WH cap phat 2');
SET @phieuXuat2 = SCOPE_IDENTITY();
INSERT INTO ChiTietPhieuXuat (MaPhieuXuat, MaPhuTung, SoLuong, DonGia) VALUES (@phieuXuat2, @pt, 2, 100000);
BEGIN TRY
    EXEC dbo.sp_XacNhanSuDungPhuTung @phieuXuat2, @pt, @ktv, 0;
    SELECT @ton = SoLuongTon FROM PhuTung WHERE MaPhuTung = @pt;
    SELECT @n = SoLuongHoanTra FROM ChiTietPhieuXuat WHERE MaPhieuXuat = @phieuXuat2 AND MaPhuTung = @pt AND SoLuongThucDung = 0 AND DaXacNhanSuDung = 1;
    SELECT @n2 = COUNT(*) FROM BienDongKho WHERE MaPhieuXuat = @phieuXuat2;
    INSERT INTO @Result VALUES (N'T10 thuc dung 0: ton khong doi, hoan tra toan bo, khong bien dong',
        N'ton=' + CAST(@ton AS NVARCHAR(10)) + N', hoan tra=' + COALESCE(CAST(@n AS NVARCHAR(10)), N'null') + N', bien dong=' + CAST(@n2 AS NVARCHAR(10)),
        CASE WHEN @ton = 7 AND @n = 2 AND @n2 = 0 THEN 'PASS' ELSE 'FAIL' END);
END TRY
BEGIN CATCH
    INSERT INTO @Result VALUES (N'T10 thuc dung 0', ERROR_MESSAGE(), 'FAIL');
END CATCH;

-- T11: ton khong du thuc dung -> 50015, rollback (ton va trang thai khong doi)
INSERT INTO PhieuXuatKho (MaPhieuSuaChua, MaNhanVienKho, MaKyThuatVienYeuCau, NgayXuat, LyDo)
VALUES (@order, @nv, @ktv, SYSDATETIME(), N'TEST-WH cap phat 3');
DECLARE @phieuXuat3 INT = SCOPE_IDENTITY();
INSERT INTO ChiTietPhieuXuat (MaPhieuXuat, MaPhuTung, SoLuong, DonGia) VALUES (@phieuXuat3, @pt, 4, 100000);
UPDATE PhuTung SET SoLuongTon = 1 WHERE MaPhuTung = @pt;
SET @err = NULL;
BEGIN TRY
    EXEC dbo.sp_XacNhanSuDungPhuTung @phieuXuat3, @pt, @ktv, 4;
END TRY
BEGIN CATCH
    SET @err = ERROR_NUMBER();
END CATCH;
SELECT @ton = SoLuongTon FROM PhuTung WHERE MaPhuTung = @pt;
SELECT @n = DaXacNhanSuDung FROM ChiTietPhieuXuat WHERE MaPhieuXuat = @phieuXuat3 AND MaPhuTung = @pt;
INSERT INTO @Result VALUES (N'T11 ton khong du thuc dung: rollback', N'loi=' + COALESCE(CAST(@err AS NVARCHAR(10)), N'khong loi') + N', ton=' + CAST(@ton AS NVARCHAR(10)),
    CASE WHEN @err = 50015 AND @ton = 1 AND @n = 0 THEN 'PASS' ELSE 'FAIL' END);
UPDATE PhuTung SET SoLuongTon = 7 WHERE MaPhuTung = @pt;

-- T12: rang buoc DB: hoan tra khong khop thuc dung bi CK_ChiTietPhieuXuat_ThucDung chan
SET @err = NULL;
BEGIN TRY
    UPDATE ChiTietPhieuXuat
    SET DaXacNhanSuDung = 1, NgayXacNhan = SYSDATETIME(), MaKyThuatVienXacNhan = @ktv, SoLuongThucDung = 1, SoLuongHoanTra = 1
    WHERE MaPhieuXuat = @phieuXuat3 AND MaPhuTung = @pt;
END TRY
BEGIN CATCH
    SET @err = ERROR_NUMBER();
    SET @msg = ERROR_MESSAGE();
END CATCH;
INSERT INTO @Result VALUES (N'T12 hoan tra khong khop thuc dung bi CK chan', COALESCE(@msg, N'khong loi'),
    CASE WHEN @err = 547 AND @msg LIKE '%CK_ChiTietPhieuXuat_ThucDung%' THEN 'PASS' ELSE 'FAIL' END);

-- T13: kiem ke co chenh lech -> CHO_PHE_DUYET, TON KHONG DOI, khong co bien dong KIEM_KE
SELECT @ton = SoLuongTon FROM PhuTung WHERE MaPhuTung = @pt;
BEGIN TRY
    EXEC dbo.sp_KiemKeTonKho @pt, 4, N'TEST-WH kiem ke lech', @nv;
    SELECT TOP 1 @pk = MaPhieuKiemKe FROM ChiTietKiemKe WHERE MaPhuTung = @pt ORDER BY MaPhieuKiemKe DESC;
    SELECT @ton2 = SoLuongTon FROM PhuTung WHERE MaPhuTung = @pt;
    SELECT @n = COUNT(*) FROM PhieuKiemKe WHERE MaPhieuKiemKe = @pk AND TrangThai = N'CHO_PHE_DUYET';
    SELECT @n2 = COUNT(*) FROM BienDongKho WHERE MaPhuTung = @pt AND LoaiBienDong = N'KIEM_KE';
    INSERT INTO @Result VALUES (N'T13 kiem ke lech: cho phe duyet, ton khong doi', N'ton truoc=' + CAST(@ton AS NVARCHAR(10)) + N', ton sau=' + CAST(@ton2 AS NVARCHAR(10)) + N', bien dong KIEM_KE=' + CAST(@n2 AS NVARCHAR(10)),
        CASE WHEN @ton = @ton2 AND @n = 1 AND @n2 = 0 THEN 'PASS' ELSE 'FAIL' END);
END TRY
BEGIN CATCH
    INSERT INTO @Result VALUES (N'T13 kiem ke lech', ERROR_MESSAGE(), 'FAIL');
END CATCH;

-- T14: kiem ke khop -> DA_HOAN_TAT, ton khong doi
BEGIN TRY
    EXEC dbo.sp_KiemKeTonKho @pt, 7, N'TEST-WH kiem ke khop', @nv;
    SELECT TOP 1 @pk = MaPhieuKiemKe FROM ChiTietKiemKe WHERE MaPhuTung = @pt ORDER BY MaPhieuKiemKe DESC;
    SELECT @ton2 = SoLuongTon FROM PhuTung WHERE MaPhuTung = @pt;
    SELECT @n = COUNT(*) FROM PhieuKiemKe WHERE MaPhieuKiemKe = @pk AND TrangThai = N'DA_HOAN_TAT';
    INSERT INTO @Result VALUES (N'T14 kiem ke khop: hoan tat, ton khong doi', N'ton=' + CAST(@ton2 AS NVARCHAR(10)),
        CASE WHEN @ton2 = 7 AND @n = 1 THEN 'PASS' ELSE 'FAIL' END);
END TRY
BEGIN CATCH
    INSERT INTO @Result VALUES (N'T14 kiem ke khop', ERROR_MESSAGE(), 'FAIL');
END CATCH;

-- T15: kiem ke so luong thuc te am -> 50020; thieu nhan vien -> 50022
SET @err = NULL;
BEGIN TRY
    EXEC dbo.sp_KiemKeTonKho @pt, -1, NULL, @nv;
END TRY
BEGIN CATCH
    SET @err = ERROR_NUMBER();
END CATCH;
SELECT @n = CASE WHEN @err = 50020 THEN 1 ELSE 0 END;
SET @err = NULL;
BEGIN TRY
    EXEC dbo.sp_KiemKeTonKho @pt, 7;
END TRY
BEGIN CATCH
    SET @err = ERROR_NUMBER();
END CATCH;
INSERT INTO @Result VALUES (N'T15 kiem ke: thuc te am (50020), thieu nhan vien (50022)', N'',
    CASE WHEN @n = 1 AND @err = 50022 THEN 'PASS' ELSE 'FAIL' END);

-- T16: rang buoc trang thai kiem ke
SET @err = NULL;
BEGIN TRY
    UPDATE PhieuKiemKe SET TrangThai = N'KHONG_HOP_LE' WHERE MaPhieuKiemKe = @pk;
END TRY
BEGIN CATCH
    SET @err = ERROR_NUMBER();
END CATCH;
INSERT INTO @Result VALUES (N'T16 trang thai kiem ke khong hop le bi CK chan', N'loi=' + COALESCE(CAST(@err AS NVARCHAR(10)), N'khong loi'),
    CASE WHEN @err = 547 THEN 'PASS' ELSE 'FAIL' END);

SELECT Id, TestName, Result, Detail FROM @Result ORDER BY Id;
SELECT @n = COUNT(*) FROM @Result WHERE Result = 'FAIL';

-- ------------------------------------------------------------
-- DON DEP (thu tu nguoc khoa ngoai)
-- ------------------------------------------------------------
DELETE FROM ChiTietKiemKe WHERE MaPhuTung = @pt;
DELETE FROM PhieuKiemKe WHERE GhiChu LIKE N'TEST-WH%';
DELETE FROM BienDongKho WHERE MaPhuTung = @pt;
DELETE FROM ChiTietPhuTung WHERE MaPhieuSuaChua = @order AND MaPhuTung = @pt;
DELETE FROM ChiTietPhieuXuat WHERE MaPhuTung = @pt;
DELETE FROM PhieuXuatKho WHERE LyDo LIKE N'TEST-WH%';
DELETE FROM ChiTietPhieuNhap WHERE MaPhuTung = @pt;
DELETE FROM PhieuNhapKho WHERE GhiChu = N'TEST-WH';
DELETE FROM PhuTung WHERE MaPhuTung = @pt;

IF @n = 0
    PRINT N'TAT CA TEST KHO DEU PASS (da don dep du lieu test).';
ELSE
    PRINT N'CO ' + CAST(@n AS NVARCHAR(10)) + N' TEST FAIL. Xem bang ket qua o tren (du lieu test da duoc don dep).';
GO
'@
Write-RepoFile 'frontend/src/api/warehouse.ts' @'
// TV3-TUAN8
import { api, unwrap } from "./client";
import type { ApiResponse } from "./types";

export type StockStatus = "CON_HANG" | "SAP_HET" | "HET_HANG";

export interface PageResult<T> {
  items: T[];
  /** Bắt đầu từ 0, giống Spring Data. */
  page: number;
  size: number;
  totalElements: number;
  totalPages: number;
}

export interface InventoryItem {
  id: number;
  warehouseId: number;
  name: string;
  manufacturer: string | null;
  unitPrice: number;
  stockQuantity: number;
  minStockLevel: number;
  stockStatus: StockStatus;
}

export interface InventoryPage extends PageResult<InventoryItem> {
  lowStockCount: number;
}

export type MovementType = "NHAP" | "XUAT" | "KIEM_KE";

export interface StockMovement {
  id: number;
  partId: number;
  partName: string;
  receiptId: number | null;
  issueId: number | null;
  time: string;
  type: MovementType;
  quantity: number;
  quantityBefore: number | null;
  quantityAfter: number | null;
  note: string | null;
}

export interface ImportItemPayload {
  partId: number;
  quantity: number;
  unitPrice: number;
}

export interface ImportPayload {
  supplier: string;
  importDate?: string | null;
  note: string | null;
  items: ImportItemPayload[];
}

export interface StockImport {
  id: number;
  importDate: string;
  supplier: string;
  warehouseStaffId: number;
  note: string | null;
  items: { partId: number; partName: string; quantity: number; unitPrice: number; lineTotal: number }[];
  totalAmount: number;
}

export interface IssuePayload {
  repairOrderId: number;
  requestedTechnicianId: number | null;
  reason: string;
  items: { partId: number; quantity: number }[];
}

export type IssueItemState = "CHO_XAC_NHAN" | "DA_XAC_NHAN";

export interface IssueItem {
  partId: number;
  partName: string;
  issuedQuantity: number;
  unitPrice: number | null;
  state: IssueItemState;
  confirmedAt: string | null;
  confirmedTechnicianId: number | null;
  actualUsedQuantity: number | null;
  returnedQuantity: number | null;
  stockAfter: number | null;
}

export interface StockIssue {
  id: number;
  repairOrderId: number | null;
  warehouseStaffId: number;
  requestedTechnicianId: number | null;
  issueDate: string;
  reason: string;
  items: IssueItem[];
}

export type CheckStatus = "DANG_KIEM_KE" | "CHO_PHE_DUYET" | "DA_HOAN_TAT" | "DA_TU_CHOI";

export interface CheckSummary {
  id: number;
  checkDate: string;
  createdBy: number;
  approvedBy: number | null;
  status: CheckStatus;
  note: string | null;
  itemCount: number;
  differenceCount: number;
}

export interface CheckItem {
  partId: number;
  partName: string;
  systemQuantity: number;
  actualQuantity: number | null;
  difference: number | null;
  reason: string | null;
  adjustmentApproved: boolean;
}

export interface InventoryCheck {
  id: number;
  checkDate: string;
  createdBy: number;
  approvedBy: number | null;
  approvedAt: string | null;
  status: CheckStatus;
  note: string | null;
  decisionReason: string | null;
  items: CheckItem[];
}

export interface PageParams {
  page?: number;
  size?: number;
}

export const inventoryApi = {
  async stock(params: PageParams & { search?: string; status?: StockStatus | "ALL" }): Promise<InventoryPage> {
    return unwrap(await api.get<ApiResponse<InventoryPage>>("/api/inventory", { params }));
  },

  async movements(params: PageParams & { partId?: number; type?: MovementType | "ALL" }): Promise<PageResult<StockMovement>> {
    return unwrap(await api.get<ApiResponse<PageResult<StockMovement>>>("/api/inventory/movements", { params }));
  },
};

export const warehouseApi = {
  async imports(params: PageParams = {}): Promise<PageResult<StockImport>> {
    return unwrap(await api.get<ApiResponse<PageResult<StockImport>>>("/api/warehouse/imports", { params }));
  },

  async createImport(payload: ImportPayload): Promise<StockImport> {
    return unwrap(await api.post<ApiResponse<StockImport>>("/api/warehouse/imports", payload));
  },

  async issues(params: PageParams = {}): Promise<PageResult<StockIssue>> {
    return unwrap(await api.get<ApiResponse<PageResult<StockIssue>>>("/api/warehouse/exports", { params }));
  },

  async createIssue(payload: IssuePayload): Promise<StockIssue> {
    return unwrap(await api.post<ApiResponse<StockIssue>>("/api/warehouse/exports", payload));
  },

  async confirmUsage(
    issueId: number,
    partId: number,
    payload: { actualUsed: number; technicianId?: number | null },
  ): Promise<IssueItem> {
    return unwrap(await api.post<ApiResponse<IssueItem>>(`/api/warehouse/exports/${issueId}/items/${partId}/confirm`, payload));
  },

  async checks(params: PageParams = {}): Promise<PageResult<CheckSummary>> {
    return unwrap(await api.get<ApiResponse<PageResult<CheckSummary>>>("/api/warehouse/checks", { params }));
  },

  async check(id: number): Promise<InventoryCheck> {
    return unwrap(await api.get<ApiResponse<InventoryCheck>>(`/api/warehouse/checks/${id}`));
  },

  async createCheck(payload: { note: string | null; partIds: number[] }): Promise<InventoryCheck> {
    return unwrap(await api.post<ApiResponse<InventoryCheck>>("/api/warehouse/checks", payload));
  },

  async setActual(checkId: number, partId: number, payload: { actualQuantity: number; reason: string | null }): Promise<InventoryCheck> {
    return unwrap(await api.put<ApiResponse<InventoryCheck>>(`/api/warehouse/checks/${checkId}/items/${partId}`, payload));
  },

  async approveCheck(id: number, reason: string | null): Promise<InventoryCheck> {
    return unwrap(await api.post<ApiResponse<InventoryCheck>>(`/api/warehouse/checks/${id}/approve`, { reason }));
  },

  async rejectCheck(id: number, reason: string): Promise<InventoryCheck> {
    return unwrap(await api.post<ApiResponse<InventoryCheck>>(`/api/warehouse/checks/${id}/reject`, { reason }));
  },
};
'@
Write-RepoFile 'frontend/src/features/warehouse/common.ts' @'
// TV3-TUAN8
import { useEffect, useState } from "react";
import { readSession } from "../../api/session";

export const formatPrice = (value: number) =>
  new Intl.NumberFormat("vi-VN", { style: "currency", currency: "VND", maximumFractionDigits: 0 }).format(value);

export const formatDateTime = (value: string | null) => (value ? new Date(value).toLocaleString("vi-VN") : "—");

export const PER_PAGE = 10;

/** Quyền thao tác trên màn kho theo vai trò backend (backend vẫn là nơi kiểm tra quyền thật). */
export function useWarehouseRole() {
  const role = readSession()?.account.role ?? "";
  return {
    role,
    canWrite: role === "WAREHOUSE" || role === "MANAGER" || role === "ADMIN",
    canConfirmUsage: role === "MANAGER" || role === "ADMIN" || role === "TECHNICIAN",
    isManager: role === "MANAGER",
    needsTechnicianId: role !== "TECHNICIAN",
  };
}

export function useDebounced<T>(value: T, delay = 300): T {
  const [debounced, setDebounced] = useState(value);
  useEffect(() => {
    const timer = window.setTimeout(() => setDebounced(value), delay);
    return () => window.clearTimeout(timer);
  }, [value, delay]);
  return debounced;
}
'@
Write-RepoFile 'frontend/src/features/warehouse/StockTab.tsx' @'
// TV3-TUAN8
import { useEffect, useState } from "react";
import { detailedErrorMessage } from "../../api/errors";
import { inventoryApi, type InventoryPage, type StockStatus } from "../../api/warehouse";
import { Badge, Card, Icons, Pagination, SearchBox, Select, TableContainer } from "../../components/ui";
import { formatPrice, PER_PAGE, useDebounced } from "./common";

const STATUS_BADGE = { CON_HANG: "ok", SAP_HET: "low", HET_HANG: "out" } as const;

export default function StockTab({ refreshKey }: { refreshKey: number }) {
  const [search, setSearch] = useState("");
  const [status, setStatus] = useState<StockStatus | "ALL">("ALL");
  const [page, setPage] = useState(1);
  const [data, setData] = useState<InventoryPage | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const keyword = useDebounced(search.trim());

  useEffect(() => setPage(1), [keyword, status]);

  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    setError("");
    inventoryApi
      .stock({ page: page - 1, size: PER_PAGE, search: keyword || undefined, status })
      .then((result) => { if (!cancelled) setData(result); })
      .catch((loadError) => { if (!cancelled) setError(detailedErrorMessage(loadError, "Không thể tải tồn kho.")); })
      .finally(() => { if (!cancelled) setLoading(false); });
    return () => { cancelled = true; };
  }, [page, keyword, status, refreshKey]);

  return (
    <div className="space-y-4">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-end">
        <SearchBox value={search} onChange={setSearch} placeholder="Mã, tên hoặc hãng phụ tùng..." />
        <Select
          value={status}
          onChange={(event) => setStatus(event.target.value as StockStatus | "ALL")}
          options={[
            { value: "ALL", label: "Tất cả trạng thái" },
            { value: "CON_HANG", label: "Còn hàng" },
            { value: "SAP_HET", label: "Sắp hết" },
            { value: "HET_HANG", label: "Hết hàng" },
          ]}
        />
      </div>

      {error && <p className="rounded-md bg-danger-soft px-4 py-3 text-sm text-danger" role="alert">{error}</p>}
      {data && data.lowStockCount > 0 && (
        <div className="flex items-center gap-3 rounded-lg border border-warning/20 bg-warning-soft p-4 text-sm text-warning">
          <span>{Icons.alertTriangle}</span>
          <span><strong>{data.lowStockCount} mặt hàng</strong> đang ở hoặc dưới mức tồn tối thiểu.</span>
        </div>
      )}

      <Card>
        <TableContainer>
          <table className="data-table w-full min-w-[820px]">
            <thead>
              <tr>
                <th>Mã</th><th>Tên phụ tùng</th><th>Hãng</th><th>Kho</th>
                <th className="text-right">Đơn giá</th><th className="text-right">Tồn</th>
                <th className="text-right">Mức tối thiểu</th><th>Trạng thái</th>
              </tr>
            </thead>
            <tbody>
              {loading && <tr><td colSpan={8} className="py-10 text-center text-sm text-muted-foreground">Đang tải tồn kho...</td></tr>}
              {!loading && data?.items.length === 0 && !error && (
                <tr><td colSpan={8} className="py-10 text-center text-sm text-muted-foreground">Không có phụ tùng phù hợp.</td></tr>
              )}
              {!loading && data?.items.map((item) => (
                <tr key={item.id}>
                  <td className="mono text-xs">{item.id}</td>
                  <td className="font-medium">{item.name}</td>
                  <td>{item.manufacturer ?? "—"}</td>
                  <td className="mono text-xs">{item.warehouseId}</td>
                  <td className="mono text-right text-sm">{formatPrice(item.unitPrice)}</td>
                  <td className="mono text-right font-bold">{item.stockQuantity}</td>
                  <td className="mono text-right text-slate-500">{item.minStockLevel}</td>
                  <td><Badge variant={STATUS_BADGE[item.stockStatus]} /></td>
                </tr>
              ))}
            </tbody>
          </table>
        </TableContainer>
        <div className="flex flex-col gap-3 border-t border-border px-4 py-3 sm:flex-row sm:items-center sm:justify-between">
          <p className="text-xs text-muted-foreground">{data?.totalElements ?? 0} phụ tùng</p>
          <Pagination page={page} total={data?.totalElements ?? 0} perPage={PER_PAGE} onChange={setPage} />
        </div>
      </Card>
    </div>
  );
}
'@
Write-RepoFile 'frontend/src/features/warehouse/ImportsTab.tsx' @'
// TV3-TUAN8
import { FormEvent, useCallback, useEffect, useState } from "react";
import { detailedErrorMessage } from "../../api/errors";
import { sparePartsApi, type SparePart } from "../../api/spareParts";
import { warehouseApi, type ImportItemPayload, type PageResult, type StockImport } from "../../api/warehouse";
import { Button, Card, Icons, Input, Pagination, Select } from "../../components/ui";
import { formatDateTime, formatPrice, PER_PAGE, useWarehouseRole } from "./common";

interface Row {
  partId: string;
  quantity: string;
  unitPrice: string;
}

const emptyRow = (): Row => ({ partId: "", quantity: "1", unitPrice: "" });

export default function ImportsTab({ refreshKey, onChanged }: { refreshKey: number; onChanged: () => void }) {
  const { canWrite } = useWarehouseRole();
  const [parts, setParts] = useState<SparePart[]>([]);
  const [supplier, setSupplier] = useState("");
  const [importDate, setImportDate] = useState("");
  const [note, setNote] = useState("");
  const [rows, setRows] = useState<Row[]>([emptyRow()]);
  const [formError, setFormError] = useState("");
  const [saving, setSaving] = useState(false);
  const [success, setSuccess] = useState("");
  const [page, setPage] = useState(1);
  const [data, setData] = useState<PageResult<StockImport> | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    sparePartsApi.list({ page: 0, size: 100 })
      .then((result) => setParts(result.items))
      .catch((loadError) => setFormError(detailedErrorMessage(loadError, "Không thể tải danh mục phụ tùng.")));
  }, []);

  const load = useCallback(() => {
    setLoading(true);
    setError("");
    warehouseApi.imports({ page: page - 1, size: PER_PAGE })
      .then(setData)
      .catch((loadError) => setError(detailedErrorMessage(loadError, "Không thể tải phiếu nhập kho.")))
      .finally(() => setLoading(false));
  }, [page]);

  useEffect(load, [load, refreshKey]);

  const updateRow = (index: number, patch: Partial<Row>) =>
    setRows((current) => current.map((row, i) => (i === index ? { ...row, ...patch } : row)));

  const total = rows.reduce((sum, row) => sum + (Number(row.quantity) || 0) * (Number(row.unitPrice) || 0), 0);

  const submit = async (event: FormEvent) => {
    event.preventDefault();
    setFormError("");
    setSuccess("");
    if (!supplier.trim()) return setFormError("Vui lòng nhập nhà cung cấp.");

    const items: ImportItemPayload[] = [];
    const seen = new Set<string>();
    for (const row of rows) {
      const quantity = Number(row.quantity);
      const unitPrice = Number(row.unitPrice);
      if (!row.partId) return setFormError("Vui lòng chọn phụ tùng cho tất cả các dòng.");
      if (seen.has(row.partId)) return setFormError("Một phụ tùng chỉ xuất hiện một lần trong phiếu nhập.");
      if (!Number.isInteger(quantity) || quantity <= 0) return setFormError("Số lượng nhập phải là số nguyên lớn hơn 0.");
      if (row.unitPrice.trim() === "" || !Number.isFinite(unitPrice) || unitPrice < 0) return setFormError("Đơn giá nhập phải là số không âm.");
      seen.add(row.partId);
      items.push({ partId: Number(row.partId), quantity, unitPrice });
    }

    setSaving(true);
    try {
      await warehouseApi.createImport({
        supplier: supplier.trim(),
        importDate: importDate || null,
        note: note.trim() || null,
        items,
      });
      setSuccess("Đã nhập kho. Tồn kho và lịch sử biến động đã được cập nhật.");
      setSupplier(""); setImportDate(""); setNote(""); setRows([emptyRow()]);
      setPage(1);
      onChanged();
      load();
    } catch (saveError) {
      setFormError(detailedErrorMessage(saveError, "Không thể lập phiếu nhập."));
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="space-y-4">
      {canWrite && (
        <Card className="p-5">
          <h3 className="mb-4 font-semibold">Lập phiếu nhập kho</h3>
          <form className="space-y-4" onSubmit={submit}>
            <div className="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-3">
              <Input label="Nhà cung cấp *" value={supplier} onChange={(event) => setSupplier(event.target.value)} maxLength={200} />
              <Input label="Ngày nhập" type="datetime-local" value={importDate} onChange={(event) => setImportDate(event.target.value)} helperText="Bỏ trống để dùng thời điểm hiện tại." />
              <Input label="Ghi chú" value={note} onChange={(event) => setNote(event.target.value)} maxLength={500} />
            </div>

            <div className="space-y-3">
              {rows.map((row, index) => (
                <div key={index} className="grid grid-cols-1 items-end gap-3 md:grid-cols-[2fr_1fr_1fr_auto]">
                  <Select
                    label={index === 0 ? "Phụ tùng *" : undefined}
                    value={row.partId}
                    onChange={(event) => {
                      const picked = parts.find((part) => String(part.id) === event.target.value);
                      updateRow(index, { partId: event.target.value, unitPrice: picked && !row.unitPrice ? String(picked.unitPrice) : row.unitPrice });
                    }}
                    options={[{ value: "", label: "— Chọn phụ tùng —" }, ...parts.map((part) => ({ value: String(part.id), label: `${part.id} · ${part.name}` }))]}
                  />
                  <Input label={index === 0 ? "Số lượng *" : undefined} type="number" min={1} value={row.quantity} onChange={(event) => updateRow(index, { quantity: event.target.value })} />
                  <Input label={index === 0 ? "Đơn giá nhập *" : undefined} type="number" min={0} step="any" value={row.unitPrice} onChange={(event) => updateRow(index, { unitPrice: event.target.value })} />
                  <Button type="button" variant="outline" disabled={rows.length === 1} onClick={() => setRows((current) => current.filter((_, i) => i !== index))}>Xóa dòng</Button>
                </div>
              ))}
              <Button type="button" variant="outline" icon={Icons.plus} onClick={() => setRows((current) => [...current, emptyRow()])}>Thêm phụ tùng</Button>
            </div>

            <p className="text-sm text-slate-600">Tổng tiền: <strong className="mono">{formatPrice(total)}</strong></p>
            <p className="text-xs text-slate-500">Mỗi chi tiết nhập tăng tồn kho đúng một lần và ghi một dòng biến động NHAP.</p>
            {formError && <p className="rounded-md bg-danger-soft px-3 py-2 text-sm text-danger" role="alert">{formError}</p>}
            {success && <p className="rounded-md bg-success-soft px-3 py-2 text-sm text-success" role="status">{success}</p>}
            <Button type="submit" disabled={saving}>{saving ? "Đang lưu..." : "Lưu phiếu nhập"}</Button>
          </form>
        </Card>
      )}

      {error && <p className="rounded-md bg-danger-soft px-4 py-3 text-sm text-danger" role="alert">{error}</p>}
      {loading && <Card className="p-6 text-center text-sm text-muted-foreground">Đang tải phiếu nhập...</Card>}
      {!loading && data?.items.length === 0 && !error && <Card className="p-6 text-center text-sm text-muted-foreground">Chưa có phiếu nhập kho.</Card>}
      {!loading && data?.items.map((receipt) => (
        <Card key={receipt.id} className="p-5">
          <div className="receipt-header">
            <div>
              <p className="font-semibold">Phiếu nhập #{receipt.id}</p>
              <p className="text-xs text-slate-500">{formatDateTime(receipt.importDate)} · {receipt.supplier}</p>
            </div>
            <p className="text-sm">Nhân viên kho: {receipt.warehouseStaffId}</p>
          </div>
          <table className="data-table w-full">
            <thead><tr><th>Mã</th><th>Tên phụ tùng</th><th className="text-right">Số lượng</th><th className="text-right">Đơn giá nhập</th><th className="text-right">Thành tiền</th></tr></thead>
            <tbody>
              {receipt.items.map((item) => (
                <tr key={item.partId}>
                  <td className="mono text-xs">{item.partId}</td><td>{item.partName}</td>
                  <td className="text-right">{item.quantity}</td>
                  <td className="text-right">{formatPrice(item.unitPrice)}</td>
                  <td className="text-right font-semibold">{formatPrice(item.lineTotal)}</td>
                </tr>
              ))}
            </tbody>
          </table>
          <p className="mt-3 text-right text-sm font-semibold">Tổng: {formatPrice(receipt.totalAmount)}</p>
          {receipt.note && <p className="mt-1 text-xs text-slate-500">Ghi chú: {receipt.note}</p>}
        </Card>
      ))}
      {data && <Pagination page={page} total={data.totalElements} perPage={PER_PAGE} onChange={setPage} />}
    </div>
  );
}
'@
Write-RepoFile 'frontend/src/features/warehouse/IssuesTab.tsx' @'
// TV3-TUAN8
import { FormEvent, useCallback, useEffect, useState } from "react";
import { detailedErrorMessage } from "../../api/errors";
import { sparePartsApi, type SparePart } from "../../api/spareParts";
import { warehouseApi, type IssueItem, type PageResult, type StockIssue } from "../../api/warehouse";
import { Badge, Button, Card, Icons, Input, Modal, Pagination, Select } from "../../components/ui";
import { formatDateTime, PER_PAGE, useWarehouseRole } from "./common";

interface Row {
  partId: string;
  quantity: string;
}

const emptyRow = (): Row => ({ partId: "", quantity: "1" });

export default function IssuesTab({ refreshKey, onChanged }: { refreshKey: number; onChanged: () => void }) {
  const { canWrite, canConfirmUsage, role, needsTechnicianId } = useWarehouseRole();
  // Kỹ thuật viên chỉ xem/xác nhận; tạo phiếu xuất do thủ kho/quản lý.
  const canIssue = canWrite && role !== "TECHNICIAN";

  const [parts, setParts] = useState<SparePart[]>([]);
  const [orderId, setOrderId] = useState("");
  const [technicianId, setTechnicianId] = useState("");
  const [reason, setReason] = useState("");
  const [rows, setRows] = useState<Row[]>([emptyRow()]);
  const [formError, setFormError] = useState("");
  const [saving, setSaving] = useState(false);
  const [success, setSuccess] = useState("");
  const [page, setPage] = useState(1);
  const [data, setData] = useState<PageResult<StockIssue> | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  const [confirming, setConfirming] = useState<{ issue: StockIssue; item: IssueItem } | null>(null);
  const [actualUsed, setActualUsed] = useState("");
  const [confirmTechnician, setConfirmTechnician] = useState("");
  const [confirmError, setConfirmError] = useState("");
  const [confirmBusy, setConfirmBusy] = useState(false);

  useEffect(() => {
    if (!canIssue) return;
    sparePartsApi.list({ page: 0, size: 100 })
      .then((result) => setParts(result.items))
      .catch((loadError) => setFormError(detailedErrorMessage(loadError, "Không thể tải danh mục phụ tùng.")));
  }, [canIssue]);

  const load = useCallback(() => {
    setLoading(true);
    setError("");
    warehouseApi.issues({ page: page - 1, size: PER_PAGE })
      .then(setData)
      .catch((loadError) => setError(detailedErrorMessage(loadError, "Không thể tải phiếu xuất kho.")))
      .finally(() => setLoading(false));
  }, [page]);

  useEffect(load, [load, refreshKey]);

  const updateRow = (index: number, patch: Partial<Row>) =>
    setRows((current) => current.map((row, i) => (i === index ? { ...row, ...patch } : row)));

  const submit = async (event: FormEvent) => {
    event.preventDefault();
    setFormError("");
    setSuccess("");
    const order = Number(orderId);
    const technician = technicianId.trim() === "" ? null : Number(technicianId);
    if (!Number.isInteger(order) || order <= 0) return setFormError("Vui lòng nhập mã phiếu sửa chữa hợp lệ.");
    if (technician !== null && (!Number.isInteger(technician) || technician <= 0)) return setFormError("Mã kỹ thuật viên không hợp lệ.");
    if (!reason.trim()) return setFormError("Vui lòng nhập lý do xuất.");

    const items: { partId: number; quantity: number }[] = [];
    const seen = new Set<string>();
    for (const row of rows) {
      const quantity = Number(row.quantity);
      if (!row.partId) return setFormError("Vui lòng chọn phụ tùng cho tất cả các dòng.");
      if (seen.has(row.partId)) return setFormError("Một phụ tùng chỉ xuất hiện một lần trong phiếu xuất.");
      if (!Number.isInteger(quantity) || quantity <= 0) return setFormError("Số lượng cấp phát phải là số nguyên lớn hơn 0.");
      seen.add(row.partId);
      items.push({ partId: Number(row.partId), quantity });
    }

    setSaving(true);
    try {
      await warehouseApi.createIssue({ repairOrderId: order, requestedTechnicianId: technician, reason: reason.trim(), items });
      // Không báo "đã trừ tồn": cấp phát chưa giảm tồn.
      setSuccess("Đã cấp phát — chờ KTV xác nhận thực dùng. Tồn kho chưa thay đổi.");
      setOrderId(""); setTechnicianId(""); setReason(""); setRows([emptyRow()]);
      setPage(1);
      load();
    } catch (saveError) {
      setFormError(detailedErrorMessage(saveError, "Không thể lập phiếu xuất."));
    } finally {
      setSaving(false);
    }
  };

  const openConfirm = (issue: StockIssue, item: IssueItem) => {
    setConfirming({ issue, item });
    setActualUsed(String(item.issuedQuantity));
    setConfirmTechnician(issue.requestedTechnicianId ? String(issue.requestedTechnicianId) : "");
    setConfirmError("");
  };

  const submitConfirm = async (event: FormEvent) => {
    event.preventDefault();
    if (!confirming) return;
    setConfirmError("");
    const used = Number(actualUsed);
    if (!Number.isInteger(used) || used < 0 || used > confirming.item.issuedQuantity) {
      return setConfirmError(`Số lượng thực dùng phải là số nguyên từ 0 đến ${confirming.item.issuedQuantity}.`);
    }
    const technician = Number(confirmTechnician);
    if (needsTechnicianId && (!Number.isInteger(technician) || technician <= 0)) return setConfirmError("Vui lòng nhập mã kỹ thuật viên xác nhận.");

    setConfirmBusy(true);
    try {
      await warehouseApi.confirmUsage(confirming.issue.id, confirming.item.partId, {
        actualUsed: used,
        technicianId: needsTechnicianId ? technician : null,
      });
      setConfirming(null);
      setSuccess("Đã xác nhận thực dùng. Tồn kho giảm theo số lượng thực dùng.");
      onChanged();
      load();
    } catch (confirmErr) {
      setConfirmError(detailedErrorMessage(confirmErr, "Không thể xác nhận thực dùng."));
    } finally {
      setConfirmBusy(false);
    }
  };

  const used = Number(actualUsed);
  const preview = confirming && Number.isInteger(used) && used >= 0 && used <= confirming.item.issuedQuantity
    ? confirming.item.issuedQuantity - used
    : null;

  return (
    <div className="space-y-4">
      <div className="rounded-lg border border-info/20 bg-info-soft p-4 text-sm text-info">
        Lập phiếu xuất là <strong>cấp phát</strong> và <strong>chưa trừ tồn kho</strong>. Tồn chỉ giảm khi kỹ thuật viên xác nhận số lượng thực dùng; phần chưa dùng được hoàn trả.
      </div>

      {canIssue && (
        <Card className="p-5">
          <h3 className="mb-4 font-semibold">Lập phiếu xuất kho (cấp phát)</h3>
          <form className="space-y-4" onSubmit={submit}>
            <div className="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-3">
              <Input label="Mã phiếu sửa chữa *" type="number" min={1} value={orderId} onChange={(event) => setOrderId(event.target.value)} />
              <Input label="Mã kỹ thuật viên yêu cầu" type="number" min={1} value={technicianId} onChange={(event) => setTechnicianId(event.target.value)} helperText="Phải là KTV được phân công cho phiếu." />
              <Input label="Lý do *" value={reason} onChange={(event) => setReason(event.target.value)} maxLength={500} />
            </div>
            <div className="space-y-3">
              {rows.map((row, index) => {
                const picked = parts.find((part) => String(part.id) === row.partId);
                return (
                  <div key={index} className="grid grid-cols-1 items-end gap-3 md:grid-cols-[2fr_1fr_auto]">
                    <Select
                      label={index === 0 ? "Phụ tùng *" : undefined}
                      value={row.partId}
                      onChange={(event) => updateRow(index, { partId: event.target.value })}
                      helperText={picked ? `Tồn hiện tại: ${picked.stockQuantity}` : undefined}
                      options={[{ value: "", label: "— Chọn phụ tùng —" }, ...parts.map((part) => ({ value: String(part.id), label: `${part.id} · ${part.name}` }))]}
                    />
                    <Input label={index === 0 ? "Số lượng cấp phát *" : undefined} type="number" min={1} value={row.quantity} onChange={(event) => updateRow(index, { quantity: event.target.value })} />
                    <Button type="button" variant="outline" disabled={rows.length === 1} onClick={() => setRows((current) => current.filter((_, i) => i !== index))}>Xóa dòng</Button>
                  </div>
                );
              })}
              <Button type="button" variant="outline" icon={Icons.plus} onClick={() => setRows((current) => [...current, emptyRow()])}>Thêm phụ tùng</Button>
            </div>
            {formError && <p className="rounded-md bg-danger-soft px-3 py-2 text-sm text-danger" role="alert">{formError}</p>}
            <Button type="submit" disabled={saving}>{saving ? "Đang cấp phát..." : "Cấp phát phụ tùng"}</Button>
          </form>
        </Card>
      )}

      {success && <p className="rounded-md bg-success-soft px-4 py-3 text-sm text-success" role="status">{success}</p>}
      {error && <p className="rounded-md bg-danger-soft px-4 py-3 text-sm text-danger" role="alert">{error}</p>}
      {loading && <Card className="p-6 text-center text-sm text-muted-foreground">Đang tải phiếu xuất...</Card>}
      {!loading && data?.items.length === 0 && !error && <Card className="p-6 text-center text-sm text-muted-foreground">Chưa có phiếu xuất kho.</Card>}

      {!loading && data?.items.map((issue) => (
        <Card key={issue.id} className="p-5">
          <div className="receipt-header">
            <div>
              <p className="font-semibold">Phiếu xuất #{issue.id} · Phiếu sửa chữa {issue.repairOrderId ?? "—"}</p>
              <p className="text-xs text-slate-500">{formatDateTime(issue.issueDate)} · {issue.reason}</p>
            </div>
            <p className="text-xs text-slate-500">Nhân viên kho: {issue.warehouseStaffId} · KTV yêu cầu: {issue.requestedTechnicianId ?? "—"}</p>
          </div>
          <table className="data-table w-full">
            <thead>
              <tr>
                <th>Mã</th><th>Tên phụ tùng</th><th className="text-right">Cấp phát</th>
                <th className="text-right">Thực dùng</th><th className="text-right">Hoàn trả</th>
                <th className="text-right">Tồn sau</th><th>Trạng thái</th><th>Thao tác</th>
              </tr>
            </thead>
            <tbody>
              {issue.items.map((item) => (
                <tr key={item.partId}>
                  <td className="mono text-xs">{item.partId}</td>
                  <td>{item.partName}</td>
                  <td className="text-right">{item.issuedQuantity}</td>
                  <td className="text-right font-semibold">{item.actualUsedQuantity ?? "—"}</td>
                  <td className="text-right">{item.returnedQuantity ?? "—"}</td>
                  <td className="text-right">{item.stockAfter ?? "—"}</td>
                  <td>
                    {item.state === "DA_XAC_NHAN"
                      ? <Badge variant="completed" label="Đã xác nhận thực dùng" />
                      : <Badge variant="pending" label="Đã cấp phát — chờ KTV xác nhận" />}
                  </td>
                  <td>
                    {item.state === "CHO_XAC_NHAN" && canConfirmUsage && issue.repairOrderId !== null && (
                      <Button size="sm" variant="outline" onClick={() => openConfirm(issue, item)}>Xác nhận thực dùng</Button>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </Card>
      ))}
      {data && <Pagination page={page} total={data.totalElements} perPage={PER_PAGE} onChange={setPage} />}

      <Modal open={confirming !== null} onClose={() => setConfirming(null)} title="Xác nhận số lượng thực dùng" width="max-w-md">
        {confirming && (
          <form className="space-y-4" onSubmit={submitConfirm}>
            <p className="text-sm text-slate-700">
              <strong>{confirming.item.partName}</strong> · đã cấp phát <strong>{confirming.item.issuedQuantity}</strong>
            </p>
            <Input label="Số lượng thực dùng *" type="number" min={0} max={confirming.item.issuedQuantity} value={actualUsed} onChange={(event) => setActualUsed(event.target.value)} autoFocus />
            {needsTechnicianId && (
              <Input label="Mã kỹ thuật viên xác nhận *" type="number" min={1} value={confirmTechnician} onChange={(event) => setConfirmTechnician(event.target.value)} />
            )}
            <p className="text-sm text-slate-600">
              {preview === null ? "Nhập số lượng từ 0 đến số đã cấp phát." : <>Hoàn trả: <strong>{preview}</strong> · Tồn kho giảm: <strong>{used}</strong></>}
            </p>
            {confirmError && <p className="rounded-md bg-danger-soft px-3 py-2 text-sm text-danger" role="alert">{confirmError}</p>}
            <div className="flex flex-col-reverse gap-2 sm:flex-row sm:justify-end">
              <Button type="button" variant="outline" onClick={() => setConfirming(null)} disabled={confirmBusy}>Hủy</Button>
              <Button type="submit" disabled={confirmBusy}>{confirmBusy ? "Đang xác nhận..." : "Xác nhận"}</Button>
            </div>
          </form>
        )}
      </Modal>
    </div>
  );
}
'@
Write-RepoFile 'frontend/src/features/warehouse/ChecksTab.tsx' @'
// TV3-TUAN8
import { FormEvent, useCallback, useEffect, useState } from "react";
import { detailedErrorMessage } from "../../api/errors";
import { sparePartsApi, type SparePart } from "../../api/spareParts";
import { warehouseApi, type CheckStatus, type CheckSummary, type InventoryCheck, type PageResult } from "../../api/warehouse";
import { Badge, Button, Card, Icons, Input, Modal, Pagination, TableContainer } from "../../components/ui";
import { formatDateTime, PER_PAGE, useWarehouseRole } from "./common";

const STATUS: Record<CheckStatus, { variant: "in_progress" | "pending" | "completed" | "rejected"; label: string }> = {
  DANG_KIEM_KE: { variant: "in_progress", label: "Đang kiểm kê" },
  CHO_PHE_DUYET: { variant: "pending", label: "Chờ quản lý phê duyệt" },
  DA_HOAN_TAT: { variant: "completed", label: "Hoàn tất" },
  DA_TU_CHOI: { variant: "rejected", label: "Bị từ chối" },
};

export default function ChecksTab({ refreshKey, onChanged }: { refreshKey: number; onChanged: () => void }) {
  const { canWrite, isManager } = useWarehouseRole();
  const [page, setPage] = useState(1);
  const [data, setData] = useState<PageResult<CheckSummary> | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");
  const [selected, setSelected] = useState<InventoryCheck | null>(null);
  const [drafts, setDrafts] = useState<Record<number, { actual: string; reason: string }>>({});
  const [busy, setBusy] = useState(false);

  const [showCreate, setShowCreate] = useState(false);
  const [parts, setParts] = useState<SparePart[]>([]);
  const [picked, setPicked] = useState<number[]>([]);
  const [note, setNote] = useState("");
  const [createError, setCreateError] = useState("");

  const [rejecting, setRejecting] = useState(false);
  const [rejectReason, setRejectReason] = useState("");
  const [rejectError, setRejectError] = useState("");

  const load = useCallback(() => {
    setLoading(true);
    setError("");
    warehouseApi.checks({ page: page - 1, size: PER_PAGE })
      .then(setData)
      .catch((loadError) => setError(detailedErrorMessage(loadError, "Không thể tải danh sách kiểm kê.")))
      .finally(() => setLoading(false));
  }, [page]);

  useEffect(load, [load, refreshKey]);

  const open = async (id: number) => {
    setError("");
    try {
      const check = await warehouseApi.check(id);
      setSelected(check);
      setDrafts({});
    } catch (loadError) {
      setError(detailedErrorMessage(loadError, "Không thể tải phiên kiểm kê."));
    }
  };

  const openCreate = () => {
    setShowCreate(true);
    setPicked([]);
    setNote("");
    setCreateError("");
    sparePartsApi.list({ page: 0, size: 100 })
      .then((result) => setParts(result.items))
      .catch((loadError) => setCreateError(detailedErrorMessage(loadError, "Không thể tải danh mục phụ tùng.")));
  };

  const submitCreate = async (event: FormEvent) => {
    event.preventDefault();
    if (picked.length === 0) return setCreateError("Vui lòng chọn ít nhất một phụ tùng để kiểm kê.");
    setBusy(true);
    try {
      const check = await warehouseApi.createCheck({ note: note.trim() || null, partIds: picked });
      setShowCreate(false);
      setSelected(check);
      setSuccess("Đã tạo phiên kiểm kê. Hãy nhập số lượng thực tế cho từng phụ tùng.");
      load();
    } catch (saveError) {
      setCreateError(detailedErrorMessage(saveError, "Không thể tạo phiên kiểm kê."));
    } finally {
      setBusy(false);
    }
  };

  const saveActual = async (partId: number) => {
    if (!selected) return;
    const draft = drafts[partId];
    const actual = Number(draft?.actual);
    if (!draft || draft.actual.trim() === "" || !Number.isInteger(actual) || actual < 0) {
      return setError("Số lượng thực tế phải là số nguyên không âm.");
    }
    setBusy(true);
    setError("");
    try {
      setSelected(await warehouseApi.setActual(selected.id, partId, { actualQuantity: actual, reason: draft.reason.trim() || null }));
      setDrafts((current) => { const next = { ...current }; delete next[partId]; return next; });
      load();
    } catch (saveError) {
      setError(detailedErrorMessage(saveError, "Không thể lưu số lượng thực tế."));
    } finally {
      setBusy(false);
    }
  };

  const approve = async () => {
    if (!selected) return;
    setBusy(true);
    setError("");
    try {
      setSelected(await warehouseApi.approveCheck(selected.id, null));
      setSuccess("Đã phê duyệt điều chỉnh. Tồn kho đã được cập nhật theo số lượng thực tế.");
      onChanged();
      load();
    } catch (approveError) {
      setError(detailedErrorMessage(approveError, "Không thể phê duyệt điều chỉnh."));
    } finally {
      setBusy(false);
    }
  };

  const reject = async (event: FormEvent) => {
    event.preventDefault();
    if (!selected) return;
    if (!rejectReason.trim()) return setRejectError("Vui lòng nhập lý do từ chối.");
    setBusy(true);
    try {
      setSelected(await warehouseApi.rejectCheck(selected.id, rejectReason.trim()));
      setRejecting(false);
      setRejectReason("");
      setSuccess("Đã từ chối điều chỉnh. Tồn kho không thay đổi.");
      load();
    } catch (rejectErr) {
      setRejectError(detailedErrorMessage(rejectErr, "Không thể từ chối điều chỉnh."));
    } finally {
      setBusy(false);
    }
  };

  const status = selected ? STATUS[selected.status] : null;

  return (
    <div className="space-y-4">
      <div className="page-toolbar">
        <div>
          <p className="font-semibold">Kiểm kê tồn kho</p>
          <p className="text-xs text-slate-500">Tồn kho chỉ thay đổi sau khi quản lý phê duyệt chênh lệch.</p>
        </div>
        {canWrite && <Button icon={Icons.plus} onClick={openCreate}>Tạo phiên kiểm kê</Button>}
      </div>

      {success && <p className="rounded-md bg-success-soft px-4 py-3 text-sm text-success" role="status">{success}</p>}
      {error && <p className="rounded-md bg-danger-soft px-4 py-3 text-sm text-danger" role="alert">{error}</p>}

      <Card>
        <TableContainer>
          <table className="data-table w-full min-w-[640px]">
            <thead><tr><th>Mã</th><th>Ngày kiểm kê</th><th>Ghi chú</th><th className="text-right">Phụ tùng</th><th className="text-right">Chênh lệch</th><th>Trạng thái</th><th>Thao tác</th></tr></thead>
            <tbody>
              {loading && <tr><td colSpan={7} className="py-8 text-center text-sm text-muted-foreground">Đang tải...</td></tr>}
              {!loading && data?.items.length === 0 && <tr><td colSpan={7} className="py-8 text-center text-sm text-muted-foreground">Chưa có phiên kiểm kê.</td></tr>}
              {!loading && data?.items.map((check) => (
                <tr key={check.id}>
                  <td className="mono text-xs">{check.id}</td>
                  <td>{formatDateTime(check.checkDate)}</td>
                  <td>{check.note ?? "—"}</td>
                  <td className="text-right">{check.itemCount}</td>
                  <td className="text-right">{check.differenceCount}</td>
                  <td><Badge variant={STATUS[check.status].variant} label={STATUS[check.status].label} /></td>
                  <td><Button size="sm" variant="outline" onClick={() => void open(check.id)}>Xem</Button></td>
                </tr>
              ))}
            </tbody>
          </table>
        </TableContainer>
        <div className="border-t border-border px-4 py-3">
          <Pagination page={page} total={data?.totalElements ?? 0} perPage={PER_PAGE} onChange={setPage} />
        </div>
      </Card>

      {selected && status && (
        <Card className="p-5">
          <div className="receipt-header">
            <div>
              <p className="font-semibold">Phiên kiểm kê #{selected.id}</p>
              <p className="text-xs text-slate-500">{formatDateTime(selected.checkDate)} · nhân viên {selected.createdBy}{selected.note ? ` · ${selected.note}` : ""}</p>
            </div>
            <Badge variant={status.variant} label={status.label} />
          </div>
          <TableContainer>
            <table className="data-table w-full min-w-[720px]">
              <thead>
                <tr><th>Mã</th><th>Tên phụ tùng</th><th className="text-right">Tồn hệ thống</th><th className="text-right">Tồn thực tế</th><th className="text-right">Chênh lệch</th><th>Nguyên nhân</th><th>Điều chỉnh</th></tr>
              </thead>
              <tbody>
                {selected.items.map((item) => {
                  const draft = drafts[item.partId] ?? { actual: item.actualQuantity === null ? "" : String(item.actualQuantity), reason: item.reason ?? "" };
                  const editable = selected.status === "DANG_KIEM_KE" && canWrite;
                  return (
                    <tr key={item.partId}>
                      <td className="mono text-xs">{item.partId}</td>
                      <td>{item.partName}</td>
                      <td className="text-right">{item.systemQuantity}</td>
                      <td className="text-right">
                        {editable
                          ? <Input type="number" min={0} value={draft.actual} onChange={(event) => setDrafts((c) => ({ ...c, [item.partId]: { ...draft, actual: event.target.value } }))} />
                          : (item.actualQuantity ?? "—")}
                      </td>
                      <td className={`text-right font-semibold ${item.difference ? "text-warning" : ""}`}>{item.difference === null ? "—" : item.difference > 0 ? `+${item.difference}` : item.difference}</td>
                      <td>
                        {editable
                          ? <Input value={draft.reason} maxLength={500} onChange={(event) => setDrafts((c) => ({ ...c, [item.partId]: { ...draft, reason: event.target.value } }))} />
                          : (item.reason ?? "—")}
                      </td>
                      <td>
                        {editable
                          ? <Button size="sm" variant="outline" disabled={busy} onClick={() => void saveActual(item.partId)}>Lưu</Button>
                          : item.adjustmentApproved ? <Badge variant="completed" label="Đã điều chỉnh" /> : "—"}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </TableContainer>

          {selected.status === "CHO_PHE_DUYET" && (
            <div className="mt-4 flex flex-col gap-3 rounded-lg border border-warning/20 bg-warning-soft p-4 text-sm text-warning sm:flex-row sm:items-center sm:justify-between">
              <span>Có chênh lệch: tồn kho giữ nguyên cho đến khi quản lý phê duyệt.</span>
              {isManager && (
                <span className="flex gap-2">
                  <Button size="sm" disabled={busy} onClick={() => void approve()}>Phê duyệt điều chỉnh</Button>
                  <Button size="sm" variant="outline" disabled={busy} onClick={() => { setRejecting(true); setRejectError(""); }}>Từ chối</Button>
                </span>
              )}
            </div>
          )}
          {selected.decisionReason && <p className="mt-3 text-xs text-slate-500">Lý do quyết định: {selected.decisionReason}</p>}
        </Card>
      )}

      <Modal open={showCreate} onClose={() => setShowCreate(false)} title="Tạo phiên kiểm kê" width="max-w-xl">
        <form className="space-y-4" onSubmit={submitCreate}>
          <Input label="Ghi chú" value={note} onChange={(event) => setNote(event.target.value)} maxLength={500} />
          <div className="max-h-64 space-y-1 overflow-y-auto rounded-md border border-border p-2">
            {parts.map((part) => (
              <label key={part.id} className="flex min-h-11 cursor-pointer items-center gap-2 rounded px-2 text-sm hover:bg-slate-50">
                <input
                  type="checkbox"
                  checked={picked.includes(part.id)}
                  onChange={(event) => setPicked((current) => event.target.checked ? [...current, part.id] : current.filter((id) => id !== part.id))}
                />
                <span className="mono text-xs text-slate-400">{part.id}</span> {part.name}
              </label>
            ))}
          </div>
          <p className="text-xs text-slate-500">Đã chọn {picked.length} phụ tùng. Hệ thống ghi nhận (chụp) tồn hiện tại làm tồn hệ thống.</p>
          {createError && <p className="rounded-md bg-danger-soft px-3 py-2 text-sm text-danger" role="alert">{createError}</p>}
          <div className="flex flex-col-reverse gap-2 sm:flex-row sm:justify-end">
            <Button type="button" variant="outline" onClick={() => setShowCreate(false)} disabled={busy}>Hủy</Button>
            <Button type="submit" disabled={busy}>{busy ? "Đang tạo..." : "Tạo phiên"}</Button>
          </div>
        </form>
      </Modal>

      <Modal open={rejecting} onClose={() => setRejecting(false)} title="Từ chối điều chỉnh" width="max-w-md">
        <form className="space-y-4" onSubmit={reject}>
          <Input label="Lý do từ chối *" value={rejectReason} onChange={(event) => setRejectReason(event.target.value)} maxLength={500} autoFocus />
          {rejectError && <p className="rounded-md bg-danger-soft px-3 py-2 text-sm text-danger" role="alert">{rejectError}</p>}
          <div className="flex flex-col-reverse gap-2 sm:flex-row sm:justify-end">
            <Button type="button" variant="outline" onClick={() => setRejecting(false)} disabled={busy}>Hủy</Button>
            <Button type="submit" disabled={busy}>Từ chối</Button>
          </div>
        </form>
      </Modal>
    </div>
  );
}
'@
Write-RepoFile 'frontend/src/features/warehouse/MovementsTab.tsx' @'
// TV3-TUAN8
import { useEffect, useState } from "react";
import { detailedErrorMessage } from "../../api/errors";
import { inventoryApi, type MovementType, type PageResult, type StockMovement } from "../../api/warehouse";
import { Badge, Card, Pagination, Select, TableContainer } from "../../components/ui";
import { formatDateTime, PER_PAGE } from "./common";

const TYPE_BADGE = { NHAP: "completed", XUAT: "in_progress", KIEM_KE: "pending" } as const;
const TYPE_LABEL: Record<MovementType, string> = { NHAP: "Nhập", XUAT: "Xuất", KIEM_KE: "Kiểm kê" };

export default function MovementsTab({ refreshKey }: { refreshKey: number }) {
  const [type, setType] = useState<MovementType | "ALL">("ALL");
  const [page, setPage] = useState(1);
  const [data, setData] = useState<PageResult<StockMovement> | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => setPage(1), [type]);

  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    setError("");
    inventoryApi.movements({ page: page - 1, size: PER_PAGE, type })
      .then((result) => { if (!cancelled) setData(result); })
      .catch((loadError) => { if (!cancelled) setError(detailedErrorMessage(loadError, "Không thể tải lịch sử biến động kho.")); })
      .finally(() => { if (!cancelled) setLoading(false); });
    return () => { cancelled = true; };
  }, [page, type, refreshKey]);

  return (
    <div className="space-y-4">
      <div className="sm:w-60">
        <Select
          value={type}
          onChange={(event) => setType(event.target.value as MovementType | "ALL")}
          options={[
            { value: "ALL", label: "Tất cả loại biến động" },
            { value: "NHAP", label: "Nhập kho" },
            { value: "XUAT", label: "Xuất (thực dùng)" },
            { value: "KIEM_KE", label: "Kiểm kê" },
          ]}
        />
      </div>
      {error && <p className="rounded-md bg-danger-soft px-4 py-3 text-sm text-danger" role="alert">{error}</p>}
      <Card>
        <TableContainer>
          <table className="data-table w-full min-w-[860px]">
            <thead>
              <tr>
                <th>Mã</th><th>Thời gian</th><th>Phụ tùng</th><th>Loại</th>
                <th className="text-right">Số lượng</th><th className="text-right">Trước</th><th className="text-right">Sau</th>
                <th>Chứng từ</th><th>Ghi chú</th>
              </tr>
            </thead>
            <tbody>
              {loading && <tr><td colSpan={9} className="py-8 text-center text-sm text-muted-foreground">Đang tải...</td></tr>}
              {!loading && data?.items.length === 0 && !error && <tr><td colSpan={9} className="py-8 text-center text-sm text-muted-foreground">Chưa có biến động kho.</td></tr>}
              {!loading && data?.items.map((movement) => (
                <tr key={movement.id}>
                  <td className="mono text-xs">{movement.id}</td>
                  <td>{formatDateTime(movement.time)}</td>
                  <td>{movement.partId} · {movement.partName}</td>
                  <td><Badge variant={TYPE_BADGE[movement.type]} label={TYPE_LABEL[movement.type]} /></td>
                  <td className="text-right font-semibold">{movement.quantity}</td>
                  <td className="text-right">{movement.quantityBefore ?? "—"}</td>
                  <td className="text-right">{movement.quantityAfter ?? "—"}</td>
                  <td className="mono text-xs">
                    {movement.receiptId ? `Nhập #${movement.receiptId}` : movement.issueId ? `Xuất #${movement.issueId}` : "—"}
                  </td>
                  <td className="text-sm text-slate-600">{movement.note ?? "—"}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </TableContainer>
        <div className="border-t border-border px-4 py-3">
          <Pagination page={page} total={data?.totalElements ?? 0} perPage={PER_PAGE} onChange={setPage} />
        </div>
      </Card>
    </div>
  );
}
'@
Write-RepoFile 'frontend/src/pages/Inventory.tsx' @'
// TV3-TUAN8
import { useState } from "react";
import ChecksTab from "../features/warehouse/ChecksTab";
import ImportsTab from "../features/warehouse/ImportsTab";
import IssuesTab from "../features/warehouse/IssuesTab";
import MovementsTab from "../features/warehouse/MovementsTab";
import StockTab from "../features/warehouse/StockTab";
import { Tabs } from "../components/ui";

const TABS = [
  { key: "stock", label: "Tồn kho" },
  { key: "import", label: "Nhập kho" },
  { key: "export", label: "Xuất kho" },
  { key: "audit", label: "Kiểm kê" },
  { key: "history", label: "Biến động kho" },
];

/** Quản lý kho phụ tùng: dữ liệu lấy từ Spring Boot API (SQL Server), không dùng mock. */
export default function Inventory() {
  const [tab, setTab] = useState("stock");
  // Tăng giá trị này sau mỗi thao tác làm thay đổi tồn để các tab khác tải lại.
  const [refreshKey, setRefreshKey] = useState(0);
  const changed = () => setRefreshKey((key) => key + 1);

  return (
    <div className="space-y-6">
      <div className="page-toolbar">
        <Tabs tabs={TABS} active={tab} onChange={setTab} />
      </div>

      {tab === "stock" && <StockTab refreshKey={refreshKey} />}
      {tab === "import" && <ImportsTab refreshKey={refreshKey} onChanged={changed} />}
      {tab === "export" && <IssuesTab refreshKey={refreshKey} onChanged={changed} />}
      {tab === "audit" && <ChecksTab refreshKey={refreshKey} onChanged={changed} />}
      {tab === "history" && <MovementsTab refreshKey={refreshKey} />}
    </div>
  );
}
'@
Write-RepoFile 'backend/src/test/java/com/gara/quanlygara/service/StockReceiptServiceTest.java' @'
// TV3-TUAN8
package com.gara.quanlygara.service;

import com.gara.quanlygara.dto.warehouse.ImportRequest;
import com.gara.quanlygara.entity.SparePart;
import com.gara.quanlygara.entity.StockMovement;
import com.gara.quanlygara.entity.StockReceipt;
import com.gara.quanlygara.entity.StockReceiptItem;
import com.gara.quanlygara.exception.BadRequestException;
import com.gara.quanlygara.exception.ConflictException;
import com.gara.quanlygara.exception.ResourceNotFoundException;
import com.gara.quanlygara.repository.SparePartRepository;
import com.gara.quanlygara.repository.StockMovementRepository;
import com.gara.quanlygara.repository.StockReceiptItemRepository;
import com.gara.quanlygara.repository.StockReceiptRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.transaction.annotation.Transactional;

import java.lang.reflect.Method;
import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class StockReceiptServiceTest {

    @Mock
    private StockReceiptRepository receiptRepository;
    @Mock
    private StockReceiptItemRepository itemRepository;
    @Mock
    private SparePartRepository sparePartRepository;
    @Mock
    private StockMovementRepository movementRepository;

    private StockReceiptService service;

    @BeforeEach
    void setUp() {
        StockLedger ledger = new StockLedger(sparePartRepository, movementRepository);
        service = new StockReceiptService(receiptRepository, itemRepository, sparePartRepository, ledger);
        lenient().when(sparePartRepository.updateStockQuantity(anyInt(), anyInt())).thenReturn(1);
        lenient().when(movementRepository.save(any(StockMovement.class))).thenAnswer(call -> call.getArgument(0));
        lenient().when(itemRepository.save(any(StockReceiptItem.class))).thenAnswer(call -> call.getArgument(0));
        lenient().when(receiptRepository.saveAndFlush(any(StockReceipt.class))).thenAnswer(call -> {
            StockReceipt receipt = call.getArgument(0);
            receipt.setId(3);
            return receipt;
        });
    }

    @Test
    void importIncreasesStockExactlyOnceAndRecordsMovement() {
        when(sparePartRepository.findById(5)).thenReturn(Optional.of(part(5, "Bugi")));
        when(sparePartRepository.lockStockQuantity(5)).thenReturn(Optional.of(12));
        when(itemRepository.findByReceiptId(3)).thenReturn(List.of(item(3, 5, 8, "100000.00")));

        var response = service.create(request(new ImportRequest.Item(5, 8, new BigDecimal("100000"))), 7);

        verify(sparePartRepository, times(1)).updateStockQuantity(5, 20);
        ArgumentCaptor<StockMovement> movement = ArgumentCaptor.forClass(StockMovement.class);
        verify(movementRepository, times(1)).save(movement.capture());
        assertEquals("NHAP", movement.getValue().getType());
        assertEquals(8, movement.getValue().getQuantity());
        assertEquals(12, movement.getValue().getQuantityBefore());
        assertEquals(20, movement.getValue().getQuantityAfter());
        assertEquals(3, movement.getValue().getReceiptId());
        assertEquals(3, response.id());
        assertEquals(7, response.warehouseStaffId());
        assertEquals(new BigDecimal("800000.00"), response.totalAmount());
        assertEquals("Bugi", response.items().get(0).partName());
    }

    @Test
    void importRejectsUnknownPartWithoutWritingAnything() {
        when(sparePartRepository.findById(99)).thenReturn(Optional.empty());

        assertThrows(ResourceNotFoundException.class,
                () -> service.create(request(new ImportRequest.Item(99, 1, BigDecimal.ONE)), 7));
        verify(receiptRepository, never()).saveAndFlush(any(StockReceipt.class));
        verify(sparePartRepository, never()).updateStockQuantity(anyInt(), anyInt());
    }

    @Test
    void importRejectsDuplicatePartInTheSameReceipt() {
        assertThrows(BadRequestException.class, () -> service.create(request(
                new ImportRequest.Item(5, 1, BigDecimal.ONE), new ImportRequest.Item(5, 2, BigDecimal.ONE)), 7));
        verify(receiptRepository, never()).saveAndFlush(any(StockReceipt.class));
    }

    @Test
    void importRejectsQuantityThatOverflowsStock() {
        when(sparePartRepository.findById(5)).thenReturn(Optional.of(part(5, "Bugi")));
        when(sparePartRepository.lockStockQuantity(5)).thenReturn(Optional.of(Integer.MAX_VALUE));

        assertThrows(BadRequestException.class,
                () -> service.create(request(new ImportRequest.Item(5, 1, BigDecimal.ONE)), 7));
        verify(sparePartRepository, never()).updateStockQuantity(anyInt(), anyInt());
    }

    @Test
    void importFailureInLedgerPropagatesSoTheTransactionRollsBack() throws Exception {
        when(sparePartRepository.findById(5)).thenReturn(Optional.of(part(5, "Bugi")));
        when(sparePartRepository.lockStockQuantity(5)).thenReturn(Optional.of(1));
        when(sparePartRepository.updateStockQuantity(5, 2)).thenReturn(0);

        assertThrows(ConflictException.class,
                () -> service.create(request(new ImportRequest.Item(5, 1, BigDecimal.ONE)), 7));
        // Không có try/catch nuốt lỗi và phương thức ghi chạy trong @Transactional => rollback toàn bộ.
        Method create = StockReceiptService.class.getMethod("create", ImportRequest.class, Integer.class);
        assertNotNull(create.getAnnotation(Transactional.class));
    }

    @Test
    void getRejectsMissingReceipt() {
        when(receiptRepository.findById(404)).thenReturn(Optional.empty());

        assertThrows(ResourceNotFoundException.class, () -> service.get(404));
    }

    private ImportRequest request(ImportRequest.Item... items) {
        return new ImportRequest("  Công ty ABC ", null, null, List.of(items));
    }

    private SparePart part(int id, String name) {
        SparePart part = new SparePart();
        part.setId(id);
        part.setWarehouseId(1);
        part.setName(name);
        part.setUnitPrice(new BigDecimal("180000.00"));
        part.setMinStockLevel(5);
        return part;
    }

    private StockReceiptItem item(int receiptId, int partId, int quantity, String price) {
        StockReceiptItem item = new StockReceiptItem();
        item.setReceiptId(receiptId);
        item.setPartId(partId);
        item.setQuantity(quantity);
        item.setUnitPrice(new BigDecimal(price));
        return item;
    }
}
'@
Write-RepoFile 'backend/src/test/java/com/gara/quanlygara/service/StockIssueServiceTest.java' @'
// TV3-TUAN8
package com.gara.quanlygara.service;

import com.gara.quanlygara.dto.warehouse.ConfirmUsageRequest;
import com.gara.quanlygara.dto.warehouse.IssueRequest;
import com.gara.quanlygara.entity.RepairPartItem;
import com.gara.quanlygara.entity.SparePart;
import com.gara.quanlygara.entity.StockIssue;
import com.gara.quanlygara.entity.StockIssueItem;
import com.gara.quanlygara.entity.StockMovement;
import com.gara.quanlygara.exception.BadRequestException;
import com.gara.quanlygara.exception.ConflictException;
import com.gara.quanlygara.exception.ResourceNotFoundException;
import com.gara.quanlygara.repository.RepairPartItemRepository;
import com.gara.quanlygara.repository.RepairServiceItemRepository;
import com.gara.quanlygara.repository.SparePartRepository;
import com.gara.quanlygara.repository.StockIssueItemRepository;
import com.gara.quanlygara.repository.StockIssueRepository;
import com.gara.quanlygara.repository.StockMovementRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class StockIssueServiceTest {

    private static final int ISSUE_ID = 1;
    private static final int PART_ID = 5;
    private static final int ORDER_ID = 9;
    private static final int TECHNICIAN_ID = 2;

    @Mock
    private StockIssueRepository issueRepository;
    @Mock
    private StockIssueItemRepository itemRepository;
    @Mock
    private SparePartRepository sparePartRepository;
    @Mock
    private StockMovementRepository movementRepository;
    @Mock
    private RepairPartItemRepository repairPartItemRepository;
    @Mock
    private RepairServiceItemRepository repairServiceItemRepository;

    private StockIssueService service;
    private final List<StockIssueItem> savedItems = new ArrayList<>();

    @BeforeEach
    void setUp() {
        StockLedger ledger = new StockLedger(sparePartRepository, movementRepository);
        service = new StockIssueService(issueRepository, itemRepository, sparePartRepository, movementRepository,
                repairPartItemRepository, repairServiceItemRepository, ledger);
        lenient().when(sparePartRepository.updateStockQuantity(anyInt(), anyInt())).thenReturn(1);
        lenient().when(movementRepository.save(any(StockMovement.class))).thenAnswer(call -> call.getArgument(0));
        lenient().when(itemRepository.saveAndFlush(any(StockIssueItem.class))).thenAnswer(call -> call.getArgument(0));
        lenient().when(repairPartItemRepository.saveAndFlush(any(RepairPartItem.class)))
                .thenAnswer(call -> call.getArgument(0));
        lenient().when(sparePartRepository.findById(PART_ID)).thenReturn(Optional.of(part()));
    }

    // ------------------------------------------------------------------ CẤP PHÁT (tạo phiếu xuất)

    @Test
    void issueDoesNotReduceStockOrWriteMovements() {
        arrangeIssue(10, 0, "DANG_SUA", 1L);

        var response = service.create(request(5), 7);

        verify(sparePartRepository, never()).updateStockQuantity(anyInt(), anyInt());
        verify(movementRepository, never()).save(any(StockMovement.class));
        assertEquals(1, response.items().size());
        assertEquals(5, response.items().get(0).issuedQuantity());
        assertEquals("CHO_XAC_NHAN", response.items().get(0).state());
        assertNull(response.items().get(0).actualUsedQuantity());
        assertFalse(savedItems.get(0).isConfirmed());
    }

    @Test
    void issueRejectsWhenAvailableStockCountsPendingAllocations() {
        arrangeIssue(10, 7, "DANG_SUA", 1L);

        assertThrows(ConflictException.class, () -> service.create(request(5), 7));
        verify(issueRepository, never()).saveAndFlush(any(StockIssue.class));
    }

    @Test
    void issueRejectsInsufficientStock() {
        arrangeIssue(3, 0, "DANG_SUA", 1L);

        assertThrows(ConflictException.class, () -> service.create(request(5), 7));
        verify(issueRepository, never()).saveAndFlush(any(StockIssue.class));
    }

    @Test
    void issueRejectsUnknownOrClosedRepairOrder() {
        when(repairServiceItemRepository.findRepairOrderStatus(ORDER_ID)).thenReturn(Optional.empty());
        assertThrows(ResourceNotFoundException.class, () -> service.create(request(1), 7));

        when(repairServiceItemRepository.findRepairOrderStatus(ORDER_ID)).thenReturn(Optional.of("HOAN_TAT"));
        assertThrows(ConflictException.class, () -> service.create(request(1), 7));
    }

    @Test
    void issueRejectsTechnicianNotAssignedAndUnknownPartAndDuplicates() {
        when(repairServiceItemRepository.findRepairOrderStatus(ORDER_ID)).thenReturn(Optional.of("DANG_SUA"));
        when(itemRepository.countAssignment(ORDER_ID, TECHNICIAN_ID)).thenReturn(0L);
        assertThrows(ConflictException.class, () -> service.create(request(1), 7));

        when(itemRepository.countAssignment(ORDER_ID, TECHNICIAN_ID)).thenReturn(1L);
        when(sparePartRepository.findById(PART_ID)).thenReturn(Optional.empty());
        assertThrows(ResourceNotFoundException.class, () -> service.create(request(1), 7));

        assertThrows(BadRequestException.class, () -> service.create(new IssueRequest(
                ORDER_ID, TECHNICIAN_ID, "Thay bugi",
                List.of(new IssueRequest.Item(PART_ID, 1), new IssueRequest.Item(PART_ID, 2))), 7));
    }

    // ------------------------------------------------------------------ XÁC NHẬN THỰC DÙNG

    @Test
    void actualUsedEqualsIssuedReducesStockByIssued() {
        StockIssueItem item = arrangeConfirm(5, 12, 5, null);

        var result = service.confirmUsage(ISSUE_ID, PART_ID, new ConfirmUsageRequest(5, null), TECHNICIAN_ID, true);

        verify(sparePartRepository, times(1)).updateStockQuantity(PART_ID, 7);
        assertEquals(5, result.actualUsedQuantity());
        assertEquals(0, result.returnedQuantity());
        assertEquals(7, result.stockAfter());
        assertTrue(item.isConfirmed());
    }

    @Test
    void actualLessThanIssuedReducesStockByActualAndReturnsTheRest() {
        // Cấp phát 5, thực dùng 3 => tồn giảm 3 (không phải 5), hoàn trả 2.
        StockIssueItem item = arrangeConfirm(5, 12, 3, null);

        var result = service.confirmUsage(ISSUE_ID, PART_ID, new ConfirmUsageRequest(3, null), TECHNICIAN_ID, true);

        verify(sparePartRepository, times(1)).updateStockQuantity(PART_ID, 9);
        ArgumentCaptor<StockMovement> movement = ArgumentCaptor.forClass(StockMovement.class);
        verify(movementRepository, times(1)).save(movement.capture());
        assertEquals("XUAT", movement.getValue().getType());
        assertEquals(3, movement.getValue().getQuantity());
        assertEquals(12, movement.getValue().getQuantityBefore());
        assertEquals(9, movement.getValue().getQuantityAfter());
        assertEquals(ISSUE_ID, movement.getValue().getIssueId());
        assertEquals(3, result.actualUsedQuantity());
        assertEquals(2, result.returnedQuantity());
        assertEquals(9, result.stockAfter());
        assertEquals(3, item.getActualUsedQuantity());
        assertEquals(2, item.getReturnedQuantity());
        assertEquals(TECHNICIAN_ID, item.getConfirmedTechnicianId());
    }

    @Test
    void repairPartLineUsesActualUsedNotIssued() {
        arrangeConfirm(5, 12, 3, null);
        ArgumentCaptor<RepairPartItem> line = ArgumentCaptor.forClass(RepairPartItem.class);

        service.confirmUsage(ISSUE_ID, PART_ID, new ConfirmUsageRequest(3, null), TECHNICIAN_ID, true);

        verify(repairPartItemRepository).saveAndFlush(line.capture());
        assertEquals(3, line.getValue().getQuantity());
        assertEquals(new BigDecimal("180000.00"), line.getValue().getUnitPrice());
        assertEquals(ORDER_ID, line.getValue().getRepairOrderId());
    }

    @Test
    void existingRepairPartLineIsReplacedByTheConfirmedTotalNotAdded() {
        RepairPartItem planned = new RepairPartItem();
        planned.setRepairOrderId(ORDER_ID);
        planned.setSparePartId(PART_ID);
        planned.setQuantity(5);
        planned.setUnitPrice(new BigDecimal("1.00"));
        arrangeConfirm(5, 12, 3, planned);

        service.confirmUsage(ISSUE_ID, PART_ID, new ConfirmUsageRequest(3, null), TECHNICIAN_ID, true);

        assertEquals(3, planned.getQuantity());
        assertEquals(new BigDecimal("180000.00"), planned.getUnitPrice());
    }

    @Test
    void actualUsedZeroKeepsStockAndReturnsEverything() {
        StockIssueItem item = arrangeConfirm(5, 12, 0, null);

        var result = service.confirmUsage(ISSUE_ID, PART_ID, new ConfirmUsageRequest(0, null), TECHNICIAN_ID, true);

        verify(sparePartRepository, never()).updateStockQuantity(anyInt(), anyInt());
        verify(movementRepository, never()).save(any(StockMovement.class));
        verify(repairPartItemRepository, never()).saveAndFlush(any(RepairPartItem.class));
        assertEquals(0, result.actualUsedQuantity());
        assertEquals(5, result.returnedQuantity());
        assertNull(result.stockAfter());
        assertTrue(item.isConfirmed());
    }

    @Test
    void actualUsedGreaterThanIssuedIsRejectedWithoutAnyWrite() {
        StockIssueItem item = arrangeConfirm(5, 12, 0, null);

        assertThrows(BadRequestException.class,
                () -> service.confirmUsage(ISSUE_ID, PART_ID, new ConfirmUsageRequest(6, null), TECHNICIAN_ID, true));
        verify(sparePartRepository, never()).updateStockQuantity(anyInt(), anyInt());
        verify(itemRepository, never()).saveAndFlush(any(StockIssueItem.class));
        assertFalse(item.isConfirmed());
    }

    @Test
    void confirmingTwiceIsRejected() {
        StockIssueItem item = arrangeConfirm(5, 12, 3, null);
        item.setConfirmed(true);

        assertThrows(ConflictException.class,
                () -> service.confirmUsage(ISSUE_ID, PART_ID, new ConfirmUsageRequest(3, null), TECHNICIAN_ID, true));
        verify(sparePartRepository, never()).updateStockQuantity(anyInt(), anyInt());
    }

    @Test
    void insufficientStockForActualUsedIsRejectedAndNothingChanges() {
        StockIssueItem item = arrangeConfirm(5, 2, 0, null);

        assertThrows(ConflictException.class,
                () -> service.confirmUsage(ISSUE_ID, PART_ID, new ConfirmUsageRequest(3, null), TECHNICIAN_ID, true));
        verify(sparePartRepository, never()).updateStockQuantity(anyInt(), anyInt());
        verify(movementRepository, never()).save(any(StockMovement.class));
        assertFalse(item.isConfirmed());
    }

    @Test
    void unassignedTechnicianUnconfirmedQuotationAndClosedOrderAreRejected() {
        arrangeConfirm(5, 12, 0, null);

        when(itemRepository.countAssignment(ORDER_ID, TECHNICIAN_ID)).thenReturn(0L);
        assertThrows(ConflictException.class,
                () -> service.confirmUsage(ISSUE_ID, PART_ID, new ConfirmUsageRequest(1, null), TECHNICIAN_ID, true));

        when(itemRepository.countAssignment(ORDER_ID, TECHNICIAN_ID)).thenReturn(1L);
        when(itemRepository.countConfirmedQuotation(ORDER_ID)).thenReturn(0L);
        assertThrows(ConflictException.class,
                () -> service.confirmUsage(ISSUE_ID, PART_ID, new ConfirmUsageRequest(1, null), TECHNICIAN_ID, true));

        when(itemRepository.countConfirmedQuotation(ORDER_ID)).thenReturn(1L);
        when(repairServiceItemRepository.findRepairOrderStatus(ORDER_ID)).thenReturn(Optional.of("HOAN_TAT"));
        assertThrows(ConflictException.class,
                () -> service.confirmUsage(ISSUE_ID, PART_ID, new ConfirmUsageRequest(1, null), TECHNICIAN_ID, true));
        verify(sparePartRepository, never()).updateStockQuantity(anyInt(), anyInt());
    }

    @Test
    void technicianCanOnlyConfirmAsThemselvesAndManagerMustNameOne() {
        arrangeConfirm(5, 12, 1, null);

        assertThrows(AccessDeniedException.class,
                () -> service.confirmUsage(ISSUE_ID, PART_ID, new ConfirmUsageRequest(1, 99), TECHNICIAN_ID, true));
        assertThrows(BadRequestException.class,
                () -> service.confirmUsage(ISSUE_ID, PART_ID, new ConfirmUsageRequest(1, null), null, false));

        var result = service.confirmUsage(ISSUE_ID, PART_ID, new ConfirmUsageRequest(1, TECHNICIAN_ID), null, false);
        assertEquals(TECHNICIAN_ID, result.confirmedTechnicianId());
    }

    @Test
    void confirmRejectsUnknownItemAndIssueWithoutRepairOrder() {
        when(itemRepository.findById(new StockIssueItem.Key(ISSUE_ID, PART_ID))).thenReturn(Optional.empty());
        assertThrows(ResourceNotFoundException.class,
                () -> service.confirmUsage(ISSUE_ID, PART_ID, new ConfirmUsageRequest(1, null), TECHNICIAN_ID, true));

        StockIssueItem item = issueItem(5);
        when(itemRepository.findById(new StockIssueItem.Key(ISSUE_ID, PART_ID))).thenReturn(Optional.of(item));
        StockIssue noOrder = issue();
        noOrder.setRepairOrderId(null);
        when(issueRepository.findById(ISSUE_ID)).thenReturn(Optional.of(noOrder));
        assertThrows(ConflictException.class,
                () -> service.confirmUsage(ISSUE_ID, PART_ID, new ConfirmUsageRequest(1, null), TECHNICIAN_ID, true));
    }

    @Test
    void technicianWithNoRelatedIssuesGetsAnEmptyPage() {
        when(issueRepository.findIdsRelatedToTechnician(TECHNICIAN_ID)).thenReturn(List.of());

        var page = service.getAll(0, 10, TECHNICIAN_ID);

        assertTrue(page.items().isEmpty());
        verify(issueRepository, never()).findByIdInOrderByIdDesc(any(), any(Pageable.class));
    }

    @Test
    void technicianListIsFilteredToRelatedIssues() {
        when(issueRepository.findIdsRelatedToTechnician(TECHNICIAN_ID)).thenReturn(List.of(ISSUE_ID));
        when(issueRepository.findByIdInOrderByIdDesc(any(), any(Pageable.class)))
                .thenReturn(new PageImpl<>(List.of(issue())));
        when(itemRepository.findByIssueIdIn(any())).thenReturn(List.of(issueItem(5)));

        var page = service.getAll(0, 10, TECHNICIAN_ID);

        assertEquals(1, page.items().size());
        verify(issueRepository, never()).findAllByOrderByIdDesc(any(Pageable.class));
    }

    @Test
    void mutatingOperationsAreTransactional() throws Exception {
        assertNotNull(StockIssueService.class.getMethod("create", IssueRequest.class, Integer.class)
                .getAnnotation(Transactional.class));
        assertNotNull(StockIssueService.class.getMethod("confirmUsage", Integer.class, Integer.class,
                ConfirmUsageRequest.class, Integer.class, boolean.class).getAnnotation(Transactional.class));
    }

    // ------------------------------------------------------------------ helpers

    private IssueRequest request(int quantity) {
        return new IssueRequest(ORDER_ID, TECHNICIAN_ID, "Thay bugi",
                List.of(new IssueRequest.Item(PART_ID, quantity)));
    }

    private void arrangeIssue(int stock, long pending, String orderStatus, long assigned) {
        lenient().when(repairServiceItemRepository.findRepairOrderStatus(ORDER_ID)).thenReturn(Optional.of(orderStatus));
        lenient().when(itemRepository.countAssignment(ORDER_ID, TECHNICIAN_ID)).thenReturn(assigned);
        lenient().when(sparePartRepository.lockStockQuantity(PART_ID)).thenReturn(Optional.of(stock));
        lenient().when(itemRepository.sumPendingAllocation(PART_ID)).thenReturn(pending);
        lenient().when(issueRepository.saveAndFlush(any(StockIssue.class))).thenAnswer(call -> {
            StockIssue saved = call.getArgument(0);
            saved.setId(ISSUE_ID);
            return saved;
        });
        lenient().when(itemRepository.save(any(StockIssueItem.class))).thenAnswer(call -> {
            savedItems.add(call.getArgument(0));
            return call.getArgument(0);
        });
        lenient().when(itemRepository.findByIssueId(ISSUE_ID)).thenReturn(savedItems);
    }

    /** Dựng ngữ cảnh xác nhận hợp lệ: đã phân công, báo giá đã xác nhận, phiếu sửa chữa đang sửa. */
    private StockIssueItem arrangeConfirm(int issued, int stock, long confirmedTotal, RepairPartItem existingLine) {
        StockIssueItem item = issueItem(issued);
        lenient().when(itemRepository.findById(new StockIssueItem.Key(ISSUE_ID, PART_ID))).thenReturn(Optional.of(item));
        lenient().when(issueRepository.findById(ISSUE_ID)).thenReturn(Optional.of(issue()));
        lenient().when(itemRepository.countAssignment(ORDER_ID, TECHNICIAN_ID)).thenReturn(1L);
        lenient().when(itemRepository.countConfirmedQuotation(ORDER_ID)).thenReturn(1L);
        lenient().when(repairServiceItemRepository.findRepairOrderStatus(ORDER_ID)).thenReturn(Optional.of("DANG_SUA"));
        lenient().when(sparePartRepository.lockStockQuantity(PART_ID)).thenReturn(Optional.of(stock));
        lenient().when(itemRepository.sumConfirmedActual(ORDER_ID, PART_ID)).thenReturn(confirmedTotal);
        lenient().when(repairPartItemRepository.findById(new RepairPartItem.Key(ORDER_ID, PART_ID)))
                .thenReturn(Optional.ofNullable(existingLine));
        lenient().when(movementRepository.findFirstByIssueIdAndPartIdAndTypeOrderByIdDesc(any(), any(), any()))
                .thenReturn(Optional.empty());
        return item;
    }

    private StockIssue issue() {
        StockIssue issue = new StockIssue();
        issue.setId(ISSUE_ID);
        issue.setRepairOrderId(ORDER_ID);
        issue.setWarehouseStaffId(7);
        issue.setRequestedTechnicianId(TECHNICIAN_ID);
        issue.setReason("Thay bugi");
        return issue;
    }

    private StockIssueItem issueItem(int issued) {
        StockIssueItem item = new StockIssueItem();
        item.setIssueId(ISSUE_ID);
        item.setPartId(PART_ID);
        item.setQuantity(issued);
        item.setUnitPrice(new BigDecimal("180000.00"));
        return item;
    }

    private SparePart part() {
        SparePart part = new SparePart();
        part.setId(PART_ID);
        part.setWarehouseId(1);
        part.setName("Bugi");
        part.setUnitPrice(new BigDecimal("180000.00"));
        part.setMinStockLevel(5);
        return part;
    }
}
'@
Write-RepoFile 'backend/src/test/java/com/gara/quanlygara/service/InventoryCheckServiceTest.java' @'
// TV3-TUAN8
package com.gara.quanlygara.service;

import com.gara.quanlygara.dto.warehouse.CheckActualRequest;
import com.gara.quanlygara.dto.warehouse.CheckCreateRequest;
import com.gara.quanlygara.entity.InventoryCheck;
import com.gara.quanlygara.entity.InventoryCheckItem;
import com.gara.quanlygara.entity.SparePart;
import com.gara.quanlygara.entity.StockMovement;
import com.gara.quanlygara.exception.BadRequestException;
import com.gara.quanlygara.exception.ConflictException;
import com.gara.quanlygara.exception.ResourceNotFoundException;
import com.gara.quanlygara.repository.InventoryCheckItemRepository;
import com.gara.quanlygara.repository.InventoryCheckRepository;
import com.gara.quanlygara.repository.SparePartRepository;
import com.gara.quanlygara.repository.StockMovementRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;

@ExtendWith(MockitoExtension.class)
class InventoryCheckServiceTest {

    @Mock
    private InventoryCheckRepository checkRepository;
    @Mock
    private InventoryCheckItemRepository itemRepository;
    @Mock
    private SparePartRepository sparePartRepository;
    @Mock
    private StockMovementRepository movementRepository;

    private InventoryCheckService service;
    private InventoryCheck check;
    private final List<InventoryCheckItem> store = new ArrayList<>();

    @BeforeEach
    void setUp() {
        StockLedger ledger = new StockLedger(sparePartRepository, movementRepository);
        service = new InventoryCheckService(checkRepository, itemRepository, sparePartRepository, ledger);

        lenient().when(sparePartRepository.updateStockQuantity(anyInt(), anyInt())).thenReturn(1);
        lenient().when(movementRepository.save(any(StockMovement.class))).thenAnswer(call -> call.getArgument(0));
        lenient().when(checkRepository.saveAndFlush(any(InventoryCheck.class))).thenAnswer(call -> {
            InventoryCheck saved = call.getArgument(0);
            if (saved.getId() == null) saved.setId(1);
            check = saved;
            return saved;
        });
        lenient().when(checkRepository.findById(1)).thenAnswer(call -> Optional.ofNullable(check));
        lenient().when(itemRepository.save(any(InventoryCheckItem.class))).thenAnswer(call -> {
            InventoryCheckItem item = call.getArgument(0);
            if (!store.contains(item)) store.add(item);
            return item;
        });
        lenient().when(itemRepository.saveAndFlush(any(InventoryCheckItem.class))).thenAnswer(call -> call.getArgument(0));
        lenient().when(itemRepository.findById(any(InventoryCheckItem.Key.class))).thenAnswer(call -> {
            InventoryCheckItem.Key key = call.getArgument(0);
            return store.stream().filter(i -> new InventoryCheckItem.Key(i.getCheckId(), i.getPartId()).equals(key)).findFirst();
        });
        lenient().when(itemRepository.findByCheckIdOrderByPartId(1)).thenAnswer(call ->
                store.stream().sorted(Comparator.comparing(InventoryCheckItem::getPartId)).toList());
        lenient().when(sparePartRepository.existsById(anyInt())).thenReturn(true);
        lenient().when(sparePartRepository.findAllById(any())).thenReturn(List.of(part(5, "Bugi"), part(6, "Lọc dầu")));
    }

    @Test
    void createSnapshotsSystemStockWithoutChangingIt() {
        lenient().when(sparePartRepository.lockStockQuantity(5)).thenReturn(Optional.of(10));
        lenient().when(sparePartRepository.lockStockQuantity(6)).thenReturn(Optional.of(3));

        var response = service.create(new CheckCreateRequest("Kiểm kê tháng 10", List.of(6, 5)), 7);

        assertEquals("DANG_KIEM_KE", response.status());
        assertEquals(7, response.createdBy());
        assertEquals(2, response.items().size());
        assertEquals(10, response.items().get(0).systemQuantity());
        assertEquals(3, response.items().get(1).systemQuantity());
        assertNull(response.items().get(0).actualQuantity());
        assertNull(response.items().get(0).difference());
        verify(sparePartRepository, never()).updateStockQuantity(anyInt(), anyInt());
    }

    @Test
    void createRejectsDuplicateAndUnknownParts() {
        assertThrows(BadRequestException.class,
                () -> service.create(new CheckCreateRequest(null, List.of(5, 5)), 7));

        lenient().when(sparePartRepository.existsById(99)).thenReturn(false);
        assertThrows(ResourceNotFoundException.class,
                () -> service.create(new CheckCreateRequest(null, List.of(99)), 7));
    }

    @Test
    void partialCountKeepsTheSessionOpen() {
        startSession(10, 3);

        var response = service.setActual(1, 5, new CheckActualRequest(10, null));

        assertEquals("DANG_KIEM_KE", response.status());
        verify(sparePartRepository, never()).updateStockQuantity(anyInt(), anyInt());
    }

    @Test
    void zeroDifferencesCompleteWithoutApprovalAndWithoutStockChange() {
        startSession(10, 3);

        service.setActual(1, 5, new CheckActualRequest(10, null));
        var response = service.setActual(1, 6, new CheckActualRequest(3, null));

        assertEquals("DA_HOAN_TAT", response.status());
        assertNull(response.approvedBy());
        verify(sparePartRepository, never()).updateStockQuantity(anyInt(), anyInt());
        verify(movementRepository, never()).save(any(StockMovement.class));
    }

    @Test
    void anyDifferenceWaitsForApprovalAndDoesNotChangeStock() {
        startSession(10, 3);

        service.setActual(1, 5, new CheckActualRequest(7, "Hỏng 3 cái"));
        var response = service.setActual(1, 6, new CheckActualRequest(3, null));

        assertEquals("CHO_PHE_DUYET", response.status());
        assertEquals(-3, response.items().get(0).difference());
        assertEquals("Hỏng 3 cái", response.items().get(0).reason());
        assertFalse(response.items().get(0).adjustmentApproved());
        // Trước khi phê duyệt tồn kho tuyệt đối không đổi.
        verify(sparePartRepository, never()).updateStockQuantity(anyInt(), anyInt());
        verify(movementRepository, never()).save(any(StockMovement.class));
    }

    @Test
    void approveSetsStockToActualAndRecordsKiemKeMovement() {
        startSession(10, 3);
        service.setActual(1, 5, new CheckActualRequest(7, null));
        service.setActual(1, 6, new CheckActualRequest(3, null));
        lenient().when(sparePartRepository.lockStockQuantity(5)).thenReturn(Optional.of(10));

        var response = service.approve(1, "Đồng ý điều chỉnh", 8);

        verify(sparePartRepository, times(1)).updateStockQuantity(5, 7);
        verify(sparePartRepository, never()).updateStockQuantity(6, 3);
        ArgumentCaptor<StockMovement> movement = ArgumentCaptor.forClass(StockMovement.class);
        verify(movementRepository, times(1)).save(movement.capture());
        assertEquals("KIEM_KE", movement.getValue().getType());
        assertEquals(3, movement.getValue().getQuantity());
        assertEquals(10, movement.getValue().getQuantityBefore());
        assertEquals(7, movement.getValue().getQuantityAfter());
        assertEquals("DA_HOAN_TAT", response.status());
        assertEquals(8, response.approvedBy());
        assertTrue(response.items().get(0).adjustmentApproved());
        assertFalse(response.items().get(1).adjustmentApproved());
    }

    @Test
    void approveHandlesSurplusDifference() {
        startSession(10, 3);
        service.setActual(1, 5, new CheckActualRequest(14, null));
        service.setActual(1, 6, new CheckActualRequest(3, null));
        lenient().when(sparePartRepository.lockStockQuantity(5)).thenReturn(Optional.of(10));

        service.approve(1, null, 8);

        verify(sparePartRepository).updateStockQuantity(5, 14);
        ArgumentCaptor<StockMovement> movement = ArgumentCaptor.forClass(StockMovement.class);
        verify(movementRepository).save(movement.capture());
        assertEquals(4, movement.getValue().getQuantity());
    }

    @Test
    void approveRejectsWhenStockChangedSinceTheSnapshot() {
        startSession(10, 3);
        service.setActual(1, 5, new CheckActualRequest(7, null));
        service.setActual(1, 6, new CheckActualRequest(3, null));
        lenient().when(sparePartRepository.lockStockQuantity(5)).thenReturn(Optional.of(12));

        assertThrows(ConflictException.class, () -> service.approve(1, null, 8));
        verify(sparePartRepository, never()).updateStockQuantity(anyInt(), anyInt());
        assertEquals("CHO_PHE_DUYET", check.getStatus());
    }

    @Test
    void approveOnlyWorksWhileWaitingForApproval() {
        startSession(10, 3);

        assertThrows(ConflictException.class, () -> service.approve(1, null, 8));
        service.setActual(1, 5, new CheckActualRequest(10, null));
        service.setActual(1, 6, new CheckActualRequest(3, null));
        assertThrows(ConflictException.class, () -> service.approve(1, null, 8));
    }

    @Test
    void rejectKeepsStockAndStoresTheReason() {
        startSession(10, 3);
        service.setActual(1, 5, new CheckActualRequest(7, null));
        service.setActual(1, 6, new CheckActualRequest(3, null));

        var response = service.reject(1, "Cần đếm lại", 8);

        assertEquals("DA_TU_CHOI", response.status());
        assertEquals("Cần đếm lại", response.decisionReason());
        assertEquals(8, response.approvedBy());
        verify(sparePartRepository, never()).updateStockQuantity(anyInt(), anyInt());
        verify(movementRepository, never()).save(any(StockMovement.class));
        assertThrows(ConflictException.class, () -> service.approve(1, null, 8));
    }

    @Test
    void rejectRequiresAReason() {
        startSession(10, 3);
        service.setActual(1, 5, new CheckActualRequest(7, null));
        service.setActual(1, 6, new CheckActualRequest(3, null));

        assertThrows(BadRequestException.class, () -> service.reject(1, "   ", 8));
        assertEquals("CHO_PHE_DUYET", check.getStatus());
    }

    @Test
    void actualQuantityCanOnlyBeEnteredWhileCountingAndForPartsInTheSession() {
        startSession(10, 3);

        assertThrows(ResourceNotFoundException.class,
                () -> service.setActual(1, 77, new CheckActualRequest(1, null)));
        assertThrows(BadRequestException.class,
                () -> service.setActual(1, 5, new CheckActualRequest(-1, null)));

        check.setStatus("DA_HOAN_TAT");
        assertThrows(ConflictException.class,
                () -> service.setActual(1, 5, new CheckActualRequest(1, null)));
    }

    private void startSession(int stockOfPart5, int stockOfPart6) {
        lenient().when(sparePartRepository.lockStockQuantity(5)).thenReturn(Optional.of(stockOfPart5));
        lenient().when(sparePartRepository.lockStockQuantity(6)).thenReturn(Optional.of(stockOfPart6));
        service.create(new CheckCreateRequest(null, List.of(5, 6)), 7);
    }

    private SparePart part(int id, String name) {
        SparePart part = new SparePart();
        part.setId(id);
        part.setWarehouseId(1);
        part.setName(name);
        part.setUnitPrice(new BigDecimal("1.00"));
        part.setMinStockLevel(1);
        return part;
    }
}
'@
Write-RepoFile 'backend/src/test/java/com/gara/quanlygara/service/InventoryServiceTest.java' @'
// TV3-TUAN8
package com.gara.quanlygara.service;

import com.gara.quanlygara.dto.warehouse.StockStatus;
import com.gara.quanlygara.entity.SparePart;
import com.gara.quanlygara.exception.BadRequestException;
import com.gara.quanlygara.repository.SparePartRepository;
import com.gara.quanlygara.repository.StockMovementRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.test.util.ReflectionTestUtils;

import java.math.BigDecimal;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class InventoryServiceTest {

    @Mock
    private SparePartRepository sparePartRepository;
    @Mock
    private StockMovementRepository movementRepository;

    private InventoryService service;

    @BeforeEach
    void setUp() {
        service = new InventoryService(sparePartRepository, movementRepository);
    }

    @Test
    void stockStatusIsDerivedFromStockAndMinimum() {
        assertEquals(StockStatus.HET_HANG, StockStatus.of(0, 5));
        assertEquals(StockStatus.HET_HANG, StockStatus.of(0, 0));
        assertEquals(StockStatus.SAP_HET, StockStatus.of(1, 5));
        assertEquals(StockStatus.SAP_HET, StockStatus.of(5, 5));
        assertEquals(StockStatus.CON_HANG, StockStatus.of(6, 5));
    }

    @Test
    void getStockMapsStatusAndPassesNormalizedFilters() {
        ArgumentCaptor<Pageable> captor = ArgumentCaptor.forClass(Pageable.class);
        when(sparePartRepository.searchInventory(eq("bugi"), eq("SAP_HET"), captor.capture()))
                .thenReturn(new PageImpl<>(List.of(part(1, "Bugi", 3, 5)), PageRequest.of(0, 10), 1));
        when(sparePartRepository.countAtOrBelowMinimum()).thenReturn(4L);

        var response = service.getStock(0, 10, "  bugi ", "sap_het");

        assertEquals(StockStatus.SAP_HET, response.items().get(0).stockStatus());
        assertEquals(3, response.items().get(0).stockQuantity());
        assertEquals(4, response.lowStockCount());
        assertEquals("name", captor.getValue().getSort().iterator().next().getProperty());
    }

    @Test
    void getStockWithoutFiltersUsesAllAndEmptyKeyword() {
        when(sparePartRepository.searchInventory(eq(""), eq("ALL"), any(Pageable.class)))
                .thenReturn(new PageImpl<>(List.of()));

        service.getStock(-1, 1000, null, null);

        verify(sparePartRepository).searchInventory(eq(""), eq("ALL"), any(Pageable.class));
    }

    @Test
    void getStockRejectsUnknownStatus() {
        assertThrows(BadRequestException.class, () -> service.getStock(0, 10, null, "KHONG_CO"));
        verify(sparePartRepository, never()).searchInventory(any(), any(), any(Pageable.class));
    }

    @Test
    void movementFiltersAreNormalizedAndValidated() {
        when(movementRepository.search(eq(0), eq("ALL"), any(Pageable.class))).thenReturn(new PageImpl<>(List.of()));
        when(movementRepository.search(eq(5), eq("XUAT"), any(Pageable.class))).thenReturn(new PageImpl<>(List.of()));

        service.getMovements(0, 20, null, null);
        service.getMovements(0, 20, 5, " xuat ");

        verify(movementRepository).search(eq(0), eq("ALL"), any(Pageable.class));
        verify(movementRepository).search(eq(5), eq("XUAT"), any(Pageable.class));
        assertThrows(BadRequestException.class, () -> service.getMovements(0, 20, null, "HUY"));
    }

    private SparePart part(int id, String name, int stock, int min) {
        SparePart part = new SparePart();
        part.setId(id);
        part.setWarehouseId(1);
        part.setName(name);
        part.setUnitPrice(new BigDecimal("1.00"));
        part.setMinStockLevel(min);
        ReflectionTestUtils.setField(part, "stockQuantity", stock);
        return part;
    }
}
'@
Write-RepoFile 'backend/src/test/java/com/gara/quanlygara/dto/WarehouseRequestValidationTest.java' @'
// TV3-TUAN8
package com.gara.quanlygara.dto;

import com.gara.quanlygara.dto.warehouse.CheckActualRequest;
import com.gara.quanlygara.dto.warehouse.CheckCreateRequest;
import com.gara.quanlygara.dto.warehouse.ConfirmUsageRequest;
import com.gara.quanlygara.dto.warehouse.ImportRequest;
import com.gara.quanlygara.dto.warehouse.IssueRequest;
import jakarta.validation.ConstraintViolation;
import jakarta.validation.Validation;
import jakarta.validation.Validator;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.Arrays;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

import static org.junit.jupiter.api.Assertions.assertTrue;

class WarehouseRequestValidationTest {

    private final Validator validator = Validation.buildDefaultValidatorFactory().getValidator();

    @Test
    void validImportHasNoViolations() {
        assertTrue(validator.validate(new ImportRequest("ABC", null, null,
                List.of(new ImportRequest.Item(1, 2, new BigDecimal("100"))))).isEmpty());
    }

    @Test
    void importRejectsBadQuantityPriceSupplierAndEmptyItems() {
        assertTrue(paths(new ImportRequest("ABC", null, null,
                List.of(new ImportRequest.Item(1, 0, BigDecimal.ONE)))).contains("items[0].quantity"));
        assertTrue(paths(new ImportRequest("ABC", null, null,
                List.of(new ImportRequest.Item(1, 1, new BigDecimal("-1"))))).contains("items[0].unitPrice"));
        assertTrue(paths(new ImportRequest("  ", null, null,
                List.of(new ImportRequest.Item(1, 1, BigDecimal.ONE)))).contains("supplier"));
        assertTrue(paths(new ImportRequest("ABC", null, null, List.of())).contains("items"));
        assertTrue(paths(new ImportRequest("ABC", null, null,
                List.of(new ImportRequest.Item(null, 1, BigDecimal.ONE)))).contains("items[0].partId"));
    }

    @Test
    void issueRejectsMissingOrderBadQuantityAndBlankReason() {
        assertTrue(paths(new IssueRequest(null, null, "Thay bugi",
                List.of(new IssueRequest.Item(1, 1)))).contains("repairOrderId"));
        assertTrue(paths(new IssueRequest(1, null, "Thay bugi",
                List.of(new IssueRequest.Item(1, 0)))).contains("items[0].quantity"));
        assertTrue(paths(new IssueRequest(1, null, " ", List.of(new IssueRequest.Item(1, 1)))).contains("reason"));
        assertTrue(paths(new IssueRequest(1, null, "Thay bugi", List.of())).contains("items"));
    }

    @Test
    void confirmUsageAllowsZeroButNotNegativeOrMissing() {
        assertTrue(validator.validate(new ConfirmUsageRequest(0, null)).isEmpty());
        assertTrue(paths(new ConfirmUsageRequest(-1, null)).contains("actualUsed"));
        assertTrue(paths(new ConfirmUsageRequest(null, null)).contains("actualUsed"));
    }

    @Test
    void checkRequestsValidateQuantitiesAndParts() {
        assertTrue(validator.validate(new CheckActualRequest(0, null)).isEmpty());
        assertTrue(paths(new CheckActualRequest(-1, null)).contains("actualQuantity"));
        assertTrue(paths(new CheckActualRequest(null, null)).contains("actualQuantity"));
        assertTrue(paths(new CheckCreateRequest(null, List.of())).contains("partIds"));
        assertTrue(validator.validate(new CheckCreateRequest("Ghi chú", List.of(1, 2))).isEmpty());
        assertTrue(!validator.validate(new CheckCreateRequest(null, Arrays.asList(1, null))).isEmpty());
    }

    private Set<String> paths(Object request) {
        return validator.validate(request).stream()
                .map(ConstraintViolation::getPropertyPath)
                .map(Object::toString)
                .collect(Collectors.toSet());
    }
}
'@
Write-RepoFile 'backend/src/test/java/com/gara/quanlygara/controller/InventoryApiTest.java' @'
// TV3-TUAN8
package com.gara.quanlygara.controller;

import com.gara.quanlygara.dto.warehouse.StockMovementResponse;
import com.gara.quanlygara.entity.Account;
import com.gara.quanlygara.entity.AccountRole;
import com.gara.quanlygara.entity.InventoryCheck;
import com.gara.quanlygara.entity.InventoryCheckItem;
import com.gara.quanlygara.entity.SparePart;
import com.gara.quanlygara.entity.StockIssue;
import com.gara.quanlygara.entity.StockIssueItem;
import com.gara.quanlygara.entity.StockMovement;
import com.gara.quanlygara.entity.StockReceipt;
import com.gara.quanlygara.entity.StockReceiptItem;
//__MOCK_IMPORTS__
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.hamcrest.Matchers.containsString;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.http.MediaType.APPLICATION_JSON;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
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
class InventoryApiTest {

    @Autowired
    private MockMvc mockMvc;

//__MOCK_FIELDS__

    private Account account(String username, AccountRole role, Integer employeeId) {
        Account account = new Account();
        account.setId(1);
        account.setUsername(username);
        account.setPasswordHash("hash");
        account.setRole(role);
        account.setActive(true);
        account.setEmployeeId(employeeId);
        when(accountRepository.findByUsername(username)).thenReturn(Optional.of(account));
        return account;
    }

    private SparePart part(int id, int unitPrice) {
        SparePart part = new SparePart();
        part.setId(id);
        part.setWarehouseId(1);
        part.setName("Bugi");
        part.setUnitPrice(new BigDecimal(unitPrice));
        part.setMinStockLevel(5);
        return part;
    }

    @Test
    void stockRequiresJwtAndWarehouseStaffRoles() throws Exception {
        mockMvc.perform(get("/api/inventory")).andExpect(status().isUnauthorized());
    }

    @Test
    @WithMockUser(roles = {"TECHNICIAN"})
    void technicianAndCustomerCannotReadStockList() throws Exception {
        mockMvc.perform(get("/api/inventory")).andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(roles = "CUSTOMER")
    void customerCannotReadMovements() throws Exception {
        mockMvc.perform(get("/api/inventory/movements")).andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(roles = "WAREHOUSE")
    void warehouseReadsStockWithDerivedStatusAndLowStockCount() throws Exception {
        SparePart low = part(2, 1000);
        org.springframework.test.util.ReflectionTestUtils.setField(low, "stockQuantity", 3);
        when(sparePartRepository.searchInventory(eq("bugi"), eq("SAP_HET"), any(Pageable.class)))
                .thenReturn(new PageImpl<>(List.of(low), PageRequest.of(0, 10), 1));
        when(sparePartRepository.countAtOrBelowMinimum()).thenReturn(5L);

        mockMvc.perform(get("/api/inventory").param("search", "bugi").param("status", "SAP_HET"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.items[0].stockQuantity").value(3))
                .andExpect(jsonPath("$.data.items[0].stockStatus").value("SAP_HET"))
                .andExpect(jsonPath("$.data.lowStockCount").value(5))
                .andExpect(jsonPath("$.data.totalElements").value(1));
    }

    @Test
    @WithMockUser(roles = "MANAGER")
    void stockRejectsUnknownStatusFilter() throws Exception {
        mockMvc.perform(get("/api/inventory").param("status", "KHONG_CO"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false));
    }

    @Test
    @WithMockUser(roles = "WAREHOUSE")
    void movementsAreReadFromBienDongKho() throws Exception {
        StockMovementResponse row = new StockMovementResponse(
                9L, 5, "Bugi", null, 1, LocalDateTime.of(2026, 10, 7, 9, 30), "XUAT", 3, 12, 9, "KTV xác nhận");
        when(stockMovementRepository.search(eq(5), eq("XUAT"), any(Pageable.class)))
                .thenReturn(new PageImpl<>(List.of(row), PageRequest.of(0, 20), 1));

        mockMvc.perform(get("/api/inventory/movements").param("partId", "5").param("type", "XUAT"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.items[0].type").value("XUAT"))
                .andExpect(jsonPath("$.data.items[0].quantity").value(3))
                .andExpect(jsonPath("$.data.items[0].quantityBefore").value(12))
                .andExpect(jsonPath("$.data.items[0].quantityAfter").value(9));
    }

    @Test
    void swaggerListsInventoryAndWarehouseApis() throws Exception {
        mockMvc.perform(get("/v3/api-docs"))
                .andExpect(status().isOk())
                .andExpect(content().string(containsString("/api/inventory")))
                .andExpect(content().string(containsString("/api/warehouse/imports")))
                .andExpect(content().string(containsString("/api/warehouse/exports")))
                .andExpect(content().string(containsString("/api/warehouse/checks")));
    }
}
'@
Write-RepoFile 'backend/src/test/java/com/gara/quanlygara/controller/WarehouseApiTest.java' @'
// TV3-TUAN8
package com.gara.quanlygara.controller;

import com.gara.quanlygara.dto.warehouse.StockMovementResponse;
import com.gara.quanlygara.entity.Account;
import com.gara.quanlygara.entity.AccountRole;
import com.gara.quanlygara.entity.InventoryCheck;
import com.gara.quanlygara.entity.InventoryCheckItem;
import com.gara.quanlygara.entity.SparePart;
import com.gara.quanlygara.entity.StockIssue;
import com.gara.quanlygara.entity.StockIssueItem;
import com.gara.quanlygara.entity.StockMovement;
import com.gara.quanlygara.entity.StockReceipt;
import com.gara.quanlygara.entity.StockReceiptItem;
//__MOCK_IMPORTS__
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.hamcrest.Matchers.containsString;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.http.MediaType.APPLICATION_JSON;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
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
class WarehouseApiTest {

    @Autowired
    private MockMvc mockMvc;

//__MOCK_FIELDS__

    private Account account(String username, AccountRole role, Integer employeeId) {
        Account account = new Account();
        account.setId(1);
        account.setUsername(username);
        account.setPasswordHash("hash");
        account.setRole(role);
        account.setActive(true);
        account.setEmployeeId(employeeId);
        when(accountRepository.findByUsername(username)).thenReturn(Optional.of(account));
        return account;
    }

    private SparePart part(int id, int unitPrice) {
        SparePart part = new SparePart();
        part.setId(id);
        part.setWarehouseId(1);
        part.setName("Bugi");
        part.setUnitPrice(new BigDecimal(unitPrice));
        part.setMinStockLevel(5);
        return part;
    }

    private static final String IMPORT_BODY =
            "{\"supplier\":\"Công ty ABC\",\"items\":[{\"partId\":5,\"quantity\":8,\"unitPrice\":100000}]}";
    private static final String ISSUE_BODY =
            "{\"repairOrderId\":9,\"requestedTechnicianId\":2,\"reason\":\"Thay bugi\",\"items\":[{\"partId\":5,\"quantity\":5}]}";

    // ------------------------------------------------------------------ NHẬP KHO

    @Test
    void importsRequireJwt() throws Exception {
        mockMvc.perform(get("/api/warehouse/imports")).andExpect(status().isUnauthorized());
    }

    @Test
    @WithMockUser(roles = {"TECHNICIAN"})
    void technicianCannotImport() throws Exception {
        mockMvc.perform(post("/api/warehouse/imports").contentType(APPLICATION_JSON).content(IMPORT_BODY))
                .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(username = "kho", roles = "WAREHOUSE")
    void warehouseImportRaisesStockOnceAndReturns201() throws Exception {
        account("kho", AccountRole.WAREHOUSE, 7);
        when(sparePartRepository.findById(5)).thenReturn(Optional.of(part(5, 100000)));
        when(sparePartRepository.lockStockQuantity(5)).thenReturn(Optional.of(12));
        when(sparePartRepository.updateStockQuantity(5, 20)).thenReturn(1);
        when(stockReceiptRepository.saveAndFlush(any(StockReceipt.class))).thenAnswer(call -> {
            StockReceipt receipt = call.getArgument(0);
            receipt.setId(3);
            return receipt;
        });
        when(stockReceiptItemRepository.save(any(StockReceiptItem.class))).thenAnswer(call -> call.getArgument(0));
        when(stockMovementRepository.save(any(StockMovement.class))).thenAnswer(call -> call.getArgument(0));
        StockReceiptItem saved = new StockReceiptItem();
        saved.setReceiptId(3);
        saved.setPartId(5);
        saved.setQuantity(8);
        saved.setUnitPrice(new BigDecimal("100000.00"));
        when(stockReceiptItemRepository.findByReceiptId(3)).thenReturn(List.of(saved));

        mockMvc.perform(post("/api/warehouse/imports").contentType(APPLICATION_JSON).content(IMPORT_BODY))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.id").value(3))
                .andExpect(jsonPath("$.data.warehouseStaffId").value(7))
                .andExpect(jsonPath("$.data.totalAmount").value(800000.0));

        verify(sparePartRepository).updateStockQuantity(5, 20);
    }

    @Test
    @WithMockUser(username = "kho", roles = "WAREHOUSE")
    void importRejectsInvalidBodyAndUnlinkedAccount() throws Exception {
        account("kho", AccountRole.WAREHOUSE, 7);
        mockMvc.perform(post("/api/warehouse/imports").contentType(APPLICATION_JSON)
                        .content("{\"supplier\":\" \",\"items\":[{\"partId\":5,\"quantity\":0,\"unitPrice\":-1}]}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false));

        account("kho", AccountRole.WAREHOUSE, null);
        mockMvc.perform(post("/api/warehouse/imports").contentType(APPLICATION_JSON).content(IMPORT_BODY))
                .andExpect(status().isBadRequest());
        verify(sparePartRepository, never()).updateStockQuantity(anyInt(), anyInt());
    }

    @Test
    @WithMockUser(username = "kho", roles = "WAREHOUSE")
    void importReturns404ForUnknownPart() throws Exception {
        account("kho", AccountRole.WAREHOUSE, 7);
        when(sparePartRepository.findById(5)).thenReturn(Optional.empty());

        mockMvc.perform(post("/api/warehouse/imports").contentType(APPLICATION_JSON).content(IMPORT_BODY))
                .andExpect(status().isNotFound());
    }

    // ------------------------------------------------------------------ XUẤT KHO / THỰC DÙNG

    @Test
    @WithMockUser(username = "ktv", roles = "TECHNICIAN")
    void technicianCannotCreateIssueButSeesOnlyRelatedIssues() throws Exception {
        account("ktv", AccountRole.TECHNICIAN, 2);
        mockMvc.perform(post("/api/warehouse/exports").contentType(APPLICATION_JSON).content(ISSUE_BODY))
                .andExpect(status().isForbidden());

        when(stockIssueRepository.findIdsRelatedToTechnician(2)).thenReturn(List.of());
        mockMvc.perform(get("/api/warehouse/exports"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.items.length()").value(0));
        verify(stockIssueRepository, never()).findAllByOrderByIdDesc(any(Pageable.class));
    }

    @Test
    @WithMockUser(username = "kho", roles = "WAREHOUSE")
    void warehouseIssueReturns201AndDoesNotReduceStock() throws Exception {
        account("kho", AccountRole.WAREHOUSE, 7);
        when(repairServiceItemRepository.findRepairOrderStatus(9)).thenReturn(Optional.of("DANG_SUA"));
        when(stockIssueItemRepository.countAssignment(9, 2)).thenReturn(1L);
        when(sparePartRepository.findById(5)).thenReturn(Optional.of(part(5, 180000)));
        when(sparePartRepository.lockStockQuantity(5)).thenReturn(Optional.of(10));
        when(stockIssueItemRepository.sumPendingAllocation(5)).thenReturn(0L);
        when(stockIssueRepository.saveAndFlush(any(StockIssue.class))).thenAnswer(call -> {
            StockIssue issue = call.getArgument(0);
            issue.setId(1);
            return issue;
        });
        StockIssueItem saved = new StockIssueItem();
        saved.setIssueId(1);
        saved.setPartId(5);
        saved.setQuantity(5);
        saved.setUnitPrice(new BigDecimal("180000.00"));
        when(stockIssueItemRepository.save(any(StockIssueItem.class))).thenAnswer(call -> call.getArgument(0));
        when(stockIssueItemRepository.findByIssueId(1)).thenReturn(List.of(saved));

        mockMvc.perform(post("/api/warehouse/exports").contentType(APPLICATION_JSON).content(ISSUE_BODY))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.items[0].state").value("CHO_XAC_NHAN"))
                .andExpect(jsonPath("$.data.items[0].issuedQuantity").value(5));

        verify(sparePartRepository, never()).updateStockQuantity(anyInt(), anyInt());
        verify(stockMovementRepository, never()).save(any(StockMovement.class));
    }

    @Test
    @WithMockUser(username = "kho", roles = "WAREHOUSE")
    void issueReturns409WhenStockIsNotEnough() throws Exception {
        account("kho", AccountRole.WAREHOUSE, 7);
        when(repairServiceItemRepository.findRepairOrderStatus(9)).thenReturn(Optional.of("DANG_SUA"));
        when(stockIssueItemRepository.countAssignment(9, 2)).thenReturn(1L);
        when(sparePartRepository.findById(5)).thenReturn(Optional.of(part(5, 180000)));
        when(sparePartRepository.lockStockQuantity(5)).thenReturn(Optional.of(2));
        when(stockIssueItemRepository.sumPendingAllocation(5)).thenReturn(0L);

        mockMvc.perform(post("/api/warehouse/exports").contentType(APPLICATION_JSON).content(ISSUE_BODY))
                .andExpect(status().isConflict());
    }

    @Test
    @WithMockUser(username = "ktv", roles = "TECHNICIAN")
    void technicianConfirmsActualUsedAndStockDropsByActualOnly() throws Exception {
        account("ktv", AccountRole.TECHNICIAN, 2);
        arrangeConfirmable(5, 12);

        mockMvc.perform(post("/api/warehouse/exports/1/items/5/confirm").contentType(APPLICATION_JSON)
                        .content("{\"actualUsed\":3}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.state").value("DA_XAC_NHAN"))
                .andExpect(jsonPath("$.data.issuedQuantity").value(5))
                .andExpect(jsonPath("$.data.actualUsedQuantity").value(3))
                .andExpect(jsonPath("$.data.returnedQuantity").value(2))
                .andExpect(jsonPath("$.data.stockAfter").value(9));

        verify(sparePartRepository).updateStockQuantity(5, 9);
    }

    @Test
    @WithMockUser(username = "ktv", roles = "TECHNICIAN")
    void confirmRejectsActualGreaterThanIssuedAndDoubleConfirmation() throws Exception {
        account("ktv", AccountRole.TECHNICIAN, 2);
        StockIssueItem item = arrangeConfirmable(5, 12);

        mockMvc.perform(post("/api/warehouse/exports/1/items/5/confirm").contentType(APPLICATION_JSON)
                        .content("{\"actualUsed\":6}"))
                .andExpect(status().isBadRequest());
        verify(sparePartRepository, never()).updateStockQuantity(anyInt(), anyInt());

        item.setConfirmed(true);
        mockMvc.perform(post("/api/warehouse/exports/1/items/5/confirm").contentType(APPLICATION_JSON)
                        .content("{\"actualUsed\":3}"))
                .andExpect(status().isConflict());
    }

    @Test
    @WithMockUser(username = "ktv", roles = "TECHNICIAN")
    void confirmRejectsNegativeActualUsedAtValidation() throws Exception {
        account("ktv", AccountRole.TECHNICIAN, 2);
        mockMvc.perform(post("/api/warehouse/exports/1/items/5/confirm").contentType(APPLICATION_JSON)
                        .content("{\"actualUsed\":-1}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.data.actualUsed").exists());
    }

    @Test
    @WithMockUser(username = "kho", roles = "WAREHOUSE")
    void warehouseCannotConfirmUsage() throws Exception {
        mockMvc.perform(post("/api/warehouse/exports/1/items/5/confirm").contentType(APPLICATION_JSON)
                        .content("{\"actualUsed\":3}"))
                .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(username = "quanly", roles = "MANAGER")
    void managerMustNameTheTechnicianWhenConfirming() throws Exception {
        account("quanly", AccountRole.MANAGER, 1);
        arrangeConfirmable(5, 12);

        mockMvc.perform(post("/api/warehouse/exports/1/items/5/confirm").contentType(APPLICATION_JSON)
                        .content("{\"actualUsed\":3}"))
                .andExpect(status().isBadRequest());
        mockMvc.perform(post("/api/warehouse/exports/1/items/5/confirm").contentType(APPLICATION_JSON)
                        .content("{\"actualUsed\":3,\"technicianId\":2}"))
                .andExpect(status().isOk());
    }

    // ------------------------------------------------------------------ KIỂM KÊ

    @Test
    @WithMockUser(username = "kho", roles = "WAREHOUSE")
    void warehouseCreatesCheckButCannotApproveOrReject() throws Exception {
        account("kho", AccountRole.WAREHOUSE, 7);
        when(sparePartRepository.existsById(5)).thenReturn(true);
        when(sparePartRepository.lockStockQuantity(5)).thenReturn(Optional.of(10));
        InventoryCheck[] holder = new InventoryCheck[1];
        when(inventoryCheckRepository.saveAndFlush(any(InventoryCheck.class))).thenAnswer(call -> {
            InventoryCheck check = call.getArgument(0);
            check.setId(1);
            holder[0] = check;
            return check;
        });
        when(inventoryCheckRepository.findById(1)).thenAnswer(call -> Optional.of(holder[0]));
        InventoryCheckItem item = new InventoryCheckItem();
        item.setCheckId(1);
        item.setPartId(5);
        item.setSystemQuantity(10);
        when(inventoryCheckItemRepository.save(any(InventoryCheckItem.class))).thenAnswer(call -> call.getArgument(0));
        when(inventoryCheckItemRepository.findByCheckIdOrderByPartId(1)).thenReturn(List.of(item));

        mockMvc.perform(post("/api/warehouse/checks").contentType(APPLICATION_JSON)
                        .content("{\"note\":\"Tháng 10\",\"partIds\":[5]}"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.status").value("DANG_KIEM_KE"))
                .andExpect(jsonPath("$.data.items[0].systemQuantity").value(10));

        mockMvc.perform(post("/api/warehouse/checks/1/approve").contentType(APPLICATION_JSON).content("{}"))
                .andExpect(status().isForbidden());
        mockMvc.perform(post("/api/warehouse/checks/1/reject").contentType(APPLICATION_JSON)
                        .content("{\"reason\":\"x\"}"))
                .andExpect(status().isForbidden());
        verify(sparePartRepository, never()).updateStockQuantity(anyInt(), anyInt());
    }

    @Test
    @WithMockUser(username = "admin", roles = "ADMIN")
    void adminCannotApproveInventoryAdjustments() throws Exception {
        mockMvc.perform(post("/api/warehouse/checks/1/approve").contentType(APPLICATION_JSON).content("{}"))
                .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(username = "quanly", roles = "MANAGER")
    void managerApprovalSetsStockToActualCount() throws Exception {
        account("quanly", AccountRole.MANAGER, 1);
        InventoryCheck check = new InventoryCheck();
        check.setId(1);
        check.setStatus(InventoryCheck.PENDING_APPROVAL);
        InventoryCheckItem item = new InventoryCheckItem();
        item.setCheckId(1);
        item.setPartId(5);
        item.setSystemQuantity(10);
        item.setActualQuantity(7);
        when(inventoryCheckRepository.findById(1)).thenReturn(Optional.of(check));
        when(inventoryCheckRepository.saveAndFlush(any(InventoryCheck.class))).thenAnswer(call -> call.getArgument(0));
        when(inventoryCheckItemRepository.findByCheckIdOrderByPartId(1)).thenReturn(List.of(item));
        when(inventoryCheckItemRepository.save(any(InventoryCheckItem.class))).thenAnswer(call -> call.getArgument(0));
        when(sparePartRepository.lockStockQuantity(5)).thenReturn(Optional.of(10));
        when(sparePartRepository.updateStockQuantity(5, 7)).thenReturn(1);
        when(stockMovementRepository.save(any(StockMovement.class))).thenAnswer(call -> call.getArgument(0));

        mockMvc.perform(post("/api/warehouse/checks/1/approve").contentType(APPLICATION_JSON)
                        .content("{\"reason\":\"Đồng ý\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value("DA_HOAN_TAT"))
                .andExpect(jsonPath("$.data.approvedBy").value(1));

        verify(sparePartRepository).updateStockQuantity(5, 7);
    }

    @Test
    @WithMockUser(username = "quanly", roles = "MANAGER")
    void managerRejectNeedsReasonAndNeverChangesStock() throws Exception {
        account("quanly", AccountRole.MANAGER, 1);
        InventoryCheck check = new InventoryCheck();
        check.setId(1);
        check.setStatus(InventoryCheck.PENDING_APPROVAL);
        when(inventoryCheckRepository.findById(1)).thenReturn(Optional.of(check));
        when(inventoryCheckRepository.saveAndFlush(any(InventoryCheck.class))).thenAnswer(call -> call.getArgument(0));
        when(inventoryCheckItemRepository.findByCheckIdOrderByPartId(1)).thenReturn(List.of());

        mockMvc.perform(post("/api/warehouse/checks/1/reject").contentType(APPLICATION_JSON).content("{}"))
                .andExpect(status().isBadRequest());
        mockMvc.perform(post("/api/warehouse/checks/1/reject").contentType(APPLICATION_JSON)
                        .content("{\"reason\":\"Cần đếm lại\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value("DA_TU_CHOI"));
        verify(sparePartRepository, never()).updateStockQuantity(anyInt(), anyInt());
    }

    @Test
    @WithMockUser(username = "kho", roles = "WAREHOUSE")
    void checkActualQuantityValidationReturns400() throws Exception {
        mockMvc.perform(put("/api/warehouse/checks/1/items/5").contentType(APPLICATION_JSON)
                        .content("{\"actualQuantity\":-3}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.data.actualQuantity").exists());
    }

    // ------------------------------------------------------------------ helpers

    /** Ngữ cảnh xác nhận hợp lệ: đã phân công, báo giá xác nhận, phiếu sửa chữa đang sửa, đã cấp phát 5. */
    private StockIssueItem arrangeConfirmable(int issued, int stock) {
        StockIssueItem item = new StockIssueItem();
        item.setIssueId(1);
        item.setPartId(5);
        item.setQuantity(issued);
        item.setUnitPrice(new BigDecimal("180000.00"));
        StockIssue issue = new StockIssue();
        issue.setId(1);
        issue.setRepairOrderId(9);
        issue.setReason("Thay bugi");

        when(stockIssueItemRepository.findById(new StockIssueItem.Key(1, 5))).thenReturn(Optional.of(item));
        when(stockIssueRepository.findById(1)).thenReturn(Optional.of(issue));
        when(stockIssueItemRepository.countAssignment(9, 2)).thenReturn(1L);
        when(stockIssueItemRepository.countConfirmedQuotation(9)).thenReturn(1L);
        when(repairServiceItemRepository.findRepairOrderStatus(9)).thenReturn(Optional.of("DANG_SUA"));
        when(sparePartRepository.lockStockQuantity(5)).thenReturn(Optional.of(stock));
        when(sparePartRepository.updateStockQuantity(anyInt(), anyInt())).thenReturn(1);
        when(sparePartRepository.findById(5)).thenReturn(Optional.of(part(5, 180000)));
        when(stockMovementRepository.save(any(StockMovement.class))).thenAnswer(call -> call.getArgument(0));
        when(stockIssueItemRepository.saveAndFlush(any(StockIssueItem.class))).thenAnswer(call -> call.getArgument(0));
        when(stockIssueItemRepository.sumConfirmedActual(9, 5)).thenReturn(3L);
        when(repairPartItemRepository.findById(any())).thenReturn(Optional.empty());
        when(repairPartItemRepository.saveAndFlush(any())).thenAnswer(call -> call.getArgument(0));
        return item;
    }
}
'@

Write-Step 'Va file Tuan 7 / file dung chung (chi them doan can thiet, co backup)'
Update-RepoFile 'backend/src/main/java/com/gara/quanlygara/repository/SparePartRepository.java' 'import org.springframework.data.jpa.repository.JpaRepository;' 'import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;' 'repository.Modifying;'
Update-RepoFile 'backend/src/main/java/com/gara/quanlygara/repository/SparePartRepository.java' 'import java.util.List;' 'import java.util.List;
import java.util.Optional;' 'import java.util.Optional;'
Update-RepoFile 'backend/src/main/java/com/gara/quanlygara/repository/SparePartRepository.java' '    interface WarehouseView {' '    // ---- Tuần 8: kho. Chỉ StockLedger được dùng lockStockQuantity/updateStockQuantity để ghi tồn. ----

    // Khóa dòng phụ tùng (UPDLOCK) tới hết transaction rồi đọc tồn hiện tại (bỏ qua cache của JPA).
    @Query(value = "SELECT SoLuongTon FROM PhuTung WITH (UPDLOCK, HOLDLOCK) WHERE MaPhuTung = :id", nativeQuery = true)
    Optional<Integer> lockStockQuantity(@Param("id") Integer id);

    @Modifying(flushAutomatically = true, clearAutomatically = true)
    @Query(value = "UPDATE PhuTung SET SoLuongTon = :quantity WHERE MaPhuTung = :id", nativeQuery = true)
    int updateStockQuantity(@Param("id") Integer id, @Param("quantity") Integer quantity);

    // keyword = '''' và status = ''ALL'' nghĩa là không lọc (tránh tham số null trong JPQL).
    @Query("SELECT p FROM SparePart p WHERE "
            + "(:keyword = '''' OR CAST(p.id AS string) = :keyword "
            + "OR LOWER(p.name) LIKE LOWER(CONCAT(''%'', :keyword, ''%'')) "
            + "OR LOWER(p.manufacturer) LIKE LOWER(CONCAT(''%'', :keyword, ''%''))) "
            + "AND (:status = ''ALL'' "
            + "OR (:status = ''HET_HANG'' AND p.stockQuantity = 0) "
            + "OR (:status = ''SAP_HET'' AND p.stockQuantity > 0 AND p.stockQuantity <= p.minStockLevel) "
            + "OR (:status = ''CON_HANG'' AND p.stockQuantity > p.minStockLevel))")
    Page<SparePart> searchInventory(@Param("keyword") String keyword, @Param("status") String status, Pageable pageable);

    @Query("SELECT COUNT(p) FROM SparePart p WHERE p.stockQuantity <= p.minStockLevel")
    long countAtOrBelowMinimum();

    interface WarehouseView {' 'lockStockQuantity'
Update-RepoFile 'frontend/src/App.tsx' '  manager: ["spare-parts", "repair-details"],' '  manager: ["spare-parts", "repair-details", "inventory"],' '"repair-details", "inventory"]'

Write-Step 'Dong bo @MockitoBean cho cac test Spring da co'
Sync-MockBeans

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
Write-Host "Luu y: chay backend/database/Test_SpareParts.sql trong SSMS de kiem tra rang buoc bang Xe (script tu ROLLBACK)." -ForegroundColor Yellow

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
        /XF *.log .env .env.local TV3_Tuan8_Warehouse_FINAL.zip TV3_Tuan8_Warehouse_APPLY.ps1 | Out-Null
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
Write-Host "  git commit -m `"feat(warehouse): implement stock management and inventory approval`""
Write-Host "  git push -u origin feature/cam-warehouse"
