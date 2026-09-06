# AGENTS.md

This repository is designed to be implemented with help from Codex and other engineering agents.

## Mission

Build a secure, multi-customer, cloud-native Windows deployment platform around OSDCloud that can observe a device from network boot through Autopilot/Intune until a usable desktop is available.

## Non-negotiable boundaries

1. **Do not reimplement OSDCloud unnecessarily.** Wrap or extend upstream behavior where possible.
2. **Never embed reusable customer secrets in WinPE, Edge packages, scripts, source code, examples or test fixtures.**
3. **PXE boot permission is not disk-wipe permission.** Destructive actions require a separate authorization decision.
4. **Customer isolation is explicit.** Every customer-owned object must carry a `customerId` and server-side authorization must enforce it.
5. **All external contracts are versioned.** Telemetry, deployment profiles and API payloads must include schema/API versions.
6. **Every destructive or privileged action must be auditable.**
7. **Fail closed.** If identity, authorization, signature verification or customer resolution fails, deployment must stop before destructive operations.
8. **Secure Boot must remain enabled in the production target design.** Do not solve boot-chain issues by documenting Secure Boot disablement as the normal path.
9. **Keep the Edge role low privilege.** Edge nodes deliver approved boot content and telemetry; they do not receive customer Graph secrets.
10. **Use short-lived/scoped tokens.** Device/WinPE credentials should be deployment-scoped and expiring.

## Engineering style

- Prefer small components with clear interfaces.
- Use PowerShell 7-compatible syntax where practical, but validate WinPE compatibility before adopting features unavailable in Windows PowerShell 5.1.
- Keep WinPE dependencies minimal.
- Avoid GUI dependencies in the deployment path.
- Use structured logging instead of parsing console output where we control the code.
- Treat upstream OSDCloud output as an integration boundary; wrap it with stable project-specific events.
- Use UTC ISO-8601 timestamps.
- Generate UUID/GUID identifiers server-side or at deployment start.
- Do not place personal data in telemetry unless required for a defined operational purpose.

## Repository structure target

```text
src/
  control-api/
  edge/
  winpe/
  windows-agent/
  autopilot-worker/
  telemetry/
infra/
  bicep/
  dashboards/
schemas/
tests/
docs/
```

Do not create all components prematurely. Follow `docs/ROADMAP.md` and `docs/BACKLOG.md`.

## Initial POC constraint

The first POC proves only this chain:

```text
UEFI PXE
  → Edge responder
  → iPXE/wimboot
  → HTTP WinPE
  → WinPE startup
  → telemetry API
  → Log Analytics
```

No automatic disk wipe is allowed in the first POC.

## Pull request expectations

Each PR should include:

- Goal and scope
- Security impact
- Test evidence
- Telemetry impact
- Customer-isolation impact
- Documentation updates when contracts/architecture change

Create or update an ADR when a change alters an architectural decision.
