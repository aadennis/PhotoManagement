#!/usr/bin/env bash

set -euo pipefail

##############################################################################
# Configuration
##############################################################################

DRY_RUN=1
TEST_LIMIT=2

##############################################################################
# State
##############################################################################

declare -A move_plan
declare -A target_dirs

declare -a no_date_files
declare -a invalid_date_files

files_scanned=0
files_valid=0
files_no_date=0
files_invalid=0

##############################################################################
# Scan
##############################################################################

echo "Scanning current directory..."
echo

shopt -s nullglob

for file in *; do

    [[ -f "$file" ]] || continue

    ((files_scanned+=1))

    valid_dates=()
    date_like_found=0

    while read -r candidate; do

        [[ -z "$candidate" ]] && continue

        date_like_found=1

        year=${candidate:0:4}
        month=${candidate:4:2}
        day=${candidate:6:2}

        if date -d "${year}-${month}-${day}" \
            "+%Y%m%d" 2>/dev/null |
            grep -qx "$candidate"
        then
            valid_dates+=("$candidate")
        fi

    done < <(
        grep -oE '[12][0-9]{3}[01][0-9][0-3][0-9]' <<<"$file" | sort -u
    )

    case ${#valid_dates[@]} in

        0)
            if (( date_like_found )); then
                invalid_date_files+=("$file")
                ((files_invalid+=1))
                echo "INVALID : $file"
            else
                no_date_files+=("$file")
                ((files_no_date+=1))
                echo "IGNORE  : $file"
            fi
            ;;

        1)

            date_value=${valid_dates[0]}

            year=${date_value:0:4}
            month=${date_value:4:2}

            folder="${year}-${month}"

            move_plan["$file"]="$folder"
            target_dirs["$folder"]=1

            ((files_valid+=1))

            echo "PLAN    : $file -> $folder/"
            ;;

        *)
            echo
            echo "ERROR: multiple valid dates found"
            echo
            echo "File:"
            echo "    $file"
            echo
            echo "Dates:"

            for d in "${valid_dates[@]}"; do
                echo "    ${d:0:4}-${d:4:2}-${d:6:2}"
            done

            echo
            echo "Aborting. No changes made."
            exit 1
            ;;
    esac

done

##############################################################################
# Summary
##############################################################################

echo
echo "=================================================="
echo "SUMMARY"
echo "=================================================="
echo

echo "Files scanned           : $files_scanned"
echo "Files with valid date   : $files_valid"
echo "Files with no date      : $files_no_date"
echo "Files with invalid date : $files_invalid"
echo "Folders required        : ${#target_dirs[@]}"
echo "Planned moves           : ${#move_plan[@]}"
echo "Dry run                 : $([[ $DRY_RUN -eq 1 ]] && echo Yes || echo No)"
echo "Move limit              : $TEST_LIMIT"

echo

if ((${#target_dirs[@]})); then
    echo "Folders to create:"
    printf '    %s\n' "${!target_dirs[@]}"
    echo
fi

if ((${#invalid_date_files[@]})); then
    echo "Files containing invalid dates:"
    printf '    %s\n' "${invalid_date_files[@]}"
    echo
fi

if ((${#no_date_files[@]})); then
    echo "Files with no recognised date:"
    printf '    %s\n' "${no_date_files[@]}"
    echo
fi

read -rp "Proceed? [y/N] " reply

[[ $reply =~ ^[Yy]$ ]] || {
    echo
    echo "Cancelled."
    exit 0
}

##############################################################################
# Create folders
##############################################################################

for dir in "${!target_dirs[@]}"; do

    if (( DRY_RUN )); then
        echo "CREATE  : $dir/"
    else
        mkdir -p -- "$dir"
        echo "CREATE  : $dir/"
    fi

done

##############################################################################
# Move files
##############################################################################

echo

moved=0

for file in "${!move_plan[@]}"; do

    (( moved >= TEST_LIMIT )) && break

    dest=${move_plan[$file]}

    if (( DRY_RUN )); then
        echo "MOVE    : $file -> $dest/"
    else
        echo "MOVE    : $file -> $dest/"
        mv -- "$file" "$dest/"
    fi

    ((moved+=1))

done

##############################################################################
# Final Summary
##############################################################################

echo
echo "=================================================="
echo "FINAL SUMMARY"
echo "=================================================="
echo

echo "Files moved this run : $moved"

if (( DRY_RUN )); then
    echo "Mode                : DRY RUN"
else
    echo "Mode                : LIVE"
fi