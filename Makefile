#variables for the monitored and malicious directories, as well as the interval for the antivirus daemon
DIR = $(HOME)/monitored_dir
MALICIOUS_DIR = $(HOME)/quarantine_dir
INTERVAL = 5 #sleep interval in seconds for the antivirus daemon


antivirus: setup #before running the antivirus daemon, ensure that the setup target has been executed to create the necessary directories
	./antivirusd.sh $(DIR) $(MALICIOUS_DIR) $(INTERVAL) 

restore: setup #before running the restore tool, ensure that the setup target has been executed to create the necessary directories
	./restore.sh $(DIR) $(MALICIOUS_DIR)

setup: #setup target to create the necessary directories. -p flag ensures that the command doesn't throw an error if the directory already exists
	mkdir -p $(MALICIOUS_DIR) 
	mkdir -p $(DIR)

.PHONY: setup antivirus restore #declares the targets as phony, meaning they don't represent actual files. This prevents make from getting confused if a file with the same name as a target exists