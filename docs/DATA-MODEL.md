# Data Model

## Core entities

### Customer

```text
customerId
name
isolationTier
status
createdAt
```

### Site

```text
siteId
customerId
name
allowedSubnets[]
status
```

### Edge

```text
edgeId
customerId
siteId
hostname
version
releaseRing
activeBootRelease
capabilities[]
status
lastSeen
```

### DeploymentProfile

```text
profileId
customerId
name
os
edition
language
autopilotSettings
securityPolicy
readinessPolicy
status
```

### Device

```text
deviceId
customerId
serialNumber
smbiosUuid
manufacturer
model
autopilotDeviceId
entraDeviceId
intuneDeviceId
deviceName
status
```

### Deployment

```text
deploymentId
customerId
siteId
edgeId
deviceId
profileId
state
startedAt
lastEventAt
completedAt
leaseId
```

### DeploymentLease

```text
leaseId
deploymentId
deviceId
expiresAt
status
```

### BootRelease

```text
releaseId
version
ring
manifestUri
status
createdAt
```

### TelemetryEvent

```text
eventId
deploymentId
customerId
siteId
edgeId
eventTime
source
phase
component
eventName
status
payload
```

## Relationship model

```text
Customer
  ├─ Site
  │   └─ Edge
  ├─ DeploymentProfile
  ├─ Device
  └─ Deployment
        ├─ Device
        ├─ Site
        ├─ Edge
        ├─ DeploymentProfile
        ├─ DeploymentLease
        └─ TelemetryEvent[]
```

## Identifier rules

- IDs are immutable.
- Human-readable names are not primary keys.
- `deploymentId` is generated once per deployment attempt.
- Reinstalling the same physical device creates a new `deploymentId`.
- `deviceId` represents the platform's logical device record and may survive multiple deployments.
- Serial number is an attribute, not a globally trusted unique key.

## Customer scoping

Every customer-owned entity must be queryable only inside its customer scope.

Where database technology supports row-level security or partition keys, `customerId` should be part of that design rather than enforced only in UI code.

## Device matching

Initial matching may use a weighted combination of:

- SMBIOS UUID
- serial number
- manufacturer/model
- known Autopilot device ID
- previously observed hardware identity

Do not trust a MAC address as stable device identity.

## Readiness policy

Readiness should be stored as policy rather than hard-coded application logic.

Example conceptual model:

```json
{
  "requiredSignals": [
    "IntuneDeviceObserved",
    "ESPCompleted",
    "RequiredAppsCompleted",
    "ComplianceSatisfied",
    "DesktopObserved"
  ],
  "timeoutMinutes": 90
}
```

## Audit separation

Audit records should be represented separately from ordinary telemetry so retention, integrity and access controls can differ.
