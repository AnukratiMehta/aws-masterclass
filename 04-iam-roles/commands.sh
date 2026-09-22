# Create IAM role that EC2 can assume
aws iam create-role \
  --role-name EC2RDSReadRole \
  --assume-role-policy-document \
  '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"ec2.amazonaws.com"},"Action":"sts:AssumeRole"}]}' \
  --tags Key=CreatedFor,Value=masterclass \
  --profile masterclass

# Attach RDS Full Access
aws iam attach-role-policy \
  --role-name EC2RDSReadRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonRDSFullAccess \
  --profile masterclass

# Attach IAM Full Access
aws iam attach-role-policy \
  --role-name EC2RDSReadRole \
  --policy-arn arn:aws:iam::aws:policy/IAMFullAccess \
  --profile masterclass

# Attach EC2 Full Access
aws iam attach-role-policy \
  --role-name EC2RDSReadRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2FullAccess \
  --profile masterclass

# Check policies attached to the role
aws iam list-attached-role-policies \
  --role-name EC2RDSReadRole \
  --profile masterclass
