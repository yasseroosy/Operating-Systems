#!/bin/bash

if [ "$#" -ne 3 ]; then #if user doesnt provide 3 args, print error message and exit
    echo "Usage: $0 <dir> <malicious_dir> <interval-secs>" 
    exit 1
fi

#positional arguments assigned to variables for easier reference
DIR=$1
MALICIOUS_DIR=$2
INTERVAL=$3

#files to track the state of the directory
LAST_STATE="directory-info.last"
NEW_STATE="directory-info.new"

scan_directory() {
    for file in "$DIR"/*; do #loop through all files in the directory
        [ -f "$file" ] || continue #skip if not a regular file (directory), || continue means skip to next iteration
        
        filename=$(basename "$file") #this gets only the filename from the full path
        is_malicious=0 #flag to track if the file is malicious, 0 means not malicious, 1 means malicious

        case "$filename" in
            *.exe|*.bat|*.vbs|*.scr|*.ps1) #if the file has a known malicious extension, flag it as malicious
                is_malicious=1
                ;; 
        esac

        if [ $is_malicious -eq 0 ]; then 
            if grep -qiE 'virus|trojan|malware|worm|ransomware' "$file"; then #grep searches for known malicious keywords in the file
                is_malicious=1
            fi
        fi

        if [ $is_malicious -eq 1 ]; then
            echo "$filename is malicious and it is DELETED"
            cp "$file" "$MALICIOUS_DIR/" #copy the malicious file to the quarantine directory
            rm "$file" #remove the malicious file from the original directory
        fi
    done
}

if [ ! -f "$LAST_STATE" ]; then #hecks if our baseline snapshot file does not exist. if it doesn't, this is the very first time the daemon is running
    scan_directory
    ls -l "$DIR" > "$LAST_STATE" #lists the contents of the directory in "long format," which includes file permissions and sizes, and saves it to the baseline snapshot file
fi

while true; do #infinite loop to continuously monitor the directory for changes
    sleep "$INTERVAL"
    
    ls -l "$DIR" > "$NEW_STATE" #after sleeping for the specified interval, it takes a new snapshot of the directory's state and saves it to a temporary file
    
    if ! cmp -s "$LAST_STATE" "$NEW_STATE"; then #compares the baseline snapshot with the new snapshot. If they differ, it means a change has occurred in the directory
        scan_directory
        # Note: The lab instructions say to use `cp directory-info.new directory-info.last`.
        # However, because the scan deletes files, copying the pre-scan state would cause 
        # the next loop to instantly trigger another change detection. We must take a fresh 
        # snapshot of the post-scan directory instead to avoid an infinite loop.
        ls -l "$DIR" > "$LAST_STATE"
    fi
done