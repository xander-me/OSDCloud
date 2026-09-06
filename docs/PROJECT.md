# Project Definition

## Problem statement

Modern Windows deployment still often depends on one or more of the following:

- USB media that drifts out of date
- Dedicated WDS/PXE infrastructure
- Site-specific server dependencies
- Opaque deployment progress
- Manual technician intervention
- Poor visibility between OS installation and Autopilot/Intune readiness

The project aims to preserve the strengths of OSDCloud while adding distributed boot capability, centralized authorization, multi-customer separation and end-to-end telemetry.

## Primary outcome

A technician should be able to power on an approved device, choose network boot and then observe the entire journey in a central dashboard until the device is ready for a user.

## Functional goals

### Boot and delivery

- UEFI network boot without requiring a dedicated WDS server at every site.
- Selected Windows endpoints can act as local Edge nodes.
- Edge nodes can answer PXE/ProxyDHCP requests when network topology permits.
- WinPE is delivered through a modern HTTP-based chain using iPXE/wimboot where appropriate.
- Boot content is centrally versioned and locally cacheable.
- USB remains available as a break-glass option, not the normal path.

### Deployment

- OSDCloud remains the Windows deployment engine.
- Deployment profiles define OS, edition, language and deployment behavior.
- Device hardware is discovered before destructive operations.
- A server-side authorization decision is required before disk wipe.
- Autopilot registration can be requested through customer-scoped backend workers.
- OSDCloud hands the device to Autopilot/Intune as early as practical.

### Observability

- Every deployment has a stable `deploymentId`.
- Events begin at PXE discovery when possible.
- WinPE, OS deployment, Windows Setup, Autopilot and post-enrollment stages share the same correlation identity.
- Events are visible in Log Analytics with low latency.
- Operators can view active, successful, failed and stalled deployments.
- The system can calculate phase durations and failure rates.

### Multi-customer

- Customer resources and authorization boundaries are explicit.
- Customer-specific Graph/Autopilot permissions are isolated.
- The platform supports both shared and dedicated telemetry workspaces.
- Site/subnet/Edge relationships are customer-scoped.
- A customer profile cannot be selected by client-side manipulation alone.

### Security

- No reusable tenant credentials in WinPE.
- No reusable Graph credentials on Edge nodes.
- Secure Boot remains part of the production design.
- Signed/hash-verified deployment artifacts.
- Short-lived deployment-scoped tokens.
- Fail-closed authorization before destructive actions.
- Full audit trail for privileged actions.

## Non-goals

The project is not intended to:

- Replace Intune as endpoint management.
- Replace Windows Autopilot.
- Replace OSDCloud's deployment engine.
- Become a general-purpose remote management tool.
- Provide remote shell capability from the control plane.
- Store end-user passwords or credentials.
- Automatically bypass unsupported network or Secure Boot configurations.
- Promise fully unattended deployment on every hardware/network combination.

## Personas

### Deployment technician

Needs a simple workflow:

```text
F12 → Network Boot → deployment progresses → device ready
```

Should not need Azure, Graph or customer tenant credentials.

### Platform operator

Needs to:

- view deployments
- approve or deny deployment when policy requires it
- inspect failure context
- manage boot-image rollout
- manage Edge health
- manage deployment profiles

### Customer administrator

Needs customer-scoped visibility and configuration without access to other customers.

### Platform engineer

Needs clear APIs, versioned contracts, testable components, deployment telemetry and safe release channels.

## Success criteria

### POC

- One Windows Edge node can boot a second UEFI device into WinPE without WDS or USB.
- WinPE can emit a structured event through the control path into Log Analytics.
- The event can be correlated to Edge node and device identity.
- No disk modification is performed.

### MVP

- Authorized device can complete OSDCloud install.
- Same `deploymentId` survives reboot into Windows.
- Autopilot/Intune stages can be correlated.
- Dashboard shows current phase and failure state.
- At least two isolated customer configurations work safely.

### Production target

- Secure boot chain validated on representative OEM hardware.
- Edge HA/failover tested.
- Artifact rollout/rollback implemented.
- Customer isolation security tested.
- Destructive-action authorization audited.
- Operational alerting and data retention defined.
