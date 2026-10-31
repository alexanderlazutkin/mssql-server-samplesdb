#  Enrique Catalá:
#    Web:      https://www.clouddataninjas.com
#    Linkedin: https://www.linkedin.com/in/enriquecatala/
#    Support:  https://github.com/sponsors/enriquecatala

.PHONY: create-local-directories download-databases download-all-databases prerequisites build start all clean migrate migrate-verify

# Step 1: Create local directories
create-local-directories:
	@echo "Creating local directories..."
	./prerequisites.create_local_directories.sh

# Step 2: Download databases with INCLUDE_ALL_DATABASES set to 1
download-databases:
	@echo "Downloading databases to './Backups' folder..."
	INCLUDE_ALL_DATABASES=0 ./prerequisites.download_databases.sh

download-all-databases:
	@echo "Downloading ALL databases to './Backups' folder..."
	INCLUDE_ALL_DATABASES=1 ./prerequisites.download_databases.sh

# Prerequisites: Executes the creation of the directory and the download of the databases
prerequisites: create-local-directories download-all-databases

# Step 3: Build the Docker container
build:
	@echo "Building Docker container..."
	docker compose build

# Step 4: Start the Docker container
start:
	@echo "Starting Docker container..."
	docker compose up

# Default make target to run all steps
all:
	@echo "Setting up the environment..."
	$(MAKE) prerequisites	
	$(MAKE) build 
	$(MAKE) start

clean:
	@echo "Cleaning up everything, including databases..."
	docker compose down
	sudo rm -rf ./Backups/AdventureWorks*
	sudo rm -rf ./Backups/WideWorldImporters*
	sudo rm -rf ./local_mountpoint/

migrate:
	@echo "Full pipeline: SQL Server AdventureWorksDW2019 -> CSV -> DuckDB..."
	./migration/bin/migrate.sh all

migrate-verify:
	@echo "Verifying migration (row counts + aggregates)..."
	./migration/.venv/bin/python migration/bin/05_verify.py

