#!/bin/bash

# Function to display usage message
usage() {
    echo "Usage: $(basename "$0") [OPTION]... [FILE]..."
    echo
    echo "Rename files by adding or removing a date-time prefix"
    echo "in the following format yyyymmddThhmmss--"
    echo
    echo "Options:"
    echo "  -u, --undo     Undo the renaming, removing the date-time prefix"
    echo "  -h, --help     Display this help message and exit"
    echo
    echo "Example:"
    echo "  $(basename "$0") file1.txt file2.txt     # Add date-time prefix"
    echo "  $(basename "$0") --undo file1.txt        # Remove date-time prefix"
}

# Check for '--help' or '-h' option
if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    usage
    exit 0
fi

undo_mode=false
if [[ "$1" == "--undo" ]] || [[ "$1" == "-u" ]]; then
    undo_mode=true
    shift # Remove '--undo' from arguments
fi

# Function to format date in "yyyymmddThhmmss" format
format_date() {
    # $1 is the date to format

    # Check whether 'date' command is the coreutils version.
    if date --version >/dev/null 2>&1; then
        # GNU coreutils date
        date -d "$1" +"%Y%m%dT%H%M%S"
    else
        # Presumably macOS date
        date -j -f "%Y-%m-%d %H:%M:%S" "$1" +"%Y%m%dT%H%M%S"
    fi
}

get_creation_date() {
    # $1 is the file from which to get the creation date

    # Check whether 'stat' command is the coreutils version.
    if stat --version >/dev/null 2>&1; then
        # GNU coreutils stat
        creation_date=$(stat -c "%w" "$1" | cut -d '.' -f 1)
        if [[ $creation_date == "-" ]]; then
            # Fallback if birth time is not available
            creation_date=$(stat -c "%y" "$1" | cut -d '.' -f 1)
        fi
    else
        # Presumably macOS stat
        creation_date=$(stat -f "%SB" -t "%F %T" "$1")
    fi
    echo "$creation_date"
}

# Iterating over each argument
for file in "$@"
do
    # Check if the file exists
    if [[ ! -f "$file" ]]; then
        echo "File not found: $file"
        continue
    fi

    # Extracting filename and directory
    filename=$(basename "$file")
    directory=$(dirname "$file")

    if $undo_mode; then
        # Undo mode: Remove the "yyyymmddThhmmss--" prefix if present
        new_filename=$(echo "$filename" | sed -E 's/^[0-9]{8}T[0-9]{6}--//')
        if [[ "$filename" != "$new_filename" ]]; then
            mv "$file" "$directory/$new_filename"
            echo "Renamed back: $file to $directory/$new_filename"
        else
            echo "No prefix to remove for: $filename"
        fi
    else
        # Normal mode: Add the "yyyymmddThhmmss--" prefix
        # ... (rest of the script for adding the prefix remains the same)
        # Please insert the code for adding the prefix here


        # Regex to check the format "yyyymmddThhmmss--"
        if [[ $filename =~ ^[0-9]{8}T[0-9]{6}-- ]]; then
            echo "Filename already in format: $filename"
            continue
        fi

        # Getting creation date in "yyyy-mm-dd HH:MM:SS" format (macOS and Linux compatible)
        creation_date=$(get_creation_date "$file")
        # Formatting the date
        formatted_date=$(format_date "$creation_date")

        # Renaming the file
        mv "$file" "$directory/$formatted_date--$filename"
        echo "Renamed $file to $directory/$formatted_date--$filename"
    fi
done
