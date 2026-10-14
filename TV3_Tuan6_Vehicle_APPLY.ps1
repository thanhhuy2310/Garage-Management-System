<#
  TV3_Tuan6_Vehicle_APPLY.ps1 - Tuan 6 - TV3 Hoang Van Cam - Quan ly xe (Vehicle)
  Chay tu repository root:   .\TV3_Tuan6_Vehicle_APPLY.ps1
  Tuy chon: -SkipBuild (chi ap dung file), -NoZip (khong tao zip)
  Khong commit, khong push Git.
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
# 1. XAC DINH REPOSITORY ROOT + KIEM TRA CAU TRUC
# ------------------------------------------------------------
Write-Step "Kiem tra repository"
$root = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$required = @(
    "backend/pom.xml",
    "backend/mvnw.cmd",
    "backend/database/QuanLyGaraOTo.sql",
    "backend/src/main/java/com/gara/quanlygara/controller/CustomerController.java",
    "backend/src/main/java/com/gara/quanlygara/config/SecurityConfig.java",
    "backend/src/main/java/com/gara/quanlygara/exception/GlobalExceptionHandler.java",
    "backend/src/test/java/com/gara/quanlygara/config/SecurityConfigTest.java",
    "frontend/package.json",
    "frontend/src/api/client.ts",
    "frontend/src/api/customers.ts",
    "frontend/src/components/ui.tsx",
    "frontend/src/pages/customer/CustomerPortal.tsx",
    "frontend/src/pages/customer/CustomerAppointments.tsx"
)
$missing = @($required | Where-Object { -not (Test-Path -LiteralPath (Join-Path $root $_)) })
if ($missing.Count -gt 0) {
    Stop-Fail ("Khong dung repository root ($root). Thieu:`n  - " + ($missing -join "`n  - "))
}
Set-Location -LiteralPath $root
Write-Ok "Repository root: $root"

