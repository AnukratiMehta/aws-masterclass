# Detach policy from limiteduser
aws iam detach-user-policy \
  --user-name limiteduser \
  --policy-arn "arn:aws:iam::<ACCOUNT-ID>:policy/policyversionmanager" \
  --profile masterclass

# Delete non-default policy version
aws iam delete-policy-version \
  --policy-arn "arn:aws:iam::<ACCOUNT-ID>:policy/policyversionmanager" \
  --version-id v1 \
  --profile masterclass

# Delete the customer-managed policy
aws iam delete-policy \
  --policy-arn "arn:aws:iam::<ACCOUNT-ID>:policy/policyversionmanager" \
  --profile masterclass

# Find access keys for the user
aws iam list-access-keys \
  --user-name limiteduser \
  --query "AccessKeyMetadata[].AccessKeyId" \
  --profile masterclass

# Delete the access key
# Replace <ACCESS-KEY-ID> with the key returned above
aws iam delete-access-key \
  --user-name limiteduser \
  --access-key-id "<ACCESS-KEY-ID>" \
  --profile masterclass

# Delete limiteduser
aws iam delete-user \
  --user-name limiteduser \
  --profile masterclass
