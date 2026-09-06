# Control Plane API

## Goals

The API is the trust boundary between temporary/local deployment components and privileged cloud operations.

All contracts are versioned under `/api/v1` initially.

## Initial endpoints

### Edge registration

`POST /api/v1/edges/register`

Purpose: bootstrap an Edge identity through an administrative enrollment flow.

### Edge heartbeat

`POST /api/v1/edges/{edgeId}/heartbeat`

Payload includes version, health, active boot release, local capabilities and observed subnet information.

### PXE event

`POST /api/v1/telemetry/events`

Used for Edge, WinPE and Windows operational events.

### Resolve deployment context

`POST /api/v1/deployments/context`

Request:

```json
{
  "apiVersion": "v1",
  "edgeId": "edge-001",
  "device": {
    "serialNumber": "PF4ABC123",
    "manufacturer": "Lenovo",
    "model": "ThinkPad T14 Gen 5",
    "smbiosUuid": "...",
    "macAddresses": ["..."]
  }
}
```

Response:

```json
{
  "apiVersion": "v1",
  "deploymentId": "...",
  "customerId": "customer-a",
  "siteId": "site-001",
  "deviceState": "Known",
  "authorizationRequired": true,
  "allowedProfileIds": ["store-w11"]
}
```

### Request deployment authorization

`POST /api/v1/deployments/{deploymentId}/authorize`

Request:

```json
{
  "apiVersion": "v1",
  "profileId": "store-w11",
  "requestedActions": ["wipeDisk", "deployOs", "registerAutopilot"]
}
```

Response:

```json
{
  "apiVersion": "v1",
  "deploymentId": "...",
  "authorized": true,
  "expiresAt": "...",
  "profile": {
    "profileId": "store-w11",
    "os": "Windows11-25H2",
    "edition": "Enterprise",
    "language": "da-DK",
    "autopilot": {
      "enabled": true,
      "groupTag": "Store"
    }
  },
  "allowedActions": ["wipeDisk", "deployOs", "registerAutopilot"],
  "deploymentToken": "<short-lived-token>"
}
```

The actual implementation may return the token in an authorization header/cookie flow instead; the contract above illustrates scope only.

### Deployment lease renew

`POST /api/v1/deployments/{deploymentId}/lease/renew`

Prevents concurrent destructive deployments for the same device.

### Autopilot registration request

`POST /api/v1/deployments/{deploymentId}/autopilot/register`

The control plane routes this to the correct customer worker. WinPE never receives the customer Graph credential.

### Boot release lookup

`GET /api/v1/edges/{edgeId}/boot-release`

Returns the approved immutable release manifest for that Edge/release ring.

## Authentication model

### Edge

Strong per-Edge identity, certificate-backed where practical.

### WinPE

Starts with low trust. After context and policy validation, receives a short-lived deployment-scoped credential.

### Windows agent

Uses the persisted deployment identity and a safe re-authentication/bootstrap mechanism; do not persist a long-lived WinPE bearer token across reboots.

### Operator

Microsoft Entra ID interactive identity and role-based authorization.

## Authorization invariants

Every protected request must verify:

1. caller identity
2. customer scope
3. target deployment/customer match
4. requested operation scope
5. token expiry/revocation
6. deployment lease where destructive work is involved

## Error format

```json
{
  "error": {
    "code": "deployment_not_authorized",
    "message": "Deployment is not authorized for the requested operation.",
    "correlationId": "..."
  }
}
```

Do not expose secrets, internal stack traces or cross-customer identifiers.

## Idempotency

Important POST operations should support idempotency:

- telemetry via unique `eventId`
- deployment context creation
- authorization requests
- Autopilot registration requests

Repeated submissions must not create duplicate Autopilot registrations or multiple active leases.

## Versioning

Breaking contract changes require a new API/schema version. Avoid silently changing meaning of existing event names or fields.
