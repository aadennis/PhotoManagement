# blogimg.ps1
#
# PURPOSE
#   Convert any input image (PNG, JPEG, TIFF, etc.) into a blog‑ready JPEG,
#   and a matching thumbnail file, denoted by "_tn_" in the thumbnail
#   filename.
#   The main output is resized so the long edge is 2200px, metadata is stripped,
#   and JPEG quality is set to a visually clean ~80%. For tn the long edge 
#   is 600px.
#
#   Resize an input image so the long edge becomes 2200px, convert to JPEG,
#   remove metadata, and save the result into an "output" subfolder located
#   beside the input file.
#
# ARGUMENT CHECKING
#   If no argument is provided, the script prints a short usage message
#   and exits without running ffmpeg.
#
#
# USAGE
#   resize_img_2200.ps1 <inputfile>
#
# EXAMPLE
#       resize_img_2200 C:\photos\image.png
#       .\resize_img_2200.ps1 "(dummy)\blog_pics\MeRun01Enhancedv2.png"
#
# OUTPUT
#       C:\photos\output\image.png_size2200.jpg
#       "(dummy)\blog_pics\output\MeRun01Enhancedv2.png_size2200.jpg"
#
#
# BEHAVIOUR
#   - Creates the "output" folder if it does not already exist.
#   - Always outputs JPEG regardless of input format.
#   - Strips metadata.
#
# PARAMETERS
#   $args[0]
#       The first argument passed to the script.
#       Represents the input filename (with extension).
#
# ffmpeg FLAGS
#   -i <file>
#       Specifies the input file.
#
#   -vf "scale=2200:-1"
#       Video filter (applies to images too).
#       Resizes the image so the *long edge* becomes 2200px.
#       The -1 tells ffmpeg to auto‑calculate the other dimension
#       while preserving aspect ratio.
#
#   -q:v 3
#       JPEG quality level.
#       Lower numbers = higher quality.
#       3 ≈ 80% quality, ideal for web photos (~0.7–1.3 MB).
#
#   -map_metadata -1
#       Removes all metadata (EXIF, GPS, camera info, thumbnails).
#       Reduces file size and protects privacy.
#
# OUTPUT NAMING
#   "$($args[0])_blog.jpg"
#       Takes the original filename and appends "_size2200.jpg".
#
# DEPENDENCIES
#   Requires ffmpeg to be installed and available in PATH.
#
# NOTES
#   - Input format does not matter; output is always JPEG.


if (-not $args[0]) {
    Write-Host "Usage: size2200 <inputfile>"
    exit 1
}

$infile   = $args[0]
$fullPath = Resolve-Path $infile
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
