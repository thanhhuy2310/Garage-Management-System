$ErrorActionPreference = "Stop"

$envFile = Join-Path $PSScriptRoot ".env"
if (-not (Test-Path -LiteralPath $envFile)) {
    Write-Error "Không tìm thấy backend/.env. Hãy sao chép .env.example thành .env và điền cấu hình local."
    exit 1
}

foreach ($rawLine in Get-Content -LiteralPath $envFile) {
    $line = $rawLine.Trim()
    if (-not $line -or $line.StartsWith("#")) {
        continue
    }

    $separatorIndex = $line.IndexOf("=")
    if ($separatorIndex -lt 1) {
        Write-Warning "Bỏ qua một dòng .env không đúng định dạng KEY=VALUE."
        continue
    }

    $name = $line.Substring(0, $separatorIndex).Trim()
    $value = $line.Substring($separatorIndex + 1)
    if ($name -notmatch "^[A-Za-z_][A-Za-z0-9_]*$") {
        Write-Warning "Bỏ qua tên biến môi trường không hợp lệ."
        continue
    }

    [Environment]::SetEnvironmentVariable($name, $value, "Process")
}

Push-Location $PSScriptRoot
try {
    & "$PSScriptRoot\mvnw.cmd" spring-boot:run
    exit $LASTEXITCODE
}
finally {
    Pop-Location
}
