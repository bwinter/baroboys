# === Config ===
TF_DIR = terraform
PROJECT = europan-world
ZONE = us-west1-b
INSTANCE = europa
USER = bwinter_sc81
REMOTE_SAVE_SCRIPT = /home/$(USER)/baroboys/scripts/teardown/user/save_game.sh
ACTIVE_GAME_FILE = .envrc


.DEFAULT_GOAL := help

# === Terraform ===

.PHONY: init apply destroy plan refresh
init:
	cd $(TF_DIR) && terraform init

plan:
	cd $(TF_DIR) && terraform plan

apply:
	cd $(TF_DIR) && terraform apply

destroy:
	cd $(TF_DIR) && terraform destroy

refresh:
	cd $(TF_DIR) && terraform refresh

# === Game Mode ===
.PHONY: switch mode
switch:
	./scripts/manual/switch_game.sh

mode:
	@grep ACTIVE_GAME $(ACTIVE_GAME_FILE) | cut -d= -f2

# === Save ===
.PHONY: save
save:
	gcloud compute ssh $(USER)@$(INSTANCE) \
		--project=$(PROJECT) \
		--zone=$(ZONE) \
		--command="$(REMOTE_SAVE_SCRIPT)"

# === SSH ===
.PHONY: ssh ssh-iap
ssh:
	gcloud compute ssh $(USER)@$(INSTANCE) \
		--project=$(PROJECT) \
		--zone=$(ZONE)

ssh-iap:
	gcloud compute ssh $(USER)@$(INSTANCE) \
		--project=$(PROJECT) \
		--zone=$(ZONE) \
		--tunnel-through-iap

# === Packer ===

TF_VAR_FILE := terraform/terraform.tfvars
TF_VAR_DEF_FILE := terraform/variables.tf

PACKER_DIR := terraform/packer
PACKER_BUILD_DIR := $(PACKER_DIR)/tmp
PACKER_VARS := terraform.pkrvars.hcl
PACKER_VAR_DEFS := variables.pkr.hcl
PACKER_TEMPLATE := packer.pkr.hcl

build:
	mkdir -p "$(PACKER_BUILD_DIR)/.secrets"
	cp ".secrets/europan-world-terraform-key.json" "$(PACKER_BUILD_DIR)/.secrets/"

	mkdir -p "$(PACKER_BUILD_DIR)/logs/"

	# Sync TF variables
	mkdir -p "$(PACKER_BUILD_DIR)/"
	cp -f "$(PACKER_DIR)/$(PACKER_TEMPLATE)" "$(PACKER_BUILD_DIR)/$(PACKER_TEMPLATE)"
	cp -f "$(TF_VAR_FILE)" "$(PACKER_BUILD_DIR)/$(PACKER_VARS)"
	cp -f "$(TF_VAR_DEF_FILE)" "$(PACKER_BUILD_DIR)/$(PACKER_VAR_DEFS)"

	# Build image
	cd "$(PACKER_BUILD_DIR)" && \
		packer init "$(PACKER_TEMPLATE)" && \
		packer build -on-error=delete -var-file="$(PACKER_VARS)" . \
		| tee "logs/packer-$(USER)-$(shell date +%Y%m%d-%H%M).log"

clean:
	# Delete old custom images
	gcloud compute images list \
	  --project=europan-world \
	  --no-standard-images \
	  --filter="name~^baroboys-base-" \
	  --sort-by="~creationTimestamp" \
	  --format="value(name)" | tail -n +3 | \
	  xargs -I {} gcloud compute images delete {} --project=europan-world --quiet

	# Delete any leftover Packer-created disks
	for zone in $$(gcloud compute disks list --filter="name~'packer-'" --format="value(name,zone)" | awk '{print $$2}' | sort -u); do \
	  for disk in $$(gcloud compute disks list --filter="name~'packer-'" --format="value(name,zone)" | grep "$$zone" | awk '{print $$1}'); do \
	    echo "🗑 Deleting disk $$disk in $$zone..."; \
	    gcloud compute disks delete "$$disk" --zone="$$zone" --quiet; \
	  done; \
	done

# === Help ===
.PHONY: help
help:
	@echo "Common targets:"
	@echo "  make init           - Initialize Terraform"
	@echo "  make plan           - Show Terraform plan"
	@echo "  make apply          - Apply Terraform (build VM)"
	@echo "  make destroy        - Save + destroy VM"
	@echo "  make refresh        - Refresh Terraform state"
	@echo ""
	@echo "  make switch         - Switch game mode (.envrc)"
	@echo "  make mode           - Show current game mode"
	@echo ""
	@echo "  make save           - Save game state (via SSH)"
	@echo ""
	@echo "  make ssh            - SSH into VM"
	@echo "  make ssh-iap        - SSH using IAP tunnel"
	@echo ""
	@echo "  make build          - Build Packer image"
	@echo "  make clean          - Clean Packer image"
