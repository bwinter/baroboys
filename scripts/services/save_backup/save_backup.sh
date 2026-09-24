#!/usr/bin/env bash
set -euo pipefail

MANIFEST_PATH="${MANIFEST_PATH:-/etc/baroboys/manifest.json}"
BACKUP_PREFIX="${BACKUP_PREFIX:-recent}"
PROJECT="${GCP_PROJECT:-}"
LOCK_FILE="${LOCK_FILE:-/tmp/baroboys-save-backup.lock}"
UPLOAD="${UPLOAD:-1}"

command -v jq >/dev/null || { echo "ERROR: jq is required" >&2; exit 1; }
command -v tar >/dev/null || { echo "ERROR: tar is required" >&2; exit 1; }
command -v gcloud >/dev/null || { echo "ERROR: gcloud is required" >&2; exit 1; }

if [[ ! -r "$MANIFEST_PATH" ]]; then
  echo "ERROR: manifest not readable: $MANIFEST_PATH" >&2
  exit 1
fi

SAVE_PATH="$(jq -r '.save_path // empty' "$MANIFEST_PATH")"
GAME_NAME="$(jq -r '.game_name // empty' "$MANIFEST_PATH")"
SAVE_NAME="$(jq -r '.save_name // empty' "$MANIFEST_PATH")"

: "${SAVE_PATH:?save_path missing from $MANIFEST_PATH}"
: "${GAME_NAME:?game_name missing from $MANIFEST_PATH}"
: "${SAVE_NAME:?save_name missing from $MANIFEST_PATH}"

if [[ ! -d "$SAVE_PATH" ]]; then
  echo "ERROR: save_path is not a directory: $SAVE_PATH" >&2
  exit 1
fi

if [[ -z "$PROJECT" ]]; then
  PROJECT="$(curl -fsS -H 'Metadata-Flavor: Google' http://metadata.google.internal/computeMetadata/v1/project/project-id)"
fi
BUCKET_NAME="${SAVE_BACKUP_BUCKET:-${PROJECT}-baroboys-save-backups}"

# Systemd serializes normal service starts; this also protects direct/manual calls.
exec 9>"$LOCK_FILE"
flock 9

slugify() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9._-]/-/g'
}

GAME_SLUG="$(slugify "$GAME_NAME")"
SAVE_SLUG="$(slugify "$SAVE_NAME")"
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
OBJECT="gs://${BUCKET_NAME}/${BACKUP_PREFIX}/${GAME_SLUG}/${SAVE_SLUG}/${TIMESTAMP}.tar.gz"
ARCHIVE="$(mktemp --tmpdir "baroboys-save-${GAME_SLUG}-${SAVE_SLUG}.XXXXXX.tar.gz")"
STARTED_AT="$(date +%s)"
trap 'rm -f "$ARCHIVE"' EXIT

SOURCE_BYTES="$(du -sk "$SAVE_PATH" | awk '{print $1 * 1024}')"
tar -C "$SAVE_PATH" -czf "$ARCHIVE" .
gzip -t "$ARCHIVE"
ARCHIVE_BYTES="$(wc -c < "$ARCHIVE" | tr -d ' ')"

RESULT="success"
if [[ "$UPLOAD" == "1" ]]; then
  gcloud storage cp --quiet "$ARCHIVE" "$OBJECT" >/dev/null
else
  RESULT="archive_only"
fi

DURATION_SECONDS=$(( $(date +%s) - STARTED_AT ))
printf 'event=save_backup result=%s game=%s save=%s source_bytes=%s archive_bytes=%s duration_seconds=%s object=%s\n' "$RESULT" "$GAME_NAME" "$SAVE_NAME" "$SOURCE_BYTES" "$ARCHIVE_BYTES" "$DURATION_SECONDS" "$OBJECT"
