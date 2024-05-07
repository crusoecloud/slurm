# SLURM
This repository is the simplest way to create a high-availability SLURM cluster on Crusoe Cloud.
```
terraform init
terraform apply
```

## Supported Compute Instance Types
This solution supports the following Crusoe Cloud compute instance types:
1. `h100-80gb-sxm-ib`
2. `a100-80gb-sxm-ib`
3. `l40s`
4. `c1a`

## How do I customize the cluster?
By default, this solution will create a high-availability SLURM cluster with 2 `c1a.8x` head nodes and 8 `h100-80gb-sxm.8x` compute nodes. Edit the `main.tf` file to change the compute instance type or count.

## How do I handle a head node outage?
This solution utilizes a secondary head-node that will take over within 10 seconds if the primary head-node stops responding. As long as at least one head-node is still responsive, the cluster will remain usable.

## How do I handle a compute node outage?
When a compute node is rebooted or stops responding for more than 5 minutes, it will be marked as `DOWN`.

```bash
sinfo
PARTITION AVAIL  TIMELIMIT  NODES  STATE NODELIST
batch*       up   infinite      1  down* slurm-compute-node-0
batch*       up   infinite      7   idle slurm-compute-node-[1-7]
```

Once the compute node is back online, the following command can be used to return it to the cluster.
```bash
sudo scontrol update NodeName=slurm-compute-node-0 State=RESUME
```

Once the compute node has been returned to the cluster, it should enter an `IDLE` state.
```bash
sinfo
PARTITION AVAIL  TIMELIMIT  NODES  STATE NODELIST
batch*       up   infinite      8   idle slurm-compute-node-[0-7]
```

## How do I resize the cluster?
To change the number of compute nodes in the cluster, modify the `count` argument within
the `slurm_compute_node` resource in the `main.tf` file and run `terraform apply`.
