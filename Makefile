# =======================
# 📦 Config
# =======================
SHELL := /bin/bash

# Infrastructure — defer to .envrc (exported by direnv) when available.
# Canonical source: .envrc for shell/Make; terraform/shared.tfvars for Terraform/Packer.
PROJECT      ?= europan-world
ZONE         ?= us-west1-c
GCP_USER     ?= bwinter_sc81

# Game name → VM machine name (lowercase). Used by foreach-generated targets.
machine_name = $(shell echo '$(1)' | tr '[:upper:]' '[:lower:]')

# Games — extend this list when adding a new game.
GAMES := Barotrauma VRising
ENV   ?= prod

# Paths
BOOTSTRAP_DIR := bootstrap
TOOLS_DIR     := scripts/tools
TF_DIR        := terraform
TF_BACKEND    := backend/$(ENV).hcl
TF_SHARED     := shared.tfvars
PACKER_DIR    := packer

# Common command templates for foreach-generated targets.
# $(1) = game name (title case, e.g. VRising)
gcloud_ssh = gcloud compute ssh $(GCP_USER)@$(call machine_name,$(1)) \
	--project=$(PROJECT) --zone=$(ZONE)

tf_in_workspace = cd $(TF_DIR) && \
	terraform workspace select $(call machine_name,$(1))

# Remote systemd commands (used by game-restart and game-shutdown).
REMOTE_RESTART_CMD  := sudo systemctl restart game-startup.service
REMOTE_SHUTDOWN_CMD := sudo systemctl restart game-shutdown.service

.DEFAULT_GOAL := help

bootstrap: terraform-bootstrap iam-bootstrap

apply: $(addprefix terraform-apply-, $(GAMES))

destroy: $(addprefix terraform-destroy-, $(GAMES))


# =======================
# 🌍 Terraform
# =======================
.PHONY: \
	terraform-bootstrap \
	terraform-init \
	terraform-plan \
	terraform-refresh \
	$(addprefix terraform-apply-, $(GAMES)) \
	$(addprefix terraform-destroy-, $(GAMES))

terraform-bootstrap:
	cd $(BOOTSTRAP_DIR) && ./bootstrap_tf_state_bucket.sh

terraform-init:
	cd $(TF_DIR) && terraform init -backend-config=$(TF_BACKEND)

terraform-plan: terraform-init
	cd $(TF_DIR) && terraform plan -var-file=$(TF_SHARED)

terraform-refresh: terraform-init
	cd $(TF_DIR) && terraform refresh -var-file=$(TF_SHARED)

define terraform_apply_recipe
terraform-apply-$(1):
	./$(TF_DIR)/build.sh $(1) $(ENV)
endef
$(foreach game,$(GAMES),$(eval $(call terraform_apply_recipe,$(game))))

define terraform_destroy_recipe
terraform-destroy-$(1): terraform-init
	$(call tf_in_workspace,$(1)) && \
		terraform destroy \
		-var-file=$(TF_SHARED) \
		-var-file=game/$(1).tfvars
endef
$(foreach game,$(GAMES),$(eval $(call terraform_destroy_recipe,$(game))))


# =======================
# 🧱 Packer Builds
# =======================
.PHONY: \
	build \
	build-base-core \
	build-base-admin \
	$(addprefix build-game-, $(GAMES))

build-base-core:
	./$(PACKER_DIR)/build.sh base/core

build-base-admin:
	./$(PACKER_DIR)/build.sh base/admin

define build_game_recipe
build-game-$(1):
	./$(PACKER_DIR)/build.sh game/$(1)
endef
$(foreach game,$(GAMES),$(eval $(call build_game_recipe,$(game))))

build: \
	build-base-core \
	build-base-admin \
	$(addprefix build-game-, $(GAMES))


# =======================
# 🎮 Game
# =======================
.PHONY: \
	$(addprefix game-start-, $(GAMES)) \
	$(addprefix game-stop-, $(GAMES)) \
	$(addprefix game-restart-, $(GAMES)) \
	$(addprefix game-shutdown-, $(GAMES)) \
	$(addprefix game-status-, $(GAMES)) \
	$(addprefix game-ssh-, $(GAMES)) \
	$(addprefix game-ssh-iap-, $(GAMES))

define game_start_recipe
game-start-$(1):
	gcloud compute instances start $(call machine_name,$(1)) \
		--project=$(PROJECT) --zone=$(ZONE)
endef
$(foreach game,$(GAMES),$(eval $(call game_start_recipe,$(game))))

define game_stop_recipe
game-stop-$(1):
	gcloud compute instances stop $(call machine_name,$(1)) \
		--project=$(PROJECT) --zone=$(ZONE)
endef
$(foreach game,$(GAMES),$(eval $(call game_stop_recipe,$(game))))

define game_restart_recipe
game-restart-$(1):
	$(call gcloud_ssh,$(1)) \
		--command="$(REMOTE_RESTART_CMD)"
endef
$(foreach game,$(GAMES),$(eval $(call game_restart_recipe,$(game))))

define game_shutdown_recipe
game-shutdown-$(1):
	$(call gcloud_ssh,$(1)) \
		--command="$(REMOTE_SHUTDOWN_CMD)"
endef
$(foreach game,$(GAMES),$(eval $(call game_shutdown_recipe,$(game))))

