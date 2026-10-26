# Tidy photos

`tidy_photos.sh` sorts files in one directory into year-month folders based on
dates found in their filenames. For example, `IMG_20220207_165203.jpg` is moved
to `2022-02/`.

The script scans only files directly inside the source directory; it does not
scan subdirectories or inspect image metadata.

## Requirements

- Bash 4 or later
- GNU `find` and GNU `date` (the script uses `find -printf` and `date -d`)
- Standard command-line tools: `grep`, `sort`, `mv`, and `mkdir`

This makes GNU/Linux the recommended environment. The default Bash on macOS
and its built-in `find` and `date` may not support the features this script
uses.

## Usage

Run the script with Bash and optionally provide the absolute path to the
directory to organize:

```bash
bash organisation/tidy_photos.sh
bash organisation/tidy_photos.sh "/absolute/path/to/photos"
```

If no directory is provided, the script uses the current working directory.
The source directory must exist, be readable and writable, and must not be
`/`. Run the script from a writable working directory that is also not `/`.

## How it works

1. Scans regular files at the top level of the source directory, in sorted
   filename order. The script itself is skipped.
2. Looks for eight-digit date strings in filenames in `YYYYMMDD` form and
   validates them as calendar dates.
3. Plans to move a file with exactly one valid date into the corresponding
   `YYYY-MM/` folder. For example, a filename containing `20260114` is sorted
   into `2026-01/`.
4. Reports files with no date or only invalid date candidates without moving
   them. If a filename contains more than one valid date, the script aborts
   before creating folders or moving files.
5. Prints a summary and asks for confirmation. Press `y` to proceed; any other
   response cancels the run.

## Dry runs and move limit

These settings are constants near the top of `tidy_photos.sh`, not command-line
options:

```bash
DRY_RUN=1
TEST_LIMIT=999999
```

By default, `DRY_RUN=1`: the script scans files, reports the plan, asks for
confirmation, and prints which folders it would create and files it would
move. It does not create folders or move files, so the source directory remains
unchanged. Confirming a dry run only lets it print the planned operations.

To actually create the folders and move files after confirmation, edit the
script and set `DRY_RUN=0`. Review the plan first; live moves can change the
directory contents, and a destination filename collision may replace an
existing file.

`TEST_LIMIT` caps the number of planned moves processed in one run. To use a
smaller cap, change its value in the script. The script still scans all files
and creates all folders needed by the full plan, even when the move limit
means some files will remain unmoved.

## Important

- Review the plan and summary before switching to live mode and confirming.
- If a destination folder already contains a file with the same name, `mv`
  may replace that existing file. Back up important photos and check for name
  collisions before running in live mode.
- A dry run still prompts for confirmation, but confirmation does not cause
  changes to the filesystem.
