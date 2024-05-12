#!/bin/bash
N=$1

if [ ! -b /dev/disk/by-id/md-name-ephemeral ]; then
    echo "info: creating md dev"
    mdadm --create /dev/md127 --name=ephemeral --level=0 --raid-devices=$N /dev/nvme[0-$(($N - 1))]n1
    if [ $? -ne 0 ]; then
        echo "error: failed to create md dev"
        exit 1
    fi
else
    echo "info: md dev already exists"
fi

udevadm settle

blkid -p -u filesystem /dev/disk/by-id/md-name-ephemeral >> /dev/null
res=$?
if [ $res -eq 2 ]; then
    echo "info: creating ext4 fs on md dev"
    mkfs.ext4 /dev/disk/by-id/md-name-ephemeral
    if [ $? -ne 0 ]; then
        echo "error: failed to create ext4 fs on md dev"
        exit 1
    fi
elif [ $res -ne 0 ]; then
    echo "error: failed to probe fs on md dev"
    exit 1
else
    echo "info: md dev is already formatted with an ext4 fs"
fi
