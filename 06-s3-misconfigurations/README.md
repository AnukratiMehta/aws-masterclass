# S3 Misconfigurations and Public Access

## Overview

This exercise explored common Amazon S3 security misconfigurations, including:

- Public bucket ACLs
- Public object access through bucket policies
- S3 Object Ownership settings
- Block Public Access settings
- `AllUsers` and `AuthenticatedUsers` ACL groups
- `READ_ACP` and `WRITE_ACP` permissions
- Testing write access to another S3 bucket
- S3 server access logging
- Google dorking for publicly indexed S3 content

The exercise was performed in a controlled AWS masterclass environment.

---

## Verify AWS Identity

Before beginning, the active AWS CLI identity was verified:

```bash
aws sts get-caller-identity --profile masterclass
```

---

## Generate a Unique Bucket Prefix

A random name was generated to help create globally unique S3 bucket names:

```bash
export UNAME=$(curl -sL https://x41.co/random.php)
echo "$UNAME"
```

A bucket name was then created using the generated value:

```bash
export bucketname="${UNAME}-public-bucket"
```

---

## Bucket 1: Public Read/Write ACL

The first bucket was created to demonstrate an insecure bucket ACL.

```bash
aws s3api create-bucket \
  --bucket "$bucketname" \
  --region us-east-1 \
  --profile masterclass
```

S3 Block Public Access was modified:

```bash
aws s3api put-public-access-block \
  --bucket "$bucketname" \
  --public-access-block-configuration "BlockPublicPolicy=false" \
  --profile masterclass
```

Object Ownership was changed to allow ACL usage:

```bash
aws s3api put-bucket-ownership-controls \
  --bucket "$bucketname" \
  --ownership-controls="Rules=[{ObjectOwnership=BucketOwnerPreferred}]" \
  --profile masterclass
```

Two sample files were downloaded for the exercise:

```bash
wget https://aws-masterclass-data.s3.amazonaws.com/session3/boat.jpg
wget https://aws-masterclass-data.s3.amazonaws.com/session3/public.txt
```

They were uploaded to the bucket:

```bash
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
```

The bucket ACL was then changed to:

```bash
aws s3api put-bucket-acl \
  --bucket "$bucketname" \
  --acl public-read-write \
  --profile masterclass
```

This demonstrates the risk of granting broad public permissions through S3 ACLs.

---

## Bucket 2: Public Objects Using a Bucket Policy

A second bucket was created:

```bash
export objbucketname="${bucketname}-public-objects"
```

The bucket was configured similarly to the first one and the two sample objects were uploaded.

A public bucket policy was then added:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicRead",
      "Effect": "Allow",
      "Principal": "*",
      "Action": [
        "s3:GetObject"
      ],
      "Resource": [
        "arn:aws:s3:::<BUCKET-NAME>/*"
      ]
    }
  ]
}
```

The important parts are:

- `"Principal": "*"` grants the permission to everyone.
- `"Action": "s3:GetObject"` allows objects to be downloaded.
- `"Resource": ".../*"` applies the permission to objects stored inside the bucket.

This demonstrated how a bucket policy can expose S3 objects publicly.

---

## Bucket 3: ACL Control Permissions

A third bucket was created:

```bash
export aclrwbucket="${UNAME}-bucket-acl-rw"
```

It was configured to demonstrate ACL management permissions.

The bucket ACL granted:

- `READ_ACP` to `AllUsers`
- `WRITE_ACP` to `AuthenticatedUsers`

Conceptually:

```text
AllUsers
└── READ_ACP
    └── Can inspect the bucket ACL

AuthenticatedUsers
└── WRITE_ACP
    └── Can modify the bucket ACL
```

An important lesson from this exercise is that `AuthenticatedUsers` does not mean only IAM users belonging to the bucket owner's AWS account.

---

## Testing Write Access to Another Bucket

The class also included a shared bucket:

```text
session3-masterclass
```

Write access was tested using:

```bash
aws s3 cp <LOCAL-FILE> \
  s3://session3-masterclass/<OBJECT-NAME> \
  --profile masterclass
```

This demonstrated that S3 permissions granted through ACLs or policies can allow principals from other AWS accounts to interact with a bucket.

---

## S3 Server Access Logging

Logging configuration was checked using:

```bash
aws s3api get-bucket-logging \
  --bucket <BUCKET-NAME> \
  --profile masterclass
```

An empty response indicates that S3 server access logging is not configured for the bucket.

An `AccessDenied` response does not mean logging is disabled. It means the current AWS identity does not have permission to inspect that bucket's logging configuration.

---

## Google Dorking

The class also demonstrated the concept of using search engines to discover publicly indexed cloud content.

An example query discussed during the exercise was:

```text
site:s3.amazonaws.com (filetype:xls OR filetype:xlsx OR filetype:csv)
```

Publicly accessible S3 content is not necessarily indexed by Google, so a public object may still produce no search results.

The purpose of this exercise was to understand how exposed cloud files may sometimes become discoverable through search engines.

---

## Key Lessons

### Block Public Access

S3 Block Public Access provides an additional protection layer against accidental public exposure.

Disabling these protections can allow public ACLs or policies to take effect.

### Object Ownership

`BucketOwnerEnforced` disables ACLs.

For this lab, `BucketOwnerPreferred` was used so ACL-based security issues could be demonstrated.

### Bucket ACLs and Bucket Policies

S3 access can be granted through multiple mechanisms.

ACLs are an older access-control mechanism, while bucket policies provide resource-based permissions.

### `AllUsers`

`AllUsers` represents anyone, including anonymous internet users.

### `AuthenticatedUsers`

`AuthenticatedUsers` represents authenticated AWS users more broadly and should not be interpreted as users belonging only to the bucket owner's account.

### `READ_ACP` and `WRITE_ACP`

These permissions concern the ACL itself:

- `READ_ACP` allows the ACL to be read.
- `WRITE_ACP` allows the ACL to be modified.

### Encryption and Access Control Are Different

Objects uploaded during the exercise were encrypted at rest by S3.

Encryption at rest does not determine whether an object is publicly accessible. Access is controlled separately through IAM, bucket policies, ACLs, and related settings.

---

## Cleanup

After the exercise, all S3 objects created for the lab were removed and the lab buckets were deleted.

Local copies of the sample files were also removed and are not stored in this repository.

AWS credentials, access keys, and account-specific secrets are not stored in this repository.
