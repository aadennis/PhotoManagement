#!/bin/bash

# linux/WSL2
# Batch convert heic files to jpg
# Typical use-case is for use of iPhone heic photos as 5 second stills in Clipchamp,
# which does not require the high resolution of the originals - jpg is sufficient.
# The conversion uses the ImageMagick/convert command, resizing the images to a 
#    maximum of 2560x1440 pixels.
# It converts all heic files in the input folder to jpg files in the output folder.
# The output folder will be created if it does not exist.
# There is no need to use the -quality option, as the default quality of 75 is 
#   sufficient for most cases.
# ------------
# cd /mnt/d/...../BashScripts/photo_management
# sudo apt upgrade
# sudo apt update
# sudo apt install imagemagick libheif1
# refresh session

# Usage: ./batch_heic_to_jpeg.sh input_folder output_folder
# Input validation
# if [ $# -ne 2 ]; then
#     echo "Usage: $0 <input_folder> <output_folder>"
#     exit 1
# fi
# input_folder="$1"
# output_folder="$2"

input_folder="/mnt/c/temp/downloads/png_out"
output_folder="/mnt/c/temp/downloads/png_out/converted"

mkdir -p "$output_folder"

# Convert each .heic file
for input_file in "$input_folder"/*.heic; do
    if [ -f "$input_file" ]; then
        filename=$(basename "$input_file" .heic)
        output_file="$output_folder/$filename.jpg"
        convert "$input_file" -resize 2560x1440 "$output_file"
        echo "Converted: $input_file -> $output_file"
    fi
done

echo "Batch conversion complete!"
 