# Repository Linting and Manual Checks

The repository keeps validation lightweight and tool-specific. There is no frontend build
system or broad CI framework required for local development. Run the checks that apply to the
files you changed.

## Installing the local tools

On macOS with Homebrew, this project maintains a small set of useful linters:

```bash
make lint-tools
```

The target installs missing tools and repairs an incomplete Homebrew installation. It does not
upgrade every tool on every run. To update them deliberately:

```bash
brew upgrade ruff markdownlint-cli2 checkmake hadolint
```

The tools are local development dependencies, not VM runtime dependencies.

## Manual checks

### Shell

```bash
shellcheck $(git ls-files '*.sh')
```

### Python

Ruff is intentionally run against the small set of tracked Python files:

```bash
ruff check $(git ls-files '*.py')
python3 -m py_compile $(git ls-files '*.py')
```

### Terraform

```bash
terraform fmt -check -recursive terraform
terraform -chdir=terraform validate
```

`terraform validate` requires the local provider plugins to be runnable. If it fails while
loading a provider schema, repair the local installation with:

```bash
terraform -chdir=terraform init -upgrade \
  -reconfigure -backend-config=backend/prod.hcl -input=false
```

Do not treat provider startup errors as configuration findings without checking the error text.

### Packer

```bash
packer fmt -check $(git ls-files '*.pkr.hcl')
```

### JSON and XML

Most tracked `.json` files are machine-readable JSON:

```bash
git ls-files '*.json' | while IFS= read -r file; do jq empty "$file"; done
```

The VRising save metadata files under `VRising/Data/Saves/` are game-owned scalar files despite
their `.json` names, so they are expected exceptions to that scan. XML configuration and mod
files can be checked with:

```bash
for file in $(git ls-files '*.xml'); do xmllint --noout "$file" || exit 1; done
```

### Make

```bash
checkmake Makefile
```

The Makefile is the repository's primary human-facing interface, so Checkmake warnings are worth
reviewing even when they do not indicate a runtime failure.

### Markdown

```bash
git ls-files -z '*.md' | xargs -0 markdownlint-cli2
```

Markdownlint is advisory. Fix clear consistency issues, but do not rewrite documentation broadly
just to satisfy a formatter. The tracked-file command intentionally avoids scanning ignored
working-directory content such as Python virtual environments.

### Nginx

The production Nginx configuration depends on privileged Debian paths and the `www-data` user.
For production or image validation, test it with:

```bash
sudo nginx -t -c "$PWD/scripts/dependencies/nginx/assets/nginx.conf"
```

The local admin workflow generates a host-user-specific configuration at
`/usr/local/etc/nginx/nginx.conf`. After `make admin-local` has installed it, the syntax check
does not require sudo:

```bash
nginx -t -c /usr/local/etc/nginx/nginx.conf
```

### Dockerfile

```bash
hadolint cloud_run/vm_control/Dockerfile
```

Hadolint findings should be weighed against the intentionally small Cloud Run image and its
runtime requirements.

### Admin page

The admin-specific HTML, CSS, and JavaScript checks live in
[`docs/admin/style_guide.md`](admin/style_guide.md).

## Interpreting the checks

These commands are a baseline scan, not a mandatory build pipeline. A new warning is useful
signal, but each result still needs to be interpreted in the context of the artifact: game-owned
save/config formats, generated Packer files, host-specific Nginx settings, and intentionally
minimal Make or frontend code may all have valid exceptions.
