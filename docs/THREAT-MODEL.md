# Threat Model

## Scope

Covers the initial platform path:

```text
PXE client → Edge → Control API → WinPE → OSDCloud → Windows → Autopilot/Intune
```

## Assets

- customer tenant access
- deployment authorization
- boot artifacts
- deployment profiles
- Edge identities
- device identity records
- telemetry/audit records
- Autopilot registration capability

## Threats and mitigations

### Rogue PXE client requests deployment

**Risk:** Any machine on a deployment subnet attempts to boot and trigger disk wipe.

**Mitigations:**

- PXE only grants WinPE boot
- device/context resolution server-side
- deployment authorization required
- known-device policy where configured
- explicit lease before destructive actions
- audit every authorization

### Client manipulates customerId/profileId

**Risk:** Cross-customer deployment or wrong tenant registration.

**Mitigations:**

- derive customer from authenticated Edge/site context
- treat client-supplied customer identifiers as untrusted
- verify profile belongs to resolved customer
- customer-scoped worker routing server-side

### Stolen WinPE token

**Risk:** Replay to submit actions/telemetry or request privileged operations.

**Mitigations:**

- short token lifetime
- bind token to deployment/customer/device scope
- narrow allowed actions
- replay/idempotency checks
- never persist long-lived bearer token to installed OS

### Compromised Edge node

**Risk:** Rogue boot content, fake customer association, telemetry spoofing.

**Mitigations:**

- unique revocable Edge identity
- Edge cannot authorize wipe
- Edge cannot access customer Graph credentials
- boot release manifests/hashes/signatures
- allowed-subnet constraints
- server validates customer/site scope
- revoke/drain Edge centrally

### Boot artifact tampering

**Risk:** Malicious WinPE or bootstrap code gains control before deployment.

**Mitigations:**

- HTTPS transport
- SHA-256 manifest validation
- signing where supported
- immutable versioned releases
- Secure Boot-compatible chain
- release rings and rollback

### Compromised control API

**Risk:** Highest-impact platform compromise.

**Mitigations:**

- Managed Identity
- least privilege
- isolate customer worker identities
- strong operator authentication
- RBAC
- audit privileged actions
- rate limits / WAF / network controls where appropriate
- code review and secure deployment pipeline

### Customer worker compromise

**Risk:** Unauthorized Autopilot/Graph operations inside one customer.

**Mitigations:**

- one customer scope per worker identity
- minimum Graph permissions
- no cross-customer credentials
- credential rotation/revocation
- audit every request/result

### Telemetry injection

**Risk:** Fake success/failure data or cross-customer visibility.

**Mitigations:**

- authenticated submission where possible
- server-side customer enrichment
- event schema validation
- eventId deduplication
- restrict message size/properties
- distinguish device-observed from server-observed signals

### Concurrent deployment race

**Risk:** Same device receives two destructive deployment attempts.

**Mitigations:**

- device-level deployment lease
- lease expiry/renewal
- idempotent context creation
- reject second destructive authorization while lease active

### Stale authorization

**Risk:** Old approval reused after context changed.

**Mitigations:**

- expiration
- bind profile/actions/device/deploymentId
- revalidate immediately before destructive boundary

### Secret leakage through logs

**Risk:** Tokens or tenant credentials land in Log Analytics.

**Mitigations:**

- structured errors
- telemetry filtering
- never log authorization headers/tokens
- sanitize exception messages before ingestion
- security tests scanning fixtures/log output

## Required negative tests

- unknown Edge rejected
- revoked Edge rejected
- invalid artifact hash blocks activation
- expired deployment token blocks wipe
- Customer A token cannot request Customer B profile
- modified local customerId cannot change server result
- second concurrent lease denied
- unknown device blocked when policy requires known device
- telemetry event with mismatched customerId is rejected/overwritten server-side
- offline control plane prevents destructive action

## Future threat-model work

- formal STRIDE review per component
- supply-chain security for PowerShell modules and OSDCloud versions
- denial-of-service on PXE/telemetry endpoints
- Edge local privilege escalation
- firmware update risks
- customer admin compromise
- privacy/Data Protection Impact Assessment requirements
