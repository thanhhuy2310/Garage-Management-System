<#
  TV3_Tuan7_APPLY.ps1 - Tuan 7 - TV3 Hoang Van Cam
  Danh muc phu tung (PhuTung) + Chi tiet phieu sua chua (ChiTietDichVu / ChiTietPhuTung)
  Chay tu repository root:   .\TV3_Tuan7_APPLY.ps1
  Tuy chon: -SkipBuild (chi ap dung file), -NoZip (khong tao zip)
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
# 1. XAC DINH REPOSITORY ROOT + KIEM TRA CAU TRUC (checkpoint Tuan 6 phai co san)
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
    "backend/src/main/java/com/gara/quanlygara/entity/Vehicle.java",
    "backend/src/main/java/com/gara/quanlygara/controller/VehicleController.java",
    "backend/src/test/java/com/gara/quanlygara/config/SecurityConfigTest.java",
    "frontend/package.json",
    "frontend/src/api/client.ts",
    "frontend/src/api/vehicles.ts",
    "frontend/src/components/ui.tsx",
    "frontend/src/router.ts",
    "frontend/src/App.tsx",
    "frontend/src/components/Sidebar.tsx",
    "frontend/src/components/Header.tsx"
)
$missing = @($required | Where-Object { -not (Test-Path -LiteralPath (Join-Path $root $_)) })
if ($missing.Count -gt 0) {
    Stop-Fail ("Khong dung repository root ($root). Thieu:`n  - " + ($missing -join "`n  - "))
}
Set-Location -LiteralPath $root
Write-Ok "Repository root: $root"

$sql = Get-Content -LiteralPath (Join-Path $root "backend/database/QuanLyGaraOTo.sql") -Raw
foreach ($table in @("PhuTung", "ChiTietPhuTung", "ChiTietDichVu", "PhieuSuaChua", "DichVu", "Kho")) {
    if ($sql -notmatch ("CREATE TABLE " + $table + "\s*\(")) {
        Stop-Fail "QuanLyGaraOTo.sql khong co bang $table nhu du kien. Khong tao bang song song; hay gui schema thuc te cho Claude."
    }
}
Write-Ok "Schema PhuTung / ChiTietPhuTung / ChiTietDichVu khop, giu nguyen QuanLyGaraOTo.sql"

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
    if ($branch -ne "feature/cam-sparepart") { Write-Warn2 "Dang o nhanh '$branch', khong phai feature/cam-sparepart. Script KHONG tu chuyen nhanh." }
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

