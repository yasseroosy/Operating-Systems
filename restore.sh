#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <dir> <malicious_dir>"
    exit 1
fi

DIR=$1
MALICIOUS_DIR=$2

while true; do #infinite loop to continuously allow the user to review and manage quarantined files
    if [ -z "$(ls -A "$MALICIOUS_DIR" 2>/dev/null)" ]; then # ls -A outputs all files/hidden files except . and ..
                                                            # 2>/dev/null suppresses error messages if the directory doesn't exist or is empty
                                                            # -z checks if the output is empty, meaning there are no files in the malicious directory
        echo "No malicious files to review."
        exit 0
    fi

    echo "Quarantined files in $MALICIOUS_DIR:"
    
    files=() #initialize an empty array to hold the list of files in the malicious directory
    i=1
    for f in "$MALICIOUS_DIR"/*; do
        # In case the directory is empty, the glob might just return the literal path + /*
        [ -e "$f" ] || continue #checks if the file exists, if not, skip to the next iteration
        files+=("$f") #append the file to the array of files
        filename=$(basename "$f") 
        echo "$i) $filename"
        ((i++))
    done

    echo "0) Exit tool"    
    read -p "Select a file by number: " file_choice #similar to scanf in c, this reads user input and stores it in the variable file_choice

    if [ "$file_choice" == "0" ]; then #if the user selects 0, exit the tool
        echo "Exiting tool."
        exit 0
    fi

    if ! [[ "$file_choice" =~ ^[0-9]+$ ]] || [ "$file_choice" -lt 1 ] || [ "$file_choice" -gt "${#files[@]}" ]; then #input validation
        echo "Invalid selection. Please try again."
        continue
    fi

    selected_file="${files[$((file_choice-1))]}" #get the selected file from the array based on user input, adjusting for 0-based indexing
    filename=$(basename "$selected_file") #only get the filename from the full path for display purposes

    echo ""
    echo "Options for $filename:"
    echo "1: Restore this file back into $DIR"
    echo "2: Permanently delete this file from $MALICIOUS_DIR"
    echo "3: Leave this file as-is and go back to the list"
    
    read -p "Pick an option (1/2/3): " action_choice

    case "$action_choice" in
        1)
            mv "$selected_file" "$DIR/"
            echo "Restored $filename to $DIR." #mv moves the file back to the original directory, effectively restoring it from quarantine
            ;;
        2)
            rm "$selected_file"
            echo "$filename permanently deleted." #rm removes the file from the malicious directory, permanently deleting it
            ;;
        3)
            #do nothing, just go back to the list of files
            echo "Leaving $filename in quarantine."
            ;;
        *)
            echo "Invalid option. Going back to list."
            ;;
    esac
done