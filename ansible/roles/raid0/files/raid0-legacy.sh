#!/bin/bash

# Automatically detect the number of NVMe drives.
# This requires the 'nvme-cli' package to be installed.
echo "info: detecting NVMe drives..."
num_nvme=$(nvme list | grep -c '^/dev/nvme')

# Exit if no NVMe drives are found.
if [ "$num_nvme" -eq 0 ]; then
    echo "error: no NVMe drives were detected. Exiting."
    exit 1
fi

echo "info: found $num_nvme NVMe drive(s)."

# Get a space-separated list of all NVMe device names.
nvme_devices=$(nvme list | grep '^/dev/nvme' | awk '{print $1}')


# Check if the RAID device already exists.
if [ ! -b /dev/md/ephemeral ]; then
    echo "info: creating md dev"
    # Create the RAID 0 array using all detected NVMe drives.
    mdadm --create /dev/md/ephemeral \
        --force \
        --name=ephemeral \
        --level=0 \
        --raid-devices=$num_nvme \
        $nvme_devices

    if [ $? -ne 0 ]; then
        echo "error: failed to create md dev"
        exit 1
    fi
else
    echo "info: md dev already exists"
fi

udevadm settle

# Check if the RAID device is already formatted.
# blkid exits with 2 if a filesystem is not found.
blkid -p -u filesystem /dev/md/ephemeral > /dev/null 2>&1
res=$?
if [ $res -eq 2 ]; then
    echo "info: creating xfs fs on md dev"
    mkfs.xfs /dev/md/ephemeral
    if [ $? -ne 0 ]; then
        echo "error: failed to create xfs fs on md dev"
        exit 1
    fi
elif [ $res -ne 0 ]; then
    echo "error: failed to probe fs on md dev"
    exit 1
else
    echo "info: md dev is already formatted with an xfs fs"
fi
