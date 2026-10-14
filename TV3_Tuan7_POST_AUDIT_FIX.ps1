<#
  TV3_Tuan7_POST_AUDIT_FIX.ps1 - Sua loi da xac nhan: tim phu tung theo MA / ten / hang san xuat
  Chay tu repository root:   .\TV3_Tuan7_POST_AUDIT_FIX.ps1
  Chi va 6 file cua Tuan 7 (khong schema, khong module khac). Tuy chon: -SkipBuild
  Khong checkout/commit/push Git.
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
    "backend/src/main/java/com/gara/quanlygara/repository/SparePartRepository.java",
    "backend/src/main/java/com/gara/quanlygara/service/SparePartService.java",
    "backend/src/test/java/com/gara/quanlygara/service/SparePartServiceTest.java",
    "backend/src/test/java/com/gara/quanlygara/controller/SparePartApiTest.java",
    "frontend/package.json",
    "frontend/src/pages/SpareParts.tsx"
)
$missing = @($required | Where-Object { -not (Test-Path -LiteralPath (Join-Path $root $_)) })
if ($missing.Count -gt 0) {
    Stop-Fail ("Khong dung repository root ($root). Thieu:`n  - " + ($missing -join "`n  - "))
}
Set-Location -LiteralPath $root
Write-Ok "Repository root: $root"
if (-not ((Get-Content -LiteralPath (Join-Path $root "backend/src/main/java/com/gara/quanlygara/service/SparePartService.java") -Raw).Contains("TV3-TUAN7"))) { Stop-Fail "SparePartService.java khong phai ban Tuan 7 do script tao. Gui file nay cho Claude." }

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


Write-Step 'Va search ma phu tung (chi cac file lien quan)'
Update-RepoFile 'backend/src/main/java/com/gara/quanlygara/repository/SparePartRepository.java' '    Page<SparePart> findByNameContainingIgnoreCaseOrManufacturerContainingIgnoreCase(
            String name, String manufacturer, Pageable pageable);
' '    Page<SparePart> findByNameContainingIgnoreCaseOrManufacturerContainingIgnoreCase(
            String name, String manufacturer, Pageable pageable);

    // Từ khóa là số: khớp mã phụ tùng (MaPhuTung) HOẶC tên/hãng chứa chuỗi số đó.
    Page<SparePart> findByIdOrNameContainingIgnoreCaseOrManufacturerContainingIgnoreCase(
            Integer id, String name, String manufacturer, Pageable pageable);
' 'findByIdOrNameContainingIgnoreCase'
Update-RepoFile 'backend/src/main/java/com/gara/quanlygara/service/SparePartService.java' '        Page<SparePart> result = keyword == null
                ? sparePartRepository.findAll(pageable)
                : sparePartRepository.findByNameContainingIgnoreCaseOrManufacturerContainingIgnoreCase(
                        keyword, keyword, pageable);
        return SparePartPageResponse.from(result);
' '        Page<SparePart> result;
        if (keyword == null) {
            result = sparePartRepository.findAll(pageable);
        } else {
            Integer partId = parsePartId(keyword);
            result = partId == null
                    ? sparePartRepository.findByNameContainingIgnoreCaseOrManufacturerContainingIgnoreCase(
                            keyword, keyword, pageable)
                    : sparePartRepository.findByIdOrNameContainingIgnoreCaseOrManufacturerContainingIgnoreCase(
                            partId, keyword, keyword, pageable);
        }
        return SparePartPageResponse.from(result);
