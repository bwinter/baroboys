#!/bin/bash
set -euo pipefail

PROJECT="europan-world"
KEEP_COUNT=2
BUILD_LABEL="baroboys"
LOG_DIVIDER="=================================================="

### 📸 Image Cleanup

print_image_table() {
  echo "$LOG_DIVIDER"
  echo "📸 Listing all custom images..."
  gcloud compute images list \
    --project="$PROJECT" \
    --no-standard-images \
    --format="table[box](name, creationTimestamp)" \
    --sort-by="~creationTimestamp" | tee /dev/stderr
}

clean_old_images() {
  echo -e "\n🧹 Selecting old images to delete (keeping $KEEP_COUNT most recent)..."

  mapfile -t images_to_delete < <(
    gcloud compute images list \
      --project="$PROJECT" \
      --no-standard-images \
      --filter="name~^$BUILD_LABEL" \
      --format="value(name)" \
      --sort-by="~creationTimestamp" | tail -n +$((KEEP_COUNT + 1))
  )

  for image in "${images_to_delete[@]}"; do
    echo "🗑 Deleting image: $image"
    gcloud compute images delete "$image" --project="$PROJECT" --quiet
  done
}

### 📦 Disk Cleanup

print_disk_table() {
  echo -e "\n$LOG_DIVIDER"
  echo "📦 Listing all disks (Packer-related)..."
  gcloud compute disks list \
    --project="$PROJECT" \
    --filter="name~'packer-'" \
    --format="table[box](name, zone.basename(), users)" | tee /dev/stderr
}

clean_orphan_disks() {
  echo -e "\n🧹 Cleaning up unattached Packer disks..."

  deleted=0
  skipped=0

  while IFS=',' read -r name zone attached; do
    if [[ -z "$name" ]]; then continue; fi

    attached=$(echo "$attached" | tr -d '[]"')

    if [[ -n "$attached" ]]; then
      echo "⚠️  Skipping $name in $zone (still attached to $attached)"
      ((skipped++))
      continue
    fi

    echo "🗑 Deleting disk $name in zone $zone..."
    if gcloud compute disks delete "$name" --zone="$zone" --project="$PROJECT" --quiet; then
      ((deleted++))
    else
      echo "❌ Failed to delete $name — skipping."
      ((skipped++))
    fi
  done < <(gcloud compute disks list \
    --project="$PROJECT" \
    --filter="name~'packer-'" \
    --format="csv[no-heading](name,zone.basename(),users)")

  echo -e "\n✅ Disks deleted: $deleted"
  echo "🚫 Disks skipped: $skipped"
}

### 🚀 Execute
print_image_table
clean_old_images
print_disk_table
clean_orphan_disks

echo -e "\n✅ Cleanup complete."
