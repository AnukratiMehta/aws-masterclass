# Create IAM user for S3 access
aws iam create-user \
  --user-name s3ReadUser \
  --tags Key=createdFor,Value=masterclass \
  --profile masterclass

# Attach Amazon S3 Full Access policy
aws iam attach-user-policy \
  --user-name s3ReadUser \
  --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess \
  --profile masterclass

# Create IAM user for EC2 read-only access
aws iam create-user \
  --user-name EC2DescribeOnlyUser \
  --tags Key=CreatedFor,Value=masterclass \
  --profile masterclass

# Attach EC2 Read Only policy
aws iam attach-user-policy \
  --user-name EC2DescribeOnlyUser \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess \
  --profile masterclass

# Check policies attached to s3ReadUser
aws iam list-attached-user-policies \
  --user-name s3ReadUser \
  --profile masterclass

# Check policies attached to EC2DescribeOnlyUser
aws iam list-attached-user-policies \
  --user-name EC2DescribeOnlyUser \
  --profile masterclass
