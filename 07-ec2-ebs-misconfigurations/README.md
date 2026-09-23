# EC2 and EBS Misconfigurations

## Overview

This exercise explored security risks associated with Amazon EC2, EBS volumes, and publicly accessible EBS snapshots.

The lab covered:

- Creating an EC2 instance
- Creating and using an SSH key pair
- Restricting SSH access using a security group
- Identifying the EBS volume attached to an EC2 instance
- Checking EBS volume encryption
- Investigating a public EBS snapshot
- Creating an EBS volume from a snapshot
- Attaching the volume to an EC2 instance
- Mounting and inspecting the snapshot filesystem
- Identifying users from the recovered filesystem
- Accessing files stored on the snapshot

The exercise was completed in a controlled AWS masterclass environment.

---

## Create an SSH Key Pair

An EC2 key pair was created for SSH access:

```bash
aws ec2 create-key-pair \
  --key-name ebs-vm-key \
  --query 'KeyMaterial' \
  --output text \
  > ebs-vm-key.pem \
  --region us-east-1 \
  --profile masterclass
```

Permissions on the private key were restricted:

```bash
chmod 400 ebs-vm-key.pem
```

The private key is not stored in this repository.

---

## Launch the EC2 Instance

The original lab used `t2.micro`.

For this AWS account, `t2.micro` was not Free Tier eligible, so the available Free Tier instance types were checked:

```bash
aws ec2 describe-instance-types \
  --filters Name=free-tier-eligible,Values=true \
  --query "InstanceTypes[*].[InstanceType]" \
  --output text \
  --region us-east-1 \
  --profile masterclass
```

The AMI architecture was also checked:

```bash
aws ec2 describe-images \
  --image-ids ami-0785e47d3610fcf66 \
  --query "Images[0].[Name,Architecture,State]" \
  --output table \
  --region us-east-1 \
  --profile masterclass
```

The AMI used the `x86_64` architecture, so `t3.micro` was used instead:

```bash
aws ec2 run-instances \
  --image-id ami-0785e47d3610fcf66 \
  --instance-type t3.micro \
  --key-name ebs-vm-key \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=masterclass-ebs-lab-vm}]' \
  --region us-east-1 \
  --profile masterclass
```

---

## Restrict SSH Access

The current public IP address was retrieved:

```bash
export myip=$(curl -sL https://x41.co/ip.php)
```

The EC2 instance ID was retrieved using its Name tag:

```bash
instance_id=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=masterclass-ebs-lab-vm" \
  --query "Reservations[].Instances[].InstanceId" \
  --output text \
  --region us-east-1 \
  --profile masterclass)
```

The security group attached to the instance was identified:

```bash
security_group_id=$(aws ec2 describe-instances \
  --instance-ids "$instance_id" \
  --query "Reservations[].Instances[].SecurityGroups[].GroupId" \
  --output text \
  --region us-east-1 \
  --profile masterclass)
```

SSH access on TCP port 22 was allowed only from the current public IP address:

```bash
aws ec2 authorize-security-group-ingress \
  --group-id "$security_group_id" \
  --protocol tcp \
  --port 22 \
  --cidr "$myip/32" \
  --region us-east-1 \
  --profile masterclass
```

Using `/32` limits access to a single IPv4 address rather than exposing SSH to the entire internet.

---

## Connect to the EC2 Instance

The instance public IP address was retrieved:

```bash
public_ip=$(aws ec2 describe-instances \
  --instance-ids "$instance_id" \
  --query "Reservations[].Instances[].PublicIpAddress" \
  --output text \
  --region us-east-1 \
  --profile masterclass)
```

The instance was accessed using SSH:

```bash
ssh -i ebs-vm-key.pem ubuntu@"$public_ip"
```

AWS CLI management commands continued to be run from the local Mac, while Linux filesystem commands were run inside the EC2 instance.

---

## Identify the EC2 EBS Volume

From the local machine, the EBS volume attached to the EC2 instance was identified:

```bash
aws ec2 describe-instances \
  --instance-ids <INSTANCE-ID> \
  --query "Reservations[].Instances[].BlockDeviceMappings[].Ebs[].VolumeId" \
  --region us-east-1 \
  --profile masterclass
```

