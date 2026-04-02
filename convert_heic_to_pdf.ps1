Param(
    [string]$InputFolder = 'C:\temp\heicset'
)

$imageType = '*.heic'

# Convert all .heic images in a folder into one PDF, saved to <input>\pdf_saved\YYYYMMDD_HHMMSS.pdf

if (-not (Test-Path -Path $InputFolder -PathType Container)) {
    Write-Error "Input folder does not exist: $InputFolder"
    exit 1
}

$outputFolder = Join-Path $InputFolder 'pdf_saved'
New-Item -ItemType Directory -Force -Path $outputFolder | Out-Null

$heicFiles = Get-ChildItem -Path $InputFolder -Filter $imageType -File
if ($heicFiles.Count -eq 0) {
    Write-Error "No [$imageType] files found in $InputFolder"
    exit 1
}

$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$outputFile = Join-Path $outputFolder "$timestamp.pdf"

if (Get-Command magick -ErrorAction SilentlyContinue) {
    Write-Output "Using ImageMagick 'magick' to create PDF..."
    magick convert "$InputFolder\$imageType" "$outputFile"
}
elseif (Get-Command convert -ErrorAction SilentlyContinue) {
    Write-Output "Using ImageMagick 'convert' to create PDF..."
    convert "$InputFolder\$imageType" "$outputFile"
}
else {
    Write-Error "ImageMagick 'magick' or 'convert' not found. Install ImageMagick first."
    exit 1
}

Write-Output "Created PDF: $outputFile"
