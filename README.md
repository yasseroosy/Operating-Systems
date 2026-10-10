# Antivirus Daemon Lab

## 1. Overview
A simplified antivirus written in bash. A daemon watches a directory by polling it at a fixed interval. When something changes, it scans the directory, and any file it flags as malicious is copied to a quarantine directory and removed from the original one. An interactive restore tool lets the user review quarantined files and either restore them (false positives) or delete them permanently. A cron-based version of the scanner is included as a bonus.

## 2. Folder Hierarchy
```
.
├── Makefile             # Targets to create the directories and run the scripts
├── README.md            # Project documentation
├── antivirusd.sh        # Long-running monitoring and quarantine daemon
├── antivirus-cron.sh    # (Bonus) One-shot scanner meant to be run by cron
├── restore.sh           # Interactive quarantine management tool
└── whitelist.txt        # (Created by restore.sh) Files marked as false positives
```
The Makefile also creates these directories in your home folder:
- `~/monitored_dir/`: the directory being monitored
- `~/quarantine_dir/`: where flagged files are moved

## 3. Detection Rules
A file is flagged as malicious if **either** of these is true:
- **Extension:** it ends in `.exe`, `.bat`, `.vbs`, `.scr`, or `.ps1`
- **Content:** it contains one of the words `virus`, `trojan`, `malware`, `worm`, or `ransomware` (case-insensitive, and the word can appear inside a longer word)

Files listed in `whitelist.txt` are skipped.

## 4. Usage

### Using the Makefile
| Command        | What it does |
|----------------|--------------|
| `make setup`     | Creates `~/monitored_dir` and `~/quarantine_dir` |
| `make antivirus` | Runs setup, then starts the daemon (5-second interval) |
| `make restore`   | Runs setup, then opens the restore tool |

### Running the scripts directly
```bash
./antivirusd.sh <dir> <malicious_dir> <interval-secs>
./restore.sh <dir> <malicious_dir>
```
Run both from the project folder so they share the same `whitelist.txt`.

## 5. How It Works

### `antivirusd.sh` (daemon)
1. Scans the directory once at startup.
2. Saves a snapshot of the directory listing (`ls -l --time-style=full-iso`) to `directory-info.last`.
3. Every `<interval>` seconds, it takes a new snapshot (`directory-info.new`) and compares the two with `cmp`.
4. If they differ, it rescans, quarantines any flagged files, and refreshes the baseline snapshot.

A file is removed from the monitored directory only if copying it to quarantine succeeded, so nothing is lost if the copy fails. Stop the daemon with `Ctrl+C`.

### `restore.sh` (restore tool)
Lists the quarantined files with numbers. After you pick one, you can:
1. **Restore** it to the monitored directory. Its name is added to `whitelist.txt` so it won't be quarantined again.
2. **Delete** it permanently from quarantine.
3. **Go back** to the list.

Invalid input is rejected and the menu is shown again. The tool exits when quarantine is empty.

### `antivirus-cron.sh` (bonus)
Uses the same detection rules but scans once and exits, so cron can run it on a schedule. It converts the paths to absolute ones and finds `whitelist.txt` next to the script, because cron doesn't run from the project folder. Every log line is timestamped.

Make the script executable, then add a line like this with `crontab -e` (this one runs every minute):
```
* * * * * /full/path/to/antivirus-cron.sh /full/path/to/monitored_dir /full/path/to/quarantine_dir >> /full/path/to/antivirus.log 2>&1
```

## 6. Testing
1. Start the daemon: `./antivirusd.sh /tmp/t/mon /tmp/t/q 1`
2. In another terminal, create test files:
   ```bash
   echo hi > /tmp/t/mon/bad.exe
   echo "this is a virus" > /tmp/t/mon/bad.txt
   echo hello > /tmp/t/mon/good.txt
   ```
3. After a couple of seconds, `good.txt` should still be in `mon`, and both bad files should be in `q`.
4. Stop the daemon and run `./restore.sh /tmp/t/mon /tmp/t/q`. Restore one file and delete the other, then check both directories and `whitelist.txt`.
