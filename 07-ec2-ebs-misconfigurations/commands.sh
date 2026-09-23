#!/bin/bash

# ==================================================
# AWS Security Masterclass - Session 4
# EC2 / EBS Misconfigurations
# ==================================================


# --------------------------------------------------
# LOCAL MAC: Create SSH key pair
# --------------------------------------------------

aws ec2 create-key-pair \
  --key-name ebs-vm-key \
  --query 'KeyMaterial' \
  --output text \
  > ebs-vm-key.pem \
  --region us-east-1 \
  --profile masterclass

chmod 400 ebs-vm-key.pem


# --------------------------------------------------
# LOCAL MAC: Check Free Tier instance types
# --------------------------------------------------

aws ec2 describe-instance-types \
  --filters Name=free-tier-eligible,Values=true \
  --query "InstanceTypes[*].[InstanceType]" \
  --output text \
  --region us-east-1 \
  --profile masterclass


# --------------------------------------------------
# LOCAL MAC: Check AMI architecture
# --------------------------------------------------

aws ec2 describe-images \
  --image-ids ami-0785e47d3610fcf66 \
  --query "Images[0].[Name,Architecture,State]" \
  --output table \
  --region us-east-1 \
  --profile masterclass


# --------------------------------------------------
# LOCAL MAC: Launch EC2 instance
#
# Original exercise used t2.micro.
# t3.micro was used because it was Free Tier eligible
# for this account and compatible with the x86_64 AMI.
# --------------------------------------------------

aws ec2 run-instances \
  --image-id ami-0785e47d3610fcf66 \
  --instance-type t3.micro \
  --key-name ebs-vm-key \
  --tag-specifications \
  'ResourceType=instance,Tags=[{Key=Name,Value=masterclass-ebs-lab-vm}]' \
  --region us-east-1 \
  --profile masterclass


# --------------------------------------------------
# LOCAL MAC: Get public IP of current machine
# --------------------------------------------------

export myip=$(curl -sL https://x41.co/ip.php)

echo "$myip"


# --------------------------------------------------
# LOCAL MAC: Identify EC2 instance
# --------------------------------------------------

instance_id=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=masterclass-ebs-lab-vm" \
  --query "Reservations[].Instances[].InstanceId" \
  --output text \
  --region us-east-1 \
  --profile masterclass)

echo "$instance_id"


# --------------------------------------------------
# LOCAL MAC: Identify security group
# --------------------------------------------------

security_group_id=$(aws ec2 describe-instances \
  --instance-ids "$instance_id" \
  --query "Reservations[].Instances[].SecurityGroups[].GroupId" \
  --output text \
  --region us-east-1 \
  --profile masterclass)

echo "$security_group_id"


# --------------------------------------------------
# LOCAL MAC: Allow SSH only from current public IP
# --------------------------------------------------

aws ec2 authorize-security-group-ingress \
  --group-id "$security_group_id" \
  --protocol tcp \
  --port 22 \
  --cidr "$myip/32" \
  --region us-east-1 \
  --profile masterclass


# --------------------------------------------------
# LOCAL MAC: Retrieve EC2 public IP
# --------------------------------------------------

public_ip=$(aws ec2 describe-instances \
  --instance-ids "$instance_id" \
  --query "Reservations[].Instances[].PublicIpAddress" \
  --output text \
  --region us-east-1 \
  --profile masterclass)

echo "$public_ip"


# --------------------------------------------------
# LOCAL MAC: Connect to instance
# --------------------------------------------------

ssh -i ebs-vm-key.pem ubuntu@"$public_ip"


# ==================================================
# Exit the SSH session before running the AWS CLI
# commands below from the local Mac.
# ==================================================


# --------------------------------------------------
# LOCAL MAC: Identify attached EBS volume
# --------------------------------------------------

aws ec2 describe-instances \
  --instance-ids "<INSTANCE-ID>" \
  --query "Reservations[].Instances[].BlockDeviceMappings[].Ebs[].VolumeId" \
  --region us-east-1 \
  --profile masterclass


# --------------------------------------------------
# LOCAL MAC: Check volume encryption
# --------------------------------------------------

aws ec2 describe-volumes \
  --volume-ids "<VOLUME-ID>" \
  --query "Volumes[].Encrypted" \
  --region us-east-1 \
  --profile masterclass


# --------------------------------------------------
# LOCAL MAC: Check class snapshot encryption
# --------------------------------------------------

aws ec2 describe-snapshots \
  --snapshot-ids "<SNAPSHOT-ID>" \
  --query "Snapshots[].Encrypted" \
  --region us-east-1 \
  --profile masterclass


# ==================================================
# AWS CONSOLE STEPS
#
# 1. Create a volume from the class snapshot.
# 2. Ensure the volume is created in the same
#    Availability Zone as masterclass-ebs-lab-vm.
# 3. Attach the new volume to the EC2 instance.
# ==================================================


# ==================================================
# INSIDE EC2 INSTANCE VIA SSH
# ==================================================


# --------------------------------------------------
# Identify available block devices
# --------------------------------------------------

lsblk


# --------------------------------------------------
# Optional: inspect filesystem information
# --------------------------------------------------

lsblk -f


# --------------------------------------------------
# Mount the partition created from the snapshot
#
# Device name may differ.
# Nitro instances commonly expose EBS devices as
# /dev/nvme...
# --------------------------------------------------

sudo mount /dev/nvme1n1p1 /mnt


# --------------------------------------------------
# Inspect the recovered filesystem
# --------------------------------------------------

ls -la /mnt


# Identify user home directories from the snapshot
ls -ltr /mnt/home


# Inspect users recorded on the original system
cat /mnt/etc/passwd


# Inspect recovered home directories
sudo ls -la /mnt/home/ubuntu
sudo ls -la /mnt/home/mysqladmin


# --------------------------------------------------
# Optional root shell for forensic inspection
# --------------------------------------------------

sudo -i

# Exit root shell when finished:
# exit
