# AWS CLI Setup

## Check AWS CLI Installation

```bash
aws --version
```

## Configure AWS CLI Profile

```bash
aws configure --profile masterclass
```

Configuration used:

- Default region: `us-east-1`
- Output format: `json`
- AWS credentials are not stored in this repository.

## Verify Authenticated Identity

```bash
aws sts get-caller-identity --profile masterclass
```

## List AWS Regions

```bash
aws account list-regions --profile masterclass
```