' 'parsePartId(keyword)'
Update-RepoFile 'backend/src/main/java/com/gara/quanlygara/service/SparePartService.java' '    private String normalizeOptional(String value) {' '    /** Từ khóa chỉ gồm chữ số (tối đa 9 chữ số, vừa kiểu INT) được hiểu thêm là mã phụ tùng. */
    private Integer parsePartId(String keyword) {
        return keyword.matches("\\d{1,9}") ? Integer.valueOf(keyword) : null;
    }

    private String normalizeOptional(String value) {' 'Integer parsePartId(String keyword)'
Update-RepoFile 'backend/src/test/java/com/gara/quanlygara/service/SparePartServiceTest.java' '    @Test
    void updateChangesCatalogFieldsButNeverTouchesStock() {' '    @Test
    void getAllNumericKeywordMatchesPartIdOrText() {
        when(sparePartRepository.findByIdOrNameContainingIgnoreCaseOrManufacturerContainingIgnoreCase(
                eq(5), eq("5"), eq("5"), any(Pageable.class)))
                .thenReturn(new PageImpl<>(List.of(part(5, "Bugi", 12))));

        var response = sparePartService.getAll(0, 10, " 5 ");

        assertEquals(1, response.items().size());
        assertEquals(5, response.items().get(0).id());
        verify(sparePartRepository, never()).findAll(any(Pageable.class));
        verify(sparePartRepository, never()).findByNameContainingIgnoreCaseOrManufacturerContainingIgnoreCase(
                any(), any(), any(Pageable.class));
    }

    @Test
    void getAllNonNumericOrOversizedKeywordSearchesTextOnly() {
        when(sparePartRepository.findByNameContainingIgnoreCaseOrManufacturerContainingIgnoreCase(
                any(), any(), any(Pageable.class)))
                .thenReturn(new PageImpl<>(List.of()));

        sparePartService.getAll(0, 10, "5W-30");
        sparePartService.getAll(0, 10, "99999999999");

        verify(sparePartRepository, never()).findByIdOrNameContainingIgnoreCaseOrManufacturerContainingIgnoreCase(
                any(), any(), any(), any(Pageable.class));
    }

    @Test
    void getAllNumericSearchKeepsPaginationAndSorting() {
        ArgumentCaptor<Pageable> captor = ArgumentCaptor.forClass(Pageable.class);
        when(sparePartRepository.findByIdOrNameContainingIgnoreCaseOrManufacturerContainingIgnoreCase(
                eq(7), eq("7"), eq("7"), captor.capture()))
                .thenReturn(new PageImpl<>(List.of(part(7, "Bugi", 1)), PageRequest.of(2, 5), 11));

        var response = sparePartService.getAll(2, 5, "7");

        assertEquals(2, response.page());
        assertEquals(11, response.totalElements());
        assertEquals(3, response.totalPages());
        assertEquals(2, captor.getValue().getPageNumber());
        assertEquals(5, captor.getValue().getPageSize());
        assertEquals("name", captor.getValue().getSort().iterator().next().getProperty());
    }

    @Test
    void updateChangesCatalogFieldsButNeverTouchesStock() {' 'getAllNumericKeywordMatchesPartIdOrText'
Update-RepoFile 'backend/src/test/java/com/gara/quanlygara/controller/SparePartApiTest.java' '    @Test
    @WithMockUser(roles = "MANAGER")
    void getByIdReturnsPart() throws Exception {' '    @Test
    @WithMockUser(roles = "MANAGER")
    void searchByPartIdReturnsThatPart() throws Exception {
        when(sparePartRepository.findByIdOrNameContainingIgnoreCaseOrManufacturerContainingIgnoreCase(
                eq(2), eq("2"), eq("2"), any(Pageable.class)))
                .thenReturn(new PageImpl<>(List.of(part(2, "Bugi", 3)), PageRequest.of(0, 10), 1));

        mockMvc.perform(get("/api/spare-parts").param("search", "2").param("page", "0").param("size", "10"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.items.length()").value(1))
                .andExpect(jsonPath("$.data.items[0].id").value(2))
                .andExpect(jsonPath("$.data.items[0].name").value("Bugi"))
                .andExpect(jsonPath("$.data.totalElements").value(1));
    }

    @Test
    @WithMockUser(roles = "MANAGER")
    void getByIdReturnsPart() throws Exception {' 'searchByPartIdReturnsThatPart'
Update-RepoFile 'frontend/src/pages/SpareParts.tsx' 'placeholder="Tìm theo tên hoặc hãng sản xuất..."' 'placeholder="Tìm theo mã, tên hoặc hãng sản xuất..."' 'Tìm theo mã, tên hoặc hãng sản xuất'

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
        $vehicleErrors = @($tsc | Where-Object { $_ -match "SpareParts|spareParts" })
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
Write-Host "Luu y: chay backend/database/Test_SpareParts.sql neu chua chay (script tu ROLLBACK)." -ForegroundColor Yellow

Show-Summary
Write-Host ""
Write-Host "SUCCESS" -ForegroundColor Green
Write-Host "Lenh Git de ban tu chay (khong merge vao main):"
Write-Host "  git status"
Write-Host "  git add backend frontend"
Write-Host "  git commit -m `"fix(spare-part): search spare parts by id, name or manufacturer`""
Write-Host "  git push -u origin feature/cam-sparepart"
