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

#terraform-refresh:
#	cd $(TF_DIR) && terraform refresh


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

clean-git-print-info:
	echo "🔍 Running Git info print-git analysis..."
	./scripts/print_git_info.sh

clean-git-bfg:
	echo "🧹 Running BFG history cleanup..."
	./scripts/bfg_cleanup.sh

clean-git-post:
	echo "🔍 BFG post-cleanup analysis suggestions..."
	./scripts/bfg_post_cleanup.sh

clean-git: clean-git-print-info clean-git-bfg
	echo "🔍 Running Git info print-git analysis..."
	./scripts/print_git_info.sh


# =======================
# 🆘 Help
# =======================
.PHONY: help

help:
	@echo "🛠️  Common targets:"
	@echo "🌍 Full:"
	@echo "  make destroy                - Initialize Terraform"
	@echo "  make apply                  - Show Terraform plan"
	@echo ""
	@echo "🌍 Terraform:"
	@echo "  make terraform-init         - Initialize Terraform"
	@echo "  make terraform-plan         - Show Terraform plan"
	@echo "  make terraform-apply        - Apply Terraform (build VM)"
	@echo "  make terraform-destroy      - Save + destroy VM"
	@echo "  make terraform-refresh      - Refresh Terraform state"
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
