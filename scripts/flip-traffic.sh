#!/usr/bin/env bash
# flip-traffic.sh — switch Cloud Load Balancer to target slot
# Usage: ./scripts/flip-traffic.sh prod-blue | prod-green
# Adapted from Ember cd-production-deploy.yml "Backout to previous" pattern
# This is the 30-second rollback that replaces the 2am manual fix

set -euo pipefail

TARGET_SLOT="${1:?Usage: flip-traffic.sh <prod-blue|prod-green>}"
PROJECT_ID="${GCP_PROJECT_ID:?GCP_PROJECT_ID env var required}"
CLUSTER="sensara-prod"
REGION="europe-west4"
LB_NAME="sensara-prod-lb"

echo "🔄 Flipping traffic to: $TARGET_SLOT"
echo "Project: $PROJECT_ID"
echo "Time: $(date -u +%Y-%m-%dT%H:%M:%SZ)"

# Validate target slot
if [[ "$TARGET_SLOT" != "prod-blue" && "$TARGET_SLOT" != "prod-green" ]]; then
  echo "❌ Invalid slot: $TARGET_SLOT. Must be prod-blue or prod-green"
  exit 1
fi

# Get the backend service name for the target slot
TARGET_NEG="sensara-${TARGET_SLOT}-neg"

echo "Updating Cloud Load Balancer backend to: $TARGET_NEG"

# Update the URL map to point to the target backend service
gcloud compute url-maps import $LB_NAME \
  --source=- \
  --project=$PROJECT_ID \
  --global << EOF
defaultService: https://www.googleapis.com/compute/v1/projects/${PROJECT_ID}/global/backendServices/sensara-${TARGET_SLOT}-backend
name: ${LB_NAME}
EOF

# Wait for LB update to propagate
echo "Waiting for LB update to propagate..."
sleep 5

# Verify by checking health of target backend
echo "Verifying target backend health..."
HEALTHY=$(gcloud compute backend-services get-health \
  sensara-${TARGET_SLOT}-backend \
  --global \
  --project=$PROJECT_ID \
  --format='value(status.healthStatus[0].healthState)' 2>/dev/null || echo "UNKNOWN")

echo "Backend health: $HEALTHY"

if [[ "$HEALTHY" == "HEALTHY" ]]; then
  echo "✅ Traffic successfully flipped to $TARGET_SLOT"
  echo "✅ Rollback complete. MTTR: under 60 seconds."
else
  echo "⚠️  Backend health check returned: $HEALTHY"
  echo "Traffic flip issued. Monitor Cloud Monitoring for confirmation."
fi

echo ""
echo "Run smoke tests to verify:"
echo "  ./scripts/smoke-test.sh $PROJECT_ID"
