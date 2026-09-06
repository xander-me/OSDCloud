# Architecture

## Overview

The platform is split into four logical components:

1. **OSDCloud Control** — central API, authorization, configuration and orchestration.
2. **OSDCloud Edge** — customer/site-local PXE bootstrap and boot-content cache.
3. **OSDCloud Agent** — WinPE/Windows-side deployment and telemetry logic.
4. **OSDCloud Observe** — Log Analytics, KQL and visualization.

OSDCloud itself remains the deployment engine inside the Agent/WinPE path.

## End-to-end flow

```text
New device
   │
   │ PXE Discover
   ▼
OSDCloud Edge
   │
   ├─ Respond with approved bootstrap
   ├─ Emit PXE telemetry
   └─ Deliver iPXE / WinPE over local HTTP
          │
          ▼
       WinPE
          │
          ├─ Generate/read DeploymentId
          ├─ Discover hardware
          ├─ Establish network
          ├─ Request deployment context
          ├─ Emit telemetry
          └─ Request authorization
                 │
                 ▼
          OSDCloud Control
                 │
                 ├─ Resolve Edge/site/customer
                 ├─ Validate device/profile
                 ├─ Create deployment lease
                 ├─ Issue scoped deployment token
                 └─ Return sanitized profile
                        │
                        ▼
                    WinPE
                        │
                        ├─ OSDCloud deployment
                        ├─ persist DeploymentId
                        ├─ stage post-OS agent
                        └─ reboot
                               │
                               ▼
                         Windows Setup/OOBE
                               │
                               ├─ telemetry
                               ├─ Autopilot handoff
                               └─ Intune enrollment
                                      │
                                      ▼
                               Cloud enrichment
                                      │
                                      ├─ Autopilot status
                                      ├─ Intune device
                                      ├─ compliance
                                      └─ readiness
                                             │
                                             ▼
                                     Deployment Complete
```

## Trust boundaries

```text
[Untrusted PXE client]
        |
        | network boot
        v
[Customer Edge boundary]
        |
        | TLS + Edge identity
        v
[Central Control Plane]
        |
        | customer-scoped workload identity
        v
[Customer Microsoft tenant]
```

WinPE is treated as a temporary, low-trust client. It is not given broad Azure or Microsoft Graph permissions.

## Control plane responsibilities

The control plane owns:

- Edge registration and status
- customer/site mapping
- deployment-profile resolution
- device authorization policy
- deployment leases
- scoped token issuance
- artifact/catalog metadata
- customer-specific backend worker routing
- telemetry intake
- audit events

The control plane does **not** directly perform Windows deployment.

## Edge responsibilities

The Edge node owns only local-site functions:

- PXE/ProxyDHCP response where supported
- iPXE bootstrap
- HTTP delivery of approved boot artifacts
- boot-artifact cache
- heartbeat/health
- local boot telemetry

The Edge node should not possess:

- customer Graph client secrets
- Log Analytics writer credentials
- cross-customer API permissions
- arbitrary remote-control capability

## Agent responsibilities

### WinPE

- initialize deployment context
- hardware discovery
- network checks
- validate central connectivity
- obtain sanitized deployment profile
- obtain deployment authorization
- invoke/wrap OSDCloud
- emit structured phase events
- persist correlation state into the installed OS

### Windows

- recover the persisted DeploymentId
- emit Windows Setup/OOBE readiness events
- collect only explicitly defined deployment-health signals
- stop acting as a deployment agent once handoff is complete

## Observe responsibilities

The observability layer does not authorize deployment.

It receives normalized events and provides:

- active deployment view
- deployment timeline
- failed/stalled deployment view
- phase-duration analytics
- Edge health
- deployment success rate
- customer/site/model comparisons

## Deployment identity

Each deployment receives a globally unique `deploymentId`.

Identity evolves during the lifecycle:

```text
deploymentId
  ├─ serialNumber
  ├─ hardwareHashDigest (optional/non-secret representation)
  ├─ customerId
  ├─ siteId
  ├─ edgeId
  ├─ autopilotDeviceId
  ├─ entraDeviceId
  ├─ intuneDeviceId
  ├─ deviceName
  └─ userId/UPN only if explicitly required and permitted
```

`deploymentId` is the primary event-correlation key. Device IDs enrich it later; they do not replace it.

## Configuration hierarchy

```text
Platform defaults
   ↓
Customer manifest
   ↓
Site manifest
   ↓
Deployment profile
   ↓
Device-specific policy result
```

Client input is never authoritative for customer identity or destructive-action permission.

## Artifact model

Boot artifacts are immutable and versioned.

Example:

```text
BootRelease 1.3.0
  ├─ ipxe.efi
  ├─ wimboot
  ├─ BCD
  ├─ boot.sdi
  ├─ boot.wim
  ├─ bootstrap.ps1
  └─ manifest.json
```

The manifest contains expected hashes and metadata. Edge validates downloaded content before making a release active.

## Release rings

```text
Development
  ↓
Lab
  ↓
Canary
  ↓
Production
```

Control plane selects which release each Edge may activate.

## Availability model

The first POC supports one Edge node per subnet.

Future production model:

- multiple eligible Edge nodes per site/subnet
- one active responder per logical PXE scope when required
- heartbeat-based failover
- lease/election logic
- version/health-aware candidate selection

## Failure philosophy

The platform must distinguish:

- **boot failure** — cannot reach WinPE
- **control failure** — cannot authenticate/authorize
- **deployment failure** — OSDCloud/Windows deployment failed
- **handoff failure** — Autopilot/Intune failed
- **readiness failure** — desktop exists but required readiness criteria are not met

Unknown state must never be represented as success.
