#!/usr/bin/env bash

set -euo pipefail

##############################################################################
# Configuration
##############################################################################

DRY_RUN=1 # Set to 1 for dry run, 0 for live run
TEST_LIMIT=999999 # Maximum number of files to move in a single run

##############################################################################
# Global State
##############################################################################

declare -A move_plan=()
declare -A target_dirs=()

declare -a no_date_files=()
declare -a invalid_date_files=()

files_scanned=0
files_valid=0
files_no_date=0
files_invalid=0
files_moved=0
folders_required=0
planned_moves=0

##############################################################################
# Validation
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

##############################################################################
# Date Handling
##############################################################################

extract_candidates() {

    local file=$1

    grep -oE '[12][0-9]{3}[01][0-9][0-3][0-9]' \
        <<<"$file" 2>/dev/null || true
}

is_valid_date() {

    local candidate=$1
    local year month day

    year=${candidate:0:4}
    month=${candidate:4:2}
    day=${candidate:6:2}

    date -d "${year}-${month}-${day}" "+%Y%m%d" 2>/dev/null |
        grep -qx "$candidate"
}

##############################################################################
# File Processing
##############################################################################

process_file() {

    local file=$1

    local -a candidates=()
    local -a valid_dates=()

    local candidate
    local folder
    local date_value

    mapfile -t candidates < <(
        extract_candidates "$file" | sort -u
    )

    for candidate in "${candidates[@]}"; do

        if is_valid_date "$candidate"; then
            valid_dates+=("$candidate")
        fi

    done

    ((files_scanned += 1))

    case ${#valid_dates[@]} in

        0)

            if ((${#candidates[@]} > 0)); then

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

            folder="${date_value:0:4}-${date_value:4:2}"

            move_plan["$file"]="$folder"

            if [[ -z ${target_dirs[$folder]+x} ]]; then
                target_dirs["$folder"]=1
                ((folders_required += 1))
            fi

            ((planned_moves += 1))
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

            for candidate in "${valid_dates[@]}"; do
                echo "    ${candidate:0:4}-${candidate:4:2}-${candidate:6:2}"
            done

            echo
            echo "Aborting. No changes made."

            exit 1
            ;;
    esac
}

##############################################################################
# Scanning
##############################################################################

scan_files() {

    local -a files=()
    script_name=$(basename "$0")

    echo "Scanning current directory..."
    echo

    shopt -s nullglob

    mapfile -t files < <(
        printf '%s\n' * | sort
    )

    for file in "${files[@]}"; do

        [[ $file == "$script_name" ]] && continue
        [[ -f "$file" ]] || continue

        process_file "$file"

    done
}

##############################################################################
# Reporting
##############################################################################

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
    echo "Folders required        : $folders_required"
    echo "Planned moves           : $planned_moves"
    echo "Dry run                 : $([[ $DRY_RUN -eq 1 ]] && echo Yes || echo No)"
    echo "Move limit              : $TEST_LIMIT"

    echo

    if ((folders_required > 0)); then

        echo "Folders to create:"

        for dir in "${!target_dirs[@]}"; do
            echo "    $dir"
        done

        echo
    fi

    if ((files_invalid > 0)); then

        echo "Files containing invalid dates:"

        printf '    %s\n' "${invalid_date_files[@]}"

        echo
    fi

    if ((files_no_date > 0)); then

        echo "Files with no recognised date:"

        printf '    %s\n' "${no_date_files[@]}"

        echo
    fi
}

##############################################################################
# Confirmation
##############################################################################

confirm_proceed() {

    read -rp "Proceed? [y/N] " reply

    [[ $reply =~ ^[Yy]$ ]] || {
        echo
        echo "Cancelled."
        exit 0
    }
}

##############################################################################
# Folder Creation
##############################################################################

create_folders() {

    local dir

    for dir in "${!target_dirs[@]}"; do

        if ((DRY_RUN)); then
            echo "CREATE  : $dir/"
        else
            mkdir -p -- "$dir"
            echo "CREATE  : $dir/"
        fi

    done
}

##############################################################################
# Moves
##############################################################################

move_files() {

    local file
    local dest
    local -a files=()

    if (( planned_moves == 0 )); then
        return 0
    fi

    echo

    mapfile -t files < <(
        printf '%s\n' "${!move_plan[@]}" | sort
    )

    for file in "${files[@]}"; do

        if (( files_moved >= TEST_LIMIT )); then
            break
        fi

        dest=${move_plan[$file]}

        if (( DRY_RUN )); then
            echo "MOVE    : $file -> $dest/"
        else
            echo "MOVE    : $file -> $dest/"
            mv -- "$file" "$dest/"
        fi

        ((files_moved+=1))

    done
}

##############################################################################
# Final Report
##############################################################################

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

##############################################################################
# Main
##############################################################################

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
