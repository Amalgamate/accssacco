param()

$root        = "c:\Amalgamate\Projects\Web\ACCS SAcco\accs-sacco"
$publicImg   = "$root\public\images"

# ── 1. Build a HashSet of every image file that actually exists on disk ─────
$onDisk = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
Get-ChildItem -Path $publicImg -Recurse -File | ForEach-Object {
    $rel = "/images/" + $_.FullName.Substring($publicImg.Length + 1).Replace("\", "/")
    [void]$onDisk.Add($rel)
}
Write-Host "Images on disk : $($onDisk.Count)" -ForegroundColor Cyan

# ── 2. Collect all references from HTML files ────────────────────────────────
$broken = [System.Collections.Generic.List[PSCustomObject]]::new()
$total  = 0

# Pattern: src="..." or url("...") containing /images/  with image extension
$pattern = [regex]@"
(?:src|href|url)\s*[=:]\s*["'\(]([^"'\)\s]+\.(?:jpe?g|png|webp|gif|svg|ico))
"@

$htmlFiles = Get-ChildItem -Path $root -Filter "*.html" -File
foreach ($f in $htmlFiles) {
    $text = [System.IO.File]::ReadAllText($f.FullName)
    $ms   = $pattern.Matches($text)
    foreach ($m in $ms) {
        $raw  = $m.Groups[1].Value.Trim() -replace "[?#].*$", ""
        if ($raw -notmatch "^/images/") { continue }
        $total++
        if (-not $onDisk.Contains($raw)) {
            $broken.Add([PSCustomObject]@{
                File = $f.Name
                Ref  = $raw
            })
        }
    }
}

# ── 3. Check gallery-data.json ───────────────────────────────────────────────
$galleryJson = "$root\public\images\gellery\gallery-data.json"
if (Test-Path $galleryJson) {
    $text    = [System.IO.File]::ReadAllText($galleryJson)
    $jsonPat = [regex]'"(?:src|thumbnail|url)"\s*:\s*"(/images/[^"]+)"'
    $ms      = $jsonPat.Matches($text)
    foreach ($m in $ms) {
        $raw = $m.Groups[1].Value.Trim() -replace "[?#].*$", ""
        $total++
        if (-not $onDisk.Contains($raw)) {
            $broken.Add([PSCustomObject]@{
                File = "gallery-data.json"
                Ref  = $raw
            })
        }
    }
}

# ── 4. Check style.css ──────────────────────────────────────────────────────
$cssFile = "$root\public\css\style.css"
if (Test-Path $cssFile) {
    $text    = [System.IO.File]::ReadAllText($cssFile)
    $cssPat  = [regex]'url\(["'']?(/images/[^"''\)\s]+\.(?:jpe?g|png|webp|gif|svg))["'']?\)'
    $ms      = $cssPat.Matches($text)
    foreach ($m in $ms) {
        $raw = $m.Groups[1].Value.Trim() -replace "[?#].*$", ""
        $total++
        if (-not $onDisk.Contains($raw)) {
            $broken.Add([PSCustomObject]@{
                File = "style.css"
                Ref  = $raw
            })
        }
    }
}

# ── 5. Report ────────────────────────────────────────────────────────────────
$uniqueBroken = $broken | Sort-Object Ref -Unique

Write-Host ""
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "  IMAGE AUDIT RESULTS" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "  Total refs scanned  : $total"
Write-Host "  Broken (unique)     : $($uniqueBroken.Count)" -ForegroundColor $(if ($uniqueBroken.Count -eq 0) { "Green" } else { "Red" })
Write-Host ""

if ($uniqueBroken.Count -eq 0) {
    Write-Host "  All image references are valid!" -ForegroundColor Green
} else {
    Write-Host "  MISSING IMAGE FILES:" -ForegroundColor Red
    $uniqueBroken | ForEach-Object {
        Write-Host "    [MISSING] $($_.Ref)" -ForegroundColor Red
    }

    Write-Host ""
    Write-Host "  BROKEN REFS BY SOURCE FILE:" -ForegroundColor Yellow
    $broken | Group-Object File | Sort-Object Name | ForEach-Object {
        Write-Host ""
        Write-Host "  >> $($_.Name)" -ForegroundColor Magenta
        $_.Group | Select-Object -ExpandProperty Ref | Sort-Object -Unique | ForEach-Object {
            Write-Host "       $_"
        }
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Yellow
