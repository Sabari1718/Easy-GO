# EasyGo — Real GPS Tracker Integration Guide

This specification describes how to connect physical GPS tracker hardware (installed inside passenger buses) to the **EasyGo Real-Time Transit Platform**.

The EasyGo GPS ingestion API is hardware-agnostic. It supports any 4G/LTE, 3G, GPRS, or OBD-II tracker capable of transmitting HTTP/HTTPS POST requests directly or via a standard IoT gateway.

---

## 1. Server Configuration & Endpoints

| Environment | Base URL | GPS Ingestion Endpoint | Heartbeat Endpoint |
| :--- | :--- | :--- | :--- |
| **Development / Local** | `http://<SERVER_IP>:3000` | `POST /gps/location` | `POST /gps/heartbeat` |
| **Production** | `https://api.easygo.transit/` | `POST /gps/location` | `POST /gps/heartbeat` |

---

## 2. Authentication

Each physical GPS device is assigned a unique **Tracker ID** (e.g., `TRK001`) and a **Device Secret / API Key**.

Authentication must be passed in HTTP Request Headers:

```http
Content-Type: application/json
X-Tracker-Key: <DEVICE_SECRET_KEY>
X-Tracker-Id: <TRACKER_ID>
```

> **Security Note:**
> Device authentication is isolated from passenger JWT tokens. Do not share passenger tokens with GPS hardware. If a tracker device is decommissioned or reported lost, it can be revoked instantly via the Tracker Management API (`POST /trackers/:trackerId/deactivate`) without affecting other buses.

---

## 3. Telemetry Ingestion Specification (`POST /gps/location`)

Physical trackers send coordinate and motion telemetry to this endpoint.

### HTTP Headers
```http
POST /gps/location HTTP/1.1
Host: api.easygo.transit
Content-Type: application/json
X-Tracker-Key: trk001-secret-key
X-Tracker-Id: TRK001
```

### Request JSON Payload
```json
{
  "trackerId": "TRK001",
  "latitude": 10.912345,
  "longitude": 76.956789,
  "speed": 34.5,
  "heading": 125.0,
  "accuracy": 4.2,
  "timestamp": "2026-09-30T10:15:30.000Z"
}
```

### Field Definitions

| Field | Type | Required | Valid Range | Description |
| :--- | :--- | :--- | :--- | :--- |
| `trackerId` | String | Yes* | Alphanumeric (e.g. `TRK001`) | Device identifier. Can be in body or `X-Tracker-Id` header. |
| `latitude` | Float | Yes | `-90.0` to `+90.0` | WGS84 standard GPS latitude in decimal degrees. |
| `longitude` | Float | Yes | `-180.0` to `+180.0` | WGS84 standard GPS longitude in decimal degrees. |
| `speed` | Float | Yes | `>= 0.0` | Instantaneous vehicle speed in **km/h**. |
| `heading` | Float | Yes | `0.0` to `360.0` | Compass bearing (`0°` = North, `90°` = East, `180°` = South, `270°` = West). |
| `accuracy` | Float | Optional | `0.0` to `50.0` | Horizontal positioning error in meters (HDOP). |
| `timestamp` | String | Yes | ISO 8601 UTC | Telemetry timestamp (e.g., `YYYY-MM-DDTHH:mm:ss.sssZ`). |

*\* If `X-Tracker-Id` is provided in the HTTP header, `trackerId` in JSON body is optional.*

> **Automatic Bus Mapping:**
> The backend automatically looks up which Bus and Route this tracker is assigned to (e.g., `TRK001` → `BUS_12A` → `Route 12A: Ukkadam → Pollachi`). The hardware does **not** need to be reconfigured when the bus route schedule changes.

### Success Response (`200 OK`)
```json
{
  "success": true,
  "busId": "BUS_12A",
  "receivedAt": "2026-09-30T10:15:30.250Z"
}
```

### Error Responses

