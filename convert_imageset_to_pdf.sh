#!/bin/bash

# Batch convert all .heic files in a folder into a single PDF.
# Default source: c:/temp/heicset (WSL style /mnt/c/temp/heicset)
# Output folder: <source>/pdf_saved
# Output filename: YYYYMMDD_HHMMSS.pdf

set -euo pipefail

input_folder="/mnt/c/temp/heicset"
image_type="*.heic"

if [[ $# -ge 1 ]]; then
  input_folder="$1"
fi

if [[ $# -ge 2 ]]; then
  image_type="$2"
fi

if [[ ! -d "$input_folder" ]]; then
  echo "Input folder does not exist: $input_folder" >&2
  exit 1
fi

output_folder="$input_folder/pdf_saved"
mkdir -p "$output_folder"

shopt -s nullglob
files=("$input_folder"/$image_type)
shopt -u nullglob

if [[ ${#files[@]} -eq 0 ]]; then
  echo "No files matching '$image_type' found in $input_folder" >&2
  exit 1
fi

timestamp=$(date +%Y%m%d_%H%M%S)
output_file="$output_folder/${timestamp}.pdf"

max_width=2560
max_height=1440
jpeg_quality=75

desc="Resize ${max_width}x${max_height}, quality ${jpeg_quality}, PDF compression JPEG"

if command -v magick >/dev/null 2>&1; then
  echo "Using ImageMagick 'magick' to create PDF ($desc)..."
  magick convert "$input_folder"/$image_type -resize "${max_width}x${max_height}>" -quality "$jpeg_quality" -compress JPEG "$output_file"
elif command -v convert >/dev/null 2>&1; then
  echo "Using ImageMagick 'convert' to create PDF ($desc)..."
  convert "$input_folder"/$image_type -resize "${max_width}x${max_height}>" -quality "$jpeg_quality" -compress JPEG "$output_file"
else
  echo "Error: ImageMagick 'magick' or 'convert' command not found." >&2
  exit 1
fi

echo "Created PDF: $output_file"
