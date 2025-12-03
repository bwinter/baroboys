## ✅ Install `gcloud` on macOS (2024+)

### 🔧 Option 1: Homebrew (recommended)

If you already have Homebrew:

```bash
brew install --cask google-cloud-sdk
```

This will:

* Install the SDK to `/usr/local/Caskroom/google-cloud-sdk/latest/`
* Set up the `gcloud` CLI
* Optionally let you auto-load completions and the `gcloud` path in your shell

---

### 📦 Optional: Enable shell integration

If prompted, you can manually initialize your shell config:

```bash
# For bash
echo 'source "$(brew --prefix)/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.bash.inc"' >> ~/.bash_profile
echo 'source "$(brew --prefix)/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.bash.inc"' >> ~/.bash_profile

# For zsh
echo 'source "$(brew --prefix)/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.zsh.inc"' >> ~/.zshrc
echo 'source "$(brew --prefix)/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.zsh.inc"' >> ~/.zshrc
```

Then restart your shell or `source ~/.zshrc`.

---

### 🔧 Option 2: Manual install (if avoiding Homebrew)

1. Download from:
   [https://cloud.google.com/sdk/docs/install](https://cloud.google.com/sdk/docs/install)

2. Extract:

   ```bash
   tar -xvzf google-cloud-sdk-*.tar.gz
   ./google-cloud-sdk/setup.sh
   ```

3. Restart your shell, or source:

   ```bash
   source ~/google-cloud-sdk/path.bash.inc
   ```

---

## ✅ Post-Install Setup

### Run:

```bash
gcloud init
```

This:

* Authenticates your Google account
* Lets you select the default project and region
* Verifies your install

---

## ✅ Verify Install

```bash
gcloud version
gcloud auth list
gcloud config list
```

---

## 🧼 Uninstall

To uninstall:

```bash
brew uninstall --cask google-cloud-sdk
```

Or delete the SDK directory manually if installed outside Homebrew.