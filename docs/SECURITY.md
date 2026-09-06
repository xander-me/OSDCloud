# Security Architecture

## Security objectives

The platform must be safe enough to initiate destructive OS deployment across multiple customers without placing broad customer credentials on temporary boot environments or local Edge nodes.

Primary objectives:

- protect customer isolation
- protect deployment authorization
- protect boot artifact integrity
- minimize credential exposure
- preserve auditability
- fail closed before destructive operations
- keep Secure Boot enabled in the production design

## Security principles

### 1. Boot is not authorization

PXE access is intentionally low privilege. A device that can load WinPE is **not** automatically permitted to wipe disks or register into a tenant.

### 2. No reusable customer credentials in WinPE

WinPE may receive only short-lived, deployment-scoped tokens. It must never contain reusable Graph client secrets, certificates with broad tenant access, Log Analytics shared keys or equivalent credentials.

### 3. No customer Graph credentials on Edge

Edge nodes provide boot and caching services only. Customer tenant write permissions live server-side in customer-scoped workers.

### 4. Fail closed

If any of the following cannot be validated, deployment stops before destructive actions:

- Edge identity
- customer/site resolution
- device identity
- deployment profile
- artifact integrity
- authorization policy
- token validity
- deployment lease

### 5. Least privilege

Each component receives only the permissions required for its role.

## Identity model

### Edge identity

Each Edge node receives its own revocable identity, preferably certificate-backed or workload-based.

Attributes:

```text
edgeId
customerId
siteId
allowedSubnets
releaseRing
certificateThumbprint / credential reference
status
lastSeen
```

An Edge identity is never reused across customers.

### WinPE/deployment identity

WinPE begins unauthenticated or minimally authenticated, then requests a deployment context using hardware/site/Edge evidence.

After policy approval, the control plane issues a short-lived token scoped to:

```text
deploymentId
customerId
device identity
allowed profile
authorized operations
expiration
```

Recommended token lifetime: short enough to limit replay, long enough to tolerate a normal deployment phase. Exact lifetime is an ADR/implementation decision.

### Cloud workload identity

Azure-hosted components should prefer Managed Identity where possible.

Customer-specific Graph integrations should use isolated workload identities/app registrations so compromise or configuration error for Customer A cannot grant access to Customer B.

## Destructive action boundary

The following operations are considered destructive/privileged:

- disk wipe
- repartition
- apply OS
- firmware changes
- Autopilot tenant registration
- changing deployment/customer association

Before disk wipe, the Agent must possess an explicit authorization result tied to the current `deploymentId`.

Example server response:

```json
{
  "apiVersion": "v1",
  "deploymentId": "...",
  "authorized": true,
  "expiresAt": "2026-09-06T18:30:00Z",
  "profileId": "matas-store-w11",
  "allowedActions": [
    "wipeDisk",
    "deployOs",
    "registerAutopilot"
  ]
}
```

The client must not infer permissions from profile names or local config files.

## Artifact integrity

Every release manifest should contain:

- artifact name
- version
- SHA-256 digest
- size
- source URI
- signature metadata where implemented

Edge behavior:

1. download artifact
2. validate TLS
3. validate expected digest
4. validate signature where applicable
5. place into immutable versioned cache
6. mark release ready only after all required artifacts validate

Rollback means activating a previous known-good release, not mutating an existing release.

## Secure Boot

Production support requires a tested UEFI Secure Boot-compatible PXE/iPXE/wimboot chain.

Disabling Secure Boot may be used only as a temporary isolated lab diagnostic and must not become an operational requirement.

## Telemetry security

Devices and Edge nodes submit telemetry through the control API rather than directly receiving broad Log Analytics ingestion credentials.

Telemetry rules:

- accept only defined schema
- server stamps/validates customer context
- reject cross-customer identifiers inconsistent with authenticated Edge/deployment context
- rate limit
- cap message size
- avoid secrets and raw access tokens
- minimize end-user PII

## Multi-customer isolation

See `MULTI-TENANCY.md`.

At minimum:

- all customer-owned entities carry `customerId`
- server-side authorization filters every request
- customer-specific Graph workers use isolated identities
- customer admin views are customer-scoped
- telemetry access follows defined isolation tier

## Audit events

Audit events must be distinct from operational telemetry for privileged actions.

Examples:

```text
DeploymentAuthorized
DeploymentDenied
DiskWipeAuthorized
ProfileChanged
EdgeRegistered
EdgeRevoked
BootReleasePromoted
BootReleaseRolledBack
AutopilotRegistrationRequested
AutopilotRegistrationCompleted
CustomerWorkerCredentialChanged
```

Audit records should include actor/workload identity, timestamp, target, result and correlation identifiers.

## Break-glass

USB boot may remain as an emergency path.

Break-glass artifacts must still:

- be versioned
- be integrity checked
- avoid embedded reusable customer credentials
- require authorization before destructive actions when central connectivity exists

Offline destructive deployment is a separate risk decision and is out of scope for the first implementation.

## Security review gates

Before enabling automatic wipe in any environment:

- threat model reviewed
- token replay tests completed
- customer-isolation tests completed
- Edge spoofing tests completed
- artifact tamper tests completed
- stale/expired authorization tests completed
- unknown-device behavior verified
- audit records verified

Before production:

- penetration/security review
- Secure Boot validation
- credential rotation/revocation procedure
- incident response procedure
- customer offboarding procedure
- data retention/privacy review
