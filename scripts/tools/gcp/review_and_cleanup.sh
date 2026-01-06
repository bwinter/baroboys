#!/usr/bin/env bash
set -euxo pipefail

PROJECT="${PROJECT:-$(gcloud config get-value project 2>/dev/null)}"

if [[ -z "$PROJECT" ]]; then
  echo "ERROR: GCP project not set. Run 'gcloud config set project ...' or export PROJECT."
  exit 1
fi


KEEP_IMAGES=5

echo "Updating \`gcloud\` cloud components"
gcloud components update

echo "=================================================="
echo "📸 Listing all custom images..."
echo '```'
gcloud compute images list \
  --project="$PROJECT" \
  --no-standard-images \
  --format="table[box](name, creationTimestamp)" \
  --sort-by="~creationTimestamp" 2>&1
echo '```'

image_names=$(gcloud compute images list \
  --project="$PROJECT" \
  --no-standard-images \
  --format="value(name)" \
  --sort-by="~creationTimestamp")

image_array=()
while IFS= read -r line; do
  [[ -n "$line" ]] && image_array+=("$line")
done <<< "$image_names"

if [ "${#image_array[@]}" -le "$KEEP_IMAGES" ]; then
  echo "✅ Only ${#image_array[@]} image(s) found. No cleanup needed."
else
  echo -e "\n🧹 Deleting old images (keeping $KEEP_IMAGES most recent)..."
  to_delete=("${image_array[@]:KEEP_IMAGES}")
  for img in "${to_delete[@]}"; do
    echo "🗑 Deleting image: $img"
    gcloud compute images delete "$img" --project="$PROJECT" --quiet || \
      echo "❌ Failed to delete $img — skipping."
  done
fi

# =================== Stopped VMs ===================

echo -e "\n🖥️ Deleting all stopped VMs..."
echo '```'
gcloud compute instances list \
  --project="$PROJECT" \
  --filter="status=TERMINATED" \
  --format="table[box](name, zone, status)" 2>&1
echo '```'

stopped_vms=$(gcloud compute instances list \
  --project="$PROJECT" \
  --filter="status=TERMINATED" \
  --format="csv(name,zone)" 2>/dev/null || true)

if [[ -n "$stopped_vms" ]]; then
  { echo "$stopped_vms" | tail -n +2 || true; } | while IFS=',' read -r name zone; do
    echo "🗑 Deleting stopped VM: $name in $zone"
    gcloud compute instances delete "$name" --zone="$zone" --project="$PROJECT" --quiet || \
      echo "❌ Failed to delete VM $name — skipping."
  done
else
  echo "✅ No stopped VMs found."
fi

# =================== Disks ===================

echo -e "\n📦 Looking for orphaned Packer-created disks..."
echo '```'
gcloud compute disks list \
  --project="$PROJECT" \
  --filter="name~^packer-" \
  --format="table[box](name, zone.basename(), users)" 2>&1
echo '```'

disk_csv=$(gcloud compute disks list \
  --project="$PROJECT" \
  --filter="name~^packer-" \
  --format="csv(name,zone.basename(),users)")

{ echo "$disk_csv" | tail -n +2 || true; } | while IFS=',' read -r name zone users; do
  if [[ -z "$users" || "$users" == "[]" ]]; then
    echo "🗑 Deleting disk $name in zone $zone..."
    gcloud compute disks delete "$name" --zone="$zone" --project="$PROJECT" --quiet || \
      echo "❌ Failed to delete $name — skipping."
  else
    echo "❌ Skipping disk $name — still in use by $users"
  fi
done

# =================== Snapshots ===================

echo -e "\n📼 Deleting all unused snapshots..."
echo '```'
gcloud compute snapshots list \
  --project="$PROJECT" \
  --format="table[box](name, creationTimestamp, diskSizeGb)" 2>&1
echo '```'

snapshot_names=$(gcloud compute snapshots list \
  --project="$PROJECT" \
  --format="value(name)")

if [[ -n "$snapshot_names" ]]; then
  for snap in $snapshot_names; do
    echo "🗑 Deleting snapshot: $snap"
    gcloud compute snapshots delete "$snap" --project="$PROJECT" --quiet || \
      echo "❌ Failed to delete snapshot $snap — skipping."
  done
else
  echo "✅ No snapshots found."
fi

# =================== External IPs ===================

echo -e "\n🌐 Releasing RESERVED but unused static IPs..."
echo '```'
gcloud compute addresses list \
  --project="$PROJECT" \
  --filter="status=RESERVED" \
  --format="table[box](name, address, status, region)" 2>&1
echo '```'

ip_csv=$(gcloud compute addresses list \
  --project="$PROJECT" \
  --filter="status=RESERVED" \
  --format="csv(name,region,address)")

{ echo "$ip_csv" | tail -n +2 || true; } | while IFS=',' read -r name region address; do
  echo "🗑 Releasing static IP: $name ($address) in $region"
  gcloud compute addresses delete "$name" --region="$region" --project="$PROJECT" --quiet || \
    echo "❌ Failed to release $name — skipping."
done


# =================== Empty GCS Buckets ===================

echo -e "\n🪣 Deleting empty GCS buckets..."
bucket_names=$(gsutil ls -p "$PROJECT" 2>/dev/null || true)

if [[ -n "$bucket_names" ]]; then
  for bucket in $bucket_names; do
    if gsutil ls "${bucket}**" | grep -q .; then
      echo "❌ Skipping non-empty bucket: $bucket"
    else
      echo "🗑 Deleting empty bucket: $bucket"
      gsutil rb "$bucket" || echo "❌ Failed to delete bucket $bucket — skipping."
    fi
  done
else
  echo "✅ No GCS buckets found."
fi

# =================== VPC Networks ===================

echo -e "\n🕸️ Deleting custom VPC networks..."
echo '```'
gcloud compute networks list \
  --project="$PROJECT" \
  --filter="NOT autoCreateSubnetworks:true" \
  --format="table[box](name, subnetworks)" 2>&1
echo '```'

vpc_csv=$(gcloud compute networks list \
  --project="$PROJECT" \
  --filter="NOT autoCreateSubnetworks:true" \
  --format="csv(name)")

{ echo "$vpc_csv" | tail -n +2 || true; } | while IFS=',' read -r netname; do
  echo "🗑 Deleting VPC network: $netname"
  gcloud compute networks delete "$netname" --project="$PROJECT" --quiet || \
    echo "❌ Failed to delete network $netname — skipping."
done

echo -e "\n✅ Full cleanup complete."
