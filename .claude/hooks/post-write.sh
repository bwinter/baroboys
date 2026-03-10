#!/usr/bin/env bash
# Runs after every Edit or Write tool call.
# - .sh files: shellcheck (errors shown to Claude on failure)
# - .tf/.tfvars files: terraform fmt auto-corrects in place silently

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

[[ -z "$FILE_PATH" ]] && exit 0

# Shellcheck bash scripts — exit 2 makes Claude see the errors
if [[ "$FILE_PATH" == *.sh ]]; then
    if ! shellcheck "$FILE_PATH" >&2; then
        exit 2
    fi
fi

# Auto-format terraform — silent, just fixes it
if [[ "$FILE_PATH" == *.tf ]] || [[ "$FILE_PATH" == *.tfvars ]]; then
    terraform fmt "$FILE_PATH" > /dev/null 2>&1 || true
fi

exit 0