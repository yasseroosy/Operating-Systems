#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <dir> <malicious_dir>"
    exit 1
fi

DIR=$1
MALICIOUS_DIR=$2

while true; do #infinite loop to continuously allow the user to review and manage quarantined files

    #build the list of quarantined files first
    files=() #initialize an empty array to hold the list of files in the malicious directory
    for f in "$MALICIOUS_DIR"/*; do
        #if the directory is empty (or missing), the glob stays as the literal text "dir/*", so skip it
        [ -f "$f" ] || continue
        files+=("$f") #append the file to the array of files
    done

    #${#files[@]} is the number of elements in the array
    if [ "${#files[@]}" -eq 0 ]; then
        echo "No malicious files to review."
        exit 0
    fi

    echo "Choose a file:"
    for i in "${!files[@]}"; do #${!files[@]} gives the indexes of the array (0, 1, 2, ...)
        echo "$((i+1)): $(basename "${files[$i]}")" #print as "N: name", numbering starts at 1
    done

    #read returns a non-zero status when there is no more input (e.g. input was piped in and ran out,
    #or the user pressed Ctrl+D). Without this check the loop would repeat forever.
    #-r stops read from treating backslashes as escape characters
    if ! read -r file_choice; then
        exit 0
    fi

    #input validation: must be digits only, and between 1 and the number of files
    if ! [[ "$file_choice" =~ ^[0-9]+$ ]] || [ "$file_choice" -lt 1 ] || [ "$file_choice" -gt "${#files[@]}" ]; then
        echo "Invalid selection. Please try again."
        continue
    fi

    #10# forces base 10, otherwise bash reads a number with a leading 0 (like 08) as octal and errors out
    selected_file="${files[$((10#$file_choice - 1))]}" #adjust for 0-based indexing
    filename=$(basename "$selected_file") #only the filename, for display purposes

    echo "For $filename:"
    echo "1: Restore this file back into dir (it was a false positive)"
    echo "2: Permanently delete this file from malicious_dir (it was genuinely malicious)"
    echo "3: Go back"

    if ! read -r action_choice; then
        exit 0
    fi

    case "$action_choice" in
        1)
            #mv moves the file back to the original directory; only log success if mv worked
            if mv "$selected_file" "$DIR/"; then
                echo "Restored $filename to $DIR."
            fi
            ;;
        2)
            #rm removes the file from the malicious directory, permanently deleting it
            if rm "$selected_file"; then
                echo "$filename permanently deleted."
            fi
            ;;
        3)
            #do nothing, just go back to the list of files
            ;;
        *)
            echo "Invalid option. Going back to list."
            ;;
    esac
done