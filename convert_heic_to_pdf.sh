#!/bin/bash

# Batch convert all .heic files in a folder into a single PDF.
# Default source: c:/temp/heicset (WSL style /mnt/c/temp/heicset)
# Output folder: <source>/pdf_saved
# Output filename: YYYYMMDD_HHMMSS.pdf

set -euo pipefail

input_folder="/mnt/c/temp/heicset"

if [[ $# -gt 0 ]]; then
  input_folder="$1"
fi

if [[ ! -d "$input_folder" ]]; then
  echo "Input folder does not exist: $input_folder" >&2
  exit 1
fi

output_folder="$input_folder/pdf_saved"
mkdir -p "$output_folder"

shopt -s nullglob
heic_files=("$input_folder"/*.heic)
shopt -u nullglob

if [[ ${#heic_files[@]} -eq 0 ]]; then
  echo "No .heic files found in $input_folder" >&2
  exit 1
fi

timestamp=$(date +%Y%m%d_%H%M%S)
output_file="$output_folder/${timestamp}.pdf"

if command -v magick >/dev/null 2>&1; then
  echo "Using ImageMagick 'magick' to create PDF..."
  magick convert "$input_folder"/*.heic "$output_file"
elif command -v convert >/dev/null 2>&1; then
  echo "Using ImageMagick 'convert' to create PDF..."
  convert "$input_folder"/*.heic "$output_file"
else
  echo "Error: ImageMagick 'magick' or 'convert' command not found." >&2
  exit 1
fi

echo "Created PDF: $output_file"
