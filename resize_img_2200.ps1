# blogimg.ps1
#
# PURPOSE
#   Convert any input image (PNG, JPEG, TIFF, etc.) into a blog‑ready JPEG.
#   The output is resized so the long edge is 2200px, metadata is stripped,
#   and JPEG quality is set to a visually clean ~80%.
#
#   Resize an input image so the long edge becomes 2200px, convert to JPEG,
#   remove metadata, and output a blog‑ready file named:
#       <input>_size2200.jpg
#
# ARGUMENT CHECKING
#   If no argument is provided, the script prints a short usage message
#   and exits without running ffmpeg.
#
#
# USAGE
#   resize_img_2200.ps1 <inputfile>
#
#   Example:
#       resize_img_2200 photo.png
#
#   This produces:
#       photo_size2200.jpg
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

ffmpeg -i $args[0] -vf "scale=2200:-1" -q:v 3 -map_metadata -1 "$($args[0])_size2200.jpg"
