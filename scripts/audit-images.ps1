$root = 'c:\Amalgamate\Projects\Web\ACCS SAcco\accs-sacco'
$publicImages = 'c:\Amalgamate\Projects\Web\ACCS SAcco\accs-sacco\public\images'

# Build set of all images that exist on disk (as /images/... paths)
$existingFiles = @{}
Get-ChildItem -Path $publicImages -Recurse -File | ForEach-Object {
    $rel = '/images/' + $_.FullName.Substring($publicImages.Length + 1).Replace('\', '/')
    $existingFiles[$rel] = $true
}

Write-Host "Images on disk: $($existingFiles.Count)" -ForegroundColor Cyan

# Regex to find image paths in src/href/url attributes
$imgPattern = [regex]'(?:src|href|background(?:-image)?|url)\s*[=:]\s*["\x27\(]([^"\x27\)\s]+\.(?:jpg|jpeg|png|webp|gif|svg|ico))'

# Scan all HTML files (and css/js in public)
$scanFiles  = @()
$scanFiles += Get-ChildItem -Path $root -Filter '*.html' -File
$scanFiles += Get-ChildItem -Path (Join-Path $root 'public\css') -Filter '*.css' -File -ErrorAction SilentlyContinue
$scanFiles += Get-ChildItem -Path (Join-Path $root 'public\js')  -Filter '*.js'  -File -ErrorAction SilentlyContinue

$refs   = [System.Collections.Generic.List[PSCustomObject]]::new()
$broken = [System.Collections.Generic.List[PSCustomObject]]::new()

foreach ($f in $scanFiles) {
    $content = [System.IO.File]::ReadAllText($f.FullName)
    $ms = $imgPattern.Matches($content)
    foreach ($m in $ms) {
        $raw = $m.Groups[1].Value.Trim()
        # Only care about absolute /images/ paths
        if ($raw -notmatch '^/images/') { continue }
        # Strip query string or hash
        $path = ($raw -replace '[?#].*$', '')
        $obj  = [PSCustomObject]@{ SourceFile = $f.Name; ImagePath = $path }
        $refs.Add($obj)
        if (-not $existingFiles.ContainsKey($path)) {
            $broken.Add($obj)
        }
    }
}

# Also scan gallery-data.json
$galleryJson = Join-Path $root 'public\images\gellery\gallery-data.json'
if (Test-Path $galleryJson) {
    $content = [System.IO.File]::ReadAllText($galleryJson)
    $jsonPattern = [regex]'"src"\s*:\s*"(/images/[^"]+)"'
    $ms = $jsonPattern.Matches($content)
    foreach ($m in $ms) {
        $path = $m.Groups[1].Value.Trim()
        $obj  = [PSCustomObject]@{ SourceFile = 'gallery-data.json'; ImagePath = $path }
        $refs.Add($obj)
        if (-not $existingFiles.ContainsKey($path)) {
            $broken.Add($obj)
        }
    }
}

# Deduplicate broken by ImagePath
$brokenUnique = $broken | Sort-Object ImagePath -Unique

Write-Host ""
Write-Host "=== IMAGE AUDIT RESULTS ===" -ForegroundColor Yellow
Write-Host "Total image refs scanned : $($refs.Count)"
Write-Host "Unique broken references : $($brokenUnique.Count)" -ForegroundColor Red
Write-Host ""

if ($brokenUnique.Count -gt 0) {
    Write-Host "BROKEN REFERENCES:" -ForegroundColor Red
    $brokenUnique | ForEach-Object {
        Write-Host "  [MISSING] $($_.ImagePath)  <- $($_.SourceFile)" -ForegroundColor Red
    }
} else {
    Write-Host "All image references are valid!" -ForegroundColor Green
}

# Show summary per source file
Write-Host ""
Write-Host "=== BROKEN BY SOURCE FILE ===" -ForegroundColor Yellow
$broken | Group-Object SourceFile | Sort-Object Name | ForEach-Object {
    Write-Host ""
    Write-Host "  $($_.Name) ($($_.Count) broken):" -ForegroundColor Magenta
    $_.Group | ForEach-Object { Write-Host "    - $($_.ImagePath)" }
}

# Export CSV
$csvPath = Join-Path $root 'scripts\image-audit-results.csv'
$brokenUnique | Export-Csv -Path $csvPath -NoTypeInformation
Write-Host ""
Write-Host "Results exported to: $csvPath" -ForegroundColor Cyan
