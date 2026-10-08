#variables for the monitored and malicious directories, as well as the interval for the antivirus daemon
DIR = monitored_dir
MALICIOUS_DIR = quarantine_dir
INTERVAL = 5 #sleep interval in seconds for the antivirus daemon

setup: #setup target to create the necessary directories. -p flag ensures that the command doesn't throw an error if the directory already exists
	mkdir -p $(MALICIOUS_DIR) 
	mkdir -p $(DIR)

antivirus: setup #before running the antivirus daemon, ensure that the setup target has been executed to create the necessary directories
	./antivirusd.sh $(DIR) $(MALICIOUS_DIR) $(INTERVAL) 

restore: setup #before running the restore tool, ensure that the setup target has been executed to create the necessary directories
	./restore.sh $(DIR) $(MALICIOUS_DIR)

clean: #standard clean target to remove the malicious directory and any temporary files created during the execution of the antivirus daemon or restore tool
	rm -rf $(MALICIOUS_DIR)
	rm -f directory-info.last directory-info.new
