# Roadmap

## Phase 0 — Architecture baseline

**Goal:** repository is ready for implementation.

Deliverables:

- project charter
- architecture
- security model
- multi-tenancy model
- Edge design
- deployment lifecycle
- telemetry contract
- API draft
- threat model
- test strategy
- ADRs

Exit criteria:

- destructive boundary is clearly defined
- POC scope is intentionally non-destructive
- Codex can implement Phase 1 without inventing architecture

---

## Phase 1 — PXE-to-WinPE POC

**Goal:** prove WDS-less and USB-less network boot on one subnet.

Build:

- minimal Edge prototype on Windows
- PXE/ProxyDHCP responder
- local HTTP boot service
- iPXE/wimboot integration
- immutable local boot release folder
- WinPE image containing bootstrap script
- basic Edge + WinPE telemetry

Flow:

```text
UEFI PXE
 → Edge
 → iPXE
 → HTTP WinPE
 → bootstrap
 → telemetry
```

No disk modification.

Exit criteria:

- supported lab device boots WinPE with Secure Boot target documented/tested
- Edge telemetry visible
- WinPE telemetry visible
- Edge can be stopped/restarted cleanly
- boot release hash verification works

---

## Phase 2 — Telemetry platform POC

**Goal:** make deployment events visible in near real time.

Build:

- Azure telemetry endpoint
- event schema validation
- Log Analytics custom table
- DCR / Logs Ingestion path
- initial KQL
- Azure Workbook
- `Write-OSDDeploymentEvent` PowerShell function

Exit criteria:

- duplicate `eventId` handled safely
- malformed/cross-customer payload rejected or normalized
- active-device timeline visible
- ingestion latency measured

---

## Phase 3 — Control and authorization POC

**Goal:** introduce secure deployment context without performing OS deployment yet.

Build:

- Edge identity
- customer/site/profile objects
- deployment context endpoint
- deployment authorization endpoint
- deployment lease
- short-lived deployment token
- audit events

Test with simulated destructive action rather than disk wipe.

Exit criteria:

- unknown/revoked Edge denied
- Customer A cannot resolve Customer B profiles
- token expiry and lease collision verified

---

## Phase 4 — OSDCloud integration

**Goal:** authorized device can perform real Windows deployment.

Build:

- OSDCloud wrapper
- profile-to-OSDCloud parameter mapping
- structured phase events around OSDCloud steps
- persistence of `deploymentId` into offline Windows
- safe failure handler
- optional manual approval policy

Exit criteria:

- no wipe before authorization/lease
- one lab device completes OS deployment
- events survive reboot correlation

---

## Phase 5 — Windows / Autopilot handoff

**Goal:** continue correlation after reboot.

Build:

- Windows-side bootstrap/agent
- safe re-authentication after WinPE
- Windows Setup/OOBE events
- customer-scoped Autopilot worker
- Autopilot registration API
- Intune/Autopilot enrichment

Exit criteria:

- same deployment timeline spans WinPE and Windows
- customer-specific Graph credential never exposed to device
- Autopilot device/Intune IDs enrich the deployment

---

## Phase 6 — Readiness and zero-to-desktop dashboard

**Goal:** define and observe a real completed deployment.

Build:

- `WindowsReady` policy
- `DeploymentReady` policy
- required app/compliance signals
- stalled deployment detection
- deployment detail view
- operational dashboard
- optional Grafana implementation

Exit criteria:

- platform can say why a machine is/not ready
- readiness is policy-driven per customer/profile
- failure phase and duration are visible

---

## Phase 7 — Multi-customer MVP

**Goal:** safely operate at least two customers.

Build:

- operator RBAC
- customer manifests
- isolated customer workers
- telemetry isolation tier support
- customer onboarding/offboarding process
- cross-customer automated security tests

Exit criteria:

- two test customers deployed
- isolation tests pass
- customer-scoped dashboard access validated

---

## Phase 8 — Edge productionization

**Goal:** reliable branch/site deployment.

Build:

- service installer/update mechanism
- heartbeat and health
- active/standby Edge role
- Edge election/failover
- cache cleanup
- release rings
- rollback
- bandwidth controls
- operational logging

Exit criteria:

- Edge failure does not permanently remove PXE capability where standby exists
- canary and rollback tested
- Edge revoke/offboard tested

---

## Phase 9 — Production security and operations

- Secure Boot matrix across OEMs
- penetration/security review
- key/certificate lifecycle
- alerts
- retention/cost design
- capacity/load testing
- disaster recovery
- incident response
- customer operational runbooks

---

## Later ideas

Not required for MVP:

- offline/break-glass authorized deployment
- peer-to-peer large-content distribution
- dynamic site discovery
- custom portal beyond Workbook/Grafana
- deployment approval mobile workflow
- predictive stall/failure detection
- automatic hardware-specific remediation
- blog-generated documentation portal
