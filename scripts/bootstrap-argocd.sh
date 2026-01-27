#!/bin/bash
# Bootstrap ArgoCD - run from terraform/config/{cluster-type} after terraform apply as it uses the output
set -euo pipefail

CLUSTER_TYPE="${1:-}"
ENVIRONMENT="${2:-integration}"
SECTOR="${3:-dev}"
REGION="${3:-$(aws configure get region)}"  # default to AWS CLI configured region

if [[ -z "$CLUSTER_TYPE" ]]; then
    echo "Usage: $0 <cluster-type> [environment] [region]"
    echo "       cluster-type: management or regional"
    echo "       environment: dev, staging, prod, etc. (default: integration)"
    echo "       sector: canary, dev, etc. (default: dev)"
    echo "       region: AWS region (default: current AWS CLI region)"
    echo ""
    echo "This script automatically reads terraform.tfvars to extract AWS profile"
    echo "and calls bootstrap-argocd.sh with the correct parameters."
    exit 1
fi

RENDERED_DIR="argocd/rendered/${ENVIRONMENT}/${SECTOR}/${REGION}/"
if [[ ! -d "$RENDERED_DIR" || -z "$(ls -A "$RENDERED_DIR" 2>/dev/null)" ]]; then
    echo "⚠ WARNING: The rendered manifests directory '$RENDERED_DIR' is empty."
    echo "  ArgoCD will not have any values to deploy resources."
    echo "  Please run './argocd/scripts/render.py' after updating '/argocd/config.yaml' for this shard and push the changes to your target branch."
    
    read -p "Do you want to continue anyway? [y/N]: " confirm
    confirm=$(echo "$confirm" | tr '[:upper:]' '[:lower:]')  # convert to lowercase
    if [[ "$confirm" != "y" && "$confirm" != "yes" ]]; then
        echo "Exiting."
        exit 1
    fi
fi

TERRAFORM_DIR="terraform/config/${CLUSTER_TYPE}-cluster"

# Read terraform outputs
cd ${TERRAFORM_DIR}/

OUTPUTS=$(terraform output -json)

ECS_CLUSTER_ARN=$(echo "$OUTPUTS" | jq -r '.ecs_cluster_arn.value')
TASK_DEFINITION_ARN=$(echo "$OUTPUTS" | jq -r '.ecs_task_definition_arn.value')
CLUSTER_NAME=$(echo "$OUTPUTS" | jq -r '.cluster_name.value')
PRIVATE_SUBNETS=$(echo "$OUTPUTS" | jq -r '.private_subnets.value[]' | tr '\n' ',' | sed 's/,$//')
BOOTSTRAP_SECURITY_GROUP=$(echo "$OUTPUTS" | jq -r '.bootstrap_security_group_id.value')
LOG_GROUP=$(echo "$OUTPUTS" | jq -r '.bootstrap_log_group_name.value')
REPOSITORY_URL=$(echo "$OUTPUTS" | jq -r '.repository_url.value')
REPOSITORY_BRANCH=$(echo "$OUTPUTS" | jq -r '.repository_branch.value')
REGION=$(echo "$OUTPUTS" | jq -r '.region.value')

# Static values
APPLICATIONSET_PATH="argocd/applicationset/"

echo "Bootstrapping ArgoCD on cluster: $CLUSTER_NAME"

# Run ECS task
echo "Starting ECS task..."
RUN_TASK_OUTPUT=$(aws ecs run-task \
  --cluster "$ECS_CLUSTER_ARN" \
  --task-definition "$TASK_DEFINITION_ARN" \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[$PRIVATE_SUBNETS],securityGroups=[$BOOTSTRAP_SECURITY_GROUP],assignPublicIp=DISABLED}" \
  --overrides "{
    \"containerOverrides\": [{
      \"name\": \"bootstrap\",
      \"environment\": [
        {\"name\": \"CLUSTER_NAME\", \"value\": \"$CLUSTER_NAME\"},
        {\"name\": \"REPOSITORY_URL\", \"value\": \"$REPOSITORY_URL\"},
        {\"name\": \"REPOSITORY_PATH\", \"value\": \"$APPLICATIONSET_PATH\"},
        {\"name\": \"REPOSITORY_BRANCH\", \"value\": \"$REPOSITORY_BRANCH\"},
        {\"name\": \"ENVIRONMENT\", \"value\": \"$ENVIRONMENT\"},
        {\"name\": \"SECTOR\", \"value\": \"$SECTOR\"},
        {\"name\": \"REGION\", \"value\": \"$REGION\"},
        {\"name\": \"CLUSTER_TYPE\", \"value\": \"$CLUSTER_TYPE\"}
      ]
    }]
  }" 2>&1)

# Check if run-task succeeded
if echo "$RUN_TASK_OUTPUT" | grep -q '"failures":\s*\[\]'; then
  echo "✓ ECS task created successfully."
  TASK_ARN=$(echo "$RUN_TASK_OUTPUT" | jq -r '.task.taskArn // .tasks[0].taskArn // empty')
  if [[ -z "$TASK_ARN" || "$TASK_ARN" == "null" ]]; then
    echo "❌ Could not extract task ARN from response"
    exit 1
  fi
  echo "✓ Bootstrap task started: $TASK_ARN"
else
  echo "❌ Failed to start ECS task. Error details:"
  echo "$RUN_TASK_OUTPUT"
  exit 1
fi

echo "Starting log monitoring..."
aws logs tail "$LOG_GROUP" --follow &
LOG_PID=$!

# Clean up background log process on script exit or interrupt
cleanup() {
    if [[ -n "${LOG_PID:-}" ]]; then
        kill $LOG_PID 2>/dev/null || true
    fi
}
trap cleanup EXIT INT TERM

# Monitor task status
while true; do
    TASK_STATUS=$(aws ecs describe-tasks --cluster "$ECS_CLUSTER_ARN" --tasks "$TASK_ARN" --query 'tasks[0].lastStatus' --output text)

    if [[ "$TASK_STATUS" == "STOPPED" ]]; then
        echo ""
        echo "Task stopped. Getting task details..."

        # Get full task details for debugging
        TASK_DETAILS=$(aws ecs describe-tasks --cluster "$ECS_CLUSTER_ARN" --tasks "$TASK_ARN")

        # Extract exit code and stop reason
        EXIT_CODE=$(echo "$TASK_DETAILS" | jq -r '.tasks[0].containers[0].exitCode // "null"')
        STOP_REASON=$(echo "$TASK_DETAILS" | jq -r '.tasks[0].stopReason // "unknown"')
        CONTAINER_REASON=$(echo "$TASK_DETAILS" | jq -r '.tasks[0].containers[0].reason // "unknown"')

        if [[ "$EXIT_CODE" == "0" ]]; then
            echo "✓ Bootstrap completed successfully!"
            exit 0
        elif [[ "$EXIT_CODE" == "null" || -z "$EXIT_CODE" ]]; then
            echo "❌ Bootstrap failed - no exit code available"
            exit 1
        else
            echo "✗ Bootstrap failed with exit code: $EXIT_CODE"
            exit 1
        fi
    fi

    sleep 10
done