$script:Marker = "TV3-TUAN7"

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
        if (-not $existing.Contains($script:Marker)) {
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
Write-Step "Preflight (tim code da co cung chuc nang)"
$javaRoot = Join-Path $root "backend/src/main/java"
$mine = @("entity/SparePart.java", "entity/RepairServiceItem.java", "entity/RepairPartItem.java", "controller/SparePartController.java", "controller/RepairDetailController.java")
$foreign = @()
foreach ($file in Get-ChildItem -LiteralPath $javaRoot -Recurse -Filter "*.java") {
    $norm = $file.FullName.Replace('\', '/')
    if ($mine | Where-Object { $norm.EndsWith("/quanlygara/" + $_) }) { continue }
    $raw = [System.IO.File]::ReadAllText($file.FullName, $utf8NoBom)
    if ($raw -match '@Table\s*\(\s*name\s*=\s*"(PhuTung|ChiTietPhuTung|ChiTietDichVu)"') { $foreign += "$norm  (entity da map bang $($Matches[1]))" }
    elseif ($raw -match '"/api/spare-parts' ) { $foreign += "$norm  (da co endpoint /api/spare-parts)" }
    elseif ($raw -match '/api/repair-orders' -and $raw -match 'details') { $foreign += "$norm  (da co endpoint chi tiet phieu sua chua)" }
}
if ($foreign.Count -gt 0) {
    Stop-Fail ("Da co implementation tuong duong trong workspace - KHONG tao ban song song. Hay gui cac file sau cho Claude de tai su dung thay vi tao moi:`n  - " + ($foreign -join "`n  - "))
}
Write-Ok "Khong co entity/endpoint trung (PhuTung, ChiTietPhuTung, ChiTietDichVu, /api/spare-parts, repair-orders/details)"


Write-Step 'Tao / cap nhat file Tuan 7 (SparePart + RepairDetail)'
Write-RepoFile 'backend/src/main/java/com/gara/quanlygara/entity/SparePart.java' @'
// TV3-TUAN7
package com.gara.quanlygara.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.math.BigDecimal;

/**
 * Danh mục phụ tùng, ánh xạ bảng PhuTung (không đổi tên bảng/cột, không thêm cột).
 * SoLuongTon chỉ đọc: tồn kho do các procedure nhập/xuất kho của CSDL thay đổi,
 * entity này không có setter và Hibernate không bao giờ ghi cột đó.
 */
@Entity
@Table(name = "PhuTung")
public class SparePart {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "MaPhuTung")
    private Integer id;

    @Column(name = "MaKho", nullable = false)
    private Integer warehouseId;

    @Column(name = "TenPhuTung", nullable = false, length = 150)
    private String name;

    @Column(name = "HangSanXuat", length = 150)
    private String manufacturer;

    @Column(name = "DonGia", nullable = false, precision = 18, scale = 2)
    private BigDecimal unitPrice;

    @Column(name = "SoLuongTon", insertable = false, updatable = false)
    private Integer stockQuantity;

    @Column(name = "MucTonToiThieu", nullable = false)
    private Integer minStockLevel;

    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public Integer getWarehouseId() {
        return warehouseId;
    }

    public void setWarehouseId(Integer warehouseId) {
        this.warehouseId = warehouseId;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getManufacturer() {
        return manufacturer;
    }

    public void setManufacturer(String manufacturer) {
        this.manufacturer = manufacturer;
    }

    public BigDecimal getUnitPrice() {
        return unitPrice;
    }

    public void setUnitPrice(BigDecimal unitPrice) {
        this.unitPrice = unitPrice;
    }

    public Integer getStockQuantity() {
        return stockQuantity;
    }

    public Integer getMinStockLevel() {
        return minStockLevel;
    }

    public void setMinStockLevel(Integer minStockLevel) {
        this.minStockLevel = minStockLevel;
    }
}
'@
Write-RepoFile 'backend/src/main/java/com/gara/quanlygara/dto/sparepart/SparePartRequest.java' @'
// TV3-TUAN7
package com.gara.quanlygara.dto.sparepart;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;

/** Không có số lượng tồn: tồn kho chỉ thay đổi bằng nghiệp vụ nhập/xuất kho (Tuần 8). */
public record SparePartRequest(
        @NotNull(message = "Vui lòng chọn kho.")
        @Positive(message = "Mã kho không hợp lệ.")
        Integer warehouseId,

        @NotBlank(message = "Tên phụ tùng không được để trống.")
        @Size(max = 150, message = "Tên phụ tùng không được vượt quá 150 ký tự.")
        String name,

        @Size(max = 150, message = "Hãng sản xuất không được vượt quá 150 ký tự.")
        String manufacturer,

        @NotNull(message = "Đơn giá không được để trống.")
        @DecimalMin(value = "0", message = "Đơn giá không được âm.")
        @Digits(integer = 16, fraction = 2, message = "Đơn giá tối đa 2 chữ số thập phân.")
        BigDecimal unitPrice,

        @Min(value = 0, message = "Mức tồn tối thiểu không được âm.")
        Integer minStockLevel
) {
}
'@
Write-RepoFile 'backend/src/main/java/com/gara/quanlygara/dto/sparepart/SparePartResponse.java' @'
// TV3-TUAN7
package com.gara.quanlygara.dto.sparepart;

import com.gara.quanlygara.entity.SparePart;

import java.math.BigDecimal;

public record SparePartResponse(
        Integer id,
        Integer warehouseId,
        String name,
        String manufacturer,
        BigDecimal unitPrice,
        Integer stockQuantity,
        Integer minStockLevel
) {
    public static SparePartResponse from(SparePart part) {
        return new SparePartResponse(
                part.getId(),
                part.getWarehouseId(),
                part.getName(),
                part.getManufacturer(),
                part.getUnitPrice(),
                // Phụ tùng vừa tạo chưa được nạp lại từ CSDL: tồn mặc định của bảng là 0.
                part.getStockQuantity() == null ? 0 : part.getStockQuantity(),
                part.getMinStockLevel()
        );
    }
}
'@
Write-RepoFile 'backend/src/main/java/com/gara/quanlygara/dto/sparepart/SparePartPageResponse.java' @'
// TV3-TUAN7
package com.gara.quanlygara.dto.sparepart;

import com.gara.quanlygara.entity.SparePart;
import org.springframework.data.domain.Page;

import java.util.List;

/** page bắt đầu từ 0, giống Spring Data. */
public record SparePartPageResponse(
        List<SparePartResponse> items,
        int page,
        int size,
        long totalElements,
        int totalPages
) {
    public static SparePartPageResponse from(Page<SparePart> result) {
        return new SparePartPageResponse(
                result.getContent().stream().map(SparePartResponse::from).toList(),
                result.getNumber(),
                result.getSize(),
                result.getTotalElements(),
                result.getTotalPages()
        );
    }
}
'@
Write-RepoFile 'backend/src/main/java/com/gara/quanlygara/dto/sparepart/WarehouseOptionResponse.java' @'
// TV3-TUAN7
package com.gara.quanlygara.dto.sparepart;

/** Kho để chọn trong form phụ tùng (đọc từ bảng Kho, chỉ đọc). */
public record WarehouseOptionResponse(Integer id, String name) {
}
'@
Write-RepoFile 'backend/src/main/java/com/gara/quanlygara/repository/SparePartRepository.java' @'
// TV3-TUAN7
package com.gara.quanlygara.repository;

import com.gara.quanlygara.entity.SparePart;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface SparePartRepository extends JpaRepository<SparePart, Integer> {

    Page<SparePart> findByNameContainingIgnoreCaseOrManufacturerContainingIgnoreCase(
            String name, String manufacturer, Pageable pageable);

    // Bảng Kho thuộc nghiệp vụ kho (Tuần 8): ở đây chỉ đọc để kiểm tra khóa ngoại và đổ danh sách chọn.
    @Query(value = "SELECT COUNT(1) FROM Kho WHERE MaKho = :id", nativeQuery = true)
    long countWarehouse(@Param("id") Integer id);

    @Query(value = "SELECT MaKho AS id, TenKho AS name FROM Kho ORDER BY MaKho", nativeQuery = true)
    List<WarehouseView> findWarehouses();

    interface WarehouseView {
        Integer getId();

        String getName();
    }
}
'@
Write-RepoFile 'backend/src/main/java/com/gara/quanlygara/service/SparePartService.java' @'
// TV3-TUAN7
package com.gara.quanlygara.service;

import com.gara.quanlygara.dto.sparepart.SparePartPageResponse;
import com.gara.quanlygara.dto.sparepart.SparePartRequest;
import com.gara.quanlygara.dto.sparepart.SparePartResponse;
import com.gara.quanlygara.dto.sparepart.WarehouseOptionResponse;
import com.gara.quanlygara.entity.SparePart;
import com.gara.quanlygara.exception.ResourceNotFoundException;
import com.gara.quanlygara.repository.SparePartRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.RoundingMode;
import java.util.List;

/**
 * Danh mục phụ tùng. Không nhập kho, không xuất kho, không điều chỉnh tồn:
 * SoLuongTon không được ghi ở đây (xem SparePart).
 */
@Service
public class SparePartService {

    private static final int MAX_PAGE_SIZE = 100;

    private final SparePartRepository sparePartRepository;

    public SparePartService(SparePartRepository sparePartRepository) {
        this.sparePartRepository = sparePartRepository;
    }

    @Transactional(readOnly = true)
    public SparePartPageResponse getAll(int page, int size, String search) {
        Pageable pageable = PageRequest.of(
                Math.max(page, 0),
                Math.min(Math.max(size, 1), MAX_PAGE_SIZE),
                Sort.by("name").and(Sort.by("id")));

        String keyword = normalizeOptional(search);
        Page<SparePart> result = keyword == null
                ? sparePartRepository.findAll(pageable)
                : sparePartRepository.findByNameContainingIgnoreCaseOrManufacturerContainingIgnoreCase(
                        keyword, keyword, pageable);
        return SparePartPageResponse.from(result);
    }

    @Transactional(readOnly = true)
    public SparePartResponse getById(Integer id) {
        return SparePartResponse.from(findEntity(id));
    }

    @Transactional(readOnly = true)
    public List<WarehouseOptionResponse> getWarehouses() {
        return sparePartRepository.findWarehouses().stream()
                .map(view -> new WarehouseOptionResponse(view.getId(), view.getName()))
                .toList();
    }

    @Transactional
    public SparePartResponse create(SparePartRequest request) {
        ensureWarehouseExists(request.warehouseId());

        SparePart part = new SparePart();
        apply(part, request);
        return SparePartResponse.from(sparePartRepository.saveAndFlush(part));
    }

    @Transactional
    public SparePartResponse update(Integer id, SparePartRequest request) {
        SparePart part = findEntity(id);
        if (!request.warehouseId().equals(part.getWarehouseId())) {
            ensureWarehouseExists(request.warehouseId());
        }

        apply(part, request);
        return SparePartResponse.from(sparePartRepository.saveAndFlush(part));
    }

    private SparePart findEntity(Integer id) {
        return sparePartRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy phụ tùng."));
    }

    private void ensureWarehouseExists(Integer warehouseId) {
        if (sparePartRepository.countWarehouse(warehouseId) == 0) {
            throw new ResourceNotFoundException("Không tìm thấy kho.");
        }
    }

    private void apply(SparePart part, SparePartRequest request) {
        part.setWarehouseId(request.warehouseId());
        part.setName(request.name().trim().replaceAll("\\s+", " "));
        part.setManufacturer(normalizeOptional(request.manufacturer()));
        part.setUnitPrice(request.unitPrice().setScale(2, RoundingMode.HALF_UP));
        part.setMinStockLevel(request.minStockLevel() == null ? 0 : request.minStockLevel());
    }

    private String normalizeOptional(String value) {
        if (value == null || value.isBlank()) return null;
        return value.trim();
    }
}
'@
Write-RepoFile 'backend/src/main/java/com/gara/quanlygara/controller/SparePartController.java' @'
// TV3-TUAN7
package com.gara.quanlygara.controller;

import com.gara.quanlygara.dto.ApiResponse;
import com.gara.quanlygara.dto.sparepart.SparePartPageResponse;
import com.gara.quanlygara.dto.sparepart.SparePartRequest;
import com.gara.quanlygara.dto.sparepart.SparePartResponse;
import com.gara.quanlygara.dto.sparepart.WarehouseOptionResponse;
import com.gara.quanlygara.service.SparePartService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/spare-parts")
@PreAuthorize("hasAnyRole('ADMIN', 'MANAGER', 'WAREHOUSE', 'RECEPTIONIST', 'TECHNICIAN')")
public class SparePartController {

    private static final String CAN_WRITE = "hasAnyRole('ADMIN', 'MANAGER', 'WAREHOUSE')";

    private final SparePartService sparePartService;

    public SparePartController(SparePartService sparePartService) {
        this.sparePartService = sparePartService;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<SparePartPageResponse>> getAll(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(required = false) String search
    ) {
        return ResponseEntity.ok(ApiResponse.success("Lấy danh sách phụ tùng thành công.",
                sparePartService.getAll(page, size, search)));
    }

    @GetMapping("/warehouses")
    public ResponseEntity<ApiResponse<List<WarehouseOptionResponse>>> getWarehouses() {
        return ResponseEntity.ok(ApiResponse.success("Lấy danh sách kho thành công.",
                sparePartService.getWarehouses()));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<SparePartResponse>> getById(@PathVariable Integer id) {
        return ResponseEntity.ok(ApiResponse.success("Lấy thông tin phụ tùng thành công.",
                sparePartService.getById(id)));
    }

    @PostMapping
    @PreAuthorize(CAN_WRITE)
    public ResponseEntity<ApiResponse<SparePartResponse>> create(@Valid @RequestBody SparePartRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Thêm phụ tùng thành công.", sparePartService.create(request)));
    }

    @PutMapping("/{id}")
    @PreAuthorize(CAN_WRITE)
    public ResponseEntity<ApiResponse<SparePartResponse>> update(
            @PathVariable Integer id,
            @Valid @RequestBody SparePartRequest request
    ) {
        return ResponseEntity.ok(ApiResponse.success("Cập nhật phụ tùng thành công.",
                sparePartService.update(id, request)));
    }
}
'@
Write-RepoFile 'backend/src/main/java/com/gara/quanlygara/entity/RepairServiceItem.java' @'
// TV3-TUAN7
package com.gara.quanlygara.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.IdClass;
import jakarta.persistence.Table;

import java.io.Serializable;
import java.math.BigDecimal;
import java.util.Objects;

/** Hạng mục dịch vụ của phiếu sửa chữa: bảng ChiTietDichVu (khóa chính = phiếu + dịch vụ). */
@Entity
@Table(name = "ChiTietDichVu")
@IdClass(RepairServiceItem.Key.class)
public class RepairServiceItem {

    @Id
    @Column(name = "MaPhieuSuaChua")
    private Integer repairOrderId;

    @Id
    @Column(name = "MaDichVu")
    private Integer serviceId;

    @Column(name = "SoLuong", nullable = false)
    private Integer quantity;

    @Column(name = "DonGia", nullable = false, precision = 18, scale = 2)
    private BigDecimal unitPrice;

    // Tiến độ do nghiệp vụ kỹ thuật viên cập nhật (Huy); ThanhTien là cột tính toán của CSDL nên không ánh xạ.
    @Column(name = "TrangThai", length = 50)
    private String status;

    public static class Key implements Serializable {
        private Integer repairOrderId;
        private Integer serviceId;

        public Key() {
        }

        public Key(Integer repairOrderId, Integer serviceId) {
            this.repairOrderId = repairOrderId;
            this.serviceId = serviceId;
        }

        @Override
        public boolean equals(Object other) {
            if (this == other) return true;
            if (!(other instanceof Key key)) return false;
            return Objects.equals(repairOrderId, key.repairOrderId) && Objects.equals(serviceId, key.serviceId);
        }

        @Override
        public int hashCode() {
            return Objects.hash(repairOrderId, serviceId);
        }
    }

    public Integer getRepairOrderId() {
        return repairOrderId;
    }

    public void setRepairOrderId(Integer repairOrderId) {
        this.repairOrderId = repairOrderId;
    }

    public Integer getServiceId() {
        return serviceId;
    }

    public void setServiceId(Integer serviceId) {
        this.serviceId = serviceId;
    }

    public Integer getQuantity() {
        return quantity;
    }

    public void setQuantity(Integer quantity) {
        this.quantity = quantity;
    }

    public BigDecimal getUnitPrice() {
        return unitPrice;
    }

    public void setUnitPrice(BigDecimal unitPrice) {
        this.unitPrice = unitPrice;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }
}
'@
Write-RepoFile 'backend/src/main/java/com/gara/quanlygara/entity/RepairPartItem.java' @'
// TV3-TUAN7
package com.gara.quanlygara.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.IdClass;
import jakarta.persistence.Table;

import java.io.Serializable;
import java.math.BigDecimal;
import java.util.Objects;

/**
 * Hạng mục phụ tùng của phiếu sửa chữa: bảng ChiTietPhuTung (khóa chính = phiếu + phụ tùng).
 * Chỉ ghi dòng chi tiết; tuyệt đối không đụng SoLuongTon của PhuTung.
 */
@Entity
@Table(name = "ChiTietPhuTung")
@IdClass(RepairPartItem.Key.class)
public class RepairPartItem {

    @Id
    @Column(name = "MaPhieuSuaChua")
    private Integer repairOrderId;

    @Id
    @Column(name = "MaPhuTung")
    private Integer sparePartId;

    @Column(name = "SoLuong", nullable = false)
    private Integer quantity;

    @Column(name = "DonGia", nullable = false, precision = 18, scale = 2)
    private BigDecimal unitPrice;

    public static class Key implements Serializable {
        private Integer repairOrderId;
        private Integer sparePartId;

        public Key() {
        }

        public Key(Integer repairOrderId, Integer sparePartId) {
            this.repairOrderId = repairOrderId;
            this.sparePartId = sparePartId;
        }

        @Override
        public boolean equals(Object other) {
            if (this == other) return true;
            if (!(other instanceof Key key)) return false;
            return Objects.equals(repairOrderId, key.repairOrderId) && Objects.equals(sparePartId, key.sparePartId);
        }

        @Override
        public int hashCode() {
            return Objects.hash(repairOrderId, sparePartId);
        }
    }

    public Integer getRepairOrderId() {
        return repairOrderId;
    }

    public void setRepairOrderId(Integer repairOrderId) {
        this.repairOrderId = repairOrderId;
    }

    public Integer getSparePartId() {
        return sparePartId;
    }

    public void setSparePartId(Integer sparePartId) {
        this.sparePartId = sparePartId;
    }

    public Integer getQuantity() {
        return quantity;
    }

    public void setQuantity(Integer quantity) {
        this.quantity = quantity;
    }

    public BigDecimal getUnitPrice() {
        return unitPrice;
    }

    public void setUnitPrice(BigDecimal unitPrice) {
        this.unitPrice = unitPrice;
    }
}
'@
Write-RepoFile 'backend/src/main/java/com/gara/quanlygara/repository/RepairDetailRow.java' @'
// TV3-TUAN7
package com.gara.quanlygara.repository;

import java.math.BigDecimal;

/** Một dòng chi tiết (kèm tên dịch vụ/phụ tùng) đọc bằng truy vấn JOIN. */
public interface RepairDetailRow {
    Integer getItemId();

    String getItemName();

    Integer getQuantity();

    BigDecimal getUnitPrice();

    String getItemStatus();
}
'@
Write-RepoFile 'backend/src/main/java/com/gara/quanlygara/repository/RepairServiceItemRepository.java' @'
// TV3-TUAN7
package com.gara.quanlygara.repository;

import com.gara.quanlygara.entity.RepairServiceItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

public interface RepairServiceItemRepository extends JpaRepository<RepairServiceItem, RepairServiceItem.Key> {

    @Query(value = """
            SELECT ct.MaDichVu AS itemId, dv.TenDichVu AS itemName, ct.SoLuong AS quantity,
                   ct.DonGia AS unitPrice, ct.TrangThai AS itemStatus
            FROM ChiTietDichVu ct
            JOIN DichVu dv ON dv.MaDichVu = ct.MaDichVu
            WHERE ct.MaPhieuSuaChua = :repairOrderId
            ORDER BY ct.MaDichVu
            """, nativeQuery = true)
    List<RepairDetailRow> findDetailRows(@Param("repairOrderId") Integer repairOrderId);

    // Chỉ ĐỌC bảng của module khác (Trung: PhieuSuaChua, Huy: DichVu); không tạo entity/module thứ hai cho chúng.
    @Query(value = "SELECT TrangThai FROM PhieuSuaChua WHERE MaPhieuSuaChua = :repairOrderId", nativeQuery = true)
    Optional<String> findRepairOrderStatus(@Param("repairOrderId") Integer repairOrderId);

    @Query(value = "SELECT DonGia FROM DichVu WHERE MaDichVu = :serviceId", nativeQuery = true)
    Optional<BigDecimal> findServiceCatalogPrice(@Param("serviceId") Integer serviceId);
}
'@
Write-RepoFile 'backend/src/main/java/com/gara/quanlygara/repository/RepairPartItemRepository.java' @'
// TV3-TUAN7
package com.gara.quanlygara.repository;

import com.gara.quanlygara.entity.RepairPartItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface RepairPartItemRepository extends JpaRepository<RepairPartItem, RepairPartItem.Key> {

    @Query(value = """
            SELECT ct.MaPhuTung AS itemId, pt.TenPhuTung AS itemName, ct.SoLuong AS quantity,
                   ct.DonGia AS unitPrice, CAST(NULL AS NVARCHAR(50)) AS itemStatus
            FROM ChiTietPhuTung ct
            JOIN PhuTung pt ON pt.MaPhuTung = ct.MaPhuTung
            WHERE ct.MaPhieuSuaChua = :repairOrderId
            ORDER BY ct.MaPhuTung
            """, nativeQuery = true)
    List<RepairDetailRow> findDetailRows(@Param("repairOrderId") Integer repairOrderId);
}
'@
Write-RepoFile 'backend/src/main/java/com/gara/quanlygara/dto/repairdetail/RepairDetailType.java' @'
// TV3-TUAN7
package com.gara.quanlygara.dto.repairdetail;

import com.gara.quanlygara.exception.BadRequestException;

import java.util.Locale;

/** Hạng mục của phiếu sửa chữa là dịch vụ (ChiTietDichVu) hoặc phụ tùng (ChiTietPhuTung). */
public enum RepairDetailType {
    SERVICE,
    SPARE_PART;

    /** Giá trị trên đường dẫn: "service" hoặc "spare-part". */
    public static RepairDetailType fromPath(String value) {
        if (value == null) throw new BadRequestException("Loại hạng mục không hợp lệ.");
        try {
            return valueOf(value.trim().toUpperCase(Locale.ROOT).replace('-', '_'));
        } catch (IllegalArgumentException exception) {
            throw new BadRequestException("Loại hạng mục không hợp lệ.");
        }
    }
}
'@
Write-RepoFile 'backend/src/main/java/com/gara/quanlygara/dto/repairdetail/RepairDetailCreateRequest.java' @'
// TV3-TUAN7
package com.gara.quanlygara.dto.repairdetail;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;

import java.math.BigDecimal;

/** unitPrice bỏ trống = lấy đơn giá hiện tại của danh mục (DichVu/PhuTung). */
public record RepairDetailCreateRequest(
        @NotNull(message = "Vui lòng chọn loại hạng mục.")
        RepairDetailType type,

        @NotNull(message = "Vui lòng chọn dịch vụ hoặc phụ tùng.")
        @Positive(message = "Mã dịch vụ/phụ tùng không hợp lệ.")
        Integer itemId,

        @NotNull(message = "Số lượng không được để trống.")
        @Min(value = 1, message = "Số lượng phải lớn hơn 0.")
        Integer quantity,

        @DecimalMin(value = "0", message = "Đơn giá không được âm.")
        @Digits(integer = 16, fraction = 2, message = "Đơn giá tối đa 2 chữ số thập phân.")
        BigDecimal unitPrice
) {
}
'@
Write-RepoFile 'backend/src/main/java/com/gara/quanlygara/dto/repairdetail/RepairDetailUpdateRequest.java' @'
// TV3-TUAN7
package com.gara.quanlygara.dto.repairdetail;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;

/** unitPrice bỏ trống = giữ nguyên đơn giá đang lưu trên dòng. */
public record RepairDetailUpdateRequest(
        @NotNull(message = "Số lượng không được để trống.")
        @Min(value = 1, message = "Số lượng phải lớn hơn 0.")
        Integer quantity,

        @DecimalMin(value = "0", message = "Đơn giá không được âm.")
        @Digits(integer = 16, fraction = 2, message = "Đơn giá tối đa 2 chữ số thập phân.")
        BigDecimal unitPrice
) {
}
'@
Write-RepoFile 'backend/src/main/java/com/gara/quanlygara/dto/repairdetail/RepairDetailResponse.java' @'
// TV3-TUAN7
package com.gara.quanlygara.dto.repairdetail;

import java.math.BigDecimal;

public record RepairDetailResponse(
        RepairDetailType type,
        Integer itemId,
        String itemName,
        Integer quantity,
        BigDecimal unitPrice,
        BigDecimal lineTotal,
        String status
) {
}
'@
Write-RepoFile 'backend/src/main/java/com/gara/quanlygara/dto/repairdetail/RepairDetailsResponse.java' @'
// TV3-TUAN7
package com.gara.quanlygara.dto.repairdetail;

import java.math.BigDecimal;
import java.util.List;

public record RepairDetailsResponse(
        Integer repairOrderId,
        String repairOrderStatus,
        boolean editable,
        List<RepairDetailResponse> items,
        BigDecimal serviceTotal,
        BigDecimal partsTotal,
        BigDecimal totalAmount
) {
}
'@
Write-RepoFile 'backend/src/main/java/com/gara/quanlygara/service/RepairDetailService.java' @'
// TV3-TUAN7
package com.gara.quanlygara.service;

import com.gara.quanlygara.dto.repairdetail.RepairDetailCreateRequest;
import com.gara.quanlygara.dto.repairdetail.RepairDetailResponse;
import com.gara.quanlygara.dto.repairdetail.RepairDetailType;
import com.gara.quanlygara.dto.repairdetail.RepairDetailUpdateRequest;
import com.gara.quanlygara.dto.repairdetail.RepairDetailsResponse;
import com.gara.quanlygara.entity.RepairPartItem;
import com.gara.quanlygara.entity.RepairServiceItem;
import com.gara.quanlygara.entity.SparePart;
import com.gara.quanlygara.exception.ConflictException;
import com.gara.quanlygara.exception.ResourceNotFoundException;
import com.gara.quanlygara.repository.RepairDetailRow;
import com.gara.quanlygara.repository.RepairPartItemRepository;
import com.gara.quanlygara.repository.RepairServiceItemRepository;
import com.gara.quanlygara.repository.SparePartRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Set;

/**
 * Chi tiết phiếu sửa chữa = các dòng ChiTietDichVu + ChiTietPhuTung của một phiếu.
 * Thêm/sửa/xóa dòng KHÔNG xuất kho và KHÔNG thay đổi SoLuongTon (thuộc nghiệp vụ kho, Tuần 8).
 */
@Service
public class RepairDetailService {

    // Không sửa hạng mục khi phiếu đã đóng. Các trạng thái khác do module Phiếu sửa chữa quản lý.
    private static final Set<String> LOCKED_STATUSES = Set.of("HOAN_TAT", "DA_HUY");

    private final RepairServiceItemRepository serviceItemRepository;
    private final RepairPartItemRepository partItemRepository;
    private final SparePartRepository sparePartRepository;

    public RepairDetailService(
            RepairServiceItemRepository serviceItemRepository,
            RepairPartItemRepository partItemRepository,
            SparePartRepository sparePartRepository
    ) {
        this.serviceItemRepository = serviceItemRepository;
        this.partItemRepository = partItemRepository;
        this.sparePartRepository = sparePartRepository;
    }

    @Transactional(readOnly = true)
    public RepairDetailsResponse getAll(Integer repairOrderId) {
        String status = requireOrderStatus(repairOrderId);

        List<RepairDetailResponse> items = new ArrayList<>();
        for (RepairDetailRow row : serviceItemRepository.findDetailRows(repairOrderId)) {
            items.add(toResponse(RepairDetailType.SERVICE, row));
        }
        for (RepairDetailRow row : partItemRepository.findDetailRows(repairOrderId)) {
            items.add(toResponse(RepairDetailType.SPARE_PART, row));
        }

        BigDecimal serviceTotal = sum(items, RepairDetailType.SERVICE);
        BigDecimal partsTotal = sum(items, RepairDetailType.SPARE_PART);
        return new RepairDetailsResponse(
                repairOrderId, status, isEditable(status), items,
                serviceTotal, partsTotal, serviceTotal.add(partsTotal));
    }

    @Transactional(readOnly = true)
    public RepairDetailResponse get(Integer repairOrderId, RepairDetailType type, Integer itemId) {
        return getAll(repairOrderId).items().stream()
                .filter(item -> item.type() == type && item.itemId().equals(itemId))
                .findFirst()
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy hạng mục trong phiếu sửa chữa."));
    }

    @Transactional
    public RepairDetailResponse create(Integer repairOrderId, RepairDetailCreateRequest request) {
        ensureEditable(requireOrderStatus(repairOrderId));

        switch (request.type()) {
            case SERVICE -> createServiceItem(repairOrderId, request);
            case SPARE_PART -> createPartItem(repairOrderId, request);
        }
        return get(repairOrderId, request.type(), request.itemId());
    }

    @Transactional
    public RepairDetailResponse update(
            Integer repairOrderId, RepairDetailType type, Integer itemId, RepairDetailUpdateRequest request
    ) {
        ensureEditable(requireOrderStatus(repairOrderId));

        switch (type) {
            case SERVICE -> {
                RepairServiceItem item = serviceItemRepository
                        .findById(new RepairServiceItem.Key(repairOrderId, itemId))
                        .orElseThrow(this::itemNotFound);
                item.setQuantity(request.quantity());
                if (request.unitPrice() != null) item.setUnitPrice(scale(request.unitPrice()));
                serviceItemRepository.saveAndFlush(item);
            }
            case SPARE_PART -> {
                RepairPartItem item = partItemRepository
                        .findById(new RepairPartItem.Key(repairOrderId, itemId))
                        .orElseThrow(this::itemNotFound);
                item.setQuantity(request.quantity());
                if (request.unitPrice() != null) item.setUnitPrice(scale(request.unitPrice()));
                partItemRepository.saveAndFlush(item);
            }
        }
        return get(repairOrderId, type, itemId);
    }

    @Transactional
    public void delete(Integer repairOrderId, RepairDetailType type, Integer itemId) {
        ensureEditable(requireOrderStatus(repairOrderId));

        switch (type) {
            case SERVICE -> {
                RepairServiceItem item = serviceItemRepository
                        .findById(new RepairServiceItem.Key(repairOrderId, itemId))
                        .orElseThrow(this::itemNotFound);
                serviceItemRepository.delete(item);
            }
            case SPARE_PART -> {
                RepairPartItem item = partItemRepository
                        .findById(new RepairPartItem.Key(repairOrderId, itemId))
                        .orElseThrow(this::itemNotFound);
                partItemRepository.delete(item);
            }
        }
    }

    private void createServiceItem(Integer repairOrderId, RepairDetailCreateRequest request) {
        BigDecimal catalogPrice = serviceItemRepository.findServiceCatalogPrice(request.itemId())
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy dịch vụ."));
        if (serviceItemRepository.existsById(new RepairServiceItem.Key(repairOrderId, request.itemId()))) {
            throw new ConflictException("Dịch vụ đã có trong phiếu sửa chữa. Hãy sửa số lượng của hạng mục đó.");
        }

        RepairServiceItem item = new RepairServiceItem();
        item.setRepairOrderId(repairOrderId);
        item.setServiceId(request.itemId());
        item.setQuantity(request.quantity());
        item.setUnitPrice(scale(request.unitPrice() != null ? request.unitPrice() : catalogPrice));
        serviceItemRepository.saveAndFlush(item);
    }

    private void createPartItem(Integer repairOrderId, RepairDetailCreateRequest request) {
        // Chỉ ĐỌC phụ tùng để kiểm tra tồn tại và lấy đơn giá; không bao giờ ghi lại PhuTung/SoLuongTon.
        SparePart part = sparePartRepository.findById(request.itemId())
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy phụ tùng."));
        if (partItemRepository.existsById(new RepairPartItem.Key(repairOrderId, request.itemId()))) {
            throw new ConflictException("Phụ tùng đã có trong phiếu sửa chữa. Hãy sửa số lượng của hạng mục đó.");
        }

        RepairPartItem item = new RepairPartItem();
        item.setRepairOrderId(repairOrderId);
        item.setSparePartId(request.itemId());
        item.setQuantity(request.quantity());
        item.setUnitPrice(scale(request.unitPrice() != null ? request.unitPrice() : part.getUnitPrice()));
        partItemRepository.saveAndFlush(item);
    }

    private String requireOrderStatus(Integer repairOrderId) {
        return serviceItemRepository.findRepairOrderStatus(repairOrderId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy phiếu sửa chữa."));
    }

    private boolean isEditable(String status) {
        return status == null || !LOCKED_STATUSES.contains(status.trim().toUpperCase(Locale.ROOT));
    }

    private void ensureEditable(String status) {
        if (!isEditable(status)) {
            throw new ConflictException("Phiếu sửa chữa đã đóng, không thể thay đổi hạng mục.");
        }
    }

    private ResourceNotFoundException itemNotFound() {
        return new ResourceNotFoundException("Không tìm thấy hạng mục trong phiếu sửa chữa.");
    }

    private RepairDetailResponse toResponse(RepairDetailType type, RepairDetailRow row) {
        BigDecimal lineTotal = row.getUnitPrice()
                .multiply(BigDecimal.valueOf(row.getQuantity()))
                .setScale(2, RoundingMode.HALF_UP);
        return new RepairDetailResponse(
                type, row.getItemId(), row.getItemName(), row.getQuantity(),
                scale(row.getUnitPrice()), lineTotal, row.getItemStatus());
    }

    private BigDecimal sum(List<RepairDetailResponse> items, RepairDetailType type) {
        return items.stream()
                .filter(item -> item.type() == type)
                .map(RepairDetailResponse::lineTotal)
                .reduce(BigDecimal.ZERO.setScale(2), BigDecimal::add);
    }

    private BigDecimal scale(BigDecimal value) {
        return value.setScale(2, RoundingMode.HALF_UP);
    }
}
'@
Write-RepoFile 'backend/src/main/java/com/gara/quanlygara/controller/RepairDetailController.java' @'
// TV3-TUAN7
package com.gara.quanlygara.controller;

import com.gara.quanlygara.dto.ApiResponse;
import com.gara.quanlygara.dto.repairdetail.RepairDetailCreateRequest;
import com.gara.quanlygara.dto.repairdetail.RepairDetailResponse;
import com.gara.quanlygara.dto.repairdetail.RepairDetailType;
import com.gara.quanlygara.dto.repairdetail.RepairDetailUpdateRequest;
import com.gara.quanlygara.dto.repairdetail.RepairDetailsResponse;
import com.gara.quanlygara.service.RepairDetailService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Chi tiết phiếu sửa chữa. Một hạng mục được xác định bởi (loại, mã): vì CSDL dùng khóa chính
 * (phiếu + dịch vụ) và (phiếu + phụ tùng) nên đường dẫn là /details/{service|spare-part}/{itemId}.
 */
@RestController
@RequestMapping("/api/repair-orders/{repairOrderId}/details")
@PreAuthorize("hasAnyRole('ADMIN', 'MANAGER', 'RECEPTIONIST', 'TECHNICIAN', 'WAREHOUSE')")
public class RepairDetailController {

    private static final String CAN_WRITE = "hasAnyRole('ADMIN', 'MANAGER', 'RECEPTIONIST')";

    private final RepairDetailService repairDetailService;

    public RepairDetailController(RepairDetailService repairDetailService) {
        this.repairDetailService = repairDetailService;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<RepairDetailsResponse>> getAll(@PathVariable Integer repairOrderId) {
        return ResponseEntity.ok(ApiResponse.success("Lấy chi tiết phiếu sửa chữa thành công.",
                repairDetailService.getAll(repairOrderId)));
    }

    @GetMapping("/{type}/{itemId}")
    public ResponseEntity<ApiResponse<RepairDetailResponse>> get(
            @PathVariable Integer repairOrderId,
            @PathVariable String type,
            @PathVariable Integer itemId
    ) {
        return ResponseEntity.ok(ApiResponse.success("Lấy hạng mục thành công.",
                repairDetailService.get(repairOrderId, RepairDetailType.fromPath(type), itemId)));
    }

    @PostMapping
    @PreAuthorize(CAN_WRITE)
    public ResponseEntity<ApiResponse<RepairDetailResponse>> create(
            @PathVariable Integer repairOrderId,
            @Valid @RequestBody RepairDetailCreateRequest request
    ) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Thêm hạng mục thành công.",
                        repairDetailService.create(repairOrderId, request)));
    }

    @PutMapping("/{type}/{itemId}")
    @PreAuthorize(CAN_WRITE)
    public ResponseEntity<ApiResponse<RepairDetailResponse>> update(
            @PathVariable Integer repairOrderId,
            @PathVariable String type,
            @PathVariable Integer itemId,
            @Valid @RequestBody RepairDetailUpdateRequest request
    ) {
        return ResponseEntity.ok(ApiResponse.success("Cập nhật hạng mục thành công.",
                repairDetailService.update(repairOrderId, RepairDetailType.fromPath(type), itemId, request)));
    }

    @DeleteMapping("/{type}/{itemId}")
    @PreAuthorize(CAN_WRITE)
    public ResponseEntity<ApiResponse<Void>> delete(
            @PathVariable Integer repairOrderId,
            @PathVariable String type,
            @PathVariable Integer itemId
    ) {
        repairDetailService.delete(repairOrderId, RepairDetailType.fromPath(type), itemId);
        return ResponseEntity.ok(ApiResponse.success("Xóa hạng mục thành công."));
    }
}
'@
Write-RepoFile 'backend/src/test/java/com/gara/quanlygara/service/SparePartServiceTest.java' @'
// TV3-TUAN7
package com.gara.quanlygara.service;

import com.gara.quanlygara.dto.sparepart.SparePartRequest;
import com.gara.quanlygara.entity.SparePart;
import com.gara.quanlygara.exception.ResourceNotFoundException;
import com.gara.quanlygara.repository.SparePartRepository;
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
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class SparePartServiceTest {

    @Mock
    private SparePartRepository sparePartRepository;

    private SparePartService sparePartService;

    @BeforeEach
    void setUp() {
        sparePartService = new SparePartService(sparePartRepository);
    }

    @Test
    void createNormalizesAndPersistsPart() {
        when(sparePartRepository.countWarehouse(1)).thenReturn(1L);
        when(sparePartRepository.saveAndFlush(any(SparePart.class))).thenAnswer(invocation -> {
            SparePart part = invocation.getArgument(0);
            part.setId(8);
            return part;
        });

        var response = sparePartService.create(
                new SparePartRequest(1, "  Lọc   dầu  động cơ ", "   ", new BigDecimal("180000"), null));

        assertEquals(8, response.id());
        assertEquals("Lọc dầu động cơ", response.name());
        assertNull(response.manufacturer());
        assertEquals(new BigDecimal("180000.00"), response.unitPrice());
        assertEquals(0, response.minStockLevel());
        // Phụ tùng mới: tồn mặc định 0, không do danh mục quyết định.
        assertEquals(0, response.stockQuantity());
    }

    @Test
    void createRejectsMissingWarehouse() {
        when(sparePartRepository.countWarehouse(99)).thenReturn(0L);

        assertThrows(ResourceNotFoundException.class, () -> sparePartService.create(request(99, "Bugi")));
        verify(sparePartRepository, never()).saveAndFlush(any(SparePart.class));
    }

    @Test
    void getByIdReturnsPartWithStock() {
        when(sparePartRepository.findById(3)).thenReturn(Optional.of(part(3, "Bugi", 12)));

        var response = sparePartService.getById(3);

        assertEquals("Bugi", response.name());
        assertEquals(12, response.stockQuantity());
    }

    @Test
    void getByIdRejectsMissingPart() {
        when(sparePartRepository.findById(404)).thenReturn(Optional.empty());

        assertThrows(ResourceNotFoundException.class, () -> sparePartService.getById(404));
    }

    @Test
    void getAllUsesPaginationAndSortsByName() {
        ArgumentCaptor<Pageable> captor = ArgumentCaptor.forClass(Pageable.class);
        when(sparePartRepository.findAll(captor.capture())).thenReturn(
                new PageImpl<>(List.of(part(1, "Bugi", 5)), PageRequest.of(1, 5), 11));

        var response = sparePartService.getAll(1, 5, null);

        assertEquals(1, response.items().size());
        assertEquals(1, response.page());
        assertEquals(11, response.totalElements());
        assertEquals(3, response.totalPages());
        assertEquals(1, captor.getValue().getPageNumber());
        assertEquals(5, captor.getValue().getPageSize());
        assertEquals("name", captor.getValue().getSort().iterator().next().getProperty());
    }

    @Test
    void getAllClampsPageAndSize() {
        ArgumentCaptor<Pageable> captor = ArgumentCaptor.forClass(Pageable.class);
        when(sparePartRepository.findAll(captor.capture())).thenReturn(new PageImpl<>(List.of()));

        sparePartService.getAll(-2, 1000, "  ");

        assertEquals(0, captor.getValue().getPageNumber());
        assertEquals(100, captor.getValue().getPageSize());
    }

    @Test
    void getAllSearchesByNameOrManufacturer() {
        when(sparePartRepository.findByNameContainingIgnoreCaseOrManufacturerContainingIgnoreCase(
                eq("loc"), eq("loc"), any(Pageable.class)))
                .thenReturn(new PageImpl<>(List.of(part(1, "Lọc dầu", 5))));

        var response = sparePartService.getAll(0, 10, "  loc ");

        assertEquals(1, response.items().size());
        verify(sparePartRepository, never()).findAll(any(Pageable.class));
    }

    @Test
    void updateChangesCatalogFieldsButNeverTouchesStock() {
        SparePart part = part(3, "Bugi", 12);
        when(sparePartRepository.findById(3)).thenReturn(Optional.of(part));
        when(sparePartRepository.saveAndFlush(part)).thenReturn(part);

        var response = sparePartService.update(3, new SparePartRequest(
                1, "Bugi Iridium", "NGK", new BigDecimal("210000"), 6));

        assertEquals("Bugi Iridium", response.name());
        assertEquals(new BigDecimal("210000.00"), response.unitPrice());
        assertEquals(6, response.minStockLevel());
        assertEquals(12, response.stockQuantity());
        assertEquals(12, part.getStockQuantity());
    }

    @Test
    void updateChecksWarehouseOnlyWhenItChanges() {
        when(sparePartRepository.findById(3)).thenReturn(Optional.of(part(3, "Bugi", 12)));
        when(sparePartRepository.countWarehouse(2)).thenReturn(0L);

        assertThrows(ResourceNotFoundException.class, () -> sparePartService.update(3, request(2, "Bugi")));
    }

    @Test
    void updateRejectsMissingPart() {
        when(sparePartRepository.findById(404)).thenReturn(Optional.empty());

        assertThrows(ResourceNotFoundException.class, () -> sparePartService.update(404, request(1, "Bugi")));
    }

    @Test
    void warehousesAreMappedFromTheKhoTable() {
        SparePartRepository.WarehouseView view = new SparePartRepository.WarehouseView() {
            @Override
            public Integer getId() {
                return 1;
            }

            @Override
            public String getName() {
                return "Kho phụ tùng chính";
            }
        };
        when(sparePartRepository.findWarehouses()).thenReturn(List.of(view));

        var response = sparePartService.getWarehouses();

        assertEquals(1, response.size());
        assertEquals("Kho phụ tùng chính", response.get(0).name());
    }

    private SparePartRequest request(int warehouseId, String name) {
        return new SparePartRequest(warehouseId, name, "NGK", new BigDecimal("180000"), 5);
    }

    private SparePart part(int id, String name, int stock) {
        SparePart part = new SparePart();
        part.setId(id);
        part.setWarehouseId(1);
        part.setName(name);
        part.setManufacturer("NGK");
        part.setUnitPrice(new BigDecimal("180000.00"));
        part.setMinStockLevel(5);
        ReflectionTestUtils.setField(part, "stockQuantity", stock);
        return part;
    }
}
'@
Write-RepoFile 'backend/src/test/java/com/gara/quanlygara/dto/SparePartRequestValidationTest.java' @'
// TV3-TUAN7
package com.gara.quanlygara.dto;

import com.gara.quanlygara.dto.sparepart.SparePartRequest;
import jakarta.validation.ConstraintViolation;
import jakarta.validation.Validation;
import jakarta.validation.Validator;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.Set;
import java.util.stream.Collectors;

import static org.junit.jupiter.api.Assertions.assertTrue;

class SparePartRequestValidationTest {

    private final Validator validator = Validation.buildDefaultValidatorFactory().getValidator();

    @Test
    void validRequestHasNoViolations() {
        assertTrue(validator.validate(new SparePartRequest(1, "Bugi", "NGK", new BigDecimal("180000"), 5)).isEmpty());
    }

    @Test
    void optionalFieldsMayBeNull() {
        assertTrue(validator.validate(new SparePartRequest(1, "Bugi", null, BigDecimal.ZERO, null)).isEmpty());
    }

    @Test
    void rejectsNegativeUnitPrice() {
        assertTrue(fields(new SparePartRequest(1, "Bugi", null, new BigDecimal("-1"), 0)).contains("unitPrice"));
    }

    @Test
    void rejectsNegativeMinStockLevel() {
        assertTrue(fields(new SparePartRequest(1, "Bugi", null, BigDecimal.ONE, -1)).contains("minStockLevel"));
    }

    @Test
    void rejectsBlankOrTooLongName() {
        assertTrue(fields(new SparePartRequest(1, "  ", null, BigDecimal.ONE, 0)).contains("name"));
        assertTrue(fields(new SparePartRequest(1, "A".repeat(151), null, BigDecimal.ONE, 0)).contains("name"));
    }

    @Test
    void rejectsMissingPriceAndWarehouse() {
        Set<String> fields = fields(new SparePartRequest(null, "Bugi", null, null, 0));
        assertTrue(fields.contains("warehouseId"));
        assertTrue(fields.contains("unitPrice"));
    }

    @Test
    void rejectsMoreThanTwoDecimals() {
        assertTrue(fields(new SparePartRequest(1, "Bugi", null, new BigDecimal("1.234"), 0)).contains("unitPrice"));
    }

    private Set<String> fields(SparePartRequest request) {
        return validator.validate(request).stream()
                .map(ConstraintViolation::getPropertyPath)
                .map(Object::toString)
                .collect(Collectors.toSet());
    }
}
'@
Write-RepoFile 'backend/src/test/java/com/gara/quanlygara/dto/RepairDetailRequestValidationTest.java' @'
// TV3-TUAN7
package com.gara.quanlygara.dto;

import com.gara.quanlygara.dto.repairdetail.RepairDetailCreateRequest;
import com.gara.quanlygara.dto.repairdetail.RepairDetailType;
import com.gara.quanlygara.dto.repairdetail.RepairDetailUpdateRequest;
import com.gara.quanlygara.exception.BadRequestException;
import jakarta.validation.ConstraintViolation;
import jakarta.validation.Validation;
import jakarta.validation.Validator;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.Set;
import java.util.stream.Collectors;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

class RepairDetailRequestValidationTest {

    private final Validator validator = Validation.buildDefaultValidatorFactory().getValidator();

    @Test
    void validCreateRequestHasNoViolations() {
        assertTrue(validator.validate(
                new RepairDetailCreateRequest(RepairDetailType.SPARE_PART, 1, 2, new BigDecimal("1000"))).isEmpty());
        assertTrue(validator.validate(
                new RepairDetailCreateRequest(RepairDetailType.SERVICE, 1, 1, null)).isEmpty());
    }

    @Test
    void rejectsZeroOrNegativeQuantity() {
        assertTrue(createFields(new RepairDetailCreateRequest(RepairDetailType.SERVICE, 1, 0, null)).contains("quantity"));
        assertTrue(createFields(new RepairDetailCreateRequest(RepairDetailType.SERVICE, 1, -3, null)).contains("quantity"));
        assertTrue(validator.validate(new RepairDetailUpdateRequest(0, null)).stream()
                .anyMatch(v -> v.getPropertyPath().toString().equals("quantity")));
    }

    @Test
    void rejectsNegativeUnitPrice() {
        assertTrue(createFields(new RepairDetailCreateRequest(
                RepairDetailType.SERVICE, 1, 1, new BigDecimal("-0.01"))).contains("unitPrice"));
    }

    @Test
    void rejectsMissingTypeAndItem() {
        Set<String> fields = createFields(new RepairDetailCreateRequest(null, null, 1, null));
        assertTrue(fields.contains("type"));
        assertTrue(fields.contains("itemId"));
    }

    @Test
    void pathTypeIsParsedOrRejected() {
        assertEquals(RepairDetailType.SERVICE, RepairDetailType.fromPath("service"));
        assertEquals(RepairDetailType.SPARE_PART, RepairDetailType.fromPath("spare-part"));
        assertThrows(BadRequestException.class, () -> RepairDetailType.fromPath("labor"));
    }

    private Set<String> createFields(RepairDetailCreateRequest request) {
        return validator.validate(request).stream()
                .map(ConstraintViolation::getPropertyPath)
                .map(Object::toString)
                .collect(Collectors.toSet());
    }
}
'@
Write-RepoFile 'backend/src/test/java/com/gara/quanlygara/service/RepairDetailServiceTest.java' @'
// TV3-TUAN7
package com.gara.quanlygara.service;

import com.gara.quanlygara.dto.repairdetail.RepairDetailCreateRequest;
import com.gara.quanlygara.dto.repairdetail.RepairDetailType;
import com.gara.quanlygara.dto.repairdetail.RepairDetailUpdateRequest;
import com.gara.quanlygara.entity.RepairPartItem;
import com.gara.quanlygara.entity.RepairServiceItem;
import com.gara.quanlygara.entity.SparePart;
import com.gara.quanlygara.exception.ConflictException;
import com.gara.quanlygara.exception.ResourceNotFoundException;
import com.gara.quanlygara.repository.RepairDetailRow;
import com.gara.quanlygara.repository.RepairPartItemRepository;
import com.gara.quanlygara.repository.RepairServiceItemRepository;
import com.gara.quanlygara.repository.SparePartRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class RepairDetailServiceTest {

    @Mock
    private RepairServiceItemRepository serviceItemRepository;

    @Mock
    private RepairPartItemRepository partItemRepository;

    @Mock
    private SparePartRepository sparePartRepository;

    private RepairDetailService service;

    @BeforeEach
    void setUp() {
        service = new RepairDetailService(serviceItemRepository, partItemRepository, sparePartRepository);
    }

    @Test
    void getAllReturnsServicesPartsAndTotals() {
        openOrder(1, "DANG_SUA");
        when(serviceItemRepository.findDetailRows(1)).thenReturn(List.of(row(3, "Kiểm tra phanh", 2, "300000.00", "HOAN_TAT")));
        when(partItemRepository.findDetailRows(1)).thenReturn(List.of(row(5, "Bugi", 4, "180000.00", null)));

        var response = service.getAll(1);

        assertEquals(2, response.items().size());
        assertEquals(RepairDetailType.SERVICE, response.items().get(0).type());
        assertEquals(new BigDecimal("600000.00"), response.items().get(0).lineTotal());
        assertEquals(new BigDecimal("720000.00"), response.items().get(1).lineTotal());
        assertEquals(new BigDecimal("600000.00"), response.serviceTotal());
        assertEquals(new BigDecimal("720000.00"), response.partsTotal());
        assertEquals(new BigDecimal("1320000.00"), response.totalAmount());
        assertTrue(response.editable());
    }

    @Test
    void getAllRejectsMissingRepairOrder() {
        when(serviceItemRepository.findRepairOrderStatus(99)).thenReturn(Optional.empty());

        assertThrows(ResourceNotFoundException.class, () -> service.getAll(99));
    }

    @Test
    void completedOrderIsReadOnly() {
        openOrder(3, "HOAN_TAT");
        when(serviceItemRepository.findDetailRows(3)).thenReturn(List.of());
        when(partItemRepository.findDetailRows(3)).thenReturn(List.of());

        assertFalse(service.getAll(3).editable());
    }

    @Test
    void getByIdReturnsMatchingItemOnly() {
        openOrder(1, "DANG_SUA");
        when(serviceItemRepository.findDetailRows(1)).thenReturn(List.of(row(3, "Kiểm tra phanh", 1, "300000.00", null)));
        when(partItemRepository.findDetailRows(1)).thenReturn(List.of(row(3, "Bugi", 1, "180000.00", null)));

        assertEquals("Bugi", service.get(1, RepairDetailType.SPARE_PART, 3).itemName());
        assertEquals("Kiểm tra phanh", service.get(1, RepairDetailType.SERVICE, 3).itemName());
        assertThrows(ResourceNotFoundException.class, () -> service.get(1, RepairDetailType.SERVICE, 9));
    }

    @Test
    void createPartLineUsesCatalogPriceAndNeverChangesStock() {
        openOrder(1, "DANG_SUA");
        SparePart part = sparePart(5, "Bugi", "180000.00", 7);
        when(sparePartRepository.findById(5)).thenReturn(Optional.of(part));
        when(partItemRepository.existsById(new RepairPartItem.Key(1, 5))).thenReturn(false);
        when(serviceItemRepository.findDetailRows(1)).thenReturn(List.of());
        when(partItemRepository.findDetailRows(1)).thenReturn(List.of(row(5, "Bugi", 2, "180000.00", null)));
        ArgumentCaptor<RepairPartItem> captor = ArgumentCaptor.forClass(RepairPartItem.class);

        var response = service.create(1, new RepairDetailCreateRequest(RepairDetailType.SPARE_PART, 5, 2, null));

        verify(partItemRepository).saveAndFlush(captor.capture());
        assertEquals(new BigDecimal("180000.00"), captor.getValue().getUnitPrice());
        assertEquals(2, captor.getValue().getQuantity());
        assertEquals(new BigDecimal("360000.00"), response.lineTotal());
        // Thêm chi tiết KHÔNG xuất kho, KHÔNG giảm tồn.
        assertEquals(7, part.getStockQuantity());
        verify(sparePartRepository, never()).save(any(SparePart.class));
        verify(sparePartRepository, never()).saveAndFlush(any(SparePart.class));
        verify(sparePartRepository, never()).delete(any(SparePart.class));
    }

    @Test
    void createPartLineKeepsExplicitUnitPrice() {
        openOrder(1, "DANG_SUA");
        when(sparePartRepository.findById(5)).thenReturn(Optional.of(sparePart(5, "Bugi", "180000.00", 7)));
        when(partItemRepository.existsById(new RepairPartItem.Key(1, 5))).thenReturn(false);
        when(serviceItemRepository.findDetailRows(1)).thenReturn(List.of());
        when(partItemRepository.findDetailRows(1)).thenReturn(List.of(row(5, "Bugi", 1, "150000.00", null)));
        ArgumentCaptor<RepairPartItem> captor = ArgumentCaptor.forClass(RepairPartItem.class);

        service.create(1, new RepairDetailCreateRequest(RepairDetailType.SPARE_PART, 5, 1, new BigDecimal("150000")));

        verify(partItemRepository).saveAndFlush(captor.capture());
        assertEquals(new BigDecimal("150000.00"), captor.getValue().getUnitPrice());
    }

    @Test
    void createServiceLineUsesCatalogPrice() {
        openOrder(1, "DANG_SUA");
        when(serviceItemRepository.findServiceCatalogPrice(2)).thenReturn(Optional.of(new BigDecimal("1200000.00")));
        when(serviceItemRepository.existsById(new RepairServiceItem.Key(1, 2))).thenReturn(false);
        when(serviceItemRepository.findDetailRows(1)).thenReturn(List.of(row(2, "Bảo dưỡng", 1, "1200000.00", null)));
        when(partItemRepository.findDetailRows(1)).thenReturn(List.of());
        ArgumentCaptor<RepairServiceItem> captor = ArgumentCaptor.forClass(RepairServiceItem.class);

        var response = service.create(1, new RepairDetailCreateRequest(RepairDetailType.SERVICE, 2, 1, null));

        verify(serviceItemRepository).saveAndFlush(captor.capture());
        assertEquals(new BigDecimal("1200000.00"), captor.getValue().getUnitPrice());
        assertEquals(new BigDecimal("1200000.00"), response.lineTotal());
    }

    @Test
    void createRejectsMissingRepairOrder() {
        when(serviceItemRepository.findRepairOrderStatus(99)).thenReturn(Optional.empty());

        assertThrows(ResourceNotFoundException.class, () -> service.create(
                99, new RepairDetailCreateRequest(RepairDetailType.SERVICE, 2, 1, null)));
    }

    @Test
    void createRejectsMissingService() {
        openOrder(1, "DANG_SUA");
        when(serviceItemRepository.findServiceCatalogPrice(77)).thenReturn(Optional.empty());

        assertThrows(ResourceNotFoundException.class, () -> service.create(
                1, new RepairDetailCreateRequest(RepairDetailType.SERVICE, 77, 1, null)));
        verify(serviceItemRepository, never()).saveAndFlush(any(RepairServiceItem.class));
    }

    @Test
    void createRejectsMissingSparePart() {
        openOrder(1, "DANG_SUA");
        when(sparePartRepository.findById(77)).thenReturn(Optional.empty());

        assertThrows(ResourceNotFoundException.class, () -> service.create(
                1, new RepairDetailCreateRequest(RepairDetailType.SPARE_PART, 77, 1, null)));
        verify(partItemRepository, never()).saveAndFlush(any(RepairPartItem.class));
    }

    @Test
    void createRejectsDuplicateLine() {
        openOrder(1, "DANG_SUA");
        when(sparePartRepository.findById(5)).thenReturn(Optional.of(sparePart(5, "Bugi", "180000.00", 7)));
        when(partItemRepository.existsById(new RepairPartItem.Key(1, 5))).thenReturn(true);

        assertThrows(ConflictException.class, () -> service.create(
                1, new RepairDetailCreateRequest(RepairDetailType.SPARE_PART, 5, 1, null)));
        verify(partItemRepository, never()).saveAndFlush(any(RepairPartItem.class));
    }

    @Test
    void closedOrderRejectsCreateUpdateAndDelete() {
        openOrder(3, "HOAN_TAT");

        assertThrows(ConflictException.class, () -> service.create(
                3, new RepairDetailCreateRequest(RepairDetailType.SERVICE, 2, 1, null)));
        assertThrows(ConflictException.class, () -> service.update(
                3, RepairDetailType.SERVICE, 2, new RepairDetailUpdateRequest(1, null)));
        assertThrows(ConflictException.class, () -> service.delete(3, RepairDetailType.SPARE_PART, 5));
    }

    @Test
    void updateChangesQuantityAndKeepsPriceWhenOmitted() {
        openOrder(1, "DANG_SUA");
        RepairPartItem item = partItem(1, 5, 2, "180000.00");
        when(partItemRepository.findById(new RepairPartItem.Key(1, 5))).thenReturn(Optional.of(item));
        when(serviceItemRepository.findDetailRows(1)).thenReturn(List.of());
        when(partItemRepository.findDetailRows(1)).thenReturn(List.of(row(5, "Bugi", 6, "180000.00", null)));

        var response = service.update(1, RepairDetailType.SPARE_PART, 5, new RepairDetailUpdateRequest(6, null));

        assertEquals(6, item.getQuantity());
        assertEquals(new BigDecimal("180000.00"), item.getUnitPrice());
        assertEquals(new BigDecimal("1080000.00"), response.lineTotal());
        verify(sparePartRepository, never()).saveAndFlush(any(SparePart.class));
    }

    @Test
    void updateRejectsMissingLine() {
        openOrder(1, "DANG_SUA");
        when(serviceItemRepository.findById(new RepairServiceItem.Key(1, 9))).thenReturn(Optional.empty());

        assertThrows(ResourceNotFoundException.class, () -> service.update(
                1, RepairDetailType.SERVICE, 9, new RepairDetailUpdateRequest(1, null)));
    }

    @Test
    void deleteRemovesOnlyTheDetailLineAndNeverTouchesStock() {
        openOrder(1, "DANG_SUA");
        RepairPartItem item = partItem(1, 5, 2, "180000.00");
        when(partItemRepository.findById(new RepairPartItem.Key(1, 5))).thenReturn(Optional.of(item));

        service.delete(1, RepairDetailType.SPARE_PART, 5);

        verify(partItemRepository).delete(item);
        verify(sparePartRepository, never()).findById(any());
        verify(sparePartRepository, never()).save(any(SparePart.class));
    }

    @Test
    void deleteRejectsMissingLine() {
        openOrder(1, "DANG_SUA");
        when(serviceItemRepository.findById(new RepairServiceItem.Key(1, 9))).thenReturn(Optional.empty());

        assertThrows(ResourceNotFoundException.class, () -> service.delete(1, RepairDetailType.SERVICE, 9));
    }

    private void openOrder(int id, String status) {
        when(serviceItemRepository.findRepairOrderStatus(id)).thenReturn(Optional.of(status));
    }

    private SparePart sparePart(int id, String name, String price, int stock) {
        SparePart part = new SparePart();
        part.setId(id);
        part.setWarehouseId(1);
        part.setName(name);
        part.setUnitPrice(new BigDecimal(price));
        part.setMinStockLevel(5);
        ReflectionTestUtils.setField(part, "stockQuantity", stock);
        return part;
    }

    private RepairPartItem partItem(int orderId, int partId, int quantity, String price) {
        RepairPartItem item = new RepairPartItem();
        item.setRepairOrderId(orderId);
        item.setSparePartId(partId);
        item.setQuantity(quantity);
        item.setUnitPrice(new BigDecimal(price));
        return item;
    }

    private RepairDetailRow row(int itemId, String name, int quantity, String price, String status) {
        return new RepairDetailRow() {
            @Override
            public Integer getItemId() {
                return itemId;
            }

            @Override
            public String getItemName() {
                return name;
            }

            @Override
            public Integer getQuantity() {
                return quantity;
            }

            @Override
            public BigDecimal getUnitPrice() {
                return new BigDecimal(price);
            }

            @Override
            public String getItemStatus() {
                return status;
            }
        };
    }
}
'@
Write-RepoFile 'backend/src/test/java/com/gara/quanlygara/controller/SparePartApiTest.java' @'
// TV3-TUAN7
package com.gara.quanlygara.controller;

import com.gara.quanlygara.entity.SparePart;
import com.gara.quanlygara.repository.SparePartRepository;
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
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.test.web.servlet.MockMvc;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

import static org.hamcrest.Matchers.containsString;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
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
class SparePartApiTest {

    private static final String PART_JSON = """
            {"warehouseId":1,"name":"Bugi Iridium","manufacturer":"NGK","unitPrice":210000,"minStockLevel":6}
            """;

    @Autowired
    private MockMvc mockMvc;

//__MOCK_FIELDS__

    @Test
    void listRejectsRequestWithoutJwt() throws Exception {
        mockMvc.perform(get("/api/spare-parts"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.success").value(false));
    }

    @Test
    @WithMockUser(roles = "CUSTOMER")
    void customerCannotReadCatalogApi() throws Exception {
        mockMvc.perform(get("/api/spare-parts")).andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(roles = "WAREHOUSE")
    void warehouseCanListWithPaginationAndSeesStock() throws Exception {
        when(sparePartRepository.findAll(any(Pageable.class))).thenReturn(
                new PageImpl<>(List.of(part(1, "Bugi", 12)), PageRequest.of(0, 10), 1));

        mockMvc.perform(get("/api/spare-parts").param("page", "0").param("size", "10"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.items[0].name").value("Bugi"))
                .andExpect(jsonPath("$.data.items[0].stockQuantity").value(12))
                .andExpect(jsonPath("$.data.totalElements").value(1));
    }

    @Test
    @WithMockUser(roles = "TECHNICIAN")
    void searchFiltersByNameOrManufacturer() throws Exception {
        when(sparePartRepository.findByNameContainingIgnoreCaseOrManufacturerContainingIgnoreCase(
                eq("bugi"), eq("bugi"), any(Pageable.class)))
                .thenReturn(new PageImpl<>(List.of(part(2, "Bugi", 3))));

        mockMvc.perform(get("/api/spare-parts").param("search", "bugi"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.items[0].id").value(2));
    }

    @Test
    @WithMockUser(roles = "MANAGER")
    void getByIdReturnsPart() throws Exception {
        when(sparePartRepository.findById(2)).thenReturn(Optional.of(part(2, "Bugi", 3)));

        mockMvc.perform(get("/api/spare-parts/2"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.name").value("Bugi"));
    }

    @Test
    @WithMockUser(roles = "MANAGER")
    void getByIdReturns404WhenMissing() throws Exception {
        when(sparePartRepository.findById(404)).thenReturn(Optional.empty());

        mockMvc.perform(get("/api/spare-parts/404"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.success").value(false));
    }

    @Test
    @WithMockUser(roles = "WAREHOUSE")
    void warehousesAreListedForTheForm() throws Exception {
        SparePartRepository.WarehouseView view = new SparePartRepository.WarehouseView() {
            @Override
            public Integer getId() {
                return 1;
            }

            @Override
            public String getName() {
                return "Kho phụ tùng chính";
            }
        };
        when(sparePartRepository.findWarehouses()).thenReturn(List.of(view));

        mockMvc.perform(get("/api/spare-parts/warehouses"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[0].name").value("Kho phụ tùng chính"));
    }

    @Test
    @WithMockUser(roles = "WAREHOUSE")
    void createReturns201() throws Exception {
        when(sparePartRepository.countWarehouse(1)).thenReturn(1L);
        when(sparePartRepository.saveAndFlush(any(SparePart.class))).thenAnswer(invocation -> {
            SparePart part = invocation.getArgument(0);
            part.setId(9);
            return part;
        });

        mockMvc.perform(post("/api/spare-parts").contentType(APPLICATION_JSON).content(PART_JSON))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.id").value(9))
                .andExpect(jsonPath("$.data.stockQuantity").value(0));
    }

    @Test
    @WithMockUser(roles = "WAREHOUSE")
    void createReturns404ForUnknownWarehouse() throws Exception {
        when(sparePartRepository.countWarehouse(1)).thenReturn(0L);

        mockMvc.perform(post("/api/spare-parts").contentType(APPLICATION_JSON).content(PART_JSON))
                .andExpect(status().isNotFound());
    }

    @Test
    @WithMockUser(roles = "WAREHOUSE")
    void createReturns400ForInvalidBody() throws Exception {
        mockMvc.perform(post("/api/spare-parts").contentType(APPLICATION_JSON)
                        .content("{\"warehouseId\":1,\"name\":\"  \",\"unitPrice\":-5,\"minStockLevel\":-1}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.data.name").exists())
                .andExpect(jsonPath("$.data.unitPrice").exists())
                .andExpect(jsonPath("$.data.minStockLevel").exists());
    }

    @Test
    @WithMockUser(roles = "WAREHOUSE")
    void updateReturns200AndKeepsStock() throws Exception {
        when(sparePartRepository.findById(3)).thenReturn(Optional.of(part(3, "Bugi", 12)));
        when(sparePartRepository.saveAndFlush(any(SparePart.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(sparePartRepository.countWarehouse(1)).thenReturn(1L);

        mockMvc.perform(put("/api/spare-parts/3").contentType(APPLICATION_JSON).content(PART_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.name").value("Bugi Iridium"))
                .andExpect(jsonPath("$.data.stockQuantity").value(12));
    }

    @Test
    @WithMockUser(roles = "WAREHOUSE")
    void updateReturns404WhenMissing() throws Exception {
        when(sparePartRepository.findById(404)).thenReturn(Optional.empty());

        mockMvc.perform(put("/api/spare-parts/404").contentType(APPLICATION_JSON).content(PART_JSON))
                .andExpect(status().isNotFound());
    }

    @Test
    @WithMockUser(roles = "RECEPTIONIST")
    void receptionistCanReadButNotWriteCatalog() throws Exception {
        when(sparePartRepository.findAll(any(Pageable.class))).thenReturn(new PageImpl<>(List.of()));

        mockMvc.perform(get("/api/spare-parts")).andExpect(status().isOk());
        mockMvc.perform(post("/api/spare-parts").contentType(APPLICATION_JSON).content(PART_JSON))
                .andExpect(status().isForbidden());
        mockMvc.perform(put("/api/spare-parts/3").contentType(APPLICATION_JSON).content(PART_JSON))
                .andExpect(status().isForbidden());
    }

    @Test
    void swaggerDocumentationListsSparePartApi() throws Exception {
        mockMvc.perform(get("/v3/api-docs"))
                .andExpect(status().isOk())
                .andExpect(content().string(containsString("/api/spare-parts")));
    }

    private SparePart part(int id, String name, int stock) {
        SparePart part = new SparePart();
        part.setId(id);
        part.setWarehouseId(1);
        part.setName(name);
        part.setManufacturer("NGK");
        part.setUnitPrice(new BigDecimal("180000.00"));
        part.setMinStockLevel(5);
        ReflectionTestUtils.setField(part, "stockQuantity", stock);
        return part;
    }
}
'@
Write-RepoFile 'backend/src/test/java/com/gara/quanlygara/controller/RepairDetailApiTest.java' @'
// TV3-TUAN7
package com.gara.quanlygara.controller;

import com.gara.quanlygara.entity.RepairPartItem;
import com.gara.quanlygara.entity.RepairServiceItem;
import com.gara.quanlygara.entity.SparePart;
import com.gara.quanlygara.repository.RepairDetailRow;
import com.gara.quanlygara.repository.RepairPartItemRepository;
import com.gara.quanlygara.repository.RepairServiceItemRepository;
import com.gara.quanlygara.repository.SparePartRepository;
//__MOCK_IMPORTS__
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.test.web.servlet.MockMvc;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.http.MediaType.APPLICATION_JSON;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
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
class RepairDetailApiTest {

    private static final String PART_BODY = "{\"type\":\"SPARE_PART\",\"itemId\":5,\"quantity\":2}";

    @Autowired
    private MockMvc mockMvc;

//__MOCK_FIELDS__

    @Test
    void listRejectsRequestWithoutJwt() throws Exception {
        mockMvc.perform(get("/api/repair-orders/1/details")).andExpect(status().isUnauthorized());
    }

    @Test
    @WithMockUser(roles = "CUSTOMER")
    void customerCannotReadDetails() throws Exception {
        mockMvc.perform(get("/api/repair-orders/1/details")).andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(roles = "TECHNICIAN")
    void technicianCanReadDetailsWithTotals() throws Exception {
        stubOrder(1, "DANG_SUA");
        when(repairServiceItemRepository.findDetailRows(1)).thenReturn(List.of(row(3, "Kiểm tra phanh", 1, "300000.00")));
        when(repairPartItemRepository.findDetailRows(1)).thenReturn(List.of(row(5, "Bugi", 4, "180000.00")));

        mockMvc.perform(get("/api/repair-orders/1/details"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.items.length()").value(2))
                .andExpect(jsonPath("$.data.items[1].lineTotal").value(720000.0))
                .andExpect(jsonPath("$.data.totalAmount").value(1020000.0))
                .andExpect(jsonPath("$.data.editable").value(true));
    }

    @Test
    @WithMockUser(roles = "MANAGER")
    void listReturns404ForUnknownRepairOrder() throws Exception {
        when(repairServiceItemRepository.findRepairOrderStatus(99)).thenReturn(Optional.empty());

        mockMvc.perform(get("/api/repair-orders/99/details"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.success").value(false));
    }

    @Test
    @WithMockUser(roles = "MANAGER")
    void getOneItemByTypeAndId() throws Exception {
        stubOrder(1, "DANG_SUA");
        when(repairServiceItemRepository.findDetailRows(1)).thenReturn(List.of());
        when(repairPartItemRepository.findDetailRows(1)).thenReturn(List.of(row(5, "Bugi", 4, "180000.00")));

        mockMvc.perform(get("/api/repair-orders/1/details/spare-part/5"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.itemName").value("Bugi"));
        mockMvc.perform(get("/api/repair-orders/1/details/service/5"))
                .andExpect(status().isNotFound());
        mockMvc.perform(get("/api/repair-orders/1/details/labor/5"))
                .andExpect(status().isBadRequest());
    }

    @Test
    @WithMockUser(roles = "RECEPTIONIST")
    void createPartReturns201AndDoesNotWriteStock() throws Exception {
        stubOrder(1, "DANG_SUA");
        SparePart part = sparePart(5, 7);
        when(sparePartRepository.findById(5)).thenReturn(Optional.of(part));
        when(repairPartItemRepository.existsById(new RepairPartItem.Key(1, 5))).thenReturn(false);
        when(repairServiceItemRepository.findDetailRows(1)).thenReturn(List.of());
        when(repairPartItemRepository.findDetailRows(1)).thenReturn(List.of(row(5, "Bugi", 2, "180000.00")));

        mockMvc.perform(post("/api/repair-orders/1/details").contentType(APPLICATION_JSON).content(PART_BODY))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.type").value("SPARE_PART"))
                .andExpect(jsonPath("$.data.lineTotal").value(360000.0));

        verify(sparePartRepository, never()).save(any(SparePart.class));
        verify(sparePartRepository, never()).saveAndFlush(any(SparePart.class));
    }

    @Test
    @WithMockUser(roles = "RECEPTIONIST")
    void createReturns409ForDuplicateLine() throws Exception {
        stubOrder(1, "DANG_SUA");
        when(sparePartRepository.findById(5)).thenReturn(Optional.of(sparePart(5, 7)));
        when(repairPartItemRepository.existsById(new RepairPartItem.Key(1, 5))).thenReturn(true);

        mockMvc.perform(post("/api/repair-orders/1/details").contentType(APPLICATION_JSON).content(PART_BODY))
                .andExpect(status().isConflict());
    }

    @Test
    @WithMockUser(roles = "RECEPTIONIST")
    void createReturns409ForClosedOrder() throws Exception {
        stubOrder(3, "HOAN_TAT");

        mockMvc.perform(post("/api/repair-orders/3/details").contentType(APPLICATION_JSON).content(PART_BODY))
                .andExpect(status().isConflict());
    }

    @Test
    @WithMockUser(roles = "RECEPTIONIST")
    void createReturns404ForUnknownRepairOrderServiceAndPart() throws Exception {
        when(repairServiceItemRepository.findRepairOrderStatus(99)).thenReturn(Optional.empty());
        mockMvc.perform(post("/api/repair-orders/99/details").contentType(APPLICATION_JSON).content(PART_BODY))
                .andExpect(status().isNotFound());

        stubOrder(1, "DANG_SUA");
        when(repairServiceItemRepository.findServiceCatalogPrice(77)).thenReturn(Optional.empty());
        mockMvc.perform(post("/api/repair-orders/1/details").contentType(APPLICATION_JSON)
                        .content("{\"type\":\"SERVICE\",\"itemId\":77,\"quantity\":1}"))
                .andExpect(status().isNotFound());

        when(sparePartRepository.findById(5)).thenReturn(Optional.empty());
        mockMvc.perform(post("/api/repair-orders/1/details").contentType(APPLICATION_JSON).content(PART_BODY))
                .andExpect(status().isNotFound());
    }

    @Test
    @WithMockUser(roles = "RECEPTIONIST")
    void createReturns400ForInvalidQuantityAndPrice() throws Exception {
        mockMvc.perform(post("/api/repair-orders/1/details").contentType(APPLICATION_JSON)
                        .content("{\"type\":\"SERVICE\",\"itemId\":1,\"quantity\":0,\"unitPrice\":-1}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.data.quantity").exists())
                .andExpect(jsonPath("$.data.unitPrice").exists());
    }

    @Test
    @WithMockUser(roles = "RECEPTIONIST")
    void updateReturns200() throws Exception {
        stubOrder(1, "DANG_SUA");
        RepairServiceItem item = new RepairServiceItem();
        item.setRepairOrderId(1);
        item.setServiceId(3);
        item.setQuantity(1);
        item.setUnitPrice(new BigDecimal("300000.00"));
        when(repairServiceItemRepository.findById(new RepairServiceItem.Key(1, 3))).thenReturn(Optional.of(item));
        when(repairServiceItemRepository.findDetailRows(1)).thenReturn(List.of(row(3, "Kiểm tra phanh", 3, "300000.00")));
        when(repairPartItemRepository.findDetailRows(1)).thenReturn(List.of());

        mockMvc.perform(put("/api/repair-orders/1/details/service/3").contentType(APPLICATION_JSON)
                        .content("{\"quantity\":3}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.lineTotal").value(900000.0));
    }

    @Test
    @WithMockUser(roles = "RECEPTIONIST")
    void deleteReturns200AndRemovesOnlyTheLine() throws Exception {
        stubOrder(1, "DANG_SUA");
        RepairPartItem item = new RepairPartItem();
        item.setRepairOrderId(1);
        item.setSparePartId(5);
        item.setQuantity(2);
        item.setUnitPrice(new BigDecimal("180000.00"));
        when(repairPartItemRepository.findById(new RepairPartItem.Key(1, 5))).thenReturn(Optional.of(item));

        mockMvc.perform(delete("/api/repair-orders/1/details/spare-part/5"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));

        verify(repairPartItemRepository).delete(item);
        verify(sparePartRepository, never()).saveAndFlush(any(SparePart.class));
    }

    @Test
    @WithMockUser(roles = "TECHNICIAN")
    void technicianCannotModifyDetails() throws Exception {
        mockMvc.perform(post("/api/repair-orders/1/details").contentType(APPLICATION_JSON).content(PART_BODY))
                .andExpect(status().isForbidden());
        mockMvc.perform(put("/api/repair-orders/1/details/service/3").contentType(APPLICATION_JSON)
                        .content("{\"quantity\":1}"))
                .andExpect(status().isForbidden());
        mockMvc.perform(delete("/api/repair-orders/1/details/service/3")).andExpect(status().isForbidden());
    }

    private void stubOrder(int id, String orderStatus) {
        when(repairServiceItemRepository.findRepairOrderStatus(id)).thenReturn(Optional.of(orderStatus));
    }

    private SparePart sparePart(int id, int stock) {
        SparePart part = new SparePart();
        part.setId(id);
        part.setWarehouseId(1);
        part.setName("Bugi");
        part.setUnitPrice(new BigDecimal("180000.00"));
        part.setMinStockLevel(5);
        ReflectionTestUtils.setField(part, "stockQuantity", stock);
        return part;
    }

    private RepairDetailRow row(int itemId, String name, int quantity, String price) {
        return new RepairDetailRow() {
            @Override
            public Integer getItemId() {
                return itemId;
            }

            @Override
            public String getItemName() {
                return name;
            }

            @Override
            public Integer getQuantity() {
                return quantity;
            }

            @Override
            public BigDecimal getUnitPrice() {
                return new BigDecimal(price);
            }

            @Override
            public String getItemStatus() {
                return null;
            }
        };
    }
}
'@
Write-RepoFile 'backend/database/Test_SpareParts.sql' @'
-- TV3-TUAN7
-- ============================================================
-- Test_SpareParts.sql - rang buoc PhuTung + ChiTietDichVu/ChiTietPhuTung (Tuan 7 - TV3)
-- Chay trong SSMS sau khi tao database bang QuanLyGaraOTo.sql.
-- Toan bo du lieu test nam trong mot transaction va duoc ROLLBACK cuoi script.
-- Khong goi procedure nhap/xuat kho: script chi kiem tra rang buoc va xac nhan
-- them dong chi tiet KHONG lam doi SoLuongTon.
-- ============================================================
USE QuanLyGaraOTo;
GO

SET NOCOUNT ON;
SET XACT_ABORT OFF;

DECLARE @Result TABLE (
    Id       INT IDENTITY(1,1),
    TestName NVARCHAR(200),
    Detail   NVARCHAR(400),
    Result   NVARCHAR(4)
);

DECLARE @kho INT, @order INT, @dv INT, @pt INT, @before INT, @after INT, @n INT, @tt DECIMAL(18,2);

SELECT TOP 1 @kho = MaKho FROM Kho ORDER BY MaKho;
SELECT TOP 1 @order = MaPhieuSuaChua FROM PhieuSuaChua ORDER BY MaPhieuSuaChua;
SELECT TOP 1 @dv = MaDichVu FROM DichVu ORDER BY MaDichVu;

IF @kho IS NULL OR @order IS NULL OR @dv IS NULL
BEGIN
    PRINT N'Thieu du lieu mau (Kho / PhieuSuaChua / DichVu). Hay chay QuanLyGaraOTo.sql truoc.';
    RETURN;
END;

BEGIN TRAN;

-- T1: them phu tung hop le, SoLuongTon mac dinh 0
BEGIN TRY
    INSERT INTO PhuTung (MaKho, TenPhuTung, HangSanXuat, DonGia, MucTonToiThieu)
    VALUES (@kho, N'TEST Phu tung 1', N'NGK', 100000, 5);
    SET @pt = SCOPE_IDENTITY();
    SELECT @n = SoLuongTon FROM PhuTung WHERE MaPhuTung = @pt;
    INSERT INTO @Result VALUES (N'T1 them phu tung hop le (ton mac dinh 0)', N'SoLuongTon=' + CAST(@n AS NVARCHAR(10)),
        CASE WHEN @n = 0 THEN 'PASS' ELSE 'FAIL' END);
END TRY
BEGIN CATCH
    INSERT INTO @Result VALUES (N'T1 them phu tung hop le', ERROR_MESSAGE(), 'FAIL');
END CATCH;

-- T2: DonGia am -> CK_PhuTung_DonGia
BEGIN TRY
    INSERT INTO PhuTung (MaKho, TenPhuTung, DonGia) VALUES (@kho, N'TEST gia am', -1);
    INSERT INTO @Result VALUES (N'T2 DonGia am', N'Insert van thanh cong', 'FAIL');
END TRY
BEGIN CATCH
    INSERT INTO @Result VALUES (N'T2 DonGia am', ERROR_MESSAGE(),
        CASE WHEN ERROR_NUMBER() = 547 AND ERROR_MESSAGE() LIKE '%CK_PhuTung_DonGia%' THEN 'PASS' ELSE 'FAIL' END);
END CATCH;

-- T3: MucTonToiThieu am -> CK_PhuTung_MucTonToiThieu
BEGIN TRY
    INSERT INTO PhuTung (MaKho, TenPhuTung, DonGia, MucTonToiThieu) VALUES (@kho, N'TEST muc ton am', 1, -1);
    INSERT INTO @Result VALUES (N'T3 MucTonToiThieu am', N'Insert van thanh cong', 'FAIL');
END TRY
BEGIN CATCH
    INSERT INTO @Result VALUES (N'T3 MucTonToiThieu am', ERROR_MESSAGE(),
        CASE WHEN ERROR_NUMBER() = 547 AND ERROR_MESSAGE() LIKE '%CK_PhuTung_MucTonToiThieu%' THEN 'PASS' ELSE 'FAIL' END);
END CATCH;

-- T4: SoLuongTon am -> CK_PhuTung_SoLuongTon
BEGIN TRY
    INSERT INTO PhuTung (MaKho, TenPhuTung, DonGia, SoLuongTon) VALUES (@kho, N'TEST ton am', 1, -1);
    INSERT INTO @Result VALUES (N'T4 SoLuongTon am', N'Insert van thanh cong', 'FAIL');
END TRY
BEGIN CATCH
    INSERT INTO @Result VALUES (N'T4 SoLuongTon am', ERROR_MESSAGE(),
        CASE WHEN ERROR_NUMBER() = 547 AND ERROR_MESSAGE() LIKE '%CK_PhuTung_SoLuongTon%' THEN 'PASS' ELSE 'FAIL' END);
END CATCH;

-- T5: MaKho khong ton tai -> FK_PhuTung_Kho
BEGIN TRY
    INSERT INTO PhuTung (MaKho, TenPhuTung, DonGia) VALUES (-1, N'TEST kho sai', 1);
    INSERT INTO @Result VALUES (N'T5 MaKho khong ton tai', N'Insert van thanh cong', 'FAIL');
END TRY
BEGIN CATCH
    INSERT INTO @Result VALUES (N'T5 MaKho khong ton tai', ERROR_MESSAGE(),
        CASE WHEN ERROR_NUMBER() = 547 AND ERROR_MESSAGE() LIKE '%FK_PhuTung_Kho%' THEN 'PASS' ELSE 'FAIL' END);
END CATCH;

-- T6: them dong ChiTietPhuTung KHONG lam doi SoLuongTon, ThanhTien = SoLuong x DonGia
BEGIN TRY
    SELECT @before = SoLuongTon FROM PhuTung WHERE MaPhuTung = @pt;
    INSERT INTO ChiTietPhuTung (MaPhieuSuaChua, MaPhuTung, SoLuong, DonGia) VALUES (@order, @pt, 3, 100000);
    SELECT @after = SoLuongTon FROM PhuTung WHERE MaPhuTung = @pt;
    SELECT @tt = ThanhTien FROM ChiTietPhuTung WHERE MaPhieuSuaChua = @order AND MaPhuTung = @pt;
    INSERT INTO @Result VALUES (N'T6 them chi tiet phu tung khong doi ton, ThanhTien dung',
        N'ton truoc=' + CAST(@before AS NVARCHAR(10)) + N', ton sau=' + CAST(@after AS NVARCHAR(10)) + N', ThanhTien=' + CAST(@tt AS NVARCHAR(30)),
        CASE WHEN @before = @after AND @tt = 300000 THEN 'PASS' ELSE 'FAIL' END);
END TRY
BEGIN CATCH
    INSERT INTO @Result VALUES (N'T6 them chi tiet phu tung', ERROR_MESSAGE(), 'FAIL');
END CATCH;

-- T7: trung (phieu, phu tung) -> PK_ChiTietPhuTung
BEGIN TRY
    INSERT INTO ChiTietPhuTung (MaPhieuSuaChua, MaPhuTung, SoLuong, DonGia) VALUES (@order, @pt, 1, 100000);
    INSERT INTO @Result VALUES (N'T7 trung phu tung trong phieu', N'Insert van thanh cong', 'FAIL');
END TRY
BEGIN CATCH
    INSERT INTO @Result VALUES (N'T7 trung phu tung trong phieu', ERROR_MESSAGE(),
        CASE WHEN ERROR_NUMBER() IN (2627, 2601) THEN 'PASS' ELSE 'FAIL' END);
END CATCH;

-- T8: SoLuong <= 0 -> CK_ChiTietPhuTung_SoLuong
BEGIN TRY
    INSERT INTO PhuTung (MaKho, TenPhuTung, DonGia) VALUES (@kho, N'TEST Phu tung 2', 1);
    INSERT INTO ChiTietPhuTung (MaPhieuSuaChua, MaPhuTung, SoLuong, DonGia) VALUES (@order, SCOPE_IDENTITY(), 0, 1);
    INSERT INTO @Result VALUES (N'T8 SoLuong = 0', N'Insert van thanh cong', 'FAIL');
END TRY
BEGIN CATCH
    INSERT INTO @Result VALUES (N'T8 SoLuong = 0', ERROR_MESSAGE(),
        CASE WHEN ERROR_NUMBER() = 547 AND ERROR_MESSAGE() LIKE '%CK_ChiTietPhuTung_SoLuong%' THEN 'PASS' ELSE 'FAIL' END);
END CATCH;

-- T9: DonGia am tren ChiTietPhuTung -> CK_ChiTietPhuTung_DonGia
BEGIN TRY
    INSERT INTO PhuTung (MaKho, TenPhuTung, DonGia) VALUES (@kho, N'TEST Phu tung 3', 1);
    INSERT INTO ChiTietPhuTung (MaPhieuSuaChua, MaPhuTung, SoLuong, DonGia) VALUES (@order, SCOPE_IDENTITY(), 1, -1);
    INSERT INTO @Result VALUES (N'T9 DonGia am (chi tiet phu tung)', N'Insert van thanh cong', 'FAIL');
END TRY
BEGIN CATCH
    INSERT INTO @Result VALUES (N'T9 DonGia am (chi tiet phu tung)', ERROR_MESSAGE(),
        CASE WHEN ERROR_NUMBER() = 547 AND ERROR_MESSAGE() LIKE '%CK_ChiTietPhuTung_DonGia%' THEN 'PASS' ELSE 'FAIL' END);
END CATCH;

-- T10: phieu sua chua khong ton tai -> FK_ChiTietPhuTung_PhieuSuaChua
BEGIN TRY
    INSERT INTO ChiTietPhuTung (MaPhieuSuaChua, MaPhuTung, SoLuong, DonGia) VALUES (-1, @pt, 1, 1);
    INSERT INTO @Result VALUES (N'T10 phieu sua chua khong ton tai', N'Insert van thanh cong', 'FAIL');
END TRY
BEGIN CATCH
    INSERT INTO @Result VALUES (N'T10 phieu sua chua khong ton tai', ERROR_MESSAGE(),
        CASE WHEN ERROR_NUMBER() = 547 AND ERROR_MESSAGE() LIKE '%FK_ChiTietPhuTung_PhieuSuaChua%' THEN 'PASS' ELSE 'FAIL' END);
END CATCH;

-- T11: dong dich vu hop le, ThanhTien dung (dich vu dau tien chua co trong phieu thi moi them)
BEGIN TRY
    DELETE FROM ChiTietDichVu WHERE MaPhieuSuaChua = @order AND MaDichVu = @dv;
    INSERT INTO ChiTietDichVu (MaPhieuSuaChua, MaDichVu, SoLuong, DonGia) VALUES (@order, @dv, 2, 250000);
    SELECT @tt = ThanhTien FROM ChiTietDichVu WHERE MaPhieuSuaChua = @order AND MaDichVu = @dv;
    INSERT INTO @Result VALUES (N'T11 chi tiet dich vu hop le, ThanhTien dung', N'ThanhTien=' + CAST(@tt AS NVARCHAR(30)),
        CASE WHEN @tt = 500000 THEN 'PASS' ELSE 'FAIL' END);
END TRY
BEGIN CATCH
    INSERT INTO @Result VALUES (N'T11 chi tiet dich vu hop le', ERROR_MESSAGE(), 'FAIL');
END CATCH;

-- T12: SoLuong <= 0 tren ChiTietDichVu -> CK_ChiTietDichVu_SoLuong
BEGIN TRY
    UPDATE ChiTietDichVu SET SoLuong = 0 WHERE MaPhieuSuaChua = @order AND MaDichVu = @dv;
    INSERT INTO @Result VALUES (N'T12 SoLuong = 0 (chi tiet dich vu)', N'Update van thanh cong', 'FAIL');
END TRY
BEGIN CATCH
    INSERT INTO @Result VALUES (N'T12 SoLuong = 0 (chi tiet dich vu)', ERROR_MESSAGE(),
        CASE WHEN ERROR_NUMBER() = 547 AND ERROR_MESSAGE() LIKE '%CK_ChiTietDichVu_SoLuong%' THEN 'PASS' ELSE 'FAIL' END);
END CATCH;

SELECT Id, TestName, Result, Detail FROM @Result ORDER BY Id;

SELECT @n = COUNT(*) FROM @Result WHERE Result = 'FAIL';
IF @n = 0
    PRINT N'TAT CA TEST SPAREPART/REPAIR DETAIL DEU PASS.';
ELSE
    PRINT N'CO ' + CAST(@n AS NVARCHAR(10)) + N' TEST FAIL. Xem bang ket qua o tren.';

-- Khong de lai du lieu test (ke ca dong dich vu bi xoa/them o T11).
ROLLBACK TRAN;
GO
'@
Write-RepoFile 'frontend/src/api/errors.ts' @'
// TV3-TUAN7
import axios from "axios";
import { errorMessage } from "./client";
import type { ApiResponse } from "./types";

/**
 * Backend trả lỗi 400 với message chung kèm map lỗi theo field trong data:
 * ưu tiên hiển thị lỗi field đầu tiên. Các lỗi khác (404/409...) dùng message của API.
 */
export function detailedErrorMessage(error: unknown, fallback: string): string {
  if (axios.isAxiosError<ApiResponse<unknown>>(error)) {
    const details = error.response?.data?.data;
    if (details && typeof details === "object") {
      const first = Object.values(details as Record<string, unknown>).find((value) => typeof value === "string");
      if (typeof first === "string") return first;
    }
  }
  return errorMessage(error, fallback);
}
'@
Write-RepoFile 'frontend/src/api/spareParts.ts' @'
// TV3-TUAN7
import { api, unwrap } from "./client";
import type { ApiResponse } from "./types";

export interface SparePart {
  id: number;
  warehouseId: number;
  name: string;
  manufacturer: string | null;
  unitPrice: number;
  /** Chỉ đọc: tồn kho do nghiệp vụ nhập/xuất kho thay đổi, không sửa ở danh mục. */
  stockQuantity: number;
  minStockLevel: number;
}

export interface SparePartPayload {
  warehouseId: number;
  name: string;
  manufacturer: string | null;
  unitPrice: number;
  minStockLevel: number;
}

export interface SparePartPage {
  items: SparePart[];
  /** Bắt đầu từ 0, giống Spring Data. */
  page: number;
  size: number;
  totalElements: number;
  totalPages: number;
}

export interface Warehouse {
  id: number;
  name: string;
}

export interface SparePartListParams {
  page?: number;
  size?: number;
  search?: string;
}

export type StockStatus = "ok" | "low" | "out";

/** Cùng quy tắc với dbo.fn_TrangThaiTonKho: 0 = hết hàng, <= mức tối thiểu = sắp hết. */
export function stockStatus(part: Pick<SparePart, "stockQuantity" | "minStockLevel">): StockStatus {
  if (part.stockQuantity === 0) return "out";
  if (part.stockQuantity <= part.minStockLevel) return "low";
  return "ok";
}

export const STOCK_LABELS: Record<StockStatus, string> = {
  ok: "Còn hàng",
  low: "Sắp hết",
  out: "Hết hàng",
};

export const sparePartsApi = {
  async list(params: SparePartListParams = {}): Promise<SparePartPage> {
    return unwrap(await api.get<ApiResponse<SparePartPage>>("/api/spare-parts", { params }));
  },

  async getById(id: number): Promise<SparePart> {
    return unwrap(await api.get<ApiResponse<SparePart>>(`/api/spare-parts/${id}`));
  },

  async create(payload: SparePartPayload): Promise<SparePart> {
    return unwrap(await api.post<ApiResponse<SparePart>>("/api/spare-parts", payload));
  },

  async update(id: number, payload: SparePartPayload): Promise<SparePart> {
    return unwrap(await api.put<ApiResponse<SparePart>>(`/api/spare-parts/${id}`, payload));
  },

  async warehouses(): Promise<Warehouse[]> {
    return unwrap(await api.get<ApiResponse<Warehouse[]>>("/api/spare-parts/warehouses"));
  },
};
'@
Write-RepoFile 'frontend/src/api/repairDetails.ts' @'
// TV3-TUAN7
import { api, unwrap } from "./client";
import type { ApiResponse } from "./types";

export type RepairDetailType = "SERVICE" | "SPARE_PART";

export interface RepairDetail {
  type: RepairDetailType;
  itemId: number;
  itemName: string;
  quantity: number;
  unitPrice: number;
  lineTotal: number;
  /** Chỉ dòng dịch vụ có trạng thái tiến độ (do nghiệp vụ kỹ thuật viên cập nhật). */
  status: string | null;
}

export interface RepairDetails {
  repairOrderId: number;
  repairOrderStatus: string;
  editable: boolean;
  items: RepairDetail[];
  serviceTotal: number;
  partsTotal: number;
  totalAmount: number;
}

export interface RepairDetailCreatePayload {
  type: RepairDetailType;
  itemId: number;
  quantity: number;
  /** Bỏ trống = lấy đơn giá hiện tại của danh mục. */
  unitPrice?: number | null;
}

export interface RepairDetailUpdatePayload {
  quantity: number;
  /** Bỏ trống = giữ nguyên đơn giá của dòng. */
  unitPrice?: number | null;
}

const PATH_SEGMENT: Record<RepairDetailType, string> = {
  SERVICE: "service",
  SPARE_PART: "spare-part",
};

const base = (repairOrderId: number) => `/api/repair-orders/${repairOrderId}/details`;
const itemUrl = (repairOrderId: number, type: RepairDetailType, itemId: number) =>
  `${base(repairOrderId)}/${PATH_SEGMENT[type]}/${itemId}`;

export const repairDetailsApi = {
  async list(repairOrderId: number): Promise<RepairDetails> {
    return unwrap(await api.get<ApiResponse<RepairDetails>>(base(repairOrderId)));
  },

  async create(repairOrderId: number, payload: RepairDetailCreatePayload): Promise<RepairDetail> {
    return unwrap(await api.post<ApiResponse<RepairDetail>>(base(repairOrderId), payload));
  },

  async update(
    repairOrderId: number,
    type: RepairDetailType,
    itemId: number,
    payload: RepairDetailUpdatePayload,
  ): Promise<RepairDetail> {
    return unwrap(await api.put<ApiResponse<RepairDetail>>(itemUrl(repairOrderId, type, itemId), payload));
  },

  async remove(repairOrderId: number, type: RepairDetailType, itemId: number): Promise<void> {
    await api.delete<ApiResponse<void>>(itemUrl(repairOrderId, type, itemId));
  },
};
'@
Write-RepoFile 'frontend/src/pages/SpareParts.tsx' @'
// TV3-TUAN7
import { FormEvent, useEffect, useMemo, useState } from "react";
import { detailedErrorMessage } from "../api/errors";
import {
  sparePartsApi,
  stockStatus,
  STOCK_LABELS,
  type SparePart,
  type SparePartPayload,
  type Warehouse,
} from "../api/spareParts";
import { Badge, Button, Card, Icons, Input, Modal, Pagination, SearchBox, Select, TableContainer } from "../components/ui";

const PER_PAGE = 10;

const formatPrice = (value: number) =>
  new Intl.NumberFormat("vi-VN", { style: "currency", currency: "VND", maximumFractionDigits: 0 }).format(value);

interface PartFormProps {
  warehouses: Warehouse[];
  initial?: SparePart;
  onSubmit: (payload: SparePartPayload) => Promise<void>;
  onCancel: () => void;
}

function SparePartForm({ warehouses, initial, onSubmit, onCancel }: PartFormProps) {
  const [warehouseId, setWarehouseId] = useState(initial?.warehouseId?.toString() ?? "");
  const [name, setName] = useState(initial?.name ?? "");
  const [manufacturer, setManufacturer] = useState(initial?.manufacturer ?? "");
  const [unitPrice, setUnitPrice] = useState(initial?.unitPrice?.toString() ?? "");
  const [minStock, setMinStock] = useState(initial?.minStockLevel?.toString() ?? "0");
  const [error, setError] = useState("");
  const [saving, setSaving] = useState(false);

  const handleSubmit = async (event: FormEvent) => {
    event.preventDefault();
    setError("");
    const price = Number(unitPrice);
    const min = Number(minStock);

    if (!warehouseId) return setError("Vui lòng chọn kho.");
    if (!name.trim()) return setError("Vui lòng nhập tên phụ tùng.");
    if (unitPrice.trim() === "" || !Number.isFinite(price) || price < 0) return setError("Đơn giá phải là số không âm.");
    if (!Number.isInteger(min) || min < 0) return setError("Mức tồn tối thiểu phải là số nguyên không âm.");

    setSaving(true);
    try {
      await onSubmit({
        warehouseId: Number(warehouseId),
        name: name.trim(),
        manufacturer: manufacturer.trim() || null,
        unitPrice: price,
        minStockLevel: min,
      });
    } catch (submitError) {
      setError(submitError instanceof Error ? submitError.message : "Không thể lưu phụ tùng.");
    } finally {
      setSaving(false);
    }
  };

  return (
    <form className="space-y-4" onSubmit={handleSubmit}>
      <Select
        label="Kho *"
        value={warehouseId}
        onChange={(event) => setWarehouseId(event.target.value)}
        options={[
          { value: "", label: "— Chọn kho —" },
          ...warehouses.map((warehouse) => ({ value: String(warehouse.id), label: warehouse.name })),
        ]}
      />
      <Input label="Tên phụ tùng *" value={name} onChange={(event) => setName(event.target.value)} maxLength={150} autoFocus required />
      <Input label="Hãng sản xuất" value={manufacturer} onChange={(event) => setManufacturer(event.target.value)} maxLength={150} />
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <Input label="Đơn giá (VND) *" type="number" inputMode="decimal" min={0} step="any" value={unitPrice} onChange={(event) => setUnitPrice(event.target.value)} required />
        <Input label="Mức tồn tối thiểu" type="number" inputMode="numeric" min={0} value={minStock} onChange={(event) => setMinStock(event.target.value)} />
      </div>
      {initial && (
        <Input
          label="Số lượng tồn"
          value={String(initial.stockQuantity)}
          disabled
          helperText="Tồn kho chỉ thay đổi qua nhập/xuất kho, không sửa tại danh mục."
        />
      )}
      {error && <p className="rounded-md bg-danger-soft px-3 py-2 text-sm text-danger" role="alert">{error}</p>}
      <div className="flex flex-col-reverse gap-2 pt-2 sm:flex-row sm:justify-end">
        <Button type="button" variant="outline" onClick={onCancel} disabled={saving}>Hủy</Button>
        <Button type="submit" disabled={saving}>{saving ? "Đang lưu..." : initial ? "Lưu thay đổi" : "Thêm phụ tùng"}</Button>
      </div>
    </form>
  );
}

export default function SpareParts() {
  const [parts, setParts] = useState<SparePart[]>([]);
  const [totalElements, setTotalElements] = useState(0);
  const [warehouses, setWarehouses] = useState<Warehouse[]>([]);
  const [search, setSearch] = useState("");
  const [query, setQuery] = useState("");
  const [page, setPage] = useState(1);
  const [refreshKey, setRefreshKey] = useState(0);
  const [editing, setEditing] = useState<SparePart | null>(null);
  const [showForm, setShowForm] = useState(false);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");

  useEffect(() => {
    const timer = window.setTimeout(() => {
      setQuery(search.trim());
      setPage(1);
    }, 300);
    return () => window.clearTimeout(timer);
  }, [search]);

  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    setError("");
    sparePartsApi
      .list({ page: page - 1, size: PER_PAGE, search: query || undefined })
      .then((result) => {
        if (cancelled) return;
        setParts(result.items);
        setTotalElements(result.totalElements);
      })
      .catch((loadError) => {
        if (!cancelled) setError(detailedErrorMessage(loadError, "Không thể tải danh mục phụ tùng."));
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [page, query, refreshKey]);

  useEffect(() => {
    let cancelled = false;
    sparePartsApi
      .warehouses()
      .then((result) => {
        if (!cancelled) setWarehouses(result);
      })
      .catch((loadError) => {
        if (!cancelled) setError(detailedErrorMessage(loadError, "Không thể tải danh sách kho."));
      });
    return () => {
      cancelled = true;
    };
  }, []);

  const warehouseName = useMemo(() => {
    const names = new Map(warehouses.map((warehouse) => [warehouse.id, warehouse.name]));
    return (id: number) => names.get(id) ?? `Kho ${id}`;
  }, [warehouses]);

  const openCreate = () => {
    setEditing(null);
    setSuccess("");
    setShowForm(true);
  };

  const openEdit = (part: SparePart) => {
    setEditing(part);
    setSuccess("");
    setShowForm(true);
  };

  const handleSubmit = async (payload: SparePartPayload) => {
    try {
      if (editing) await sparePartsApi.update(editing.id, payload);
      else await sparePartsApi.create(payload);
    } catch (saveError) {
      throw new Error(detailedErrorMessage(saveError, "Không thể lưu phụ tùng."));
    }
    setShowForm(false);
    setSuccess(editing ? "Đã cập nhật phụ tùng." : "Đã thêm phụ tùng mới.");
    if (!editing) {
      setSearch("");
      setQuery("");
      setPage(1);
    }
    setRefreshKey((key) => key + 1);
  };

  return (
    <div className="space-y-6">
      <div className="page-toolbar">
        <SearchBox value={search} onChange={setSearch} placeholder="Tìm theo tên hoặc hãng sản xuất..." />
        <div className="flex flex-wrap gap-2">
          <Button variant="outline" onClick={() => setRefreshKey((key) => key + 1)} disabled={loading}>Tải lại</Button>
          <Button icon={Icons.plus} onClick={openCreate}>Thêm phụ tùng</Button>
        </div>
      </div>

      {error && <p className="rounded-md bg-danger-soft px-4 py-3 text-sm text-danger" role="alert">{error}</p>}
      {success && <p className="rounded-md bg-success-soft px-4 py-3 text-sm text-success" role="status">{success}</p>}

      <Card>
        <TableContainer>
          <table className="data-table w-full min-w-[820px]">
            <thead>
              <tr>
                <th>Mã</th>
                <th>Tên phụ tùng</th>
                <th>Hãng sản xuất</th>
                <th>Kho</th>
                <th className="text-right">Đơn giá</th>
                <th className="text-right">Tồn</th>
                <th className="text-right">Tối thiểu</th>
                <th>Tình trạng</th>
                <th>Thao tác</th>
              </tr>
            </thead>
            <tbody>
              {loading && <tr><td colSpan={9} className="py-10 text-center text-sm text-muted-foreground">Đang tải danh mục phụ tùng...</td></tr>}
              {!loading && parts.length === 0 && !error && (
                <tr><td colSpan={9} className="py-10 text-center text-sm text-muted-foreground">Không tìm thấy phụ tùng phù hợp.</td></tr>
              )}
              {!loading && parts.map((part) => {
                const state = stockStatus(part);
                return (
                  <tr key={part.id}>
                    <td><span className="mono text-xs text-slate-400">{part.id}</span></td>
                    <td className="font-medium text-slate-800">{part.name}</td>
                    <td className="text-slate-600">{part.manufacturer || "—"}</td>
                    <td className="text-slate-600">{warehouseName(part.warehouseId)}</td>
                    <td className="mono text-right text-sm">{formatPrice(part.unitPrice)}</td>
                    <td className="mono text-right text-sm font-semibold">{part.stockQuantity}</td>
                    <td className="mono text-right text-sm text-slate-500">{part.minStockLevel}</td>
                    <td><Badge variant={state} label={STOCK_LABELS[state]} /></td>
                    <td>
                      <button
                        type="button"
                        aria-label={`Sửa phụ tùng ${part.name}`}
                        onClick={() => openEdit(part)}
                        className="flex h-11 w-11 items-center justify-center rounded text-slate-500 hover:bg-slate-100"
                      >{Icons.edit}</button>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </TableContainer>
        <div className="flex flex-col gap-3 border-t border-border px-4 py-3 sm:flex-row sm:items-center sm:justify-between">
          <p className="text-xs text-muted-foreground">{totalElements} phụ tùng · Tồn kho chỉ thay đổi qua nhập/xuất kho</p>
          <Pagination page={page} total={totalElements} perPage={PER_PAGE} onChange={setPage} />
        </div>
      </Card>

      <Modal open={showForm} onClose={() => setShowForm(false)} title={editing ? "Cập nhật phụ tùng" : "Thêm phụ tùng"} width="max-w-xl">
        {showForm && (
          <SparePartForm
            key={editing?.id ?? "new"}
            warehouses={warehouses}
            initial={editing ?? undefined}
            onSubmit={handleSubmit}
            onCancel={() => setShowForm(false)}
          />
        )}
      </Modal>
    </div>
  );
}
'@
Write-RepoFile 'frontend/src/pages/RepairDetails.tsx' @'
// TV3-TUAN7
import { FormEvent, useCallback, useEffect, useState } from "react";
import { detailedErrorMessage } from "../api/errors";
import {
  repairDetailsApi,
  type RepairDetail,
  type RepairDetailType,
  type RepairDetails as RepairDetailsData,
} from "../api/repairDetails";
import { sparePartsApi, type SparePart } from "../api/spareParts";
import { Badge, Button, Card, Icons, Input, Modal, Select, TableContainer } from "../components/ui";

const formatPrice = (value: number) =>
  new Intl.NumberFormat("vi-VN", { style: "currency", currency: "VND", maximumFractionDigits: 0 }).format(value);

const TYPE_LABELS: Record<RepairDetailType, string> = {
  SERVICE: "Dịch vụ",
  SPARE_PART: "Phụ tùng",
};

interface DetailFormProps {
  editing: RepairDetail | null;
  onSubmit: (value: { type: RepairDetailType; itemId: number; quantity: number; unitPrice: number | null }) => Promise<void>;
  onCancel: () => void;
}

function DetailForm({ editing, onSubmit, onCancel }: DetailFormProps) {
  const [type, setType] = useState<RepairDetailType>(editing?.type ?? "SPARE_PART");
  const [itemId, setItemId] = useState(editing?.itemId?.toString() ?? "");
  const [quantity, setQuantity] = useState(editing?.quantity?.toString() ?? "1");
  const [unitPrice, setUnitPrice] = useState(editing ? String(editing.unitPrice) : "");
  const [parts, setParts] = useState<SparePart[]>([]);
  const [partsError, setPartsError] = useState("");
  const [error, setError] = useState("");
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    if (editing || type !== "SPARE_PART") return;
    let cancelled = false;
    sparePartsApi
      .list({ page: 0, size: 100 })
      .then((result) => {
        if (!cancelled) setParts(result.items);
      })
      .catch((loadError) => {
        if (!cancelled) setPartsError(detailedErrorMessage(loadError, "Không thể tải danh mục phụ tùng."));
      });
    return () => {
      cancelled = true;
    };
  }, [editing, type]);

  const handleSubmit = async (event: FormEvent) => {
    event.preventDefault();
    setError("");
    const id = Number(itemId);
    const qty = Number(quantity);
    const price = unitPrice.trim() === "" ? null : Number(unitPrice);

    if (!editing && (!Number.isInteger(id) || id <= 0)) return setError(type === "SERVICE" ? "Vui lòng nhập mã dịch vụ." : "Vui lòng chọn phụ tùng.");
    if (!Number.isInteger(qty) || qty <= 0) return setError("Số lượng phải là số nguyên lớn hơn 0.");
    if (price !== null && (!Number.isFinite(price) || price < 0)) return setError("Đơn giá phải là số không âm.");

    setSaving(true);
    try {
      await onSubmit({ type, itemId: editing ? editing.itemId : id, quantity: qty, unitPrice: price });
    } catch (submitError) {
      setError(submitError instanceof Error ? submitError.message : "Không thể lưu hạng mục.");
    } finally {
      setSaving(false);
    }
  };

  return (
    <form className="space-y-4" onSubmit={handleSubmit}>
      {editing ? (
        <p className="rounded-md bg-muted px-3 py-2 text-sm text-slate-700">
          {TYPE_LABELS[editing.type]}: <span className="font-semibold">{editing.itemName}</span>
        </p>
      ) : (
        <>
          <Select
            label="Loại hạng mục *"
            value={type}
            onChange={(event) => { setType(event.target.value as RepairDetailType); setItemId(""); }}
            options={[
              { value: "SPARE_PART", label: "Phụ tùng" },
              { value: "SERVICE", label: "Dịch vụ" },
            ]}
          />
          {type === "SPARE_PART" ? (
            <Select
              label="Phụ tùng *"
              value={itemId}
              onChange={(event) => {
                setItemId(event.target.value);
                const picked = parts.find((part) => String(part.id) === event.target.value);
                if (picked) setUnitPrice(String(picked.unitPrice));
              }}
              helperText={partsError || "Đơn giá mặc định lấy từ danh mục phụ tùng."}
              options={[
                { value: "", label: "— Chọn phụ tùng —" },
                ...parts.map((part) => ({ value: String(part.id), label: `${part.name}${part.manufacturer ? ` – ${part.manufacturer}` : ""}` })),
              ]}
            />
          ) : (
            <Input
              label="Mã dịch vụ *"
              type="number"
              inputMode="numeric"
              min={1}
              value={itemId}
              onChange={(event) => setItemId(event.target.value)}
              helperText="Nhập mã dịch vụ trong danh mục Dịch vụ. Để trống đơn giá để lấy giá niêm yết."
            />
          )}
        </>
      )}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <Input label="Số lượng *" type="number" inputMode="numeric" min={1} value={quantity} onChange={(event) => setQuantity(event.target.value)} required />
        <Input label="Đơn giá (VND)" type="number" inputMode="decimal" min={0} step="any" value={unitPrice} onChange={(event) => setUnitPrice(event.target.value)} />
      </div>
      <p className="text-xs leading-5 text-muted-foreground">
        Thêm hoặc sửa hạng mục chỉ ghi chi tiết phiếu; không xuất kho và không thay đổi tồn kho.
      </p>
      {error && <p className="rounded-md bg-danger-soft px-3 py-2 text-sm text-danger" role="alert">{error}</p>}
      <div className="flex flex-col-reverse gap-2 pt-2 sm:flex-row sm:justify-end">
        <Button type="button" variant="outline" onClick={onCancel} disabled={saving}>Hủy</Button>
        <Button type="submit" disabled={saving}>{saving ? "Đang lưu..." : editing ? "Lưu thay đổi" : "Thêm hạng mục"}</Button>
      </div>
    </form>
  );
}

export default function RepairDetails() {
  const [orderInput, setOrderInput] = useState("");
  const [orderId, setOrderId] = useState<number | null>(null);
  const [data, setData] = useState<RepairDetailsData | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");
  const [showForm, setShowForm] = useState(false);
  const [editing, setEditing] = useState<RepairDetail | null>(null);
  const [deleting, setDeleting] = useState<RepairDetail | null>(null);
  const [deleteBusy, setDeleteBusy] = useState(false);

  const load = useCallback(async (id: number) => {
    setLoading(true);
    setError("");
    try {
      setData(await repairDetailsApi.list(id));
    } catch (loadError) {
      setData(null);
      setError(detailedErrorMessage(loadError, "Không thể tải chi tiết phiếu sửa chữa."));
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    if (orderId !== null) void load(orderId);
  }, [orderId, load]);

  const handleLookup = (event: FormEvent) => {
    event.preventDefault();
    setSuccess("");
    const id = Number(orderInput);
    if (!Number.isInteger(id) || id <= 0) {
      setData(null);
      setError("Vui lòng nhập mã phiếu sửa chữa hợp lệ.");
      return;
    }
    if (id === orderId) void load(id);
    else setOrderId(id);
  };

  const handleSubmit = async (value: { type: RepairDetailType; itemId: number; quantity: number; unitPrice: number | null }) => {
    if (orderId === null) return;
    try {
      if (editing) {
        await repairDetailsApi.update(orderId, editing.type, editing.itemId, { quantity: value.quantity, unitPrice: value.unitPrice });
      } else {
        await repairDetailsApi.create(orderId, value);
      }
    } catch (saveError) {
      throw new Error(detailedErrorMessage(saveError, "Không thể lưu hạng mục."));
    }
    setShowForm(false);
    setSuccess(editing ? "Đã cập nhật hạng mục." : "Đã thêm hạng mục.");
    await load(orderId);
  };

  const confirmDelete = async () => {
    if (orderId === null || !deleting) return;
    setDeleteBusy(true);
    try {
      await repairDetailsApi.remove(orderId, deleting.type, deleting.itemId);
      setDeleting(null);
      setSuccess("Đã xóa hạng mục.");
      await load(orderId);
    } catch (deleteError) {
      setDeleting(null);
      setError(detailedErrorMessage(deleteError, "Không thể xóa hạng mục."));
    } finally {
      setDeleteBusy(false);
    }
  };

  return (
    <div className="space-y-6">
      <Card className="p-4 sm:p-5">
        <form className="flex flex-col gap-3 sm:flex-row sm:items-end" onSubmit={handleLookup}>
          <div className="sm:w-72">
            <Input
              label="Mã phiếu sửa chữa"
              type="number"
              inputMode="numeric"
              min={1}
              value={orderInput}
              onChange={(event) => setOrderInput(event.target.value)}
              placeholder="Ví dụ: 1"
            />
          </div>
          <Button type="submit" disabled={loading}>{loading ? "Đang tải..." : "Xem chi tiết"}</Button>
        </form>
      </Card>

      {error && <p className="rounded-md bg-danger-soft px-4 py-3 text-sm text-danger" role="alert">{error}</p>}
      {success && <p className="rounded-md bg-success-soft px-4 py-3 text-sm text-success" role="status">{success}</p>}

      {data && (
        <Card>
          <div className="flex flex-col gap-3 border-b border-border px-4 py-4 sm:flex-row sm:items-center sm:justify-between sm:px-5">
            <div>
              <p className="text-lg font-bold text-foreground">Phiếu sửa chữa #{data.repairOrderId}</p>
              <p className="mt-1 flex items-center gap-2 text-sm text-muted-foreground">
                Trạng thái phiếu: <Badge variant={data.editable ? "in_progress" : "completed"} label={data.repairOrderStatus} />
              </p>
            </div>
            <Button icon={Icons.plus} disabled={!data.editable} onClick={() => { setEditing(null); setSuccess(""); setShowForm(true); }}>
              Thêm hạng mục
            </Button>
          </div>
          {!data.editable && (
            <p className="border-b border-border bg-muted px-4 py-2 text-xs text-muted-foreground sm:px-5">
              Phiếu đã đóng nên không thể thêm, sửa hoặc xóa hạng mục.
            </p>
          )}
          <TableContainer>
            <table className="data-table w-full min-w-[720px]">
              <thead>
                <tr>
                  <th>Loại</th>
                  <th>Hạng mục</th>
                  <th className="text-right">Số lượng</th>
                  <th className="text-right">Đơn giá</th>
                  <th className="text-right">Thành tiền</th>
                  <th>Tiến độ</th>
                  <th>Thao tác</th>
                </tr>
              </thead>
              <tbody>
                {data.items.length === 0 && (
                  <tr><td colSpan={7} className="py-10 text-center text-sm text-muted-foreground">Phiếu chưa có hạng mục nào.</td></tr>
                )}
                {data.items.map((item) => (
                  <tr key={`${item.type}-${item.itemId}`}>
                    <td><Badge variant={item.type === "SERVICE" ? "confirmed" : "draft"} label={TYPE_LABELS[item.type]} /></td>
                    <td className="font-medium text-slate-800">{item.itemName}</td>
                    <td className="mono text-right text-sm">{item.quantity}</td>
                    <td className="mono text-right text-sm">{formatPrice(item.unitPrice)}</td>
                    <td className="mono text-right text-sm font-semibold">{formatPrice(item.lineTotal)}</td>
                    <td className="text-sm text-slate-600">{item.status ?? "—"}</td>
                    <td>
                      <div className="flex gap-1">
                        <button
                          type="button"
                          aria-label={`Sửa hạng mục ${item.itemName}`}
                          disabled={!data.editable}
                          onClick={() => { setEditing(item); setSuccess(""); setShowForm(true); }}
                          className="flex h-11 w-11 items-center justify-center rounded text-slate-500 hover:bg-slate-100 disabled:opacity-40"
                        >{Icons.edit}</button>
                        <button
                          type="button"
                          aria-label={`Xóa hạng mục ${item.itemName}`}
                          disabled={!data.editable}
                          onClick={() => setDeleting(item)}
                          className="flex h-11 items-center justify-center rounded px-2 text-sm text-danger hover:bg-danger-soft disabled:opacity-40"
                        >Xóa</button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </TableContainer>
          <dl className="grid grid-cols-1 gap-3 border-t border-border px-4 py-4 text-sm sm:grid-cols-3 sm:px-5">
            <div><dt className="text-xs text-muted-foreground">Tiền dịch vụ</dt><dd className="mono mt-1 font-semibold">{formatPrice(data.serviceTotal)}</dd></div>
            <div><dt className="text-xs text-muted-foreground">Tiền phụ tùng</dt><dd className="mono mt-1 font-semibold">{formatPrice(data.partsTotal)}</dd></div>
            <div><dt className="text-xs text-muted-foreground">Tổng cộng</dt><dd className="mono mt-1 text-lg font-bold text-primary">{formatPrice(data.totalAmount)}</dd></div>
          </dl>
        </Card>
      )}

      <Modal open={showForm} onClose={() => setShowForm(false)} title={editing ? "Sửa hạng mục" : "Thêm hạng mục"} width="max-w-xl">
        {showForm && (
          <DetailForm
            key={editing ? `${editing.type}-${editing.itemId}` : "new"}
            editing={editing}
            onSubmit={handleSubmit}
            onCancel={() => setShowForm(false)}
          />
        )}
      </Modal>

      <Modal open={deleting !== null} onClose={() => setDeleting(null)} title="Xóa hạng mục" width="max-w-md">
        {deleting && (
          <div className="space-y-4">
            <p className="text-sm text-slate-700">
              Xóa <span className="font-semibold">{deleting.itemName}</span> khỏi phiếu #{orderId}? Thao tác này không ảnh hưởng đến tồn kho.
            </p>
            <div className="flex flex-col-reverse gap-2 sm:flex-row sm:justify-end">
              <Button variant="outline" onClick={() => setDeleting(null)} disabled={deleteBusy}>Hủy</Button>
              <Button variant="danger" onClick={() => void confirmDelete()} disabled={deleteBusy}>{deleteBusy ? "Đang xóa..." : "Xóa hạng mục"}</Button>
            </div>
          </div>
        )}
      </Modal>
    </div>
  );
}
'@

Write-Step 'Va file dung chung (chi them dong can thiet, co backup)'
Update-RepoFile 'frontend/src/router.ts' '| "technician" | "design-system";' '| "technician" | "design-system" | "spare-parts" | "repair-details";' '"spare-parts" | "repair-details";'
Update-RepoFile 'frontend/src/router.ts' '"technician", "design-system",' '"technician", "design-system", "spare-parts", "repair-details",' '"design-system", "spare-parts"'
Update-RepoFile 'frontend/src/components/Sidebar.tsx' '  { key: "inventory", label: "Phụ tùng & Kho", icon: Icons.package },' '  { key: "inventory", label: "Phụ tùng & Kho", icon: Icons.package },
  { key: "spare-parts", label: "Danh mục phụ tùng", icon: Icons.package },
  { key: "repair-details", label: "Chi tiết phiếu sửa", icon: Icons.wrench },' 'key: "spare-parts"'
Update-RepoFile 'frontend/src/components/Header.tsx' '  inventory: "Phụ tùng & Kho",' '  inventory: "Phụ tùng & Kho",
  "spare-parts": "Danh mục phụ tùng",
  "repair-details": "Chi tiết phiếu sửa chữa",' '"spare-parts": "Danh mục phụ tùng"'
Update-RepoFile 'frontend/src/App.tsx' 'const Inventory = lazy(() => import("./pages/Inventory"));' 'const Inventory = lazy(() => import("./pages/Inventory"));
const SpareParts = lazy(() => import("./pages/SpareParts"));
const RepairDetails = lazy(() => import("./pages/RepairDetails"));' 'import("./pages/SpareParts")'
Update-RepoFile 'frontend/src/App.tsx' '    case "inventory": return <Inventory />;' '    case "inventory": return <Inventory />;
    case "spare-parts": return <SpareParts />;
    case "repair-details": return <RepairDetails />;' 'case "spare-parts"'
Update-RepoFile 'frontend/src/App.tsx' 'const ROLE_NAV: Record<Role, AdminPage[]> = {' 'const BASE_ROLE_NAV: Record<Role, AdminPage[]> = {' 'const BASE_ROLE_NAV'
Update-RepoFile 'frontend/src/App.tsx' '};

function accountRole(role: string): Role | null {' '};

// Tuần 7: danh mục phụ tùng và chi tiết phiếu sửa chữa, gộp thêm vào menu theo vai trò.
const WEEK7_ROLE_NAV: Partial<Record<Role, AdminPage[]>> = {
  receptionist: ["repair-details"],
  warehouse: ["spare-parts"],
  manager: ["spare-parts", "repair-details"],
};

const ROLE_NAV: Record<Role, AdminPage[]> = Object.fromEntries(
  (Object.keys(BASE_ROLE_NAV) as Role[]).map((role) => [role, [...BASE_ROLE_NAV[role], ...(WEEK7_ROLE_NAV[role] ?? [])]]),
) as Record<Role, AdminPage[]>;

function accountRole(role: string): Role | null {' 'const WEEK7_ROLE_NAV'

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
        $vehicleErrors = @($tsc | Where-Object { $_ -match "SpareParts|RepairDetails|spareParts|repairDetails|errors\.ts|router|Sidebar|Header|App\.tsx" })
        if ($vehicleErrors.Count -gt 0) {
            $vehicleErrors | ForEach-Object { Write-Host "    $_" -ForegroundColor Red }
            $script:Results["Frontend tsc"] = "FAIL (loi lien quan Tuan 7)"
            Show-Summary
            exit 1
        }
        $script:Results["Frontend tsc"] = "WARN (loi khong thuoc Tuan 7)"
        Write-Warn2 "tsc bao loi o file khac Tuan 7 (co the co san tu truoc)."
    }
}

Write-Host ""
Write-Host "Luu y: chay backend/database/Test_SpareParts.sql trong SSMS de kiem tra rang buoc bang Xe (script tu ROLLBACK)." -ForegroundColor Yellow

# ============================================================
# 8. ZIP (chi khi build/test da chay thanh cong)
# ============================================================
if (-not $SkipBuild -and -not $NoZip) {
    Write-Step "Tao TV3_Tuan7_SparePart_RepairDetail_FINAL.zip"
    $zip = Join-Path $root "TV3_Tuan7_SparePart_RepairDetail_FINAL.zip"
    $stage = Join-Path ([System.IO.Path]::GetTempPath()) "tv3-vehicle-$stamp"
    New-Item -ItemType Directory -Force -Path $stage | Out-Null
    robocopy $root $stage /E /NFL /NDL /NJH /NJS /NP `
        /XD target node_modules .idea .vscode .backup .git dist .dart_tool build .gradle `
        /XF *.log .env .env.local TV3_Tuan7_SparePart_RepairDetail_FINAL.zip TV3_Tuan7_APPLY.ps1 | Out-Null
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
Write-Host "  git commit -m `"feat(spare-part): implement spare part and repair details`""
Write-Host "  git push -u origin feature/cam-sparepart"
