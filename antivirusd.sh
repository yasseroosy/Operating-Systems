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

#make sure the quarantine directory exists, so cp never fails because of a missing folder
#(-p means: don't complain if it already exists)
mkdir -p "$MALICIOUS_DIR"

take_snapshot() {
    #saves a "long format" listing of the directory into the file passed as $1
    #--time-style=full-iso prints the full modification time (down to fractions of a second)
    #instead of only hours:minutes, so a change within the same minute is still detected
    ls -l --time-style=full-iso "$DIR" > "$1"
}

scan_directory() {
    for file in "$DIR"/*; do #loop through all files in the directory
        [ -f "$file" ] || continue #skip if not a regular file (directory), || continue means skip to next iteration

        filename=$(basename "$file") #this gets only the filename from the full path
        is_malicious=0 #flag to track if the file is malicious, 0 means not malicious, 1 means malicious

        case "$filename" in
            *.exe|*.bat|*.vbs|*.scr|*.ps1)
                is_malicious=1
                ;;
        esac

        #-q quiet (only the exit status matters), -i case-insensitive, -E allows | between words
        #grep matches the keyword anywhere, even inside a longer word (e.g. "wormhole" matches "worm")
        if [ $is_malicious -eq 0 ]; then
            if grep -qiE 'virus|trojan|malware|worm|ransomware' "$file"; then
                is_malicious=1
            fi
        fi

        if [ $is_malicious -eq 1 ]; then
            echo "$filename is malicious and it is DELETED"
            #only delete the original if the copy into quarantine actually succeeded,
            #otherwise the file would be lost without being quarantined
            if cp "$file" "$MALICIOUS_DIR/"; then
                rm "$file"
            else
                echo "Error: could not quarantine $filename, it was left in $DIR" >&2 #>&2 sends the message to stderr
            fi
        fi
    done
}

if [ ! -f "$LAST_STATE" ]; then #checks if our baseline snapshot file does not exist. if it doesn't, this is the very first time the daemon is running
    scan_directory
    take_snapshot "$LAST_STATE" #baseline is taken AFTER the scan, so it doesn't list removed files
fi

while true; do #infinite loop to continuously monitor the directory for changes
    sleep "$INTERVAL"

    take_snapshot "$NEW_STATE" #after sleeping, take a new snapshot of the directory's current state

    if ! cmp -s "$LAST_STATE" "$NEW_STATE"; then #compares the baseline snapshot with the new snapshot. If they differ, a change has occurred
        scan_directory
        #regenerate directory-info.last from the directory as it is NOW (after removals).
        #we don't copy directory-info.new into it, because .new was taken before the scan
        take_snapshot "$LAST_STATE"
    fi
done