#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail
set -o xtrace

function waitBeforeExit() {
  local exit_code=$?
  echo "Waiting before exiting to ensure that logs are captured."
  sleep 10
  exit "$exit_code"
}

trap waitBeforeExit EXIT

if [ -z "${PROW_JOB_NAME:-}" ]; then
  echo "PROW_JOB_NAME is not set. Exiting."
  exit 0
fi

# "${PROW_JOB_EXECUTOR}" execute --job-name "$PROW_JOB_NAME" --region "$REGION" --dry-run="${DRY_RUN:-false}" --gate-promotion="${GATE_PROMOTION:-false}"
echo "hello prow"

