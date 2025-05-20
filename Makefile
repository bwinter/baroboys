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

PACKER_TEMPLATE := baroboys.pkr.hcl

build:
	cd terraform/packer && \
	packer init $(PACKER_TEMPLATE) && \
	packer build -var-file=../terraform.tfvars $(PACKER_TEMPLATE) | tee packer-$$USER-`date +%Y%m%d-%H%M`.log

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