$sql = Get-Content -LiteralPath (Join-Path $root "backend/database/QuanLyGaraOTo.sql") -Raw
if ($sql -notmatch "CREATE TABLE Xe\s*\(" -or $sql -notmatch "BienSo" -or $sql -notmatch "NamSanXuat") {
    Stop-Fail "QuanLyGaraOTo.sql khong co bang Xe nhu du kien (MaXe/MaKhachHang/BienSo/HangXe/DongXe/NamSanXuat/SoKm)."
}
Write-Ok "Schema bang Xe khop, giu nguyen QuanLyGaraOTo.sql"

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
Write-Step "Git"
if ((Get-Command git -ErrorAction SilentlyContinue) -and (Test-Path -LiteralPath (Join-Path $root ".git"))) {
    $branch = (git rev-parse --abbrev-ref HEAD).Trim()
    Write-Host "    Nhanh hien tai: $branch"
    $dirty = git status --short
    if ($dirty) { Write-Host "    Thay doi chua commit (se duoc giu nguyen):"; $dirty | ForEach-Object { Write-Host "      $_" } }
    if ($branch -eq "main" -or $branch -eq "master") {
        git show-ref --verify --quiet refs/heads/feature/cam-vehicle
        if ($LASTEXITCODE -eq 0) { git checkout feature/cam-vehicle } else { git checkout -b feature/cam-vehicle }
        if ($LASTEXITCODE -ne 0) { Stop-Fail "Khong chuyen duoc sang nhanh feature/cam-vehicle. Hay xu ly thu cong roi chay lai." }
        Write-Ok "Dang o nhanh feature/cam-vehicle"
    }
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

function Write-RepoFile($rel, $content) {
    $path = Join-Path $root $rel
    $text = ($content -replace "`r`n", "`n").TrimEnd("`n") + "`n"
    if (Test-Path -LiteralPath $path) {
        $existing = [System.IO.File]::ReadAllText($path, $utf8NoBom) -replace "`r`n", "`n"
        if ($existing -eq $text) { Write-Host "    = $rel (khong doi)"; return }
        Backup-RepoFile $rel
        Write-Host "    ~ $rel (da backup)"
    } else {
        New-Item -ItemType Directory -Force -Path (Split-Path $path) | Out-Null
        Write-Host "    + $rel"
    }
    [System.IO.File]::WriteAllText($path, $text, $utf8NoBom)
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
# 4. KIEM TRA FILE SE BI GHI DE
# ------------------------------------------------------------
Write-Step "Ap dung Vehicle (khong phai tao project moi, khong doi schema)"

# ============================================================
# 5. TAO / GHI DE FILE VEHICLE (co backup neu file da ton tai)
# ============================================================
Write-Step 'Tao / cap nhat file Vehicle'
Write-RepoFile 'backend/src/main/java/com/gara/quanlygara/entity/Vehicle.java' @'
package com.gara.quanlygara.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

/**
 * Xe của khách hàng. Ánh xạ trực tiếp vào bảng Xe của QuanLyGaraOTo.sql,
 * không đổi tên bảng/cột và không thêm cột mới.
 */
@Entity
@Table(name = "Xe")
public class Vehicle {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "MaXe")
    private Integer id;

    @Column(name = "MaKhachHang", nullable = false)
    private Integer customerId;

    @Column(name = "BienSo", nullable = false, length = 20, unique = true)
    private String licensePlate;

    @Column(name = "HangXe", length = 100)
    private String brand;

    @Column(name = "DongXe", length = 100)
    private String model;

    @Column(name = "NamSanXuat")
    private Short year;

    @Column(name = "SoKm")
    private Integer mileage;

    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public Integer getCustomerId() {
        return customerId;
    }

    public void setCustomerId(Integer customerId) {
        this.customerId = customerId;
    }

    public String getLicensePlate() {
        return licensePlate;
    }

    public void setLicensePlate(String licensePlate) {
        this.licensePlate = licensePlate;
    }

    public String getBrand() {
        return brand;
    }

    public void setBrand(String brand) {
        this.brand = brand;
    }

    public String getModel() {
        return model;
    }

    public void setModel(String model) {
        this.model = model;
    }

    public Short getYear() {
        return year;
    }

    public void setYear(Short year) {
        this.year = year;
    }

    public Integer getMileage() {
        return mileage;
    }

    public void setMileage(Integer mileage) {
        this.mileage = mileage;
    }
}
'@
Write-RepoFile 'backend/src/main/java/com/gara/quanlygara/dto/vehicle/VehicleRequest.java' @'
package com.gara.quanlygara.dto.vehicle;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

public record VehicleRequest(
        @NotNull(message = "Vui lòng chọn chủ xe.")
        @Positive(message = "Mã khách hàng không hợp lệ.")
        Integer customerId,

        @NotBlank(message = "Biển số không được để trống.")
        @Size(max = 20, message = "Biển số không được vượt quá 20 ký tự.")
        String licensePlate,

        @Size(max = 100, message = "Hãng xe không được vượt quá 100 ký tự.")
        String brand,

        @Size(max = 100, message = "Dòng xe không được vượt quá 100 ký tự.")
        String model,

        @Min(value = 1886, message = "Năm sản xuất không hợp lệ.")
        @Max(value = 2100, message = "Năm sản xuất không hợp lệ.")
        Short year,

        @Min(value = 0, message = "Số km không được âm.")
        Integer mileage
) {
}
'@
Write-RepoFile 'backend/src/main/java/com/gara/quanlygara/dto/vehicle/VehicleResponse.java' @'
package com.gara.quanlygara.dto.vehicle;

import com.gara.quanlygara.entity.Vehicle;

public record VehicleResponse(
        Integer id,
        Integer customerId,
        String licensePlate,
        String brand,
        String model,
        Short year,
        Integer mileage
) {
    public static VehicleResponse from(Vehicle vehicle) {
        return new VehicleResponse(
                vehicle.getId(),
                vehicle.getCustomerId(),
                vehicle.getLicensePlate(),
                vehicle.getBrand(),
                vehicle.getModel(),
                vehicle.getYear(),
                vehicle.getMileage()
        );
    }
}
'@
Write-RepoFile 'backend/src/main/java/com/gara/quanlygara/dto/vehicle/VehiclePageResponse.java' @'
package com.gara.quanlygara.dto.vehicle;

import com.gara.quanlygara.entity.Vehicle;
import org.springframework.data.domain.Page;

import java.util.List;

/** Trang dữ liệu xe. page bắt đầu từ 0, giống Spring Data. */
public record VehiclePageResponse(
        List<VehicleResponse> items,
        int page,
        int size,
        long totalElements,
        int totalPages
) {
    public static VehiclePageResponse from(Page<Vehicle> result) {
        return new VehiclePageResponse(
                result.getContent().stream().map(VehicleResponse::from).toList(),
                result.getNumber(),
                result.getSize(),
                result.getTotalElements(),
                result.getTotalPages()
        );
    }
}
'@
Write-RepoFile 'backend/src/main/java/com/gara/quanlygara/repository/VehicleRepository.java' @'
package com.gara.quanlygara.repository;

import com.gara.quanlygara.entity.Vehicle;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface VehicleRepository extends JpaRepository<Vehicle, Integer> {

    boolean existsByLicensePlate(String licensePlate);

    boolean existsByLicensePlateAndIdNot(String licensePlate, Integer id);

    Page<Vehicle> findByLicensePlateContainingIgnoreCase(String keyword, Pageable pageable);

    List<Vehicle> findByCustomerIdOrderByIdDesc(Integer customerId);
}
'@
Write-RepoFile 'backend/src/main/java/com/gara/quanlygara/service/VehicleService.java' @'
package com.gara.quanlygara.service;

import com.gara.quanlygara.dto.vehicle.VehiclePageResponse;
import com.gara.quanlygara.dto.vehicle.VehicleRequest;
import com.gara.quanlygara.dto.vehicle.VehicleResponse;
import com.gara.quanlygara.entity.Vehicle;
import com.gara.quanlygara.exception.BadRequestException;
import com.gara.quanlygara.exception.ConflictException;
import com.gara.quanlygara.exception.ResourceNotFoundException;
import com.gara.quanlygara.repository.CustomerRepository;
import com.gara.quanlygara.repository.VehicleRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Year;
import java.util.List;
import java.util.Locale;

@Service
public class VehicleService {

    private static final int MIN_YEAR = 1886;
    private static final int MAX_PAGE_SIZE = 100;

    private final VehicleRepository vehicleRepository;
    private final CustomerRepository customerRepository;

    public VehicleService(VehicleRepository vehicleRepository, CustomerRepository customerRepository) {
        this.vehicleRepository = vehicleRepository;
        this.customerRepository = customerRepository;
    }

    @Transactional(readOnly = true)
    public VehiclePageResponse getAll(int page, int size, String search) {
        Pageable pageable = PageRequest.of(
                Math.max(page, 0),
                Math.min(Math.max(size, 1), MAX_PAGE_SIZE),
                Sort.by(Sort.Direction.DESC, "id"));

        String keyword = normalizeOptional(search);
        Page<Vehicle> result = keyword == null
                ? vehicleRepository.findAll(pageable)
                : vehicleRepository.findByLicensePlateContainingIgnoreCase(keyword, pageable);
        return VehiclePageResponse.from(result);
    }

    @Transactional(readOnly = true)
    public VehicleResponse getById(Integer id) {
        return VehicleResponse.from(findEntity(id));
    }

    @Transactional(readOnly = true)
    public List<VehicleResponse> getByCustomer(Integer customerId) {
        ensureCustomerExists(customerId);
        return vehicleRepository.findByCustomerIdOrderByIdDesc(customerId)
                .stream()
                .map(VehicleResponse::from)
                .toList();
    }

    @Transactional
    public VehicleResponse create(VehicleRequest request) {
        ensureCustomerExists(request.customerId());
        validateYear(request.year());

        String plate = normalizePlate(request.licensePlate());
        if (vehicleRepository.existsByLicensePlate(plate)) {
            throw new ConflictException("Biển số xe đã tồn tại.");
        }

        Vehicle vehicle = new Vehicle();
        apply(vehicle, request, plate);
        return VehicleResponse.from(vehicleRepository.saveAndFlush(vehicle));
    }

    @Transactional
    public VehicleResponse update(Integer id, VehicleRequest request) {
        Vehicle vehicle = findEntity(id);
        if (!request.customerId().equals(vehicle.getCustomerId())) {
            ensureCustomerExists(request.customerId());
        }
        validateYear(request.year());

        String plate = normalizePlate(request.licensePlate());
        if (vehicleRepository.existsByLicensePlateAndIdNot(plate, id)) {
            throw new ConflictException("Biển số xe đã được sử dụng bởi xe khác.");
        }

        apply(vehicle, request, plate);
        return VehicleResponse.from(vehicleRepository.saveAndFlush(vehicle));
    }

    private Vehicle findEntity(Integer id) {
        return vehicleRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy xe."));
    }

    private void ensureCustomerExists(Integer customerId) {
        if (customerId == null || !customerRepository.existsById(customerId)) {
            throw new ResourceNotFoundException("Không tìm thấy khách hàng.");
        }
    }

    private void validateYear(Short year) {
        if (year == null) return;
        int maxYear = Year.now().getValue() + 1;
        if (year < MIN_YEAR || year > maxYear) {
            throw new BadRequestException("Năm sản xuất phải từ " + MIN_YEAR + " đến " + maxYear + ".");
        }
    }

    private void apply(Vehicle vehicle, VehicleRequest request, String plate) {
        vehicle.setCustomerId(request.customerId());
        vehicle.setLicensePlate(plate);
        vehicle.setBrand(normalizeOptional(request.brand()));
        vehicle.setModel(normalizeOptional(request.model()));
        vehicle.setYear(request.year());
        vehicle.setMileage(request.mileage());
    }

    private String normalizePlate(String value) {
        return value.trim().replaceAll("\\s+", " ").toUpperCase(Locale.ROOT);
    }

    private String normalizeOptional(String value) {
        if (value == null || value.isBlank()) return null;
        return value.trim();
    }
}
'@
Write-RepoFile 'backend/src/main/java/com/gara/quanlygara/security/VehicleAccessPolicy.java' @'
package com.gara.quanlygara.security;

import com.gara.quanlygara.repository.AccountRepository;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Component;

/**
 * Dùng trong @PreAuthorize: tài khoản CUSTOMER chỉ được thao tác trên xe của chính mình.
 */
@Component("vehicleAccess")
public class VehicleAccessPolicy {

    private final AccountRepository accountRepository;

    public VehicleAccessPolicy(AccountRepository accountRepository) {
        this.accountRepository = accountRepository;
    }

    public boolean ownsCustomer(Authentication authentication, Integer customerId) {
        if (authentication == null || customerId == null) return false;
        return accountRepository.findByUsername(authentication.getName())
                .map(account -> customerId.equals(account.getCustomerId()))
                .orElse(false);
    }
}
'@
Write-RepoFile 'backend/src/main/java/com/gara/quanlygara/controller/VehicleController.java' @'
package com.gara.quanlygara.controller;

import com.gara.quanlygara.dto.ApiResponse;
import com.gara.quanlygara.dto.vehicle.VehiclePageResponse;
import com.gara.quanlygara.dto.vehicle.VehicleRequest;
import com.gara.quanlygara.dto.vehicle.VehicleResponse;
import com.gara.quanlygara.service.VehicleService;
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

@RestController
@RequestMapping("/api/vehicles")
@PreAuthorize("hasAnyRole('ADMIN', 'MANAGER', 'RECEPTIONIST')")
public class VehicleController {

    private final VehicleService vehicleService;

    public VehicleController(VehicleService vehicleService) {
        this.vehicleService = vehicleService;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<VehiclePageResponse>> getAll(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(required = false) String search
    ) {
        return ResponseEntity.ok(ApiResponse.success("Lấy danh sách xe thành công.",
                vehicleService.getAll(page, size, search)));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<VehicleResponse>> getById(@PathVariable Integer id) {
        return ResponseEntity.ok(ApiResponse.success("Lấy thông tin xe thành công.", vehicleService.getById(id)));
    }

    // Nhân viên tạo xe cho mọi khách hàng; khách hàng chỉ được thêm xe cho chính mình.
    @PostMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER', 'RECEPTIONIST')"
            + " or (hasRole('CUSTOMER') and @vehicleAccess.ownsCustomer(authentication, #request.customerId()))")
    public ResponseEntity<ApiResponse<VehicleResponse>> create(@Valid @RequestBody VehicleRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Thêm xe thành công.", vehicleService.create(request)));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<VehicleResponse>> update(
            @PathVariable Integer id,
            @Valid @RequestBody VehicleRequest request
    ) {
        return ResponseEntity.ok(ApiResponse.success("Cập nhật xe thành công.", vehicleService.update(id, request)));
    }
}
'@
Write-RepoFile 'backend/src/main/java/com/gara/quanlygara/controller/CustomerVehicleController.java' @'
package com.gara.quanlygara.controller;

import com.gara.quanlygara.dto.ApiResponse;
import com.gara.quanlygara.dto.vehicle.VehicleResponse;
import com.gara.quanlygara.service.VehicleService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * GET /api/customers/{id}/vehicles. Tách khỏi CustomerController vì controller đó
 * chỉ cho phép nhân viên, trong khi khách hàng cần xem xe của chính mình.
 */
@RestController
@RequestMapping("/api/customers")
public class CustomerVehicleController {

    private final VehicleService vehicleService;

    public CustomerVehicleController(VehicleService vehicleService) {
        this.vehicleService = vehicleService;
    }

    @GetMapping("/{id}/vehicles")
    @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER', 'RECEPTIONIST')"
            + " or (hasRole('CUSTOMER') and @vehicleAccess.ownsCustomer(authentication, #id))")
    public ResponseEntity<ApiResponse<List<VehicleResponse>>> getByCustomer(@PathVariable Integer id) {
        return ResponseEntity.ok(ApiResponse.success("Lấy danh sách xe của khách hàng thành công.",
                vehicleService.getByCustomer(id)));
    }
}
'@
Write-RepoFile 'backend/src/main/java/com/gara/quanlygara/config/OpenApiConfig.java' @'
package com.gara.quanlygara.config;

import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.security.SecurityScheme;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class OpenApiConfig {

    private static final String BEARER_SCHEME = "bearerAuth";

    @Bean
    public OpenAPI garageOpenApi() {
        return new OpenAPI()
                .info(new Info()
                        .title("Garage Management API")
                        .version("0.0.1")
                        .description("API hệ thống quản lý gara sửa chữa ô tô"))
                .addSecurityItem(new SecurityRequirement().addList(BEARER_SCHEME))
                .components(new Components().addSecuritySchemes(BEARER_SCHEME,
                        new SecurityScheme()
                                .type(SecurityScheme.Type.HTTP)
                                .scheme("bearer")
                                .bearerFormat("JWT")));
    }
}
'@
Write-RepoFile 'backend/src/test/java/com/gara/quanlygara/service/VehicleServiceTest.java' @'
package com.gara.quanlygara.service;

import com.gara.quanlygara.dto.vehicle.VehicleRequest;
import com.gara.quanlygara.entity.Vehicle;
import com.gara.quanlygara.exception.BadRequestException;
import com.gara.quanlygara.exception.ConflictException;
import com.gara.quanlygara.exception.ResourceNotFoundException;
import com.gara.quanlygara.repository.CustomerRepository;
import com.gara.quanlygara.repository.VehicleRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;

import java.time.Year;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class VehicleServiceTest {

    @Mock
    private VehicleRepository vehicleRepository;

    @Mock
    private CustomerRepository customerRepository;

    private VehicleService vehicleService;

    @BeforeEach
    void setUp() {
        vehicleService = new VehicleService(vehicleRepository, customerRepository);
    }

    @Test
    void createNormalizesAndPersistsVehicle() {
        when(customerRepository.existsById(1)).thenReturn(true);
        when(vehicleRepository.existsByLicensePlate("51A-123.45")).thenReturn(false);
        when(vehicleRepository.saveAndFlush(any(Vehicle.class))).thenAnswer(invocation -> {
            Vehicle vehicle = invocation.getArgument(0);
            vehicle.setId(7);
            return vehicle;
        });

        var response = vehicleService.create(
                new VehicleRequest(1, "  51a-123.45 ", " Toyota ", "   ", (short) 2021, 1000));

        assertEquals(7, response.id());
        assertEquals(1, response.customerId());
        assertEquals("51A-123.45", response.licensePlate());
        assertEquals("Toyota", response.brand());
        assertNull(response.model());
        assertEquals((short) 2021, response.year());
        assertEquals(1000, response.mileage());
    }

    @Test
    void createRejectsDuplicateLicensePlate() {
        when(customerRepository.existsById(1)).thenReturn(true);
        when(vehicleRepository.existsByLicensePlate("51A-123.45")).thenReturn(true);

        assertThrows(ConflictException.class, () -> vehicleService.create(request(1, "51a-123.45")));
        verify(vehicleRepository, never()).saveAndFlush(any(Vehicle.class));
    }

    @Test
    void createRejectsMissingCustomer() {
        when(customerRepository.existsById(99)).thenReturn(false);

        assertThrows(ResourceNotFoundException.class, () -> vehicleService.create(request(99, "51A-123.45")));
        verify(vehicleRepository, never()).saveAndFlush(any(Vehicle.class));
    }

    @Test
    void createRejectsYearInTheFarFuture() {
        when(customerRepository.existsById(1)).thenReturn(true);
        short tooLate = (short) (Year.now().getValue() + 2);

        assertThrows(BadRequestException.class, () -> vehicleService.create(
                new VehicleRequest(1, "51A-123.45", "Toyota", "Vios", tooLate, 0)));
    }

    @Test
    void getByIdReturnsVehicle() {
        when(vehicleRepository.findById(3)).thenReturn(Optional.of(vehicle(3, 1, "59K-456.78")));

        var response = vehicleService.getById(3);

        assertEquals(3, response.id());
        assertEquals("59K-456.78", response.licensePlate());
    }

    @Test
    void getByIdRejectsMissingVehicle() {
        when(vehicleRepository.findById(404)).thenReturn(Optional.empty());

        assertThrows(ResourceNotFoundException.class, () -> vehicleService.getById(404));
    }

    @Test
    void getAllUsesPaginationAndSortsNewestFirst() {
        ArgumentCaptor<Pageable> captor = ArgumentCaptor.forClass(Pageable.class);
        when(vehicleRepository.findAll(captor.capture())).thenReturn(
                new PageImpl<>(List.of(vehicle(1, 1, "51A-123.45")), PageRequest.of(1, 5), 11));

        var response = vehicleService.getAll(1, 5, null);

        assertEquals(1, response.items().size());
        assertEquals(1, response.page());
        assertEquals(5, response.size());
        assertEquals(11, response.totalElements());
        assertEquals(3, response.totalPages());
        assertEquals(1, captor.getValue().getPageNumber());
        assertEquals(5, captor.getValue().getPageSize());
        assertEquals(Sort.Direction.DESC, captor.getValue().getSort().getOrderFor("id").getDirection());
    }

    @Test
    void getAllClampsPageAndSize() {
        ArgumentCaptor<Pageable> captor = ArgumentCaptor.forClass(Pageable.class);
        when(vehicleRepository.findAll(captor.capture())).thenReturn(new PageImpl<>(List.of()));

        vehicleService.getAll(-3, 1000, "   ");

        assertEquals(0, captor.getValue().getPageNumber());
        assertEquals(100, captor.getValue().getPageSize());
    }

    @Test
    void getAllSearchesByLicensePlate() {
        when(vehicleRepository.findByLicensePlateContainingIgnoreCase(eq("51A"), any(Pageable.class)))
                .thenReturn(new PageImpl<>(List.of(vehicle(1, 1, "51A-123.45"))));

        var response = vehicleService.getAll(0, 10, "  51A ");

        assertEquals(1, response.items().size());
        assertEquals("51A-123.45", response.items().get(0).licensePlate());
        verify(vehicleRepository, never()).findAll(any(Pageable.class));
    }

    @Test
    void getByCustomerReturnsEmptyListWhenCustomerHasNoVehicles() {
        when(customerRepository.existsById(2)).thenReturn(true);
        when(vehicleRepository.findByCustomerIdOrderByIdDesc(2)).thenReturn(List.of());

        assertTrue(vehicleService.getByCustomer(2).isEmpty());
    }

    @Test
    void getByCustomerReturnsOnlyThatCustomersVehicles() {
        when(customerRepository.existsById(1)).thenReturn(true);
        when(vehicleRepository.findByCustomerIdOrderByIdDesc(1)).thenReturn(
                List.of(vehicle(2, 1, "51A-222.22"), vehicle(1, 1, "51A-111.11")));

        var response = vehicleService.getByCustomer(1);

        assertEquals(2, response.size());
        assertEquals("51A-222.22", response.get(0).licensePlate());
    }

    @Test
    void getByCustomerRejectsMissingCustomer() {
        when(customerRepository.existsById(99)).thenReturn(false);

        assertThrows(ResourceNotFoundException.class, () -> vehicleService.getByCustomer(99));
    }

    @Test
    void updateKeepsVehicleIdentity() {
        Vehicle vehicle = vehicle(3, 1, "59K-456.78");
        when(vehicleRepository.findById(3)).thenReturn(Optional.of(vehicle));
        when(vehicleRepository.existsByLicensePlateAndIdNot("51A-999.99", 3)).thenReturn(false);
        when(vehicleRepository.saveAndFlush(vehicle)).thenReturn(vehicle);

        var response = vehicleService.update(3, request(1, "51a-999.99"));

        assertEquals(3, response.id());
        assertEquals("51A-999.99", response.licensePlate());
        assertEquals("Toyota", response.brand());
    }

    @Test
    void updateRejectsPlateOwnedByAnotherVehicle() {
        when(vehicleRepository.findById(3)).thenReturn(Optional.of(vehicle(3, 1, "59K-456.78")));
        when(vehicleRepository.existsByLicensePlateAndIdNot("51A-999.99", 3)).thenReturn(true);

        assertThrows(ConflictException.class, () -> vehicleService.update(3, request(1, "51A-999.99")));
        verify(vehicleRepository, never()).saveAndFlush(any(Vehicle.class));
    }

    @Test
    void updateChecksNewOwnerOnlyWhenCustomerChanges() {
        when(vehicleRepository.findById(3)).thenReturn(Optional.of(vehicle(3, 1, "59K-456.78")));
        when(customerRepository.existsById(2)).thenReturn(false);

        assertThrows(ResourceNotFoundException.class, () -> vehicleService.update(3, request(2, "59K-456.78")));
    }

    @Test
    void updateRejectsMissingVehicle() {
        when(vehicleRepository.findById(404)).thenReturn(Optional.empty());

        assertThrows(ResourceNotFoundException.class, () -> vehicleService.update(404, request(1, "51A-999.99")));
    }

    private VehicleRequest request(int customerId, String plate) {
        return new VehicleRequest(customerId, plate, "Toyota", "Vios", (short) 2021, 1000);
    }

    private Vehicle vehicle(int id, int customerId, String plate) {
        Vehicle vehicle = new Vehicle();
        vehicle.setId(id);
        vehicle.setCustomerId(customerId);
        vehicle.setLicensePlate(plate);
        vehicle.setBrand("Honda");
        vehicle.setModel("City");
        vehicle.setYear((short) 2020);
        vehicle.setMileage(62100);
        return vehicle;
    }
}
'@
Write-RepoFile 'backend/src/test/java/com/gara/quanlygara/dto/VehicleRequestValidationTest.java' @'
package com.gara.quanlygara.dto;

import com.gara.quanlygara.dto.vehicle.VehicleRequest;
import jakarta.validation.ConstraintViolation;
import jakarta.validation.Validation;
import jakarta.validation.Validator;
import org.junit.jupiter.api.Test;

import java.util.Set;
import java.util.stream.Collectors;

import static org.junit.jupiter.api.Assertions.assertTrue;

class VehicleRequestValidationTest {

    private final Validator validator = Validation.buildDefaultValidatorFactory().getValidator();

    @Test
    void validRequestHasNoViolations() {
        assertTrue(validator.validate(new VehicleRequest(1, "51A-123.45", "Toyota", "Vios", (short) 2021, 0)).isEmpty());
    }

    @Test
    void optionalFieldsMayBeNull() {
        assertTrue(validator.validate(new VehicleRequest(1, "51A-123.45", null, null, null, null)).isEmpty());
    }

    @Test
    void rejectsNegativeMileage() {
        assertTrue(fields(new VehicleRequest(1, "51A-123.45", null, null, null, -1)).contains("mileage"));
    }

    @Test
    void rejectsInvalidYear() {
        assertTrue(fields(new VehicleRequest(1, "51A-123.45", null, null, (short) 1500, null)).contains("year"));
        assertTrue(fields(new VehicleRequest(1, "51A-123.45", null, null, (short) 3000, null)).contains("year"));
    }

    @Test
    void rejectsBlankOrTooLongLicensePlate() {
        assertTrue(fields(new VehicleRequest(1, "   ", null, null, null, null)).contains("licensePlate"));
        assertTrue(fields(new VehicleRequest(1, "A".repeat(21), null, null, null, null)).contains("licensePlate"));
    }

    @Test
    void rejectsMissingOrNonPositiveCustomerId() {
        assertTrue(fields(new VehicleRequest(null, "51A-123.45", null, null, null, null)).contains("customerId"));
        assertTrue(fields(new VehicleRequest(0, "51A-123.45", null, null, null, null)).contains("customerId"));
    }

    private Set<String> fields(VehicleRequest request) {
        return validator.validate(request).stream()
                .map(ConstraintViolation::getPropertyPath)
                .map(Object::toString)
                .collect(Collectors.toSet());
    }
}
'@
Write-RepoFile 'backend/src/test/java/com/gara/quanlygara/controller/VehicleApiTest.java' @'
package com.gara.quanlygara.controller;

import com.gara.quanlygara.entity.Account;
import com.gara.quanlygara.entity.AccountRole;
import com.gara.quanlygara.entity.Vehicle;
import com.gara.quanlygara.repository.AccountRepository;
import com.gara.quanlygara.repository.CustomerRepository;
import com.gara.quanlygara.repository.EmployeeRepository;
import com.gara.quanlygara.repository.TechnicianRepository;
import com.gara.quanlygara.repository.VehicleRepository;
import com.gara.quanlygara.repository.GarageServiceRepository;
import com.gara.quanlygara.repository.RepairOrderRepository;
import com.gara.quanlygara.repository.TechnicianAssignmentRepository;
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
class VehicleApiTest {

    private static final String VEHICLE_JSON = """
            {"customerId":1,"licensePlate":"51a-999.99","brand":"Toyota","model":"Vios","year":2021,"mileage":1000}
            """;

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private AccountRepository accountRepository;

    @MockitoBean
    private CustomerRepository customerRepository;

    @MockitoBean
    private EmployeeRepository employeeRepository;

    @MockitoBean
    private TechnicianRepository technicianRepository;

    @MockitoBean
    private VehicleRepository vehicleRepository;

    @MockitoBean
        private GarageServiceRepository garageServiceRepository;

    @MockitoBean
        private RepairOrderRepository repairOrderRepository;

    @MockitoBean
        private TechnicianAssignmentRepository technicianAssignmentRepository;

    @Test
    void listRejectsRequestWithoutJwt() throws Exception {
        mockMvc.perform(get("/api/vehicles"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.success").value(false));
    }

    @Test
    @WithMockUser(roles = "WAREHOUSE")
    void warehouseCannotReadVehicles() throws Exception {
        mockMvc.perform(get("/api/vehicles"))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.success").value(false));
    }

    @Test
    @WithMockUser(roles = "RECEPTIONIST")
    void receptionistCanListVehiclesWithPagination() throws Exception {
        when(vehicleRepository.findAll(any(Pageable.class))).thenReturn(
                new PageImpl<>(List.of(vehicle(1, 1, "51A-123.45")), PageRequest.of(0, 10), 1));

        mockMvc.perform(get("/api/vehicles").param("page", "0").param("size", "10"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.items[0].licensePlate").value("51A-123.45"))
                .andExpect(jsonPath("$.data.totalElements").value(1))
                .andExpect(jsonPath("$.data.page").value(0));
    }

    @Test
    @WithMockUser(roles = "MANAGER")
    void searchFiltersByLicensePlate() throws Exception {
        when(vehicleRepository.findByLicensePlateContainingIgnoreCase(eq("59K"), any(Pageable.class)))
                .thenReturn(new PageImpl<>(List.of(vehicle(2, 2, "59K-456.78"))));

        mockMvc.perform(get("/api/vehicles").param("search", "59K"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.items[0].licensePlate").value("59K-456.78"));
    }

    @Test
    @WithMockUser(roles = "ADMIN")
    void getByIdReturnsVehicle() throws Exception {
        when(vehicleRepository.findById(2)).thenReturn(Optional.of(vehicle(2, 2, "59K-456.78")));

        mockMvc.perform(get("/api/vehicles/2"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.id").value(2))
                .andExpect(jsonPath("$.data.customerId").value(2));
    }

    @Test
    @WithMockUser(roles = "ADMIN")
    void getByIdReturns404WhenMissing() throws Exception {
        when(vehicleRepository.findById(404)).thenReturn(Optional.empty());
        mockMvc.perform(get("/api/vehicles/404"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.success").value(false));
    }

    @Test
    @WithMockUser(roles = "RECEPTIONIST")
    void createReturns201() throws Exception {
        when(customerRepository.existsById(1)).thenReturn(true);
        when(vehicleRepository.existsByLicensePlate("51A-999.99")).thenReturn(false);
        stubSave();

        mockMvc.perform(post("/api/vehicles").contentType(APPLICATION_JSON).content(VEHICLE_JSON))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.id").value(5))
                .andExpect(jsonPath("$.data.licensePlate").value("51A-999.99"));
    }

    @Test
    @WithMockUser(roles = "RECEPTIONIST")
    void createReturns409ForDuplicateLicensePlate() throws Exception {
        when(customerRepository.existsById(1)).thenReturn(true);
        when(vehicleRepository.existsByLicensePlate("51A-999.99")).thenReturn(true);

        mockMvc.perform(post("/api/vehicles").contentType(APPLICATION_JSON).content(VEHICLE_JSON))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.success").value(false));
    }

    @Test
    @WithMockUser(roles = "RECEPTIONIST")
    void createReturns404ForUnknownCustomer() throws Exception {
        when(customerRepository.existsById(1)).thenReturn(false);

        mockMvc.perform(post("/api/vehicles").contentType(APPLICATION_JSON).content(VEHICLE_JSON))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.success").value(false));
    }

    @Test
    @WithMockUser(roles = "RECEPTIONIST")
    void createReturns400ForInvalidBody() throws Exception {
        mockMvc.perform(post("/api/vehicles").contentType(APPLICATION_JSON)
                        .content("{\"customerId\":1,\"licensePlate\":\"  \",\"mileage\":-5}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.data.licensePlate").exists())
                .andExpect(jsonPath("$.data.mileage").exists());
    }

    @Test
    @WithMockUser(roles = "RECEPTIONIST")
    void createReturns400ForMalformedYear() throws Exception {
        mockMvc.perform(post("/api/vehicles").contentType(APPLICATION_JSON)
                        .content("{\"customerId\":1,\"licensePlate\":\"51A-1\",\"year\":\"abc\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false));
    }

    @Test
    @WithMockUser(roles = "RECEPTIONIST")
    void updateReturns200() throws Exception {
        when(vehicleRepository.findById(3)).thenReturn(Optional.of(vehicle(3, 1, "59K-456.78")));
        when(vehicleRepository.existsByLicensePlateAndIdNot("51A-999.99", 3)).thenReturn(false);
        stubSave();

        mockMvc.perform(put("/api/vehicles/3").contentType(APPLICATION_JSON).content(VEHICLE_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.id").value(3))
                .andExpect(jsonPath("$.data.licensePlate").value("51A-999.99"));
    }

    @Test
    @WithMockUser(roles = "RECEPTIONIST")
    void updateReturns409ForPlateOfAnotherVehicle() throws Exception {
        when(vehicleRepository.findById(3)).thenReturn(Optional.of(vehicle(3, 1, "59K-456.78")));
        when(vehicleRepository.existsByLicensePlateAndIdNot("51A-999.99", 3)).thenReturn(true);

        mockMvc.perform(put("/api/vehicles/3").contentType(APPLICATION_JSON).content(VEHICLE_JSON))
                .andExpect(status().isConflict());
    }

    @Test
    @WithMockUser(roles = "MANAGER")
    void staffCanReadVehiclesOfACustomer() throws Exception {
        when(customerRepository.existsById(1)).thenReturn(true);
        when(vehicleRepository.findByCustomerIdOrderByIdDesc(1)).thenReturn(List.of(vehicle(1, 1, "51A-123.45")));

        mockMvc.perform(get("/api/customers/1/vehicles"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[0].licensePlate").value("51A-123.45"));
    }

    @Test
    @WithMockUser(roles = "MANAGER")
    void customerWithoutVehiclesGetsEmptyList() throws Exception {
        when(customerRepository.existsById(2)).thenReturn(true);
        when(vehicleRepository.findByCustomerIdOrderByIdDesc(2)).thenReturn(List.of());

        mockMvc.perform(get("/api/customers/2/vehicles"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data").isEmpty());
    }

    @Test
    @WithMockUser(roles = "MANAGER")
    void customerVehiclesReturns404ForUnknownCustomer() throws Exception {
        when(customerRepository.existsById(99)).thenReturn(false);

        mockMvc.perform(get("/api/customers/99/vehicles"))
                .andExpect(status().isNotFound());
    }

    @Test
    @WithMockUser(username = "khach", roles = "CUSTOMER")
    void customerCanReadOwnVehicles() throws Exception {
        when(accountRepository.findByUsername("khach")).thenReturn(Optional.of(account(4)));
        when(customerRepository.existsById(4)).thenReturn(true);
        when(vehicleRepository.findByCustomerIdOrderByIdDesc(4)).thenReturn(List.of(vehicle(9, 4, "51K-789.01")));

        mockMvc.perform(get("/api/customers/4/vehicles"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[0].licensePlate").value("51K-789.01"));
    }

    @Test
    @WithMockUser(username = "khach", roles = "CUSTOMER")
    void customerCannotReadVehiclesOfAnotherCustomer() throws Exception {
        when(accountRepository.findByUsername("khach")).thenReturn(Optional.of(account(4)));

        mockMvc.perform(get("/api/customers/5/vehicles"))
                .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(username = "khach", roles = "CUSTOMER")
    void customerCanAddVehicleForThemselves() throws Exception {
        when(accountRepository.findByUsername("khach")).thenReturn(Optional.of(account(1)));
        when(customerRepository.existsById(1)).thenReturn(true);
        when(vehicleRepository.existsByLicensePlate("51A-999.99")).thenReturn(false);
        stubSave();

        mockMvc.perform(post("/api/vehicles").contentType(APPLICATION_JSON).content(VEHICLE_JSON))
                .andExpect(status().isCreated());
    }

    @Test
    @WithMockUser(username = "khach", roles = "CUSTOMER")
    void customerCannotAddVehicleForSomeoneElse() throws Exception {
        when(accountRepository.findByUsername("khach")).thenReturn(Optional.of(account(4)));

        mockMvc.perform(post("/api/vehicles").contentType(APPLICATION_JSON).content(VEHICLE_JSON))
                .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(username = "khach", roles = "CUSTOMER")
    void customerCannotListOrUpdateVehicles() throws Exception {
        mockMvc.perform(get("/api/vehicles")).andExpect(status().isForbidden());
        mockMvc.perform(put("/api/vehicles/3").contentType(APPLICATION_JSON).content(VEHICLE_JSON))
                .andExpect(status().isForbidden());
    }

    @Test
    void swaggerDocumentationListsVehicleApi() throws Exception {
        mockMvc.perform(get("/v3/api-docs"))
                .andExpect(status().isOk())
                .andExpect(content().string(containsString("/api/vehicles")));
    }

    private void stubSave() {
        when(vehicleRepository.saveAndFlush(any(Vehicle.class))).thenAnswer(invocation -> {
            Vehicle vehicle = invocation.getArgument(0);
            if (vehicle.getId() == null) vehicle.setId(5);
            return vehicle;
        });
    }

    private Vehicle vehicle(int id, int customerId, String plate) {
        Vehicle vehicle = new Vehicle();
        vehicle.setId(id);
        vehicle.setCustomerId(customerId);
        vehicle.setLicensePlate(plate);
        vehicle.setBrand("Honda");
        vehicle.setModel("City");
        vehicle.setYear((short) 2020);
        vehicle.setMileage(62100);
        return vehicle;
    }

    private Account account(int customerId) {
        Account account = new Account();
        account.setId(1);
        account.setUsername("khach");
        account.setPasswordHash("hash");
        account.setRole(AccountRole.CUSTOMER);
        account.setActive(true);
        account.setCustomerId(customerId);
        return account;
    }
}
'@
Write-RepoFile 'backend/database/Test_Vehicles.sql' @'
-- ============================================================
-- Test_Vehicles.sql - kiem tra rang buoc bang Xe (Tuan 6 - TV3)
-- Chay trong SSMS sau khi da tao database bang QuanLyGaraOTo.sql.
-- Toan bo du lieu test nam trong mot transaction va duoc ROLLBACK cuoi script.
-- ============================================================
USE QuanLyGaraOTo;
GO

SET NOCOUNT ON;
SET XACT_ABORT OFF;

DECLARE @Result TABLE (
    Id       INT IDENTITY(1,1),
    TestName NVARCHAR(200),
    Expected NVARCHAR(20),
    Detail   NVARCHAR(400),
    Result   NVARCHAR(4)
);

DECLARE @c1 INT, @c2 INT, @n INT;

SELECT TOP 1 @c1 = MaKhachHang FROM KhachHang ORDER BY MaKhachHang;
SELECT TOP 1 @c2 = MaKhachHang FROM KhachHang WHERE MaKhachHang <> @c1 ORDER BY MaKhachHang;

IF @c1 IS NULL
BEGIN
    PRINT N'Khong co khach hang nao trong bang KhachHang. Hay chay QuanLyGaraOTo.sql truoc.';
    RETURN;
END;

BEGIN TRAN;

-- T1: insert xe hop le -> thanh cong
BEGIN TRY
    INSERT INTO Xe (MaKhachHang, BienSo, HangXe, DongXe, NamSanXuat, SoKm)
    VALUES (@c1, 'TEST-VEH-001', N'Toyota', N'Vios', 2021, 1000);
    INSERT INTO @Result VALUES (N'T1 insert xe hop le', 'SUCCESS', N'Insert thanh cong', 'PASS');
END TRY
BEGIN CATCH
    INSERT INTO @Result VALUES (N'T1 insert xe hop le', 'SUCCESS', ERROR_MESSAGE(), 'FAIL');
END CATCH;

-- T2: trung BienSo -> phai loi UNIQUE (2627/2601)
BEGIN TRY
    INSERT INTO Xe (MaKhachHang, BienSo, HangXe, DongXe, NamSanXuat, SoKm)
    VALUES (@c1, 'TEST-VEH-001', N'Honda', N'City', 2020, 500);
    INSERT INTO @Result VALUES (N'T2 trung BienSo', 'FAIL', N'Insert trung bien so van thanh cong', 'FAIL');
END TRY
BEGIN CATCH
    INSERT INTO @Result VALUES (N'T2 trung BienSo', 'FAIL', ERROR_MESSAGE(),
        CASE WHEN ERROR_NUMBER() IN (2627, 2601) THEN 'PASS' ELSE 'FAIL' END);
END CATCH;

-- T3: MaKhachHang khong ton tai -> phai loi FK (547)
BEGIN TRY
    INSERT INTO Xe (MaKhachHang, BienSo, HangXe, DongXe, NamSanXuat, SoKm)
    VALUES (-1, 'TEST-VEH-003', N'Kia', N'Seltos', 2023, 100);
    INSERT INTO @Result VALUES (N'T3 khach hang khong ton tai', 'FAIL', N'Insert xe voi khach khong ton tai van thanh cong', 'FAIL');
END TRY
BEGIN CATCH
    INSERT INTO @Result VALUES (N'T3 khach hang khong ton tai', 'FAIL', ERROR_MESSAGE(),
        CASE WHEN ERROR_NUMBER() = 547 AND ERROR_MESSAGE() LIKE '%FK_Xe_KhachHang%' THEN 'PASS' ELSE 'FAIL' END);
END CATCH;

-- T4: SoKm am -> phai loi CHECK CK_Xe_SoKm (547)
BEGIN TRY
    INSERT INTO Xe (MaKhachHang, BienSo, HangXe, DongXe, NamSanXuat, SoKm)
    VALUES (@c1, 'TEST-VEH-004', N'Mazda', N'Mazda 3', 2022, -1);
    INSERT INTO @Result VALUES (N'T4 SoKm am', 'FAIL', N'Insert SoKm am van thanh cong', 'FAIL');
END TRY
BEGIN CATCH
    INSERT INTO @Result VALUES (N'T4 SoKm am', 'FAIL', ERROR_MESSAGE(),
        CASE WHEN ERROR_NUMBER() = 547 AND ERROR_MESSAGE() LIKE '%CK_Xe_SoKm%' THEN 'PASS' ELSE 'FAIL' END);
END CATCH;

-- T5: nhieu xe cung mot khach hang, khac bien so -> hop le
BEGIN TRY
    INSERT INTO Xe (MaKhachHang, BienSo, HangXe, DongXe, NamSanXuat, SoKm)
    VALUES (@c1, 'TEST-VEH-005A', N'Toyota', N'Camry', 2019, 20000),
           (@c1, 'TEST-VEH-005B', N'Toyota', N'Fortuner', 2018, 30000);
    SELECT @n = COUNT(*) FROM Xe WHERE MaKhachHang = @c1 AND BienSo LIKE 'TEST-VEH-005%';
    INSERT INTO @Result VALUES (N'T5 nhieu xe cung khach hang', 'SUCCESS', N'So xe test: ' + CAST(@n AS NVARCHAR(10)),
        CASE WHEN @n = 2 THEN 'PASS' ELSE 'FAIL' END);
END TRY
BEGIN CATCH
    INSERT INTO @Result VALUES (N'T5 nhieu xe cung khach hang', 'SUCCESS', ERROR_MESSAGE(), 'FAIL');
END CATCH;

-- T5b: hai khach hang khac nhau van khong duoc dung chung bien so
IF @c2 IS NOT NULL
BEGIN
    BEGIN TRY
        INSERT INTO Xe (MaKhachHang, BienSo, HangXe, DongXe, NamSanXuat, SoKm)
        VALUES (@c2, 'TEST-VEH-005A', N'Honda', N'Civic', 2020, 1000);
        INSERT INTO @Result VALUES (N'T5b trung bien so khac khach hang', 'FAIL', N'Insert van thanh cong', 'FAIL');
    END TRY
    BEGIN CATCH
        INSERT INTO @Result VALUES (N'T5b trung bien so khac khach hang', 'FAIL', ERROR_MESSAGE(),
            CASE WHEN ERROR_NUMBER() IN (2627, 2601) THEN 'PASS' ELSE 'FAIL' END);
    END CATCH;
END;

-- T6: cac gia tri NamSanXuat hop le (NULL, 1886, 1990, nam hien tai, nam sau)
BEGIN TRY
    INSERT INTO Xe (MaKhachHang, BienSo, HangXe, DongXe, NamSanXuat, SoKm)
    VALUES (@c1, 'TEST-VEH-Y0', N'Test', N'Nam NULL', NULL, NULL),
           (@c1, 'TEST-VEH-Y1', N'Test', N'Nam 1886', 1886, 0),
           (@c1, 'TEST-VEH-Y2', N'Test', N'Nam 1990', 1990, 0),
           (@c1, 'TEST-VEH-Y3', N'Test', N'Nam hien tai', YEAR(GETDATE()), 0),
           (@c1, 'TEST-VEH-Y4', N'Test', N'Nam sau', YEAR(GETDATE()) + 1, 0);
    SELECT @n = COUNT(*) FROM Xe WHERE BienSo LIKE 'TEST-VEH-Y_';
    INSERT INTO @Result VALUES (N'T6 NamSanXuat hop le', 'SUCCESS', N'So xe test: ' + CAST(@n AS NVARCHAR(10)),
        CASE WHEN @n = 5 THEN 'PASS' ELSE 'FAIL' END);
END TRY
BEGIN CATCH
    INSERT INTO @Result VALUES (N'T6 NamSanXuat hop le', 'SUCCESS', ERROR_MESSAGE(), 'FAIL');
END CATCH;

-- T6b: NamSanXuat vuot SMALLINT -> phai loi tran so (220/8115)
BEGIN TRY
    INSERT INTO Xe (MaKhachHang, BienSo, HangXe, DongXe, NamSanXuat, SoKm)
    VALUES (@c1, 'TEST-VEH-Y9', N'Test', N'Nam tran so', 40000, 0);
    INSERT INTO @Result VALUES (N'T6b NamSanXuat vuot SMALLINT', 'FAIL', N'Insert van thanh cong', 'FAIL');
END TRY
BEGIN CATCH
    INSERT INTO @Result VALUES (N'T6b NamSanXuat vuot SMALLINT', 'FAIL', ERROR_MESSAGE(),
        CASE WHEN ERROR_NUMBER() IN (220, 8115) THEN 'PASS' ELSE 'FAIL' END);
END CATCH;

SELECT Id, TestName, Expected, Result, Detail FROM @Result ORDER BY Id;

SELECT @n = COUNT(*) FROM @Result WHERE Result = 'FAIL';
IF @n = 0
    PRINT N'TAT CA TEST VEHICLE DEU PASS.';
ELSE
    PRINT N'CO ' + CAST(@n AS NVARCHAR(10)) + N' TEST FAIL. Xem bang ket qua o tren.';

-- Khong de lai du lieu test trong database.
ROLLBACK TRAN;
GO
'@
Write-RepoFile 'frontend/src/api/vehicles.ts' @'
import axios from "axios";
import { api, errorMessage, unwrap } from "./client";
import type { ApiResponse } from "./types";

export interface Vehicle {
  id: number;
  customerId: number;
  licensePlate: string;
  brand: string | null;
  model: string | null;
  year: number | null;
  mileage: number | null;
}

export interface VehiclePayload {
  customerId: number;
  licensePlate: string;
  brand: string | null;
  model: string | null;
  year: number | null;
  mileage: number | null;
}

export interface VehiclePage {
  items: Vehicle[];
  /** Bắt đầu từ 0, giống Spring Data. */
  page: number;
  size: number;
  totalElements: number;
  totalPages: number;
}

export interface VehicleListParams {
  page?: number;
  size?: number;
  search?: string;
}

/** Giá trị nhập từ form xe (dùng chung cho nhân viên và khách hàng). */
export interface VehicleFormValue {
  customerId?: number | null;
  plate: string;
  brand: string;
  model: string;
  year: number | null;
  mileage: number | null;
}

export function toVehiclePayload(customerId: number, value: VehicleFormValue): VehiclePayload {
  return {
    customerId,
    licensePlate: value.plate.trim(),
    brand: value.brand.trim() || null,
    model: value.model.trim() || null,
    year: value.year,
    mileage: value.mileage,
  };
}

export const vehiclesApi = {
  async list(params: VehicleListParams = {}): Promise<VehiclePage> {
    return unwrap(await api.get<ApiResponse<VehiclePage>>("/api/vehicles", { params }));
  },

  async getById(id: number): Promise<Vehicle> {
    return unwrap(await api.get<ApiResponse<Vehicle>>(`/api/vehicles/${id}`));
  },

  async create(payload: VehiclePayload): Promise<Vehicle> {
    return unwrap(await api.post<ApiResponse<Vehicle>>("/api/vehicles", payload));
  },

  async update(id: number, payload: VehiclePayload): Promise<Vehicle> {
    return unwrap(await api.put<ApiResponse<Vehicle>>(`/api/vehicles/${id}`, payload));
  },

  async listByCustomer(customerId: number): Promise<Vehicle[]> {
    return unwrap(await api.get<ApiResponse<Vehicle[]>>(`/api/customers/${customerId}/vehicles`));
  },
};

/**
 * Lỗi 400 của backend trả message chung "Dữ liệu không hợp lệ." kèm map lỗi theo field
 * trong data; ưu tiên hiển thị lỗi field đầu tiên. Các lỗi khác (404/409...) dùng message của API.
 */
export function vehicleErrorMessage(error: unknown, fallback: string): string {
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
Write-RepoFile 'frontend/src/features/vehicles/VehicleForm.tsx' @'
import { FormEvent, useState } from "react"
import { Button, Input, Select } from "../../components/ui"
import type { VehicleFormValue } from "../../api/vehicles"

export interface CustomerOption {
  value: number
  label: string
}

interface VehicleFormProps {
  onSubmit: (value: VehicleFormValue) => void | Promise<void>
  onCancel: () => void
  initialValue?: VehicleFormValue
  /** Khi có danh sách khách hàng, form hiển thị ô chọn chủ xe (dùng cho nhân viên). */
  customerOptions?: CustomerOption[]
  lockCustomer?: boolean
  submitLabel?: string
  savingLabel?: string
}

export default function VehicleForm({
  onSubmit,
  onCancel,
  initialValue,
  customerOptions,
  lockCustomer = false,
  submitLabel = "Thêm xe",
  savingLabel = "Đang lưu...",
}: VehicleFormProps) {
  const [customerId, setCustomerId] = useState(initialValue?.customerId?.toString() ?? "")
  const [plate, setPlate] = useState(initialValue?.plate ?? "")
  const [brand, setBrand] = useState(initialValue?.brand ?? "")
  const [model, setModel] = useState(initialValue?.model ?? "")
  const [year, setYear] = useState(initialValue?.year?.toString() ?? "")
  const [mileage, setMileage] = useState(initialValue?.mileage?.toString() ?? "")
  const [error, setError] = useState("")
  const [saving, setSaving] = useState(false)

  const handleSubmit = async (event: FormEvent) => {
    event.preventDefault()
    setError("")
    const normalizedPlate = plate.trim()
    const parsedYear = year ? Number(year) : null
    const parsedMileage = mileage ? Number(mileage) : null
    const maxYear = new Date().getFullYear() + 1

    if (customerOptions && !customerId) {
      setError("Vui lòng chọn chủ xe.")
      return
    }
    if (!normalizedPlate) {
      setError("Vui lòng nhập biển số xe.")
      return
    }
    if (
      parsedYear !== null &&
      (!Number.isInteger(parsedYear) ||
        parsedYear < 1886 ||
        parsedYear > maxYear)
    ) {
      setError(`Năm sản xuất phải từ 1886 đến ${maxYear}.`)
      return
    }
    if (
      parsedMileage !== null &&
      (!Number.isInteger(parsedMileage) || parsedMileage < 0)
    ) {
      setError("Số km phải là số nguyên không âm.")
      return
    }

    setSaving(true)
    try {
      await onSubmit({
        customerId: customerId ? Number(customerId) : null,
        plate: normalizedPlate,
        brand,
        model,
        year: parsedYear,
        mileage: parsedMileage,
      })
    } catch (submitError) {
      setError(
        submitError instanceof Error
          ? submitError.message
          : "Không thể lưu xe. Vui lòng thử lại.",
      )
    } finally {
      setSaving(false)
    }
  }

  return (
    <form className="space-y-4" onSubmit={handleSubmit}>
      {customerOptions && (
        <Select
          label="Chủ xe *"
          value={customerId}
          onChange={(event) => setCustomerId(event.target.value)}
          disabled={lockCustomer}
          helperText={lockCustomer ? "Không thể đổi chủ xe vì xe có thể đã gắn với lịch hẹn và phiếu tiếp nhận." : undefined}
          options={[
            { value: "", label: "— Chọn khách hàng —" },
            ...customerOptions.map((option) => ({ value: String(option.value), label: option.label })),
          ]}
        />
      )}
      <Input
        label="Biển số xe *"
        value={plate}
        onChange={(event) => setPlate(event.target.value)}
        placeholder="51A-123.45"
        maxLength={20}
        autoFocus
        required
      />
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <Input
          label="Hãng xe"
          value={brand}
          onChange={(event) => setBrand(event.target.value)}
          placeholder="Toyota"
          maxLength={100}
        />
        <Input
          label="Dòng xe"
          value={model}
          onChange={(event) => setModel(event.target.value)}
          placeholder="Vios"
          maxLength={100}
        />
        <Input
          label="Năm sản xuất"
          type="number"
          inputMode="numeric"
          value={year}
          onChange={(event) => setYear(event.target.value)}
          min={1886}
          max={new Date().getFullYear() + 1}
        />
        <Input
          label="Số km"
          type="number"
          inputMode="numeric"
          value={mileage}
          onChange={(event) => setMileage(event.target.value)}
          min={0}
        />
      </div>
      <p className="text-xs leading-5 text-muted-foreground">
        Hãng xe, dòng xe, năm sản xuất và số km có thể cập nhật sau.
      </p>
      {error && (
        <p
          className="rounded-md bg-danger-soft px-3 py-2 text-sm text-danger"
          role="alert"
        >
          {error}
        </p>
      )}
      <div className="flex flex-col-reverse gap-2 pt-2 sm:flex-row sm:justify-end">
        <Button
          type="button"
          variant="outline"
          onClick={onCancel}
          disabled={saving}
        >
          Hủy
        </Button>
        <Button type="submit" disabled={saving}>
          {saving ? savingLabel : submitLabel}
        </Button>
      </div>
    </form>
  )
}
'@
Write-RepoFile 'frontend/src/features/vehicles/AddVehicleModal.tsx' @'
import { Modal } from "../../components/ui"
import type { Vehicle, VehicleFormValue } from "../../api/vehicles"
import VehicleForm from "./VehicleForm"

interface AddVehicleModalProps {
  open: boolean
  onClose: () => void
  onSubmit: (value: VehicleFormValue) => Promise<Vehicle>
  onCreated: (vehicle: Vehicle) => void
}

export default function AddVehicleModal({
  open,
  onClose,
  onSubmit,
  onCreated,
}: AddVehicleModalProps) {
  const handleSubmit = async (value: VehicleFormValue) => {
    // Nếu API lỗi, onSubmit ném Error và VehicleForm hiển thị message; modal vẫn mở.
    const vehicle = await onSubmit(value)
    onCreated(vehicle)
    onClose()
  }

  return (
    <Modal open={open} onClose={onClose} title="Thêm xe mới" width="max-w-xl">
      {open && (
        <VehicleForm
          onSubmit={handleSubmit}
          onCancel={onClose}
          submitLabel="Thêm xe"
          savingLabel="Đang thêm..."
        />
      )}
    </Modal>
  )
}
'@
Write-RepoFile 'frontend/src/features/vehicles/VehicleCard.tsx' @'
import { Icons } from "../../components/ui"
import type { Vehicle } from "../../api/vehicles"

export default function VehicleCard({ vehicle }: { vehicle: Vehicle }) {
  const description =
    [vehicle.brand, vehicle.model].filter(Boolean).join(" ") ||
    "Chưa cập nhật hãng và dòng xe"

  return (
    <article className="rounded-lg border border-border bg-surface p-4 card-shadow sm:p-5">
      <div className="flex items-start gap-3">
        <span
          className="flex h-11 w-11 flex-shrink-0 items-center justify-center rounded-md bg-primary-soft text-primary"
          aria-hidden="true"
        >
          {Icons.car}
        </span>
        <div className="min-w-0 flex-1">
          <p className="mono text-lg font-bold text-primary">
            {vehicle.licensePlate}
          </p>
          <p className="mt-1 text-sm font-medium text-foreground">
            {description}
          </p>
        </div>
      </div>
      <dl className="mt-4 grid grid-cols-2 gap-3 border-t border-border pt-4 text-sm">
        <div>
          <dt className="text-xs text-muted-foreground">Năm sản xuất</dt>
          <dd className="mt-1 font-semibold text-foreground">
            {vehicle.year ?? "Chưa cập nhật"}
          </dd>
        </div>
        <div>
          <dt className="text-xs text-muted-foreground">Số km</dt>
          <dd className="mono mt-1 font-semibold text-foreground">
            {vehicle.mileage === null
              ? "Chưa cập nhật"
              : `${vehicle.mileage.toLocaleString("vi-VN")} km`}
          </dd>
        </div>
      </dl>
    </article>
  )
}
'@
Write-RepoFile 'frontend/src/features/vehicles/customerVehicleRepository.ts' @'
import { useCallback, useEffect, useState } from "react"
import {
  toVehiclePayload,
  vehicleErrorMessage,
  vehiclesApi,
  type Vehicle,
  type VehicleFormValue,
} from "../../api/vehicles"

export type { VehicleFormValue }

// Mã hiển thị kiểu KH001, vẫn được CustomerPortal dùng cho các màn hình còn dữ liệu mẫu.
export function toCustomerKey(customerId: number) {
  return `KH${String(customerId).padStart(3, "0")}`
}

/** Xe của khách hàng đang đăng nhập, lấy từ backend (bảng Xe trong SQL Server). */
export function useCustomerVehicles(customerId: number) {
  const [vehicles, setVehicles] = useState<Vehicle[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState("")

  const reload = useCallback(async () => {
    if (!customerId) {
      setVehicles([])
      setLoading(false)
      return
    }
    setLoading(true)
    setError("")
    try {
      setVehicles(await vehiclesApi.listByCustomer(customerId))
    } catch (loadError) {
      setError(vehicleErrorMessage(loadError, "Không thể tải danh sách xe."))
    } finally {
      setLoading(false)
    }
  }, [customerId])

  useEffect(() => {
    void reload()
  }, [reload])

  const addVehicle = useCallback(
    async (value: VehicleFormValue): Promise<Vehicle> => {
      if (!customerId) {
        throw new Error("Tài khoản chưa liên kết với khách hàng nên không thể thêm xe.")
      }
      try {
        const created = await vehiclesApi.create(toVehiclePayload(customerId, value))
        setVehicles((current) => [created, ...current])
        return created
      } catch (saveError) {
        throw new Error(vehicleErrorMessage(saveError, "Không thể thêm xe. Vui lòng thử lại."))
      }
    },
    [customerId],
  )

  return { vehicles, loading, error, reload, addVehicle }
}
'@
Write-RepoFile 'frontend/src/pages/customer/CustomerVehicles.tsx' @'
import { useState } from "react"
import { Button, Card, Icons } from "../../components/ui"
import AddVehicleModal from "../../features/vehicles/AddVehicleModal"
import VehicleCard from "../../features/vehicles/VehicleCard"
import { useCustomerVehicles } from "../../features/vehicles/customerVehicleRepository"

export default function CustomerVehicles({
  customerId,
}: {
  customerId: number
}) {
  const { vehicles, loading, error, reload, addVehicle } =
    useCustomerVehicles(customerId)
  const [showAdd, setShowAdd] = useState(false)
  const [success, setSuccess] = useState("")

  return (
    <div className="space-y-6">
      <div className="page-toolbar">
        <div>
          <h1 className="ui-section-title text-left">Xe của tôi</h1>
          <p className="ui-secondary-text mt-1 text-sm">
            Quản lý thông tin các xe của bạn.
          </p>
        </div>
        <Button icon={Icons.plus} onClick={() => setShowAdd(true)}>
          Thêm xe
        </Button>
      </div>

      {success && (
        <p
          className="rounded-md bg-success-soft px-4 py-3 text-sm text-success"
          role="status"
        >
          {success}
        </p>
      )}

      {error && (
        <div
          className="flex flex-col gap-3 rounded-md bg-danger-soft px-4 py-3 text-sm text-danger sm:flex-row sm:items-center sm:justify-between"
          role="alert"
        >
          <span>{error}</span>
          <Button size="sm" variant="outline" onClick={() => void reload()}>
            Thử lại
          </Button>
        </div>
      )}

      {loading ? (
        <Card className="p-6 text-center text-sm text-muted-foreground">
          Đang tải danh sách xe...
        </Card>
      ) : vehicles.length === 0 && !error ? (
        <Card className="flex min-h-72 items-center justify-center p-6 text-center">
          <div className="max-w-sm">
            <span
              className="mx-auto flex h-14 w-14 items-center justify-center rounded-full bg-primary-soft text-primary"
              aria-hidden="true"
            >
              {Icons.car}
            </span>
            <h2 className="mt-4 text-lg font-bold text-foreground">
              Bạn chưa có xe nào
            </h2>
            <p className="mt-2 text-sm leading-6 text-muted-foreground">
              Thêm thông tin xe để sử dụng khi đặt lịch sửa chữa hoặc bảo dưỡng.
            </p>
            <Button
              className="mt-5"
              icon={Icons.plus}
              onClick={() => setShowAdd(true)}
            >
              Thêm xe
            </Button>
          </div>
        </Card>
      ) : (
        <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
          {vehicles.map((vehicle) => (
            <VehicleCard key={vehicle.id} vehicle={vehicle} />
          ))}
        </div>
      )}

      <AddVehicleModal
        open={showAdd}
        onClose={() => setShowAdd(false)}
        onSubmit={addVehicle}
        onCreated={() => setSuccess("Đã thêm xe.")}
      />
    </div>
  )
}
'@
Write-RepoFile 'frontend/src/pages/Vehicles.tsx' @'
import { useEffect, useMemo, useState } from "react";
import { customersApi, type Customer } from "../api/customers";
import { errorMessage } from "../api/client";
import {
  toVehiclePayload,
  vehicleErrorMessage,
  vehiclesApi,
  type Vehicle,
  type VehicleFormValue,
} from "../api/vehicles";
import { Button, Card, Icons, Modal, Pagination, SearchBox, TableContainer } from "../components/ui";
import VehicleForm from "../features/vehicles/VehicleForm";

const PER_PAGE = 10;

const customerCode = (customerId: number) => `KH${String(customerId).padStart(3, "0")}`;

export default function Vehicles() {
  const [vehicles, setVehicles] = useState<Vehicle[]>([]);
  const [totalElements, setTotalElements] = useState(0);
  const [customers, setCustomers] = useState<Customer[]>([]);
  const [search, setSearch] = useState("");
  const [query, setQuery] = useState("");
  const [page, setPage] = useState(1);
  const [refreshKey, setRefreshKey] = useState(0);
  const [selected, setSelected] = useState<Vehicle | null>(null);
  const [editing, setEditing] = useState<Vehicle | null>(null);
  const [showForm, setShowForm] = useState(false);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [customerError, setCustomerError] = useState("");
  const [success, setSuccess] = useState("");

  // Tìm kiếm theo biển số gửi lên backend sau 300ms ngừng gõ.
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
    vehiclesApi
      .list({ page: page - 1, size: PER_PAGE, search: query || undefined })
      .then((result) => {
        if (cancelled) return;
        setVehicles(result.items);
        setTotalElements(result.totalElements);
      })
      .catch((loadError) => {
        if (!cancelled) setError(vehicleErrorMessage(loadError, "Không thể tải danh sách xe."));
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
    customersApi
      .list()
      .then((result) => {
        if (!cancelled) setCustomers(result);
      })
      .catch((loadError) => {
        if (!cancelled) setCustomerError(errorMessage(loadError, "Không thể tải danh sách khách hàng."));
      });
    return () => {
      cancelled = true;
    };
  }, []);

  const customerName = (customerId: number) =>
    customers.find((customer) => customer.id === customerId)?.fullName ?? customerCode(customerId);

  const customerOptions = useMemo(
    () =>
      customers
        .filter((customer) => customer.active || customer.id === editing?.customerId)
        .map((customer) => ({ value: customer.id, label: `${customer.fullName} – ${customer.phone}` })),
    [customers, editing],
  );

  const openCreate = () => {
    setEditing(null);
    setSuccess("");
    setShowForm(true);
  };

  const openEdit = (vehicle: Vehicle) => {
    setEditing(vehicle);
    setSuccess("");
    setShowForm(true);
  };

  const openDetail = (vehicle: Vehicle) => {
    setSelected(vehicle);
    vehiclesApi
      .getById(vehicle.id)
      .then((fresh) => setSelected((current) => (current?.id === fresh.id ? fresh : current)))
      .catch((detailError) => setError(vehicleErrorMessage(detailError, "Không thể tải thông tin xe.")));
  };

  const toggleDetail = (vehicle: Vehicle) => {
    if (selected?.id === vehicle.id) setSelected(null);
    else openDetail(vehicle);
  };

  const handleSubmit = async (value: VehicleFormValue) => {
    if (value.customerId == null) throw new Error("Vui lòng chọn chủ xe.");
    const payload = toVehiclePayload(value.customerId, value);
    try {
      const saved = editing
        ? await vehiclesApi.update(editing.id, payload)
        : await vehiclesApi.create(payload);
      setShowForm(false);
      setSuccess(editing ? "Đã cập nhật thông tin xe." : "Đã thêm xe mới.");
      setSelected(saved);
      if (!editing) {
        setSearch("");
        setQuery("");
        setPage(1);
      }
      setRefreshKey((key) => key + 1);
    } catch (saveError) {
      throw new Error(vehicleErrorMessage(saveError, "Không thể lưu thông tin xe."));
    }
  };

  return (
    <div className="space-y-6">
      <div className="page-toolbar">
        <SearchBox value={search} onChange={setSearch} placeholder="Tìm theo biển số..." />
        <div className="flex flex-wrap gap-2">
          <Button variant="outline" onClick={() => setRefreshKey((key) => key + 1)} disabled={loading}>Tải lại</Button>
          <Button icon={Icons.plus} onClick={openCreate}>Thêm xe</Button>
        </div>
      </div>

      {error && <p className="rounded-md bg-danger-soft px-4 py-3 text-sm text-danger" role="alert">{error}</p>}
      {customerError && <p className="rounded-md bg-danger-soft px-4 py-3 text-sm text-danger" role="alert">{customerError}</p>}
      {success && <p className="rounded-md bg-success-soft px-4 py-3 text-sm text-success" role="status">{success}</p>}

      <div className={`grid gap-4 ${selected ? "xl:grid-cols-3" : "grid-cols-1"}`}>
        <div className={selected ? "xl:col-span-2" : ""}>
          <Card>
            <TableContainer>
              <table className="data-table w-full min-w-[760px]">
                <thead>
                  <tr>
                    <th>Mã xe</th>
                    <th>Biển số</th>
                    <th>Chủ xe</th>
                    <th>Hãng xe</th>
                    <th>Dòng xe</th>
                    <th className="text-right">Năm SX</th>
                    <th className="text-right">Số km</th>
                    <th>Thao tác</th>
                  </tr>
                </thead>
                <tbody>
                  {loading && <tr><td colSpan={8} className="py-10 text-center text-sm text-muted-foreground">Đang tải danh sách xe...</td></tr>}
                  {!loading && vehicles.length === 0 && !error && (
                    <tr><td colSpan={8} className="py-10 text-center text-sm text-muted-foreground">Không tìm thấy xe phù hợp.</td></tr>
                  )}
                  {!loading && vehicles.map((vehicle) => (
                    <tr
                      key={vehicle.id}
                      tabIndex={0}
                      aria-selected={selected?.id === vehicle.id}
                      onClick={() => toggleDetail(vehicle)}
                      onKeyDown={(event) => {
                        if (event.currentTarget !== event.target || (event.key !== "Enter" && event.key !== " ")) return;
                        event.preventDefault();
                        toggleDetail(vehicle);
                      }}
                      className={`cursor-pointer ${selected?.id === vehicle.id ? "bg-info-soft" : ""}`}
                    >
                      <td><span className="mono text-xs text-slate-400">{vehicle.id}</span></td>
                      <td><span className="mono font-bold text-primary">{vehicle.licensePlate}</span></td>
                      <td className="font-medium text-slate-800">{customerName(vehicle.customerId)}</td>
                      <td className="text-slate-600">{vehicle.brand || "—"}</td>
                      <td className="text-slate-600">{vehicle.model || "—"}</td>
                      <td className="text-right text-slate-600">{vehicle.year ?? "—"}</td>
                      <td className="mono text-right text-sm">{vehicle.mileage?.toLocaleString("vi-VN") ?? "—"}</td>
                      <td>
                        <div className="flex gap-1">
                          <button
                            type="button"
                            aria-label={`Xem xe ${vehicle.licensePlate}`}
                            onClick={(event) => { event.stopPropagation(); openDetail(vehicle); }}
                            className="flex h-11 w-11 items-center justify-center rounded text-slate-500 hover:bg-slate-100"
                          >{Icons.eye}</button>
                          <button
                            type="button"
                            aria-label={`Sửa xe ${vehicle.licensePlate}`}
                            onClick={(event) => { event.stopPropagation(); openEdit(vehicle); }}
                            className="flex h-11 w-11 items-center justify-center rounded text-slate-500 hover:bg-slate-100"
                          >{Icons.edit}</button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </TableContainer>
            <div className="flex flex-col gap-3 border-t border-border px-4 py-3 sm:flex-row sm:items-center sm:justify-between">
              <p className="text-xs text-muted-foreground">{totalElements} xe</p>
              <Pagination page={page} total={totalElements} perPage={PER_PAGE} onChange={setPage} />
            </div>
          </Card>
        </div>

        {selected && (
          <div className="detail-panel space-y-4">
            <Card className="p-4 sm:p-5">
              <div className="mb-4 flex items-start justify-between">
                <div>
                  <p className="mono text-2xl font-bold text-primary">{selected.licensePlate}</p>
                  <p className="font-medium text-slate-600">{[selected.brand, selected.model, selected.year].filter(Boolean).join(" ") || "Chưa cập nhật thông tin xe"}</p>
                  <p className="mono mt-1 text-xs text-slate-400">Mã xe: {selected.id}</p>
                </div>
                <button type="button" onClick={() => setSelected(null)} aria-label="Đóng chi tiết xe" className="flex h-11 w-11 items-center justify-center rounded text-slate-500 hover:bg-slate-100">{Icons.close}</button>
              </div>
              <div className="grid grid-cols-2 gap-3 text-sm">
                <div className="rounded-lg bg-slate-50 p-3"><p className="text-xs text-slate-400">Chủ xe</p><p className="font-semibold">{customerName(selected.customerId)}</p></div>
                <div className="rounded-lg bg-slate-50 p-3"><p className="text-xs text-slate-400">Mã khách hàng</p><p className="mono font-semibold">{customerCode(selected.customerId)}</p></div>
                <div className="rounded-lg bg-slate-50 p-3"><p className="text-xs text-slate-400">Số km</p><p className="mono font-semibold">{selected.mileage !== null ? `${selected.mileage.toLocaleString("vi-VN")} km` : "—"}</p></div>
                <div className="rounded-lg bg-slate-50 p-3"><p className="text-xs text-slate-400">Năm sản xuất</p><p className="font-semibold">{selected.year ?? "—"}</p></div>
              </div>
              <Button className="mt-4 w-full" variant="outline" icon={Icons.edit} onClick={() => openEdit(selected)}>Chỉnh sửa thông tin</Button>
            </Card>
          </div>
        )}
      </div>

      <Modal open={showForm} onClose={() => setShowForm(false)} title={editing ? "Cập nhật xe" : "Thêm xe"} width="max-w-xl">
        {showForm && (
          <VehicleForm
            key={editing?.id ?? "new"}
            customerOptions={customerOptions}
            lockCustomer={Boolean(editing)}
            initialValue={editing ? {
              customerId: editing.customerId,
              plate: editing.licensePlate,
              brand: editing.brand ?? "",
              model: editing.model ?? "",
              year: editing.year,
              mileage: editing.mileage,
            } : undefined}
            onSubmit={handleSubmit}
            onCancel={() => setShowForm(false)}
            submitLabel={editing ? "Lưu thay đổi" : "Lưu xe"}
            savingLabel="Đang lưu..."
          />
        )}
      </Modal>
    </div>
  );
}
'@

# ============================================================
# 6. VA CAC FILE HIEN CO (chi thay doan can thiet, co backup)
# ============================================================
Write-Step 'Va file hien co'
Update-RepoFile 'backend/pom.xml' '    </dependencies>' '        <dependency>
            <groupId>org.springdoc</groupId>
            <artifactId>springdoc-openapi-starter-webmvc-ui</artifactId>
            <version>2.8.13</version>
        </dependency>
    </dependencies>' 'springdoc-openapi-starter-webmvc-ui'
Update-RepoFile 'backend/src/main/java/com/gara/quanlygara/config/SecurityConfig.java' '.requestMatchers(HttpMethod.GET, "/api/health").permitAll()' '.requestMatchers(HttpMethod.GET, "/api/health").permitAll()
                        .requestMatchers("/swagger-ui/**", "/swagger-ui.html", "/v3/api-docs/**").permitAll()' '/v3/api-docs/**'
Update-RepoFile 'backend/src/test/java/com/gara/quanlygara/config/SecurityConfigTest.java' 'import com.gara.quanlygara.repository.TechnicianRepository;' 'import com.gara.quanlygara.repository.TechnicianRepository;
import com.gara.quanlygara.repository.VehicleRepository;' 'repository.VehicleRepository;'
Update-RepoFile 'backend/src/test/java/com/gara/quanlygara/config/SecurityConfigTest.java' '    private TechnicianRepository technicianRepository;' '    private TechnicianRepository technicianRepository;

    @MockitoBean
    private VehicleRepository vehicleRepository;' 'private VehicleRepository vehicleRepository;'
Update-RepoFile 'frontend/src/pages/customer/CustomerPortal.tsx' '<CustomerVehicles customerKey={customerKey} />' '<CustomerVehicles customerId={customerId} />' '<CustomerVehicles customerId='
Update-RepoFile 'frontend/src/pages/customer/CustomerPortal.tsx' '<CustomerAppointments customerKey={customerKey} />' '<CustomerAppointments customerKey={customerKey} customerId={customerId} />' '<CustomerAppointments customerKey={customerKey} customerId='
Update-RepoFile 'frontend/src/pages/customer/CustomerAppointments.tsx' 'import { dichVu, formatCurrency, lichHen, type AppointmentStatus } from "../../mock/data";' 'import { dichVu, formatCurrency, lichHen, xe as mockVehicles, type AppointmentStatus } from "../../mock/data";' 'xe as mockVehicles'
Update-RepoFile 'frontend/src/pages/customer/CustomerAppointments.tsx' 'export default function CustomerAppointments({ customerKey, onBooked }: { customerKey: string; onBooked?: () => void }) {' 'export default function CustomerAppointments({ customerKey, customerId, onBooked }: { customerKey: string; customerId: number; onBooked?: () => void }) {' 'customerKey, customerId, onBooked'
Update-RepoFile 'frontend/src/pages/customer/CustomerAppointments.tsx' 'useCustomerVehicles(customerKey);' 'useCustomerVehicles(customerId);' 'useCustomerVehicles(customerId);'
Update-RepoFile 'frontend/src/pages/customer/CustomerAppointments.tsx' 'const vehiclePlate = (id: string) => myVehicles.find((vehicle) => vehicle.MaXe === id)?.BienSo ?? id;' '// Lịch hẹn vẫn là dữ liệu mẫu (mã xe dạng chuỗi), nên tra thêm trong dữ liệu mẫu nếu không có xe thật.
  const vehiclePlate = (id: string) => myVehicles.find((vehicle) => String(vehicle.id) === id)?.licensePlate
    ?? mockVehicles.find((vehicle) => vehicle.MaXe === id)?.BienSo
    ?? id;' 'String(vehicle.id) === id'
Update-RepoFile 'frontend/src/pages/customer/CustomerAppointments.tsx' 'const selected = selectedVehicle === vehicle.MaXe;' 'const selected = selectedVehicle === String(vehicle.id);' 'selectedVehicle === String(vehicle.id)'
Update-RepoFile 'frontend/src/pages/customer/CustomerAppointments.tsx' '[vehicle.HangXe, vehicle.DongXe, vehicle.NamSanXuat]' '[vehicle.brand, vehicle.model, vehicle.year]' '[vehicle.brand, vehicle.model, vehicle.year]'
Update-RepoFile 'frontend/src/pages/customer/CustomerAppointments.tsx' 'key={vehicle.MaXe}' 'key={vehicle.id}' 'key={vehicle.id}'
Update-RepoFile 'frontend/src/pages/customer/CustomerAppointments.tsx' 'onClick={() => setSelectedVehicle(vehicle.MaXe)}' 'onClick={() => setSelectedVehicle(String(vehicle.id))}' 'setSelectedVehicle(String(vehicle.id))}'
Update-RepoFile 'frontend/src/pages/customer/CustomerAppointments.tsx' '<span className="mono block font-bold text-primary">{vehicle.BienSo}</span>' '<span className="mono block font-bold text-primary">{vehicle.licensePlate}</span>' '{vehicle.licensePlate}</span>'
Update-RepoFile 'frontend/src/pages/customer/CustomerAppointments.tsx' 'setSelectedVehicle(vehicle.MaXe);' 'setSelectedVehicle(String(vehicle.id));' 'setSelectedVehicle(String(vehicle.id));'
Update-RepoFile 'frontend/src/pages/customer/CustomerOverview.tsx' 'import { thongBao } from "../../mock/schemaData";' 'import { thongBao } from "../../mock/schemaData";
import { useCustomerVehicles } from "../../features/vehicles/customerVehicleRepository";' 'useCustomerVehicles }'
Update-RepoFile 'frontend/src/pages/customer/CustomerOverview.tsx' '  onNavigate: (page: CustomerPage) => void;
}' '  onNavigate: (page: CustomerPage) => void;
  customerId: number;
}' 'customerId: number;'
Update-RepoFile 'frontend/src/pages/customer/CustomerOverview.tsx' 'export default function CustomerOverview({ onNavigate }: CustomerOverviewProps) {
' 'export default function CustomerOverview({ onNavigate, customerId }: CustomerOverviewProps) {
  // Số xe lấy từ API thật; myVehicles (mock) chỉ còn để nối dữ liệu lịch hẹn/sửa chữa mẫu của module khác.
  const { vehicles: realVehicles, loading: vehiclesLoading } = useCustomerVehicles(customerId);
' 'vehicles: realVehicles'
Update-RepoFile 'frontend/src/pages/customer/CustomerOverview.tsx' 'label: "Xe của tôi", value: myVehicles.length,' 'label: "Xe của tôi", value: vehiclesLoading ? "…" : realVehicles.length,' 'realVehicles.length'
Update-RepoFile 'frontend/src/pages/customer/CustomerPortal.tsx' '<CustomerOverview onNavigate={onNavigate} />' '<CustomerOverview onNavigate={onNavigate} customerId={customerId} />' '<CustomerOverview onNavigate={onNavigate} customerId='

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
        $vehicleErrors = @($tsc | Where-Object { $_ -match "vehicle|Vehicle|CustomerAppointments|CustomerPortal" })
        if ($vehicleErrors.Count -gt 0) {
            $vehicleErrors | ForEach-Object { Write-Host "    $_" -ForegroundColor Red }
            $script:Results["Frontend tsc"] = "FAIL (loi lien quan Vehicle)"
            Show-Summary
            exit 1
        }
        $script:Results["Frontend tsc"] = "WARN (loi khong thuoc Vehicle)"
        Write-Warn2 "tsc bao loi o file khac Vehicle (co the co san tu truoc)."
    }
}

Write-Host ""
Write-Host "Luu y: chay backend/database/Test_Vehicles.sql trong SSMS de kiem tra rang buoc bang Xe (script tu ROLLBACK)." -ForegroundColor Yellow

# ============================================================
# 8. ZIP (chi khi build/test da chay thanh cong)
# ============================================================
if (-not $SkipBuild -and -not $NoZip) {
    Write-Step "Tao TV3_Tuan6_Vehicle_FINAL.zip"
    $zip = Join-Path $root "TV3_Tuan6_Vehicle_FINAL.zip"
    $stage = Join-Path ([System.IO.Path]::GetTempPath()) "tv3-vehicle-$stamp"
    New-Item -ItemType Directory -Force -Path $stage | Out-Null
    robocopy $root $stage /E /NFL /NDL /NJH /NJS /NP `
        /XD target node_modules .idea .vscode .backup .git dist .dart_tool build .gradle `
        /XF *.log .env .env.local TV3_Tuan6_Vehicle_FINAL.zip TV3_Tuan6_Vehicle_APPLY.ps1 | Out-Null
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
Write-Host "Lenh Git de ban tu chay:"
Write-Host "  git status"
Write-Host "  git add backend frontend"
Write-Host "  git commit -m `"feat(vehicle): implement vehicle management`""
Write-Host "  git push -u origin feature/cam-vehicle"
