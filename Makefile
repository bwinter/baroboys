# =======================
# 📦 Config
# =======================
TF_DIR           := terraform
PROJECT          := europan-world
ZONE             := us-west1-c
INSTANCE         := europa
USER             := bwinter_sc81
REMOTE_SAVE_SCRIPT := sudo systemctl start vm-shutdown.service
ACTIVE_GAME_FILE := .envrc

TF_VAR_FILE      := terraform/terraform.tfvars
TF_VAR_DEF_FILE  := terraform/variables.tf

.DEFAULT_GOAL := help

dev: vm-refresh

apply: terraform-apply

destroy: terraform-destroy

# =======================
# 🐍 Flask Admin Panel
# =======================
.PHONY: admin-local admin-logs

admin-local:
	scripts/setup/install/flask_server/run_admin_server_local.sh

admin-logs:
	scripts/setup/install/flask_server/get_admin_server_logs.sh


# =======================
# 🌍 Terraform
# =======================
.PHONY: terraform-init terraform-plan terraform-apply terraform-destroy

terraform-init:
	cd $(TF_DIR) && terraform init

terraform-plan:
	cd $(TF_DIR) && terraform plan

terraform-apply:
	cd $(TF_DIR) && terraform apply

terraform-destroy:
	cd $(TF_DIR) && terraform destroy

terraform-refresh:
	cd $(TF_DIR) && terraform refresh


# =======================
# 🔐 IAM (Service Accounts)
# =======================
IAM_TF_DIR     := $(TF_DIR)/iam
IAM_BUILD_DIR  := $(IAM_TF_DIR)/tmp
IAM_VARS       := terraform.tfvars
IAM_VAR_DEFS   := variables.tf

.PHONY: iam-apply iam-destroy

iam-apply:
	@echo "📤 Syncing IAM Terraform files..."
	mkdir -p "$(IAM_BUILD_DIR)/"
	cp -f "$(IAM_TF_DIR)/iam_terraform_service_account.tf" "$(IAM_BUILD_DIR)/"
	cp -f "$(IAM_TF_DIR)/iam_vm_runtime.tf" "$(IAM_BUILD_DIR)/"
	cp -f "$(IAM_TF_DIR)/iam_vrising_admins.tf" "$(IAM_BUILD_DIR)/"
	cp -f "$(TF_VAR_FILE)" "$(IAM_BUILD_DIR)/$(IAM_VARS)"
	cp -f "$(TF_VAR_DEF_FILE)" "$(IAM_BUILD_DIR)/$(IAM_VAR_DEFS)"

	@echo "✅ Applying IAM using GCP user credentials..."
	cd $(IAM_BUILD_DIR) && \
		unset GOOGLE_APPLICATION_CREDENTIALS && \
		terraform init && \
		terraform apply -var-file=$(IAM_VARS)

	gcloud iam service-accounts keys create .secrets/europan-world-terraform-key.json \
	  --iam-account=terraform@europan-world.iam.gserviceaccount.com

iam-destroy:
	@echo "🔥 Destroying IAM with GCP user credentials..."
	cd $(IAM_BUILD_DIR) && \
		unset GOOGLE_APPLICATION_CREDENTIALS && \
		terraform init && \
		terraform destroy -var-file=$(IAM_VARS)

	rm .secrets/europan-world-terraform-key.json


# =======================
# 🎮 Game
# =======================
.PHONY: vm-switch vm-mode vm-refresh

vm-switch:
	scripts/manual/switch_game.sh

vm-mode:
	@grep ACTIVE_GAME $(ACTIVE_GAME_FILE) | cut -d= -f2

vm-refresh:
	scripts/setup/remote_refresh.sh


# =======================
# 💾 Save + Shutdown
# =======================
.PHONY: save-and-shutdown

save-and-shutdown:
	gcloud compute ssh $(USER)@$(INSTANCE) \
		--project=$(PROJECT) \
		--zone=$(ZONE) \
		--command="$(REMOTE_SAVE_SCRIPT)"


# =======================
# 🔐 SSH Access
# =======================
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


# =======================
# 🧱 Packer Builds
# =======================
.PHONY: build-core build-steam build

build-core:
	scripts/packer_build.sh core

build-steam:
	scripts/packer_build.sh steam

build: build-core build-steam


# =======================
# 🧹 Cleanup
# =======================
.PHONY: clean

clean:
	scripts/gcp_review_and_cleanup.sh

# Git Cleanup Targets
.PHONY: clean-git-pre clean-git-bfg clean-git-post clean-git

clean-git-pre:
	echo "🔍 [print_git_info] Scanning for large blobs and writing deletable list..."
	./scripts/manual/clean_git/bfg_pre_cleanup.sh

clean-git-bfg:
	echo "🧹 [bfg_cleanup] Running BFG history rewrite using deletable list..."
	./scripts/manual/clean_git/bfg_cleanup.sh

clean-git-post:
	echo "✅ [bfg_post_cleanup] Cloning preview, diffing, pushing cleaned history..."
	./scripts/manual/clean_git/bfg_post_cleanup.sh

clean-git: clean-git-pre clean-git-bfg clean-git-post
	echo "🎉 [clean-git] Repo fully cleaned, reviewed, and remote history overwritten (if confirmed)."


# =======================
# 🆘 Help
# =======================
.PHONY: help

.PHONY: help

help:
	@echo "🛠️  Common Targets:"
	@echo "  make apply                  - Alias for terraform-apply"
	@echo "  make destroy                - Alias for terraform-destroy"
	@echo ""

	@echo "🌍 Terraform:"
	@echo "  make terraform-init         - Initialize Terraform"
	@echo "  make terraform-plan         - Show Terraform plan"
	@echo "  make terraform-apply        - Apply Terraform (build VM)"
	@echo "  make terraform-destroy      - Destroy infrastructure"
	@echo "  make terraform-refresh      - Refresh Terraform state"
	@echo ""

	@echo "🔐 IAM:"
	@echo "  make iam-apply              - Build and apply IAM service accounts"
	@echo "  make iam-destroy            - Destroy IAM service accounts and keys"
	@echo ""

	@echo "🐍 Flask Admin Panel:"
	@echo "  make admin-local            - Run admin server locally"
	@echo "  make admin-logs             - Fetch logs from admin systemd service"
	@echo ""

	@echo "🎮 Game Mode:"
	@echo "  make vm-switch              - Switch game vm-mode (.envrc)"
	@echo "  make vm-mode                - Show current game vm-mode"
	@echo "  make vm-refresh             - Trigger remote reinstall of game"
	@echo ""

	@echo "🧪 Control:"
	@echo "  make save-and-shutdown      - Save game state by triggering shutdown"
	@echo "  make ssh                    - SSH into VM"
	@echo "  make ssh-iap                - SSH using IAP tunnel"
	@echo ""

	@echo "📦 Packer Builds:"
	@echo "  make build-core             - Build base image (core setup)"
	@echo "  make build-steam            - Build Steam dependencies layer"
	@echo "  make build                  - Build all Packer image layers"
	@echo "  make clean                  - Review usage and delete Packer images and disks"
	@echo ""

	@echo "🧹 Git History Cleanup:"
	@echo "  make clean-git-pre          - Scan repo history and write deletable blobs list"
	@echo "  make clean-git-bfg          - Rewrite repo history using BFG with the deletable list"
	@echo "  make clean-git-post         - Preview, diff, and optionally push cleaned history"
	@echo "  make clean-git              - Full pipeline: pre-check → BFG → post-cleanup workflow"
