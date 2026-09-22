#!/bin/bash

# --------------------------------------------------
# Verify current AWS identity
# --------------------------------------------------

aws sts get-caller-identity \
  --profile masterclass


# --------------------------------------------------
# Generate unique bucket names
# --------------------------------------------------

export UNAME=$(curl -sL https://x41.co/random.php)

echo "$UNAME"

export bucketname="${UNAME}-public-bucket"

echo "$bucketname"


# --------------------------------------------------
# Bucket 1: Public Read/Write ACL
# --------------------------------------------------

aws s3api create-bucket \
  --bucket "$bucketname" \
  --region us-east-1 \
  --profile masterclass

aws s3api put-public-access-block \
  --bucket "$bucketname" \
  --public-access-block-configuration "BlockPublicPolicy=false" \
  --profile masterclass

aws s3api put-bucket-ownership-controls \
  --bucket "$bucketname" \
  --ownership-controls="Rules=[{ObjectOwnership=BucketOwnerPreferred}]" \
  --profile masterclass


# Download exercise files

wget https://aws-masterclass-data.s3.amazonaws.com/session3/boat.jpg
wget https://aws-masterclass-data.s3.amazonaws.com/session3/public.txt


# Upload objects

aws s3api put-object \
  --bucket "$bucketname" \
  --key boat.jpg \
  --body boat.jpg \
  --profile masterclass

aws s3api put-object \
  --bucket "$bucketname" \
  --key public.txt \
  --body public.txt \
  --profile masterclass


# Apply public read/write bucket ACL

aws s3api put-bucket-acl \
  --bucket "$bucketname" \
  --acl public-read-write \
  --profile masterclass


# --------------------------------------------------
# Bucket 2: Public Objects
# --------------------------------------------------

export objbucketname="${bucketname}-public-objects"

aws s3api create-bucket \
  --bucket "$objbucketname" \
  --region us-east-1 \
  --profile masterclass

aws s3api put-public-access-block \
  --bucket "$objbucketname" \
  --public-access-block-configuration "BlockPublicPolicy=false" \
  --profile masterclass

aws s3api put-bucket-ownership-controls \
  --bucket "$objbucketname" \
  --ownership-controls="Rules=[{ObjectOwnership=BucketOwnerPreferred}]" \
  --profile masterclass

aws s3api put-object \
  --bucket "$objbucketname" \
  --key boat.jpg \
  --body boat.jpg \
  --profile masterclass

aws s3api put-object \
  --bucket "$objbucketname" \
  --key public.txt \
  --body public.txt \
  --profile masterclass

aws s3api put-bucket-acl \
  --bucket "$objbucketname" \
  --acl public-read-write \
  --profile masterclass


# Public GetObject bucket policy

aws s3api put-bucket-policy \
  --bucket "$objbucketname" \
  --policy "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Sid\":\"PublicRead\",\"Effect\":\"Allow\",\"Principal\":\"*\",\"Action\":[\"s3:GetObject\"],\"Resource\":[\"arn:aws:s3:::$objbucketname/*\"]}]}" \
  --profile masterclass


# --------------------------------------------------
# Bucket 3: ACL Read/Write Permissions
# --------------------------------------------------

export aclrwbucket="${UNAME}-bucket-acl-rw"

aws s3api create-bucket \
  --bucket "$aclrwbucket" \
  --region us-east-1 \
  --profile masterclass

aws s3api put-bucket-ownership-controls \
  --bucket "$aclrwbucket" \
  --ownership-controls="Rules=[{ObjectOwnership=BucketOwnerPreferred}]" \
  --profile masterclass

aws s3api put-public-access-block \
  --bucket "$aclrwbucket" \
  --public-access-block-configuration "BlockPublicPolicy=false" \
  --profile masterclass

aws s3api put-bucket-acl \
  --bucket "$aclrwbucket" \
  --grant-read-acp uri=http://acs.amazonaws.com/groups/global/AllUsers \
  --grant-write-acp uri=http://acs.amazonaws.com/groups/global/AuthenticatedUsers \
  --profile masterclass


# --------------------------------------------------
# Test write access to class bucket
# --------------------------------------------------

echo "AWS S3 masterclass upload test" > "${UNAME}-upload-test.txt"

aws s3 cp \
  "${UNAME}-upload-test.txt" \
  "s3://session3-masterclass/${UNAME}-upload-test.txt" \
  --profile masterclass


# --------------------------------------------------
# Check server access logging
# --------------------------------------------------

aws s3api get-bucket-logging \
  --bucket "$bucketname" \
  --profile masterclass

aws s3api get-bucket-logging \
  --bucket "$objbucketname" \
  --profile masterclass

aws s3api get-bucket-logging \
  --bucket "$aclrwbucket" \
  --profile masterclass

# This may return AccessDenied depending on permissions
aws s3api get-bucket-logging \
  --bucket session3-masterclass \
  --profile masterclass
