#!/bin/bash
# DEPRECATED - SEE convert_heic_to_jpg.sh
# -- archive:
# Batch convert heic files to png
# ------------
# cd /mnt/d/...../BashScripts/photo_management
# sudo apt upgrade
# sudo apt-get install imagemagick
# refresh session
# note that required command is [convert], not [magick convert], so on this
# Ubuntu a bit out of date
# https://chatgpt.com/share/66fa7432-b40c-8010-836e-f9ff48eb451e

input_dir="/mnt/c/temp/b"

cd "$input_dir" || exit

for file in *.heic; do
  # Extract the file name without the extension
  filename="${file%.*}"
  
  convert "$file" "${filename}.png"
  
  if [ $? -eq 0 ]; then
    echo "Converted $file to ${filename}.png"
  else
    echo "Failed to convert $file"
  fi
done
