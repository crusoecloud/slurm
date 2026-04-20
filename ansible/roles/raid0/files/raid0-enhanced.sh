#!/bin/bash
set -euo pipefail

echo "info: detecting NVMe drives by-id..."

# Collect all nvme-* symlinks, exclude partitions
all_symlinks=$(ls -1 /dev/disk/by-id/nvme-* 2>/dev/null | grep -vE '(_[0-9]+$|part[0-9]+$)' || true)

# Deduplicate: keep only one symlink per backing device
nvme_devices=""
seen_targets=""
for symlink in $all_symlinks; do
    target=$(readlink -f "$symlink")
    if ! echo "$seen_targets" | grep -q -w "$target"; then
        nvme_devices="$nvme_devices $symlink"
        seen_targets="$seen_targets $target"
    fi
done

nvme_devices=$(echo "$nvme_devices" | xargs) # trim
num_nvme=$(echo "$nvme_devices" | wc -w)

if [ "$num_nvme" -eq 0 ]; then
    echo "error: no NVMe drives were detected under /dev/disk/by-id/. Exiting."
    exit 1
fi

echo "info: found $num_nvme NVMe drive(s)."
echo "info: devices: $nvme_devices"

if [ ! -b /dev/md/ephemeral ]; then
    echo "info: creating md dev"
    sudo mdadm --create /dev/md/ephemeral \
        --force \
        --name=ephemeral \
        --level=0 \
        --raid-devices=$num_nvme \
        --homehost=any \
        $nvme_devices

    if [ $? -ne 0 ]; then
        echo "error: failed to create md dev"
        exit 1
    fi
else
    echo "info: md dev already exists"
fi

sudo udevadm settle

# Check if the RAID device is already formatted
if ! sudo blkid -p -u filesystem /dev/md/ephemeral > /dev/null 2>&1; then
    echo "info: creating xfs fs on md dev"
    sudo mkfs.xfs /dev/md/ephemeral
else
    echo "info: md dev is already formatted with an xfs fs"
fi



