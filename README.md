# OSDCloud Zero-to-Desktop Platform

> **Status:** Architecture / POC design
>
> **Repository:** Independent engineering project built around OSDCloud. This is **not** the official OSDCloud repository and is not affiliated with or endorsed by the OSDCloud maintainers.

## Vision

Build a secure, cloud-native Windows deployment platform that can follow a device from its first network boot until a usable, managed desktop is available to the end user.

The platform should remove the normal dependency on USB deployment media and dedicated WDS/PXE servers while retaining PXE functionality through distributed customer-side edge nodes.

The target journey is:

```text
Power on
   ↓
UEFI PXE / recovery boot
   ↓
OSDCloud Edge
   ↓
iPXE / WinPE
   ↓
OSDCloud deployment
   ↓
Windows Setup
   ↓
Autopilot
   ↓
Intune / ESP
   ↓
Required apps + policy + security health
   ↓
Desktop Ready
   ↓
✓ Deployment Complete
```

Every meaningful transition is emitted as structured telemetry so an operator can follow the deployment in near real time.

## Design goals

1. **Zero-to-desktop observability** — one correlated deployment timeline from PXE through Intune readiness.
2. **No permanent deployment server requirement** — ordinary managed Windows endpoints can provide local PXE bootstrap capability.
3. **Cloud-controlled, edge-delivered** — configuration and authorization are centralized; boot delivery can be local and cached.
4. **Secure by default** — PXE boot does not imply authorization to wipe a disk.
5. **Multi-customer from day one** — tenant boundaries, secrets, authorization, telemetry and customer configuration are explicit architectural concerns.
6. **OSDCloud remains the deployment engine** — do not unnecessarily reimplement Windows deployment functionality already provided by OSDCloud.
7. **Autopilot and Intune remain the management plane** — the platform hands the device over rather than trying to replace Intune.
8. **API-first** — Edge, WinPE, Windows and dashboards communicate through versioned contracts.
9. **Observable and auditable** — destructive actions and identity transitions can be reconstructed later.
10. **Codex-friendly engineering** — small components, explicit interfaces, ADRs, tests and milestones.

## Logical components

```text
┌──────────────────────────────────────────────────────────────────┐
│                       CLOUD CONTROL PLANE                        │
│                                                                  │
│  OSDCloud Control                                                │
│  ├─ API                                                          │
│  ├─ Deployment authorization                                    │
│  ├─ Customer/site/profile resolution                            │
│  ├─ Deployment leases                                           │
│  ├─ Artifact/catalog metadata                                   │
│  └─ Customer-specific workers                                   │
│                                                                  │
│  OSDCloud Observe                                                │
│  ├─ Azure Monitor / Log Analytics                               │
│  ├─ KQL                                                         │
│  └─ Workbook / Grafana                                          │
└──────────────────────────────┬───────────────────────────────────┘
                               │ HTTPS
───────────────────────────────┼────────────────────────────────────
                               │
┌──────────────────────────────▼───────────────────────────────────┐
│                         CUSTOMER SITE                           │
│                                                                  │
│  OSDCloud Edge                                                   │
│  ├─ Identity + heartbeat                                        │
│  ├─ ProxyDHCP / PXE bootstrap                                   │
│  ├─ iPXE                                                         │
│  ├─ HTTP boot delivery                                          │
│  ├─ Signed boot cache                                           │
│  └─ Edge telemetry                                              │
│           │                                                      │
│           ▼                                                      │
│  OSDCloud Agent / WinPE                                         │
│  ├─ Device discovery                                            │
│  ├─ Authorization                                                │
│  ├─ Deployment profile                                          │
│  ├─ OSDCloud                                                     │
│  ├─ Autopilot handoff                                           │
│  └─ Telemetry                                                    │
└─────────────────────────────────────────────────────────────────┘
```

## Repository map

