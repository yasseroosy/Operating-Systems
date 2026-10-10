#!/bin/bash

if [ "$#" -ne 2 ]; then #if user doesnt provide 2 args, print error message and exit
echo "Usage: $0 <dir> <malicious_dir>"
exit 1
fi

#readlink -f turns the arguments into absolute paths, because cron does not run from the folder we expect
DIR=$(readlink -f "$1")
MALICIOUS_DIR=$(readlink -f "$2")
whitelist="$(dirname "$(readlink -f "$0")")/whitelist.txt"

#make sure the quarantine directory exists, so cp never fails because of a missing folder
mkdir -p "$MALICIOUS_DIR"

for file in "$DIR"/*; do #loop through all files in the directory
        [ -f "$file" ] || continue #skip if not a regular file (directory), || continue means skip to next iteration

filename=$(basename "$file") #this gets only the filename from the full path

#skip files the user has marked as false positives
#-q quiet, -x match the whole line, -F treat the name as plain text (not a regex)
if [ -f "$whitelist" ] && grep -qxF "$filename" "$whitelist"; then
continue
fi

is_malicious=0 #flag to track if the file is malicious, 0 means not malicious, 1 means malicious

case "$filename" in
*.exe|*.bat|*.vbs|*.scr|*.ps1)
is_malicious=1
        ;;
esac

#-q quiet (only the exit status matters), -i case-insensitive, -E allows | between words
if [ $is_malicious -eq 0 ]; then
if grep -qiE 'virus|trojan|malware|worm|ransomware' "$file"; then
is_malicious=1
fi
fi

if [ $is_malicious -eq 1 ]; then
#cron has no terminal, so the date makes the lines in the log file easier to read
echo "$(date '+%Y-%m-%d %H:%M:%S') $filename is malicious and it is DELETED"
#only delete the original if the copy into quarantine actually succeeded
if cp "$file" "$MALICIOUS_DIR/"; then
rm "$file"
else
echo "Error: could not quarantine $filename, it was left in $DIR" >&2
fi
fi
done