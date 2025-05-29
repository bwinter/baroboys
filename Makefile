# === Config ===
TF_DIR = terraform
PROJECT = europan-world
ZONE = us-west1-b
INSTANCE = europa
USER = bwinter_sc81
REMOTE_SAVE_SCRIPT = /home/$(USER)/baroboys/scripts/teardown/user/save_game.sh
ACTIVE_GAME_FILE = .envrc

TF_VAR_FILE := terraform/terraform.tfvars
TF_VAR_DEF_FILE := terraform/variables.tf

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

# === IAM ===
IAM_TF_DIR := $(TF_DIR)/iam
IAM_BUILD_DIR := $(IAM_TF_DIR)/tmp
IAM_VARS := terraform.tfvars
IAM_VAR_DEFS := variables.tf

# Use default gcloud credentials instead of GOOGLE_APPLICATION_CREDENTIALS
.PHONY: iam-apply iam-destroy

iam-apply:
	# Sync TF variables
	mkdir -p "$(IAM_BUILD_DIR)/"
	cp -f "$(IAM_TF_DIR)/iam_terraform_service_account.tf" "$(IAM_BUILD_DIR)/iam_terraform_service_account.tf"
	cp -f "$(IAM_TF_DIR)/iam_vm_runtime.tf" "$(IAM_BUILD_DIR)/iam_vm_runtime.tf"
	cp -f "$(IAM_TF_DIR)/iam_vrising_admins.tf" "$(IAM_BUILD_DIR)/iam_vrising_admins.tf"
	cp -f "$(TF_VAR_FILE)" "$(IAM_BUILD_DIR)/$(IAM_VARS)"
	cp -f "$(TF_VAR_DEF_FILE)" "$(IAM_BUILD_DIR)/$(IAM_VAR_DEFS)"

	@echo "✅ Applying IAM changes using your GCP user credentials..."
	cd $(IAM_BUILD_DIR) && \
		unset GOOGLE_APPLICATION_CREDENTIALS && \
		terraform init && \
		terraform apply -var-file=$(IAM_VARS)

iam-destroy:
	@echo "🔥 Destroying IAM changes using your GCP user credentials..."
	cd $(IAM_BUILD_DIR) && \
		unset GOOGLE_APPLICATION_CREDENTIALS && \
		terraform init && \
		terraform destroy -var-file=$(IAM_VARS)


# === Game Mode ===
.PHONY: switch mode
switch:
	./scripts/manual/switch_game.sh

mode:
	@grep ACTIVE_GAME $(ACTIVE_GAME_FILE) | cut -d= -f2

# === Save ===
.PHONY: save-and-shutdown
save-and-shutdown:
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

.PHONY: build-core build-steam build-game build-all

build-core:
	./scripts/packer_build.sh core

build-steam:
	./scripts/packer_build.sh steam

build-game:
	./scripts/packer_build.sh game

build-all: build-core build-steam build-game

.PHONY: clean
clean:
	./scripts/gcp_review_and_cleanup.sh

# === Help ===
.PHONY: help
help:
	@echo "Common targets:"
	@echo ""
	@echo "Terraform:"
	@echo "  make init                   - Initialize Terraform"
	@echo "  make plan                   - Show Terraform plan"
	@echo "  make apply                  - Apply Terraform (build VM)"
	@echo "  make destroy                - Save + destroy VM"
	@echo "  make refresh                - Refresh Terraform state"
	@echo ""
	@echo "Game Mode:"
	@echo "  make switch                 - Switch game mode (.envrc)"
	@echo "  make mode                   - Show current game mode"
	@echo ""
	@echo "Control:"
	@echo "  make save-and-shutdown      - Save game state by triggering shutdown"
	@echo "  make ssh                    - SSH into VM"
	@echo "  make ssh-iap                - SSH using IAP tunnel"
	@echo ""
	@echo "Packer Builds:"
	@echo "  make build-core             - Build base image (core setup)"
	@echo "  make build-steam            - Build Steam dependencies layer"
	@echo "  make build-game             - Build game layer"
	@echo "  make build-all              - Build all Packer image layers"
	@echo "  make clean                  - Review usage and delete Packer images and disks"
