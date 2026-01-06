# =======================
# 📦 Config
# =======================
SHELL            := /bin/bash
ENV              ?= prod
GAMES            := barotrauma vrising
PROJECT          := europan-world
ZONE             := us-west1-c
INSTANCE         := europa
USER             := bwinter_sc81
BOOTSTRAP_DIR    := bootstrap
TOOLS_DIR        := scripts/tools

.DEFAULT_GOAL := help

bootstrap: terraform-bootstrap iam-bootstrap

# Barotrauma as default for now.
apply: terraform-apply-barotrauma

destroy: terraform-destroy

# =======================
# 🐍 Flask Admin Panel
# =======================
.PHONY: admin-local admin-logs

admin-local:
	cd $(TOOLS_DIR) && \
	./admin/run_admin_server_local.sh

admin-logs:
	cd $(TOOLS_DIR) && \
	./admin/get_admin_server_logs.sh


# =======================
# 🌍 Terraform
# =======================
TF_DIR        := terraform
TF_BACKEND    := backend/$(ENV).hcl
TF_SHARED     := shared.tfvars

.PHONY: \
	terraform-bootstrap \
	terraform-init \
	terraform-plan \
	terraform-destroy \
	terraform-refresh \
	$(addprefix terraform-apply-, $(GAMES))

# -----------------------
# Bootstrap
# -----------------------
terraform-bootstrap:
	cd $(BOOTSTRAP_DIR) && ./bootstrap_tf_state_bucket.sh

# -----------------------
# Init
# -----------------------
terraform-init:
	cd $(TF_DIR) && terraform init -backend-config=$(TF_BACKEND)

# -----------------------
# Plan / Destroy / Refresh
# -----------------------
terraform-plan: terraform-init
	cd $(TF_DIR) && terraform plan -var-file=shared.tfvars

terraform-destroy: terraform-init
	cd $(TF_DIR) && terraform destroy -var-file=shared.tfvars

terraform-refresh: terraform-init
	cd $(TF_DIR) && terraform refresh -var-file=shared.tfvars

# -----------------------
# Apply (game-specific vars)
# -----------------------
$(foreach game,$(GAMES),\
  $(eval terraform-apply-$(game): terraform-init ; ./$(TF_DIR)/build.sh $(game)))


# =======================
# 🔑 Server / Game Password
# =======================
.PHONY: update-password

update-password:
	cd $(TOOLS_DIR) && \
	./update_password.sh


# =======================
# 🔐 IAM (Service Accounts)
# =======================
.PHONY: iam-bootstrap iam-add-admin

iam-bootstrap:
	echo "✅ Bootstrapping IAM roles..."
	cd $(BOOTSTRAP_DIR) && \
		./bootstrap_vm_runtime_sa.sh

iam-add-admin:
	read -p "Admin email: " EMAIL; \
	cd $(TOOLS_DIR) && \
	./gcp/add_admin.sh $$EMAIL


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
PACKER_DIR       := packer

.PHONY: \
	build \
	build-base-core \
	build-base-admin \
	$(addprefix build-game-, $(GAMES))

build-base-core:
	./$(PACKER_DIR)/build.sh base/core

build-base-admin:
	./$(PACKER_DIR)/build.sh base/admin

$(foreach game,$(GAMES),\
  $(eval build-game-$(game): ; ./$(PACKER_DIR)/build.sh game/$(game)))

build: \
	build-base-core \
	build-base-admin \
	$(addprefix build-game-, $(GAMES))


# =======================
# 🧹 Cleanup
# =======================
.PHONY: clean

clean:
	cd $(TOOLS_DIR) && \
	./gcp/review_and_cleanup.sh

# Git Cleanup Targets
.PHONY: clean-git-pre clean-git-bfg clean-git-post clean-git

clean-git-pre:
	echo "🔍 [print_git_info] Scanning for large blobs and writing deletable list..."
	cd $(TOOLS_DIR) && \
	./clean_git/bfg_pre_cleanup.sh

clean-git-bfg:
	echo "🧹 [bfg_cleanup] Running BFG history rewrite using deletable list..."
	cd $(TOOLS_DIR) && \
	./clean_git/bfg_cleanup.sh

clean-git-post:
	echo "✅ [bfg_post_cleanup] Cloning preview, diffing, pushing cleaned history..."
	cd $(TOOLS_DIR) && \
	./clean_git/bfg_post_cleanup.sh

clean-git: clean-git-pre clean-git-bfg clean-git-post
	echo "🎉 [clean-git] Repo fully cleaned, reviewed, and remote history overwritten (if confirmed)."


# =======================
# 🆘 Help
# =======================
.PHONY: help

help:
	@echo "🛠️  Common Targets:"
	@echo "  make bootstrap                - Bootstraps terraform and iam"
	@echo "  make apply                    - Alias for terraform-apply"
	@echo "  make destroy                  - Alias for terraform-destroy"
	@echo ""

	@echo "🌍 Terraform:"
	@echo "  make terraform-bootstrap      - Bootstrap Terraform Buckets"
	@echo "  make terraform-init           - Initialize Terraform"
	@echo "  make terraform-plan           - Show Terraform plan"
	@echo "  make terraform-apply-<GAME>   - Apply Terraform (build VM)"
	@echo "  make terraform-destroy        - Destroy infrastructure"
	@echo "  make terraform-refresh        - Refresh Terraform state"
	@echo ""

	@echo "🔑 Game / Admin Password"
	@echo "  make update-password          - Modify game and admin password (requires server restart)"
	@echo ""

	@echo "🔐 IAM:"
	@echo "  make iam-bootstrap            - Bootstrap IAM service accounts"
	@echo "  make iam-add-admin            - Add administrator emails (can start VMs)"
	@echo ""

	@echo "🐍 Flask Admin Panel:"
	@echo "  make admin-local              - Run admin server locally"
	@echo "  make admin-logs               - Fetch logs from admin systemd service"
	@echo ""

	@echo "🎮 Game Mode:"
	@echo "  make restart-game             - Trigger remote restart of game"
	@echo "  make save-and-shutdown        - Save game state by triggering shutdown"
	@echo ""

	@echo "🧪 SSH Access:"
	@echo "  make ssh                      - SSH into VM"
	@echo "  make ssh-iap                  - SSH using IAP tunnel"
	@echo ""

	@echo "📦 Packer Builds:"
	@echo "  make build-base-core          - Build base image (core setup)"
	@echo "  make build-base-admin         - Build Admin layer"
	@echo "  make build-game-<GAME>        - Build V Rising Game layer"
	@echo "  make build                    - Build all images"
	@echo "  make clean                    - Review usage and delete unused images and disks"
	@echo ""

	@echo "🧹 Git History Cleanup:"
	@echo "  make clean-git-pre            - Scan repo history and write deletable blobs list"
	@echo "  make clean-git-bfg            - Rewrite repo history using BFG with the deletable list"
	@echo "  make clean-git-post           - Preview, diff, and optionally push cleaned history"
	@echo "  make clean-git                - Full pipeline: pre-check → BFG → post-cleanup workflow"