| Path | Purpose |
|---|---|
| [`AGENTS.md`](AGENTS.md) | Instructions and engineering boundaries for Codex/AI agents |
| [`docs/PROJECT.md`](docs/PROJECT.md) | Product scope, requirements and non-goals |
| [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) | End-to-end system architecture |
| [`docs/SECURITY.md`](docs/SECURITY.md) | Security architecture and trust model |
| [`docs/MULTI-TENANCY.md`](docs/MULTI-TENANCY.md) | Multi-customer isolation model |
| [`docs/DEPLOYMENT-LIFECYCLE.md`](docs/DEPLOYMENT-LIFECYCLE.md) | Deployment state machine from PXE to desktop |
| [`docs/EDGE.md`](docs/EDGE.md) | Distributed PXE/Edge design |
| [`docs/TELEMETRY.md`](docs/TELEMETRY.md) | Event schema, correlation and Log Analytics design |
| [`docs/API.md`](docs/API.md) | Initial control-plane API contracts |
| [`docs/DATA-MODEL.md`](docs/DATA-MODEL.md) | Core entities and identifiers |
| [`docs/THREAT-MODEL.md`](docs/THREAT-MODEL.md) | Threats, mitigations and security test cases |
| [`docs/ROADMAP.md`](docs/ROADMAP.md) | POC → MVP → production roadmap |
| [`docs/BACKLOG.md`](docs/BACKLOG.md) | Codex-ready implementation backlog |
| [`docs/TESTING.md`](docs/TESTING.md) | Test strategy and acceptance criteria |
| [`docs/adr/`](docs/adr/) | Architecture Decision Records |
| [`schemas/`](schemas/) | Versioned machine-readable contracts |

## Core design rule

**Boot authorization and deployment authorization are different things.**

A device may be allowed to load WinPE while still being denied permission to modify local storage:

```text
PXE request
   ↓
Boot WinPE             ← low privilege
   ↓
Identify device/site
   ↓
Request deployment authorization
   ↓
Policy decision
   ├── DENY → diagnostics / wait for approval
   └── ALLOW
          ↓
      disk wipe        ← destructive boundary
          ↓
      OSDCloud
```

## Initial technology direction

- **Deployment:** OSDCloud / PowerShell / WinPE
- **Network bootstrap:** PXE + ProxyDHCP where appropriate, iPXE, `wimboot`, HTTP(S)
- **Control plane:** Azure-hosted API; exact runtime selected during POC
- **Workload identity:** Microsoft Entra ID / Managed Identity for Azure-hosted components
- **Telemetry:** Azure Monitor Logs Ingestion API → DCR → Log Analytics custom table
- **Visualization:** Azure Workbook first; Grafana as an operational dashboard option
- **Autopilot:** customer-scoped server-side integration rather than reusable tenant credentials in WinPE
- **Configuration:** versioned customer/site/deployment manifests
- **Secrets:** never committed to Git and never embedded as reusable credentials in WinPE

## Current source material

`Basic.ps1` predates this architecture and is retained as historical experimentation. It should not be treated as the target security or deployment implementation.

## Documentation sources

Important upstream references for implementation validation:

- OSDCloud: https://github.com/RecastSoftware/RecastOSDCloud
- iPXE WinPE/wimboot: https://ipxe.org/wimboot
- iPXE WinPE guide: https://ipxe.org/howto/winpe
- Azure Monitor Logs Ingestion API: https://learn.microsoft.com/azure/azure-monitor/logs/logs-ingestion-api-overview
- Windows Autopilot: https://learn.microsoft.com/autopilot/

## Where to start

For implementation, read in this order:

1. [`AGENTS.md`](AGENTS.md)
2. [`docs/PROJECT.md`](docs/PROJECT.md)
3. [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)
4. [`docs/SECURITY.md`](docs/SECURITY.md)
5. [`docs/DEPLOYMENT-LIFECYCLE.md`](docs/DEPLOYMENT-LIFECYCLE.md)
6. [`docs/ROADMAP.md`](docs/ROADMAP.md)
7. [`docs/BACKLOG.md`](docs/BACKLOG.md)

The first engineering goal is intentionally small:

> **UEFI PXE → local Edge responder → HTTP-delivered WinPE → telemetry event visible in Log Analytics, without WDS and without USB media.**
