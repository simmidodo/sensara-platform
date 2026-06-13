## What does this PR do?

<!-- Brief description of the change -->

## Why?

<!-- Motivation, ticket reference e.g. SENSARA-123 -->

## Type of change

- [ ] Bug fix
- [ ] New feature (non-breaking)
- [ ] Breaking change (requires coordination with Head of Development)
- [ ] Database migration (Flyway script added to `src/main/resources/db/migration/`)
- [ ] Feature flag change (`runtime-config/featureFlags/*.featureFlag.json`)
- [ ] Infrastructure / K8s manifest change
- [ ] Dependency update

## Definition of Done checklist

- [ ] Unit tests pass locally (`mvn test`)
- [ ] Integration tests pass locally (`mvn verify -P integration-tests`)
- [ ] No new OWASP vulnerabilities above CVSS 7
- [ ] If DB migration: migration is backward-compatible with the previous version of the code (old pods can run against new schema)
- [ ] If feature flag change: flag defaults to `false` in prod, `true` in staging
- [ ] If new service dependency: circuit breaker added (Resilience4j)
- [ ] Deployment tested in staging namespace
- [ ] Pub/Sub subscriber lag is zero after staging deploy

## How to test

<!-- Steps for reviewer to verify the change -->

## Rollback plan

<!-- How to rollback this change if it causes issues in production -->
<!-- Default: flip-traffic.sh to previous slot (< 60 seconds) -->
<!-- If DB migration: describe the compensation steps -->
