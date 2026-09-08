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
# sudo apt install imagemagick libheif1 libheif-examples libheif-plugin-libde265
# refresh session

# Usage: ./convert_heic_to_jpeg.sh input_folder output_folder
# Input validation
# if [ $# -ne 2 ]; then
#     echo "Usage: $0 <input_folder> <output_folder>"
#     exit 1
# fi
# input_folder="$1"
# output_folder="$2"

# sanity check:
# (HEIC support showing up in ImageMagick does not guarantee HEIC decoding will work. 
# The HEVC decoder plugin (libheif-plugin-libde265) may also be required.
# convert -list format | grep -i HEIC
# heif-convert image.heic test.jpg

# to test a single file when debugging, use eg:
# heif-convert "/mnt/c/temp/OneDrive_2_08-09-2026/20260907_150650682_iOS.heic" test.jpg
# heif-info "/mnt/c/temp/OneDrive_2_08-09-2026/20260907_150650682_iOS.heic"


input_folder="/mnt/c/temp/OneDrive_2_08-09-2026"
output_folder="${input_folder}/converted"

mkdir -p "$output_folder"

find "$input_folder" -maxdepth 1 -type f -iname "*.heic" |
while read -r input_file
do
    filename=$(basename "$input_file")
    filename="${filename%.*}"

    output_file="$output_folder/$filename.jpg"

    convert "$input_file" -resize 2560x1440 "$output_file"

    echo "Converted: $input_file -> $output_file"
done

echo "Batch conversion complete!"

 