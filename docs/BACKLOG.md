# Implementation Backlog

This backlog is ordered for Codex/engineering execution. Do not skip security gates by jumping directly to destructive deployment.

## Epic A — Repository foundation

### A1. Create source structure

Create:

```text
src/control-api/
src/edge/
src/winpe/
src/windows-agent/
src/autopilot-worker/
src/telemetry/
infra/bicep/
infra/dashboards/
tests/unit/
tests/integration/
tests/security/
```

Acceptance:

- empty directories represented with README placeholders where needed
- no secrets or environment-specific values committed

### A2. Add common version/constants package

Define stable source/phase/status/event-name constants from documentation.

Acceptance:

- client and server code do not invent event names independently

---

## Epic B — Telemetry contract

### B1. Implement JSON schema validation

Use `schemas/deployment-event.schema.json`.

Acceptance:

- valid sample accepted
- missing required field rejected
- invalid enum rejected
- oversized `message` rejected

### B2. Implement PowerShell `Write-OSDDeploymentEvent`

Requirements:

- WinPE-compatible
- JSON serialization
- timeout/retry
- bounded queue/fallback file when endpoint temporarily unavailable
- never throw secrets into logs
- eventId generated automatically
- UTC time generated automatically

### B3. Create telemetry API stub

Acceptance:

- accepts schema-valid event
- returns correlation ID
- idempotent by `eventId`
- unit tests

### B4. Deploy Log Analytics POC

Create Bicep for:

- Log Analytics workspace
- DCR/DCE as required
- custom table / ingestion configuration
- workload identity permissions

### B5. Build initial Workbook/KQL

Views:

- latest event per deployment
- active deployments
- failures
- single deployment timeline

---

## Epic C — Edge POC

### C1. Research/select PXE responder implementation

Document decision in ADR.

Must evaluate:

- ProxyDHCP behavior
- port binding/service privileges
- coexistence with normal DHCP
- UEFI x64
- Secure Boot implications
- licensing of embedded components

### C2. Implement Edge configuration model

Local config should contain only non-secret operational settings plus secure identity reference.

### C3. Implement local HTTP boot server

Requirements:

- serve only approved cache directory
- no directory traversal
- bind to configured interface
- basic request telemetry

### C4. Implement boot release cache

- manifest download
- SHA-256 verification
- atomic activation
- retain previous known-good release

### C5. Implement PXE-to-iPXE boot

Acceptance:

- lab client receives bootstrap
- no WDS present
- normal DHCP remains authoritative for IP

### C6. Implement iPXE/wimboot WinPE delivery

Acceptance:

- WinPE loads over local HTTP
- Edge records start/completion/failure events

### C7. Implement Edge Windows service wrapper

Do only after C2-C6 work interactively.

---

## Epic D — WinPE POC

### D1. Create bootstrap script

Responsibilities:

- initialize networking
- identify hardware
- create deploymentId
- detect Edge/control endpoint
- emit `WinPEStarted`
- write local diagnostic log

No disk operations.

### D2. Persist local deployment context

During later phases, support writing sanitized correlation state to offline Windows.

### D3. Create WinPE diagnostics command

Output:

- deploymentId
- network
- serial/model
- Edge/control reachability
- active boot version
- telemetry queue status

---

## Epic E — Control/authorization

### E1. Implement customer/site/Edge domain model

### E2. Implement Edge authentication

### E3. Implement deployment context endpoint

### E4. Implement authorization policy engine

First policies:

- known Edge
- Edge belongs to site/customer
- device known when required
- profile belongs to customer

### E5. Implement deployment lease

Acceptance:

- only one active destructive lease per device
- expiry
- renewal
- idempotency

### E6. Implement short-lived deployment credential

Scope to deployment/customer/actions.

### E7. Implement audit log

---

## Epic F — OSDCloud integration

Blocked until security acceptance for Epics B-E.

### F1. Create OSDCloud adapter

Map deployment profile to supported upstream OSDCloud parameters.

### F2. Add authorization guard

The code path that invokes disk wipe/OS deployment must require a validated current authorization object and lease.

### F3. Wrap major OSDCloud stages with telemetry

Do not depend on parsing console text where stable hooks can be used.

### F4. Persist deploymentId into installed Windows

### F5. Build failure capture

Preserve upstream OSDCloud logs and emit concise structured error event.

---

## Epic G — Autopilot and Windows continuation

### G1. Windows-side correlation bootstrap

### G2. Customer-scoped Autopilot worker

### G3. Autopilot registration endpoint

### G4. Intune/Autopilot enricher

### G5. WindowsReady detection

### G6. DeploymentReady policy evaluation

---

## Epic H — Multi-customer security

### H1. Customer role authorization

### H2. Cross-customer integration tests

### H3. Customer worker isolation tests

### H4. Dedicated telemetry workspace routing option

### H5. Customer onboarding/offboarding automation

---

## First Codex task

Start with **B1 + A1 only**:

> Create the target source/test directory skeleton and implement automated validation tests for `schemas/deployment-event.schema.json`. Do not implement PXE, Azure deployment or destructive functionality yet.
