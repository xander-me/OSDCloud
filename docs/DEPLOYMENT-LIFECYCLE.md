# Deployment Lifecycle

## Purpose

Define one canonical state machine that all components use for telemetry, authorization, dashboards and troubleshooting.

## Top-level phases

```text
Detected
  ↓
Booting
  ↓
WinPE
  ↓
Authorized
  ↓
DeployingOS
  ↓
WindowsSetup
  ↓
Autopilot
  ↓
IntuneProvisioning
  ↓
ReadinessValidation
  ↓
Complete
```

Failure can occur from any active phase.

## Detailed events

### 0. PXE / pre-WinPE

- `PxeRequestReceived`
- `PxeResponderSelected`
- `BootArtifactRequested`
- `BootArtifactDeliveryStarted`
- `BootArtifactDeliveryCompleted`
- `BootChainFailed`

### 1. WinPE initialization

- `WinPEStarted`
- `NetworkInitializationStarted`
- `NetworkReady`
- `HardwareDiscoveryCompleted`
- `ControlPlaneReachable`
- `DeploymentContextRequested`

### 2. Authorization

- `DeploymentContextResolved`
- `DeviceKnown`
- `DeviceUnknown`
- `DeploymentAuthorizationRequested`
- `DeploymentAuthorized`
- `DeploymentDenied`
- `DeploymentLeaseAcquired`

No destructive action may occur before `DeploymentAuthorized` and `DeploymentLeaseAcquired`.

### 3. OSDCloud deployment

- `DiskPreparationStarted`
- `DiskPreparationCompleted`
- `OSDownloadStarted`
- `OSDownloadProgress`
- `OSDownloadCompleted`
- `OSApplyStarted`
- `OSApplyCompleted`
- `DriverProcessingStarted`
- `DriverProcessingCompleted`
- `OfflineServicingStarted`
- `OfflineServicingCompleted`
- `PostOSStagingCompleted`
- `RebootInitiated`

### 4. Windows Setup

- `WindowsBootDetected`
- `SpecializeStarted`
- `SpecializeCompleted`
- `SetupCompleteStarted`
- `SetupCompleteCompleted`
- `OOBEStarted`

### 5. Autopilot

- `AutopilotProfileDetected`
- `AutopilotEnrollmentStarted`
- `AutopilotEnrollmentCompleted`
- `AutopilotEnrollmentFailed`

### 6. Intune provisioning

- `IntuneDeviceObserved`
- `ESPStarted`
- `ESPDevicePhaseCompleted`
- `ESPAccountPhaseCompleted`
- `ESPCompleted`
- `RequiredAppsPending`
- `RequiredAppsCompleted`
- `CompliancePending`
- `ComplianceSatisfied`

### 7. Desktop readiness

- `DesktopObserved`
- `ReadinessCheckStarted`
- `ReadinessCheckCompleted`
- `DeploymentCompleted`

## Status values

Use a small stable set:

```text
Pending
Running
Success
Warning
Failed
Blocked
Cancelled
TimedOut
```

## Readiness definitions

### WindowsReady

Minimum signal that the machine has reached a usable Windows environment:

- OOBE completed or bypassed correctly
- interactive desktop observed
- Intune enrollment record exists

### DeploymentReady

Customer-defined readiness policy may additionally require:

- Intune Management Extension present
- required apps installed
- required security policy observed
- compliance state acceptable
- required certificates/network profiles delivered
- no blocking ESP failure

The platform must distinguish `WindowsReady` from `DeploymentReady`.

## Stall detection

Each phase has an expected duration profile. A deployment is marked `Stalled` by derived monitoring logic when no new event arrives within the configured threshold for the active phase.

Do not synthesize a failure event on the device merely because the dashboard detects a stall. Keep observed events and derived health separate.

## Correlation persistence

At deployment start:

```powershell
$DeploymentId = [guid]::NewGuid().Guid
```

Persist into installed Windows before reboot, for example:

```text
C:\ProgramData\OSDCloudPlatform\deployment.json
```

Suggested content:

```json
{
  "schemaVersion": "1.0",
  "deploymentId": "...",
  "customerId": "...",
  "siteId": "...",
  "profileId": "..."
}
```

Do not persist bearer tokens or reusable credentials in this file.