The volume encryption status was then checked:

```bash
aws ec2 describe-volumes \
  --volume-ids <VOLUME-ID> \
  --query "Volumes[].Encrypted" \
  --region us-east-1 \
  --profile masterclass
```

The volume returned:

```text
false
```

showing that it was not encrypted.

---

## Investigate the Public Snapshot

The class provided a public EBS snapshot in `us-east-1`.

Its encryption status was checked using:

```bash
aws ec2 describe-snapshots \
  --snapshot-ids <SNAPSHOT-ID> \
  --query "Snapshots[].Encrypted" \
  --region us-east-1 \
  --profile masterclass
```

A new EBS volume was then created from the snapshot using the AWS Console.

The new volume had to be created in the same Availability Zone as the EC2 instance because an EBS volume can only be attached to an EC2 instance in the same Availability Zone.

---

## Attach the Snapshot Volume

The volume created from the snapshot was attached to:

```text
masterclass-ebs-lab-vm
```

After attaching it, the filesystem was investigated from inside the EC2 instance.

---

## Identify the Attached Disk

Inside the EC2 instance:

```bash
lsblk
```

Because the lab instance used the Nitro platform, the attached EBS volume appeared as an NVMe device rather than `/dev/xvdf`.

The disks appeared similar to:

```text
nvme0n1
└─nvme0n1p1    Current EC2 root filesystem

nvme1n1
└─nvme1n1p1    Volume created from the public snapshot
```

The snapshot partition was mounted:

```bash
sudo mount /dev/nvme1n1p1 /mnt
```

After mounting:

```text
/       = filesystem of the current EC2 instance
/mnt    = filesystem recovered from the snapshot
```

---

## Identify Users from the Snapshot

The home directories on the mounted snapshot were inspected:

```bash
ls -ltr /mnt/home
```

This revealed user directories including:

```text
ubuntu
mysqladmin
```

These directories belonged to the system from which the snapshot was created, not to the current EC2 instance.

The snapshot's user database could also be inspected using:

```bash
cat /mnt/etc/passwd
```

---

## Inspect Snapshot Files

Files in the recovered user directories were inspected:

```bash
sudo ls -la /mnt/home/ubuntu
sudo ls -la /mnt/home/mysqladmin
```

A root shell could be opened when required:

```bash
sudo -i
```

This allowed files protected by Linux filesystem permissions to be examined during the lab.

The root shell was exited using:

```bash
exit
```

---

## Key Lessons

### EBS Volumes Are Availability Zone Specific

An EBS volume can only be attached to an EC2 instance in the same Availability Zone.

Snapshots are regional and can be used to create new volumes in different Availability Zones within that region.

### Public Snapshots Can Expose Entire Filesystems

A publicly accessible EBS snapshot can potentially expose much more than a single file.

A snapshot may contain:

- User home directories
- Configuration files
- Application data
- Credentials
- SSH-related files
- Database files
- Sensitive documents

An attacker who can access a public snapshot may be able to:

```text
Public EBS snapshot
        ↓
Create EBS volume
        ↓
Attach volume to EC2
        ↓
Mount filesystem
        ↓
Inspect original system data
```

### Encryption Matters

An unencrypted EBS snapshot can be shared publicly.

Encryption at rest helps reduce the risk of accidental public exposure and protects EBS data using AWS KMS.

### Device Names May Differ

Older EC2 instances may display attached volumes as:

```text
/dev/xvdf
```

Nitro-based EC2 instances commonly expose EBS volumes as NVMe devices such as:

```text
/dev/nvme1n1
```

The Linux device name may therefore differ from the device name selected when attaching the volume in AWS.

### SSH Should Be Restricted

SSH access should not normally be exposed to:

```text
0.0.0.0/0
```

For this lab, access was restricted to the current public IP using a `/32` CIDR.

---

## Cleanup

All EC2, EBS, and key-pair resources created for the lab were removed after completing the exercise.

Private SSH keys, AWS credentials, access keys, recovered sensitive files, and account-specific identifiers are not stored in this repository.
