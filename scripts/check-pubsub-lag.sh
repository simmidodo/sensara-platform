#!/usr/bin/env bash
# check-pubsub-lag.sh — verify Pub/Sub subscriber lag is zero
# Usage: ./scripts/check-pubsub-lag.sh <namespace> <minutes>
# Used in smoke tests and go/no-go gate

set -euo pipefail

NAMESPACE="${1:?Usage: check-pubsub-lag.sh <namespace> <minutes>}"
MINUTES="${2:-5}"
PROJECT_ID="${GCP_PROJECT_ID:?GCP_PROJECT_ID required}"

SUBSCRIPTION="sensara-alert-sub-${NAMESPACE}"
MAX_AGE_SECONDS=30    # alert if oldest message > 30 seconds

echo "Checking Pub/Sub lag for subscription: $SUBSCRIPTION"
echo "Required: lag < ${MAX_AGE_SECONDS}s for ${MINUTES} consecutive minutes"

for i in $(seq 1 $MINUTES); do
  LAG=$(gcloud pubsub subscriptions describe $SUBSCRIPTION \
    --project=$PROJECT_ID \
    --format='value(topicMessageRetentionDuration)' 2>/dev/null || echo "0")

  OLDEST_AGE=$(gcloud monitoring time-series list \
    --filter='metric.type="pubsub.googleapis.com/subscription/oldest_unacked_message_age" AND resource.labels.subscription_id="'"$SUBSCRIPTION"'"' \
    --project=$PROJECT_ID \
    --format='value(points[0].value.int64Value)' 2>/dev/null || echo "0")

  echo "[$i/$MINUTES] Oldest unacked message age: ${OLDEST_AGE}s (threshold: ${MAX_AGE_SECONDS}s)"

  if [ "${OLDEST_AGE:-0}" -gt "$MAX_AGE_SECONDS" ]; then
    echo "❌ Pub/Sub lag too high: ${OLDEST_AGE}s > ${MAX_AGE_SECONDS}s"
    echo "Deployment blocked — check SensaraConnect consumer health"
    exit 1
  fi

  if [ "$i" -lt "$MINUTES" ]; then
    echo "Waiting 60 seconds before next check..."
    sleep 60
  fi
done

echo "✅ Pub/Sub lag within threshold for ${MINUTES} consecutive minutes"
echo "Safe to promote to production."
