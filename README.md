# Antivirus Daemon Lab

## 1. Overview
This project implements a simplified antivirus daemon using bash shell scripts. It actively monitors a specified directory for file changes using polling. When a change is detected, it scans the directory for files with malicious extensions or content, quarantines flagged files, and removes them from the source directory. An interactive restore tool is also provided to review quarantined files, allowing users to restore false positives or permanently delete genuine threats.

### Folder Hierarchy
.
├── Makefile             # Contains targets to set up directories and run the scripts
├── README.md            # Project documentation
├── antivirusd.sh        # The long-lived monitoring and quarantine daemon
├── restore.sh           # The interactive quarantine management tool
├── monitored_dir/       # (Created via make) The source directory being monitored
└── quarantine_dir/      # (Created via make) The destination for quarantined files