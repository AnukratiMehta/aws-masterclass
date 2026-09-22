# Create IAM group
aws iam create-group \
  --group-name EC2ManagementUsers \
  --profile masterclass

# Attach EC2 Full Access policy to the group
aws iam attach-group-policy \
  --group-name EC2ManagementUsers \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2FullAccess \
  --profile masterclass

# Add user to the group
aws iam add-user-to-group \
  --user-name EC2DescribeOnlyUser \
  --group-name EC2ManagementUsers \
  --profile masterclass

# Check the groups the user belongs to
aws iam list-groups-for-user \
  --user-name EC2DescribeOnlyUser \
  --profile masterclass
