<#
.SYNOPSIS
Generates a pair of blog‑ready JPEG images from a single input file.

.DESCRIPTION
Write-BlogImagePair processes an input image of any format supported by ffmpeg
and produces two resized JPEG outputs:

  • A main blog image with a 2200px long edge.
  • A thumbnail image with a 600px long edge.

Both files are written into an "output" subfolder located beside the input
file. The folder is created automatically if it does not already exist.

All metadata is removed. Existing output files are overwritten without
confirmation.

.PARAMETER InputFile
The path to the input image. Can be absolute or relative. The file must exist.

.EXAMPLE
Write-BlogImagePair C:\photos\image.png

Creates:
  C:\photos\output\image.png_size2200.jpg
  C:\photos\output\image.png_tn.jpg

.EXAMPLE
Write-BlogImagePair .\header.png

Creates:
  .\output\header.png_size2200.jpg
  .\output\header.png_tn.jpg

.NOTES
Requires ffmpeg to be installed and available in PATH.
This function overwrites existing output files without prompting.

Get-Help Write-BlogImagePair
Get-Help Write-BlogImagePair -Detailed
Get-Help Write-BlogImagePair -Full
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$InputFile
)

$fullPath = Resolve-Path $InputFile
$dir      = Split-Path $fullPath
$outdir   = Join-Path $dir "output"

if (-not (Test-Path $outdir)) {
    New-Item -ItemType Directory -Path $outdir | Out-Null
}

$basename = Split-Path $fullPath -Leaf

# Main 2200px output
$out_main = Join-Path $outdir "${basename}_size2200.jpg"

# Thumbnail output (600px)
$out_tn   = Join-Path $outdir "${basename}_tn.jpg"

# Create main resized image (overwrite enabled)
ffmpeg -y -i $fullPath -vf "scale=2200:-1" -q:v 3 -map_metadata -1 $out_main

# Create thumbnail (overwrite enabled)
ffmpeg -y -i $fullPath -vf "scale=600:-1" -q:v 6 -map_metadata -1 $out_tn