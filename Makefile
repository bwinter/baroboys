# =======================
# 📦 Config
# =======================
PROJECT          := europan-world
ZONE             := us-west1-c
INSTANCE         := europa
USER             := bwinter_sc81
REMOTE_SAVE_SCRIPT := sudo systemctl restart game-shutdown.service

TF_VAR_FILE      := terraform/terraform.tfvars
TF_VAR_DEF_FILE  := terraform/variables.tf

.DEFAULT_GOAL := help

apply: terraform-apply

destroy: terraform-destroy

# =======================
# 🐍 Flask Admin Panel
# =======================
.PHONY: admin-local admin-logs

admin-local:
	scripts/tools/admin/run_admin_server_local.sh

admin-logs:
	scripts/tools/admin/get_admin_server_logs.sh


# =======================
# 🌍 Terraform
# =======================
TF_DIR           := terraform

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
IAM_TF_DIR     := iam
IAM_BUILD_DIR  := $(IAM_TF_DIR)/tmp
IAM_VARS       := terraform.tfvars
IAM_VAR_DEFS   := variables.tf

.PHONY: iam-boostrap iam-import iam-apply iam-refresh iam-destroy

iam-bootstrap:
	@echo "✅ Bootstrapping IAM roles..."
	cd "$(IAM_TF_DIR)" && \
		./bootstrap_terraform_sa.sh && \
		./bootstrap_vm_runtime_sa.sh

iam-import:
	@echo "✅ Importing IAM roles..."
	cd "$(IAM_TF_DIR)" && \
		./import_terraform_sa_roles.sh && \
		./import_vm_runtime_sa_roles.sh

iam-apply:
	@echo "📤 Syncing IAM Terraform files..."
	mkdir -p "$(IAM_BUILD_DIR)/"
	#cp -f "$(IAM_TF_DIR)/iam_terraform_service_account.tf" "$(IAM_BUILD_DIR)/"
	#cp -f "$(IAM_TF_DIR)/iam_vm_runtime.tf" "$(IAM_BUILD_DIR)/"
	cp -f "$(IAM_TF_DIR)/iam_game_admins.tf" "$(IAM_BUILD_DIR)/"
	cp -f "$(TF_VAR_FILE)" "$(IAM_BUILD_DIR)/$(IAM_VARS)"
	cp -f "$(TF_VAR_DEF_FILE)" "$(IAM_BUILD_DIR)/$(IAM_VAR_DEFS)"

	@echo "✅ Applying IAM roles..."
	cd $(IAM_BUILD_DIR) && \
		unset GOOGLE_APPLICATION_CREDENTIALS && \
		terraform init && \
		terraform apply -var-file=$(IAM_VARS)

	gcloud iam service-accounts keys create .secrets/europan-world-terraform-key.json \
	  --iam-account=terraform@europan-world.iam.gserviceaccount.com

iam-refresh:
	@echo "📤 Syncing IAM Terraform files..."
	mkdir -p "$(IAM_BUILD_DIR)/"
	#cp -f "$(IAM_TF_DIR)/iam_terraform_service_account.tf" "$(IAM_BUILD_DIR)/"
	#cp -f "$(IAM_TF_DIR)/iam_vm_runtime.tf" "$(IAM_BUILD_DIR)/"
	cp -f "$(IAM_TF_DIR)/iam_game_admins.tf" "$(IAM_BUILD_DIR)/"
	cp -f "$(TF_VAR_FILE)" "$(IAM_BUILD_DIR)/$(IAM_VARS)"
	cp -f "$(TF_VAR_DEF_FILE)" "$(IAM_BUILD_DIR)/$(IAM_VAR_DEFS)"

	@echo "✅ Refreshing IAM roles..."
	cd $(IAM_BUILD_DIR) && \
		unset GOOGLE_APPLICATION_CREDENTIALS && \
		terraform refresh -var-file=$(IAM_VARS)

iam-destroy:
	@echo "🔥 Destroying IAM roles..."
	cd $(IAM_BUILD_DIR) && \
		unset GOOGLE_APPLICATION_CREDENTIALS && \
		terraform init && \
		terraform destroy -var-file=$(IAM_VARS)

	rm .secrets/europan-world-terraform-key.json


# =======================
# 🎮 Game
# =======================
.PHONY: restart-game save-and-shutdown

restart-game:
	scripts/tools/remote_refresh.sh

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
.PHONY: build-core build-admin build-barotrauma build-vrising build

build-core:
	packer/packer_build.sh core

build-admin:
	packer/packer_build.sh admin

build-barotrauma:
	packer/packer_build.sh barotrauma

build-vrising:
	packer/packer_build.sh vrising

build: build-core build-admin build-barotrauma build-vrising


# =======================
# 🧹 Cleanup
# =======================
.PHONY: clean

clean:
	scripts/tools/gcp/review_and_cleanup.sh

# Git Cleanup Targets
.PHONY: clean-git-pre clean-git-bfg clean-git-post clean-git

clean-git-pre:
	echo "🔍 [print_git_info] Scanning for large blobs and writing deletable list..."
	./scripts/tools/clean_git/bfg_pre_cleanup.sh

clean-git-bfg:
	echo "🧹 [bfg_cleanup] Running BFG history rewrite using deletable list..."
	./scripts/tools/clean_git/bfg_cleanup.sh

clean-git-post:
	echo "✅ [bfg_post_cleanup] Cloning preview, diffing, pushing cleaned history..."
	./scripts/tools/clean_git/bfg_post_cleanup.sh

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
	@echo "  make iam-bootstrap          - Bootstrap IAM service accounts"
	@echo "  make iam-apply              - Apply IAM roles"
	@echo "  make iam-import             - Import IAM roles"
	@echo "  make iam-refresh            - Refresh IAM roles"
	@echo "  make iam-destroy            - Destroy IAM roles"
	@echo ""

	@echo "🐍 Flask Admin Panel:"
	@echo "  make admin-local            - Run admin server locally"
	@echo "  make admin-logs             - Fetch logs from admin systemd service"
	@echo ""

	@echo "🎮 Game Mode:"
	@echo "  make restart game           - Trigger remote restart of game"
	@echo "  make save-and-shutdown      - Save game state by triggering shutdown"
	@echo ""

	@echo "🧪 Control:"
	@echo "  make ssh                    - SSH into VM"
	@echo "  make ssh-iap                - SSH using IAP tunnel"
	@echo ""

	@echo "📦 Packer Builds:"
	@echo "  make build-core             - Build base image (core setup)"
	@echo "  make build-admin            - Build Admin layer"
	@echo "  make build-vrising          - Build V Rising Game layer"
	@echo "  make build-barotraums       - Build Barotrauma Game layer"
	@echo "  make build                  - Build all image layers"
	@echo "  make clean                  - Review usage and delete unused images and disks"
	@echo ""

	@echo "🧹 Git History Cleanup:"
	@echo "  make clean-git-pre          - Scan repo history and write deletable blobs list"
	@echo "  make clean-git-bfg          - Rewrite repo history using BFG with the deletable list"
	@echo "  make clean-git-post         - Preview, diff, and optionally push cleaned history"
	@echo "  make clean-git              - Full pipeline: pre-check → BFG → post-cleanup workflow"