define game_status_recipe
game-status-$(1):
	MACHINE_NAME=$(call machine_name,$(1)) \
		$(TOOLS_DIR)/status.sh
endef
$(foreach game,$(GAMES),$(eval $(call game_status_recipe,$(game))))

define game_ssh_recipe
game-ssh-$(1):
	$(call gcloud_ssh,$(1))
endef
$(foreach game,$(GAMES),$(eval $(call game_ssh_recipe,$(game))))

define game_ssh_iap_recipe
game-ssh-iap-$(1):
	$(call gcloud_ssh,$(1)) \
		--tunnel-through-iap
endef
$(foreach game,$(GAMES),$(eval $(call game_ssh_iap_recipe,$(game))))


# =======================
# 🐍 Admin Panel
# =======================
.PHONY: admin-local $(addprefix admin-logs-, $(GAMES)) $(addprefix admin-url-, $(GAMES))

admin-local:
	cd $(TOOLS_DIR) && \
	./admin/run_admin_server_local.sh

define admin_logs_recipe
admin-logs-$(1):
	MACHINE_NAME=$(call machine_name,$(1)) \
		$(TOOLS_DIR)/admin/get_admin_server_logs.sh
endef
$(foreach game,$(GAMES),$(eval $(call admin_logs_recipe,$(game))))

define admin_url_recipe
admin-url-$(1): terraform-init
	$(call tf_in_workspace,$(1)) && \
		terraform output admin_server_url
endef
$(foreach game,$(GAMES),$(eval $(call admin_url_recipe,$(game))))


# =======================
# 🔑 Secrets
# =======================
.PHONY: secret-set-password secret-set-deploy-key

secret-set-password:
	cd $(TOOLS_DIR) && \
	./set_secret.sh

secret-set-deploy-key:
	cd $(TOOLS_DIR) && \
	./set_deploy_key.sh


# =======================
# 🔐 IAM
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
# 🧪 Smoke Test
# =======================
.PHONY: $(addprefix smoke-test-, $(GAMES))

define smoke_test_recipe
smoke-test-$(1):
	./scripts/tools/smoke_test/run.sh --game=$(1)
endef
$(foreach game,$(GAMES),$(eval $(call smoke_test_recipe,$(game))))


# =======================
# 🧹 Cleanup
# =======================
.PHONY: clean clean-git-pre clean-git-bfg clean-git-post clean-git

clean:
	cd $(TOOLS_DIR) && \
	./gcp/review_and_cleanup.sh

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
	@echo "  make bootstrap                       - Bootstraps terraform and iam"
	@echo "  make build                           - Build all Packer images in order"
	@echo "  make apply                           - Apply all games"
	@echo "  make destroy                         - Destroy all games"
	@echo ""

	@echo "🌍 Terraform:"
	@echo "  make terraform-bootstrap             - Bootstrap Terraform state bucket"
	@echo "  make terraform-init                  - Initialize Terraform"
	@echo "  make terraform-plan                  - Show Terraform plan"
	@echo "  make terraform-apply-<GAME>          - Apply Terraform (build VM for game)"
	@echo "  make terraform-destroy-<GAME>        - Destroy game VM"
	@echo "  make terraform-refresh               - Refresh Terraform state"
	@echo ""

	@echo "📦 Packer Builds:"
	@echo "  make build-base-core                 - Build base image (core setup)"
	@echo "  make build-base-admin                - Build admin layer"
	@echo "  make build-game-<GAME>               - Build game image layer"
	@echo ""

	@echo "🎮 Game:"
	@echo "  make game-start-<GAME>               - Start the VM"
	@echo "  make game-stop-<GAME>                - Hard stop (no save — use game-shutdown)"
	@echo "  make game-restart-<GAME>             - Restart game service (keeps VM running)"
	@echo "  make game-shutdown-<GAME>            - Graceful shutdown: save then power off"
	@echo "  make game-status-<GAME>              - Fetch and display VM status"
	@echo "  make game-ssh-<GAME>                 - SSH into VM"
	@echo "  make game-ssh-iap-<GAME>             - SSH using IAP tunnel"
	@echo ""

	@echo "🐍 Admin Panel:"
	@echo "  make admin-local                     - Run admin server locally (macOS only)"
	@echo "  make admin-logs-<GAME>               - Fetch logs from admin systemd service"
	@echo "  make admin-url-<GAME>                - Print the live admin panel URL"
	@echo ""

	@echo "🔑 Secrets:"
	@echo "  make secret-set-password             - Set server password (game, admin, RCON)"
	@echo "  make secret-set-deploy-key           - Generate and store GitHub deploy key"
	@echo ""

	@echo "🔐 IAM:"
	@echo "  make iam-bootstrap                   - Bootstrap IAM service accounts"
	@echo "  make iam-add-admin                   - Add administrator emails (can start VMs)"
	@echo ""

	@echo "🧪 Smoke Test:"
	@echo "  make smoke-test-<GAME>               - Full deploy+verify+destroy smoke test"
	@echo ""

	@echo "🧹 Cleanup:"
	@echo "  make clean                           - Review and delete unused GCP images/disks/IPs"
	@echo "  make clean-git                       - Full pipeline: scan → BFG → push"
