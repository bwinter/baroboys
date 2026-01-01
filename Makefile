# =======================
# 📦 Config
# =======================
PROJECT          := europan-world
ZONE             := us-west1-c
INSTANCE         := europa
USER             := bwinter_sc81
BOOTSTRAP_DIR    := bootstrap

.DEFAULT_GOAL := help

bootstrap: terraform-bootstrap iam-bootstrap

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
ENV ?= prod
TF_BACKEND=backend/$(ENV).hcl
TF_VARS=$(ENV).tfvars
TF_DIR           := terraform

.PHONY: terraform-bootstrap terraform-init terraform-plan terraform-apply terraform-destroy

terraform-bootstrap:
	cd $(BOOTSTRAP_DIR) && \
		./bootstrap_tf_state_bucket.sh

terraform-init:
	cd $(TF_DIR) && terraform init -backend-config=$(TF_BACKEND)

terraform-plan: terraform-init
	cd $(TF_DIR) && terraform plan -var-file=$(TF_VARS)

terraform-apply: terraform-init
	cd $(TF_DIR) && terraform apply -var-file=$(TF_VARS)

terraform-destroy: terraform-init
	cd $(TF_DIR) && terraform destroy -var-file=$(TF_VARS)

terraform-refresh: terraform-init
	cd $(TF_DIR) && terraform refresh -var-file=$(TF_VARS)


# =======================
# 🔐 IAM (Service Accounts)
# =======================
.PHONY: iam-boostrap

iam-bootstrap:
	@echo "✅ Bootstrapping IAM roles..."
	cd $(BOOTSTRAP_DIR) && \
		./bootstrap_vm_runtime_sa.sh


# =======================
# 🎮 Game
# =======================
REMOTE_STARTUP_SCRIPT := sudo systemctl restart game-startup.service
REMOTE_SHUTDOWN_SCRIPT := sudo systemctl restart game-shutdown.service

.PHONY: restart-game save-and-shutdown

restart-game:
	gcloud compute ssh $(USER)@$(INSTANCE) \
		--project=$(PROJECT) \
		--zone=$(ZONE) \
		--command="$(REMOTE_STARTUP_SCRIPT)"

save-and-shutdown:
	gcloud compute ssh $(USER)@$(INSTANCE) \
		--project=$(PROJECT) \
		--zone=$(ZONE) \
		--command="$(REMOTE_SHUTDOWN_SCRIPT)"

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

help:
	@echo "🛠️  Common Targets:"
	@echo "  make bootstrap              - Bootstraps terraform and iam"
	@echo "  make apply                  - Alias for terraform-apply"
	@echo "  make destroy                - Alias for terraform-destroy"
	@echo ""

	@echo "🌍 Terraform:"
	@echo "  make terraform-bootstrap    - Bootstrap Terraform Buckets"
	@echo "  make terraform-init         - Initialize Terraform"
	@echo "  make terraform-plan         - Show Terraform plan"
	@echo "  make terraform-apply        - Apply Terraform (build VM)"
	@echo "  make terraform-destroy      - Destroy infrastructure"
	@echo "  make terraform-refresh      - Refresh Terraform state"
	@echo ""

	@echo "🔐 IAM:"
	@echo "  make iam-bootstrap          - Bootstrap IAM service accounts"
	@echo ""

	@echo "🐍 Flask Admin Panel:"
	@echo "  make admin-local            - Run admin server locally"
	@echo "  make admin-logs             - Fetch logs from admin systemd service"
	@echo ""

	@echo "🎮 Game Mode:"
	@echo "  make restart-game           - Trigger remote restart of game"
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