| HTTP Status | Error Reason | Description & Recommended Device Action |
| :--- | :--- | :--- |
| `400 Bad Request` | Coordinates / Timestamp invalid | Check coordinate ranges (`-90..90`, `-180..180`) or fix device RTC clock. |
| `401 Unauthorized` | Invalid `X-Tracker-Key` | Ensure hardware secret matches provisioned key. Do not retry aggressively. |
| `403 Forbidden` | Inactive Tracker or Bus mismatch | Device is suspended or attempted to send for an unassigned bus. Contact dispatch. |
| `429 Too Many Requests` | Rate limit exceeded | Device transmitting too frequently (> 2 requests/second). Increase interval. |
| `500 Server Error` | Temporary backend issue | Retry after exponential backoff (2s, 4s, 8s). |

---

## 4. Heartbeat / Liveness Endpoint (`POST /gps/heartbeat`)

When a bus is parked at a depot or idling with engine off, trackers can conserve cellular bandwidth by sending lightweight heartbeat pings instead of full GPS frames.

### HTTP Headers
```http
POST /gps/heartbeat HTTP/1.1
Content-Type: application/json
X-Tracker-Key: trk001-secret-key
```

### Request JSON Payload
```json
{
  "trackerId": "TRK001",
  "timestamp": "2026-09-30T10:20:00.000Z"
}
```

### Success Response (`200 OK`)
```json
{
  "success": true,
  "trackerId": "TRK001",
  "busId": "BUS_12A",
  "deviceStatus": "ONLINE",
  "lastSeenAt": "2026-09-30T10:20:00.100Z"
}
```

---

## 5. Transmission Recommendations & Device Timing

1. **Active Route / Moving:**
   - Transmit `POST /gps/location` every **3 to 5 seconds**.
   - If bus is stationary at a traffic light or bus stop (`speed < 2 km/h`), transmission interval can scale to **10 seconds**.
2. **Stationary / Parked / Depot:**
   - Transmit `POST /gps/heartbeat` every **60 to 120 seconds**.
3. **Location Freshness Windows (EasyGo Passenger App):**
   - **0–15 seconds:** 🟢 **LIVE** — Smooth Google Maps marker animation.
   - **15–60 seconds:** 🟡 **RECENT** — Displayed as recent with elapsed seconds.
   - **60–300 seconds:** 🟠 **STALE** — Marker marked stale with elapsed minutes.
   - **> 300 seconds:** ⚫ **OFFLINE / LOCATION UNAVAILABLE** — Real-time marker hidden from active tracking to prevent misleading passengers.
4. **Offline Buffer & Reconnect:**
   - If cellular signal is lost in a tunnel or rural zone, the device should cache points in flash memory and flush upon reconnect with original GPS timestamps preserved.

---

## 6. Tracker Provisioning & Management APIs

Admins manage tracker assignments via REST:

| Method | Endpoint | Description |
| :--- | :--- | :--- |
| `GET` | `/trackers` | List all provisioned GPS trackers and assigned buses |
| `GET` | `/trackers/:trackerId` | Get tracker hardware and assignment details |
| `POST` | `/trackers` | Provision a new tracker with IMEI, model, SIM, and secret |
| `PATCH` | `/trackers/:trackerId` | Update tracker settings (SIM, model, secret) |
| `POST` | `/trackers/:trackerId/activate` | Enable GPS telemetry ingestion |
| `POST` | `/trackers/:trackerId/deactivate` | Revoke/suspend device ingestion |
| `POST` | `/trackers/:trackerId/assign-bus` | Map tracker to a bus (`{ "busId": "BUS_12A" }`) |
| `POST` | `/trackers/:trackerId/unassign-bus`| Detach tracker from bus |

---

## 7. Example Testing via curl / Postman

### Step 1: Submit Live Location
```bash
curl -X POST http://localhost:3000/gps/location \
  -H "Content-Type: application/json" \
  -H "X-Tracker-Key: trk001-secret-key" \
  -H "X-Tracker-Id: TRK001" \
  -d '{
    "latitude": 10.9256,
    "longitude": 76.9330,
    "speed": 38.0,
    "heading": 130.0,
    "accuracy": 3.5,
    "timestamp": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'"
  }'
```

### Step 2: Send Heartbeat
```bash
curl -X POST http://localhost:3000/gps/heartbeat \
  -H "Content-Type: application/json" \
  -H "X-Tracker-Key: trk001-secret-key" \
  -d '{
    "trackerId": "TRK001",
    "timestamp": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'"
  }'
```

### Step 3: Verify Live Telemetry
```bash
curl http://localhost:3000/buses/BUS_12A/live
```
