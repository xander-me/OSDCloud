# Multi-Tenancy

## Goal

Support multiple customers safely without allowing client-side selection, operator error, or backend misconfiguration to cross customer boundaries.

## Core rule

`customerId` is an authorization boundary, not just metadata.

Every customer-owned object must be scoped to a customer, including:

- site
- Edge node
- subnet
- deployment profile
- deployment
- device registration
- Autopilot worker
- telemetry routing policy
- operator role assignment

## Resolution chain

Customer identity is resolved server-side from trusted context:

```text
Authenticated Edge identity
  ↓
edgeId
  ↓
siteId
  ↓
customerId
  ↓
allowed profiles / subnets / actions
```

The WinPE client may submit observed identifiers, but it cannot authoritatively choose another customer.

## Isolation tiers

### Tier 1 — Shared platform / shared observability

Suitable for lab, small environments or low-isolation customers.

- shared control plane
- shared Log Analytics workspace
- shared API runtime
- customer-scoped records and authorization
- isolated customer Graph workers/identities

### Tier 2 — Shared control plane / dedicated telemetry

- shared control API
- dedicated Log Analytics workspace per customer
- isolated ingestion route per customer
- isolated customer Graph worker/identity

### Tier 3 — Dedicated customer boundary

For stricter customers:

- dedicated Azure subscription/resource group or tenant boundary as required
- dedicated telemetry
- dedicated worker identities
- optional dedicated control-plane deployment

The domain model and contracts must support all three tiers even if the POC only implements Tier 1.

## Customer manifest

Server-side configuration example:

```yaml
apiVersion: v1
customerId: customer-a
displayName: Customer A
telemetry:
  isolationTier: shared
sites:
  - siteId: dk-hq
    allowedSubnets:
      - 10.20.30.0/24
deploymentProfiles:
  - profileId: store-w11
    os: Windows11-25H2
    edition: Enterprise
    language: da-DK
    autopilot:
      enabled: true
      groupTag: Store
security:
  requireKnownDevice: true
  requireApproval: false
  allowZeroTouchWipe: true
```

This manifest must never contain reusable client secrets.

## Customer workers

Autopilot/Graph operations are executed by customer-scoped workers.

```text
Control API
  ├─ customer-a → worker-a → Entra tenant A
  └─ customer-b → worker-b → Entra tenant B
```

A worker must reject requests where the request's customer does not match the worker's configured customer.

## Operator authorization

Recommended role model:

- PlatformReader
- PlatformOperator
- PlatformAdmin
- CustomerReader
- CustomerOperator
- CustomerAdmin

Customer roles are always bound to explicit customer IDs.

## Cross-customer invariants

Automated tests must prove:

- Customer A token cannot read Customer B deployments.
- Customer A Edge cannot request Customer B profiles.
- Customer A deployment token cannot submit telemetry as Customer B.
- Customer A worker cannot perform Graph operations for Customer B.
- Customer A operator cannot approve Customer B deployment.
- Customer A device cannot select Customer B by changing local JSON.

## Customer onboarding

Minimum onboarding workflow:

1. create `customerId`
2. create customer worker identity/integration
3. define telemetry isolation tier
4. define sites and allowed subnets
5. enroll Edge identities
6. define deployment profiles
7. validate test device
8. run non-destructive PXE test
9. run authorized deployment test
10. approve production rollout

## Customer offboarding

- revoke Edge identities
- disable worker identity
- disable deployment profiles
- stop new authorizations
- retain/export telemetry according to policy
- remove secrets/credentials from secure stores
- document customer data-retention outcome
