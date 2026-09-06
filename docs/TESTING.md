# Testing Strategy

## Test layers

### Unit

Validate pure logic:

- schema validation
- event normalization
- authorization policy
- customer scoping
- lease logic
- manifest/hash verification
- profile mapping

### Integration

Validate component boundaries:

- Edge → Control API
- WinPE → telemetry endpoint
- Control API → Log Analytics
- Control API → customer worker
- Windows agent → Control API

### Lab/system

Validate real deployment behavior:

- UEFI PXE
- ProxyDHCP coexistence with existing DHCP
- iPXE/wimboot
- WinPE startup
- OSDCloud deployment
- reboot correlation
- Autopilot/Intune handoff

### Security

Mandatory negative testing:

- revoked Edge
- cross-customer access
- expired/replayed token
- duplicate deployment lease
- malformed telemetry
- artifact tampering
- unknown device
- offline control plane before wipe

## POC lab matrix

Start with at least:

- one Edge Windows 11 device
- one physical UEFI x64 client
- one VM if PXE firmware behavior is representative
- one simple subnet with existing DHCP

Record:

- DHCP server implementation
- VLAN/subnet
- Edge NIC/interface
- client OEM/model/firmware
- Secure Boot state
- boot release version

## Phase 1 acceptance test

```text
Given: existing DHCP and one Edge node
When: a second device performs UEFI PXE boot
Then:
  - DHCP still provides IP
  - Edge provides PXE bootstrap
  - iPXE starts
  - WinPE downloads over HTTP
  - WinPE starts successfully
  - Edge and WinPE telemetry appear centrally
  - no local disk is modified
```

## Authorization safety test

Before real OSDCloud wipe is enabled:

```text
Given: a device without valid authorization
When: deployment reaches destructive boundary
Then:
  - disk commands are not executed
  - DeploymentDenied/Blocked event exists
  - local diagnostics identify authorization failure
```

## Multi-customer tests

Create synthetic Customer A and Customer B.

Tests:

1. A Edge asks for A profile → allowed.
2. A Edge asks for B profile → denied.
3. A deployment token submits B telemetry → rejected or server-corrected and audited.
4. A operator reads B deployment → denied.
5. A worker receives B operation → rejected.
6. B local manifest copied to A WinPE → server still resolves A.

## Artifact tests

- valid hash activates release
- modified boot.wim rejected
- partial download rejected
- previous active release remains available after failed update
- rollback switches atomically

## Telemetry tests

- duplicate eventId does not create duplicate logical event
- UTC timestamps accepted
- invalid phase/status rejected
- large/unbounded message rejected
- token-like values are not included in fixtures/logs
- timeline remains coherent when events arrive slightly out of order

## Deployment correlation tests

- WinPE creates deploymentId
- deploymentId written to installed OS
- Windows reads same deploymentId
- cloud enrichment attaches Intune/Autopilot IDs to same deployment
- second reinstall creates a new deploymentId

## Readiness tests

- DesktopObserved alone does not imply DeploymentReady when policy requires apps/compliance
- all required signals produce DeploymentCompleted
- missing required signal produces Pending/Stalled, not false success

## Performance measurements

Capture during POC/MVP:

- PXE-to-iPXE time
- boot.wim local download throughput
- WinPE-start-to-first-telemetry latency
- telemetry ingestion latency
- OS download duration
- OS apply duration
- Autopilot duration
- zero-to-desktop duration

## Test evidence

PRs that alter deployment or security behavior should include reproducible evidence in the PR body or linked test artifacts.
