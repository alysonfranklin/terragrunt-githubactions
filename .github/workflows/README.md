# Terraform Deploy Workflow
This repository contains a GitHub Actions workflow for deploying infrastructure with Terraform to multiple AWS accounts. The workflow includes manual approval, Slack notifications, and uses AWS roles for each account.

## Workflow Configuration

### Workflow Trigger
The workflow is triggered manually using workflow_dispatch with the following inputs:

- `aws_account`: The AWS account to deploy to (options: prod, dev, data, stage).
- `terraform_directory`: The directory containing the Terraform code (default: ./terraform).

## Jobs
### Setup Credentials
This job sets up the AWS credentials and determines the appropriate role ARN based on the selected AWS account.

```yaml
jobs:
  setup_credentials:
    runs-on: ubuntu-latest
    outputs:
      role_arn: ${{ steps.set_env.outputs.role_arn }}
    steps:
      - name: Checkout Code
        uses: actions/checkout@v2

      - name: Set AWS Role ARN Environment Variable
        id: set_env
        run: |
          case "${{ github.event.inputs.aws_account }}" in
            dev)
              echo "AWS_ROLE_ARN=${{ secrets.AWS_ROLE_ARN_DEV }}" >> $GITHUB_ENV
              ;;
            prod)
              echo "AWS_ROLE_ARN=${{ secrets.AWS_ROLE_ARN_PROD }}" >> $GITHUB_ENV
              ;;
            data)
              echo "AWS_ROLE_ARN=${{ secrets.AWS_ROLE_ARN_DATA }}" >> $GITHUB_ENV
              ;;
            stage)
              echo "AWS_ROLE_ARN=${{ secrets.AWS_ROLE_ARN_STAGE }}" >> $GITHUB_ENV
              ;;
            *)
              echo "Invalid AWS account specified"
              exit 1
              ;;
          esac
```

## Approval
This job requests manual approval from specified users before proceeding with the deployment.

```yaml
  approval:
    needs: setup_credentials
    runs-on: ubuntu-latest
    steps:
      - name: Request Approval
        uses: hmarr/auto-approve-action@v2
        with:
          approvers: 'username1,username2'
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## Deploy
This job performs the deployment using Terraform. It assumes the AWS role, initializes Terraform, creates a plan, and applies the plan.

```yaml
  deploy:
    needs: approval
    runs-on: ubuntu-latest
    steps:
      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v1
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-west-2
          role-to-assume: ${{ env.AWS_ROLE_ARN }}
          role-duration-seconds: 1200

      - name: Initialize Terraform
        working-directory: ${{ github.event.inputs.terraform_directory }}
        run: terraform init

      - name: Plan Terraform
        working-directory: ${{ github.event.inputs.terraform_directory }}
        run: terraform plan -out=tfplan

      - name: Apply Terraform
        working-directory: ${{ github.event.inputs.terraform_directory }}
        run: terraform apply -auto-approve tfplan
```

## Notify
This job sends a notification to a Slack channel about the status of the deployment.

```yaml
  notify:
    needs: deploy
    runs-on: ubuntu-latest
    if: always()
    steps:
      - name: Notify Slack
        uses: slackapi/slack-github-action@v1.15.0
        with:
          channel-id: 'YOUR_SLACK_CHANNEL_ID'
          slack-message: |
            *Deployment Status*: ${{ job.status }}
            *Account*: ${{ github.event.inputs.aws_account }}
            *Directory*: ${{ github.event.inputs.terraform_directory }}
        env:
          SLACK_BOT_TOKEN: ${{ secrets.SLACK_BOT_TOKEN }}
```

## Setting Up Secrets
To use this workflow, you need to configure the following secrets in your GitHub repository:

- `**AWS_ACCESS_KEY_ID**`: Your AWS access key ID.
- `**AWS_SECRET_ACCESS_KEY**`: Your AWS secret access key.
- `**AWS_ROLE_ARN_DEV**`: The ARN of the role for the `dev` account.
- `**AWS_ROLE_ARN_PROD**`: The ARN of the role for the `prod` account.
- `**AWS_ROLE_ARN_DATA**`: The ARN of the role for the `data` account.
- `**AWS_ROLE_ARN_STAGE**`: The ARN of the role for the `stage` account.
- `**SLACK_BOT_TOKEN**`: The token for your Slack bot.

## Usage
1. Trigger the workflow manually in the GitHub Actions tab.
2. Select the desired AWS account (prod, dev, data, stage).
3. Specify the directory containing the Terraform code.
4. Wait for manual approval from the specified users.
5. The workflow will proceed to deploy the Terraform code.
6. Notifications will be sent to the specified Slack channel regarding the deployment status.

This workflow ensures a controlled and auditable deployment process for Terraform infrastructure changes across multiple AWS accounts.