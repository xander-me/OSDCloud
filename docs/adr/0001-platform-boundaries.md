# ADR-0001: Separate Control, Edge, Agent and Observe Boundaries

- **Status:** Accepted
- **Date:** 2026-09-06

## Context

The platform combines local PXE behavior, destructive Windows deployment, privileged customer tenant integrations and central telemetry. Collapsing these into one highly privileged component would increase blast radius and make multi-customer isolation harder to reason about.

## Decision

Use four logical boundaries:

- **Control** — authorization, configuration, orchestration
- **Edge** — local PXE/bootstrap/cache
- **Agent** — WinPE/Windows deployment execution and telemetry
- **Observe** — monitoring and analytics

OSDCloud remains an upstream deployment engine used by Agent code.

## Consequences

Positive:

- lower Edge privilege
- clearer multi-customer separation
- observability cannot authorize deployment
- easier component testing
- customer Graph rights remain server-side

Costs:

- more interfaces/contracts
- additional identity/bootstrap design
- deployment correlation must survive phase boundaries

---

# ADR-0002: PXE Boot Does Not Authorize Disk Wipe

- **Status:** Accepted
- **Date:** 2026-09-06

## Context

PXE is discoverable on a local network and cannot be treated as sufficient proof that a machine should be destructively reimaged.

## Decision

Allow a device to boot WinPE without granting destructive privileges. A separate control-plane authorization and active deployment lease are mandatory before disk wipe/OS deployment.

## Consequences

- safe diagnostics can occur before authorization
- unknown devices can be blocked centrally
- zero-touch remains possible for pre-authorized policy cases
- offline destructive deployment requires a separate future security design

---

# ADR-0003: Customer Graph Credentials Stay Server-Side

- **Status:** Accepted
- **Date:** 2026-09-06

## Context

Autopilot registration requires privileged customer tenant access. WinPE and Edge nodes are unsuitable places for reusable cross-deployment credentials.

## Decision

Autopilot/Graph operations are executed through customer-scoped backend workers. WinPE sends required device data to the control plane using a short-lived deployment identity; it never receives the worker credential.

## Consequences

- compromise of a boot image does not directly disclose customer Graph secrets
- each customer can use an isolated workload identity
- control API becomes an important privileged trust boundary

---

# ADR-0004: Event-Based Telemetry with DeploymentId Correlation

- **Status:** Accepted
- **Date:** 2026-09-06

## Context

Raw OSDCloud/Windows logs are useful diagnostically but poor as a near-real-time operational state model.

## Decision

Emit structured lifecycle events and correlate every stage with a stable `deploymentId`. Preserve raw logs separately only when needed.

## Consequences

- dashboards can derive current phase without text parsing
- metrics become queryable
- event contract must be versioned and tested
- code must carefully persist correlation across reboot
