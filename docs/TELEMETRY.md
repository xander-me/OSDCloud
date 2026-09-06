# Telemetry and Observability

## Goal

Follow a device from first PXE request through OSDCloud, Windows Setup, Autopilot, Intune provisioning and final readiness using one correlated event stream.

## Principles

- event-based, not logfile-first
- structured JSON
- stable event names
- low payload size
- UTC timestamps
- one `deploymentId` across all phases
- customer context validated server-side
- operational events separated from audit events
- raw upstream logs retained only when needed for troubleshooting

## Pipeline

```text
Edge / WinPE / Windows
        │ HTTPS JSON
        ▼
Telemetry endpoint in Control API
        │ validate + enrich + normalize
        ▼
Azure Monitor Logs Ingestion API
        │
        ▼
DCR / transformation
        │
        ▼
Log Analytics
        │
        ├─ Azure Workbook
        └─ Grafana
```

## Initial table

Use one table for the POC/MVP:

```text
OSDDeployment_CL
```

Split tables later only when operational or cost requirements justify it.

## Canonical event

```json
{
  "schemaVersion": "1.0",
  "eventId": "d69d2a66-5ce6-458c-8b06-46bd9d6fd1ef",
  "eventTime": "2026-09-06T18:01:22.123Z",
  "deploymentId": "6a7b815a-bfee-4a8b-b28f-85aaae9f4885",
  "customerId": "customer-a",
  "siteId": "site-001",
  "edgeId": "edge-001",
  "source": "winpe",
  "phase": "DeployingOS",
  "component": "OSDCloud",
  "eventName": "OSDownloadStarted",
  "status": "Running",
  "progressPercent": 0,
  "message": "Downloading Windows 11 Enterprise",
  "durationMs": null,
  "device": {
    "serialNumber": "PF4ABC123",
    "manufacturer": "Lenovo",
    "model": "ThinkPad T14 Gen 5",
    "deviceName": null
  },
  "error": null,
  "properties": {
    "osRelease": "25H2",
    "edition": "Enterprise"
  }
}
```

## Required fields

- schemaVersion
- eventId
- eventTime
- deploymentId
- source
- phase
- component
- eventName
- status

`customerId`, `siteId` and `edgeId` should be enriched/validated by the server wherever possible rather than trusted solely from the submitting client.

## Sources

Stable values initially:

```text
edge
winpe
windows
control
customer-worker
intune-enricher
```

## Phases

Use the canonical phases from `DEPLOYMENT-LIFECYCLE.md`.

## Progress events

Progress events can be noisy. Rules:

- emit phase start/end always
- emit percentage only when materially useful
- throttle progress updates (for example 5% increments or time-based)
- do not emit every console line

## Error object

```json
{
  "code": "DISM_0x800f0246",
  "category": "DriverProcessing",
  "message": "Driver package could not be installed",
  "isRetryable": false
}
```

Never place access tokens, passwords or secret material in error text.

## Device identity

Serial number is useful operationally but not guaranteed globally unique across all vendors. Correlation should always prefer `deploymentId`.

Cloud identifiers are appended when known:

- autopilotDeviceId
- entraDeviceId
- intuneDeviceId
- deviceName

## Log Analytics columns

Initial normalized columns:

```text
TimeGenerated
datetime EventTime
string SchemaVersion
string EventId
string DeploymentId
string CustomerId
string SiteId
string EdgeId
string Source
string Phase
string Component
string EventName
string Status
real ProgressPercent
long DurationMs
string Message
string ErrorCode
string ErrorCategory
string ErrorMessage
string SerialNumber
string Manufacturer
string Model
string DeviceName
string AutopilotDeviceId
string EntraDeviceId
string IntuneDeviceId
dynamic Properties
```

## Dashboard views

### Operations overview

- active deployments
- completed today
- failed today
- stalled deployments
- average deployment duration
- Edge health

### Active deployments

Columns:

- customer/site
- serial/device
- model
- current phase
- status
- elapsed time
- last event age

### Deployment details

A chronological timeline grouped by phase.

### Engineering analytics

- phase duration percentiles
- failure category
- failure by model
- failure by site
- WinPE-to-desktop time
- OS download duration
- Autopilot/ESP duration

## Derived state

Do not require clients to calculate overall current state. The dashboard/control layer derives it from latest trusted events.

Example KQL concept:

```kusto
OSDDeployment_CL
| summarize arg_max(EventTime, *) by DeploymentId
| project DeploymentId, CustomerId, SiteId, Phase, Status, EventName, EventTime
```

## Stall logic

Derived service/dashboard logic compares current phase and age of last event against configured thresholds.

Example:

```text
OSDownload:       20 minutes
OSApply:          20 minutes
WindowsSetup:     15 minutes
Autopilot:        30 minutes
IntuneProvision:  60 minutes
```

These are placeholders, not production defaults.

## Retention

Define later by customer/tier. Separate short-lived high-volume operational detail from longer-lived audit/summary data when scale requires it.
