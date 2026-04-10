param()

$galleryRoot = "c:\Amalgamate\Projects\Web\ACCS SAcco\accs-sacco\public\images\gellery"
$jsonPath = Join-Path $galleryRoot "gallery-data.json"

Write-Host ""
Write-Host "=== Gallery Duplicate Cleanup ===" -ForegroundColor Cyan
Write-Host "Root: $galleryRoot"
Write-Host ""

# STEP 1: Delete .jpg / .JPG files where a .webp sibling exists
Write-Host "STEP 1: Removing JPG originals that have a WebP counterpart..." -ForegroundColor Yellow

$jpgFiles = Get-ChildItem -Path $galleryRoot -Recurse -Include "*.jpg","*.JPG"
$deletedJpg = 0
$skippedJpg = 0

foreach ($jpg in $jpgFiles) {
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($jpg.FullName)
    $webpPath = Join-Path $jpg.DirectoryName ($baseName + ".webp")

    if (Test-Path $webpPath) {
        $sizeMB = [math]::Round($jpg.Length / 1MB, 1)
        Write-Host "  DELETE: $($jpg.Name) [$sizeMB MB]" -ForegroundColor Red
        Remove-Item $jpg.FullName -Force
        $deletedJpg++
    } else {
        Write-Host "  KEEP (no webp): $($jpg.Name)" -ForegroundColor Gray
        $skippedJpg++
    }
}

Write-Host "  Result -> Deleted: $deletedJpg  |  Kept: $skippedJpg" -ForegroundColor Green
Write-Host ""

# STEP 2: Delete "IMG_1513 (1)" files - exact duplicate of IMG_1513
Write-Host "STEP 2: Removing IMG_1513 (1) duplicate files..." -ForegroundColor Yellow

$dupFiles = Get-ChildItem -Path $galleryRoot -Recurse | Where-Object { $_.Name -like "IMG_1513 (1)*" }

if ($dupFiles.Count -eq 0) {
    Write-Host "  No IMG_1513 (1) files found - already clean." -ForegroundColor Gray
} else {
    foreach ($dup in $dupFiles) {
        Write-Host "  DELETE: $($dup.Name)" -ForegroundColor Red
        Remove-Item $dup.FullName -Force
    }
    Write-Host "  Result -> Deleted $($dupFiles.Count) duplicate file(s)." -ForegroundColor Green
}
Write-Host ""

# STEP 3: Remove duplicate JSON entry for IMG_1513 (1)
Write-Host "STEP 3: Cleaning gallery-data.json..." -ForegroundColor Yellow

$jsonRaw = Get-Content $jsonPath -Raw -Encoding UTF8
$jsonData = $jsonRaw | ConvertFrom-Json

$before = $jsonData.Count
$cleaned = $jsonData | Where-Object { $_.src -notlike "*IMG_1513 (1)*" }
$after = $cleaned.Count
$removed = $before - $after

$cleanedJson = $cleaned | ConvertTo-Json -Depth 5
Set-Content -Path $jsonPath -Value $cleanedJson -Encoding UTF8

Write-Host "  JSON entries: $before -> $after (removed $removed)" -ForegroundColor Green
Write-Host ""

# SUMMARY
Write-Host "=== Cleanup Complete ===" -ForegroundColor Cyan
Write-Host "  JPG/JPG files removed : $deletedJpg"
Write-Host "  Duplicate files removed: $($dupFiles.Count)"
Write-Host "  JSON entries removed   : $removed"
Write-Host ""
