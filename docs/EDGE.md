# OSDCloud Edge

## Purpose

Provide site-local network boot capability without requiring a dedicated WDS server.

An Edge node is an ordinary managed Windows endpoint or lightweight Windows host that can be promoted into a local deployment bootstrap role.

## Responsibilities

- register with control plane
- send heartbeat/health
- know its site/customer/subnet scope
- answer PXE/ProxyDHCP requests where supported
- provide iPXE bootstrap
- serve approved WinPE artifacts over HTTP
- cache immutable boot releases
- validate artifact hashes/signatures
- emit PXE and delivery telemetry

## Non-responsibilities

Edge must not:

- contain reusable customer Graph secrets
- authorize disk wipe on its own
- choose a customer based solely on client request
- mutate boot releases in place
- expose arbitrary file serving outside the approved cache
- provide remote shell/control-plane command execution

## Network model

Preferred model for distributed sites:

```text
Existing DHCP
   │
   ├─ IP configuration
   │
PXE client broadcast
   │
   └─ OSDCloud Edge / ProxyDHCP
          │
          └─ boot instruction
                ↓
              iPXE
                ↓
         local HTTP boot cache
```

Where the customer network requires routing between subnets, IP-helper design may still be required. The goal is to avoid requiring a dedicated deployment server, not to bypass normal layer-3 network behavior.

## Edge state

Suggested health model:

```text
Unknown
Registering
Healthy
Degraded
Draining
Offline
Revoked
```

## Edge metadata

```json
{
  "edgeId": "...",
  "customerId": "...",
  "siteId": "...",
  "hostname": "...",
  "version": "0.1.0",
  "releaseRing": "lab",
  "activeBootRelease": "1.0.0",
  "subnets": ["10.20.30.0/24"],
  "capabilities": ["pxe", "http-cache"],
  "lastSeen": "..."
}
```

## Boot release cache

```text
C:\ProgramData\OSDCloudEdge\cache\
  releases\
    1.0.0\
      manifest.json
      ipxe.efi
      wimboot
      BCD
      boot.sdi
      boot.wim
```

A release is activated only after all required artifacts are validated.

## Release lifecycle

```text
Announced
  ↓
Downloading
  ↓
Validating
  ↓
Ready
  ↓
Active
  ↓
Retired
```

Failed validation keeps the previous active release intact.

## Edge selection / HA

POC: one Edge per subnet.

Later design:

- candidate discovery through control plane
- active/standby roles
- heartbeat timeout
- deterministic election or server-assigned active responder
- drain mode before maintenance
- only healthy nodes with current approved release can become active

## Security controls

- unique Edge identity
- certificate or equivalent strong credential
- revocation support
- TLS to control plane
- explicit allowed subnets
- approved release only
- local firewall rules scoped to necessary ports/interfaces
- no customer Graph permissions

## POC acceptance criteria

1. Windows host runs Edge prototype.
2. Second UEFI device sends PXE request.
3. Edge responds without WDS.
4. iPXE/wimboot chain loads WinPE over HTTP.
5. Edge emits `PxeRequestReceived` and boot-delivery events.
6. WinPE emits `WinPEStarted` through telemetry path.
7. No disk modification occurs.
