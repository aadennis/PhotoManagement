#!/usr/bin/env bash

set -euo pipefail

##############################################################################
# Configuration
##############################################################################

DRY_RUN=1
TEST_LIMIT=2

##############################################################################
# Global State
##############################################################################

declare -A move_plan
declare -A target_dirs

declare -a no_date_files
declare -a invalid_date_files

files_scanned=0
files_valid=0
files_no_date=0
files_invalid=0
files_moved=0

##############################################################################
# Functions
##############################################################################

validate_configuration() {

    [[ "$DRY_RUN" =~ ^[01]$ ]] || {
        echo "ERROR: DRY_RUN must be 0 or 1"
        exit 1
    }

    [[ "$TEST_LIMIT" =~ ^[0-9]+$ ]] || {
        echo "ERROR: TEST_LIMIT must be a positive integer"
        exit 1
    }

    ((TEST_LIMIT > 0)) || {
        echo "ERROR: TEST_LIMIT must be greater than zero"
        exit 1
    }

    [[ $PWD != "/" ]] || {
        echo "ERROR: Refusing to run in /"
        exit 1
    }

    [[ -w . ]] || {
        echo "ERROR: Current directory is not writable"
        exit 1
    }
}

extract_valid_dates() {

    local file=$1
    local candidate
    local year
    local month
    local day

    while read -r candidate; do

        year=${candidate:0:4}
        month=${candidate:4:2}
        day=${candidate:6:2}

        if date -d "${year}-${month}-${day}" "+%Y%m%d" \
            2>/dev/null | grep -qx "$candidate"; then
            echo "$candidate"
        fi

    done < <(
        grep -oE '[12][0-9]{3}[01][0-9][0-3][0-9]' \
            <<<"$file" |
            sort -u ||
            true
    )
}

process_file() {

    local file=$1
    local date_value
    local year
    local month
    local folder

    ((files_scanned += 1))

    mapfile -t valid_dates < <(extract_valid_dates "$file" || true)

    local date_like_count=0
    date_like_count=$(
        {
            grep -oE '[12][0-9]{3}[01][0-9][0-3][0-9]' <<<"$file" |
                sort -u
        } 2>/dev/null || true
    )

    date_like_count=$(wc -w <<<"$date_like_count")

    case ${#valid_dates[@]} in

        0)

            if ((date_like_count > 0)); then
                invalid_date_files+=("$file")
                ((files_invalid += 1))
                echo "INVALID : $file"
            else
                no_date_files+=("$file")
                ((files_no_date += 1))
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

            ((files_valid += 1))

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
}

scan_files() {

    echo "Scanning current directory..."
    echo

    shopt -s nullglob

    for file in *; do

        [[ -f "$file" ]] || continue

        process_file "$file"

    done
}

print_summary() {

    echo
    echo "=================================================="
    echo "SUMMARY"
    echo "=================================================="
    echo

    echo "Files scanned           : $files_scanned"
    echo "Files with valid date   : $files_valid"
    echo "Files with no date      : $files_no_date"
    echo "Files with invalid date : $files_invalid"
    folders_required=0
    planned_moves=0

    for _ in "${!target_dirs[@]}"; do
        ((folders_required += 1))
    done

    for _ in "${!move_plan[@]}"; do
        ((planned_moves += 1))
    done

    echo "Folders required        : $folders_required"
    echo "Planned moves           : $planned_moves"
    echo "Dry run                 : $([[ $DRY_RUN -eq 1 ]] && echo Yes || echo No)"
    echo "Move limit              : $TEST_LIMIT"

    echo

    if ((${#folders_required})); then
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
}

confirm_proceed() {

    read -rp "Proceed? [y/N] " reply

    [[ $reply =~ ^[Yy]$ ]] || {
        echo
        echo "Cancelled."
        exit 0
    }
}

create_folders() {

    for dir in "${!target_dirs[@]}"; do

        if ((DRY_RUN)); then
            echo "CREATE  : $dir/"
        else
            mkdir -p -- "$dir"
            echo "CREATE  : $dir/"
        fi

    done
}

move_files() {

    local file
    local dest

    echo

    for file in "${!move_plan[@]}"; do

        ((files_moved >= TEST_LIMIT)) && break

        dest=${move_plan[$file]}

        if ((DRY_RUN)); then
            echo "MOVE    : $file -> $dest/"
        else
            echo "MOVE    : $file -> $dest/"
            mv -- "$file" "$dest/"
        fi

        ((files_moved += 1))

    done
}

print_final_summary() {

    echo
    echo "=================================================="
    echo "FINAL SUMMARY"
    echo "=================================================="
    echo

    echo "Files moved this run : $files_moved"

    if ((DRY_RUN)); then
        echo "Mode                : DRY RUN"
    else
        echo "Mode                : LIVE"
    fi
}

main() {

    validate_configuration
    scan_files
    print_summary
    confirm_proceed
    create_folders
    move_files
    print_final_summary
}

main "$@"
