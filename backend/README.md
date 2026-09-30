# EasyGo Backend 🚌

**Production-Ready Real-Time Bus Tracking Backend**

```
REAL BUS GPS TRACKER
      ↓
  4G / GPRS
      ↓
EASYGO BACKEND (NestJS)
      ↓
REDIS + POSTGRESQL
      ↓
  WEBSOCKET
      ↓
EASYGO FLUTTER APP
      ↓
LIVE BUS ON MAP
```

---

## Tech Stack

| Technology | Purpose |
|-----------|---------|
| NestJS + TypeScript | API Framework |
| PostgreSQL + Prisma | Persistent storage |
| Redis (ioredis) | Live bus state cache |
| Socket.IO | Real-time WebSocket |
| JWT (Passport) | Passenger authentication |
| API Key | GPS tracker authentication |
| Swagger/OpenAPI | API documentation |

---

## Prerequisites

- Node.js v18+ 
- PostgreSQL 14+
- Redis 5+

---

## Installation

```bash
cd backend
npm install
npx prisma generate
```

---

## Environment Variables

Copy `.env.example` to `.env` and configure:

```bash
cp .env.example .env
```

Key variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection string | `postgresql://postgres:password@localhost:5432/easygo_db` |
| `REDIS_HOST` | Redis host | `localhost` |
| `REDIS_PORT` | Redis port | `6379` |
| `JWT_SECRET` | JWT signing secret (min 32 chars) | — |
| `TRACKER_API_KEY` | GPS tracker API key | — |
| `MOCK_OTP` | Development OTP code | `123456` |
| `SIMULATOR_ENABLED` | Enable GPS simulator | `true` |
| `SIMULATOR_INTERVAL_MS` | Simulator tick interval | `3000` |

---

## PostgreSQL Setup

```bash
# Create database
psql -U postgres -c "CREATE DATABASE easygo_db;"

# Run migrations
npx prisma migrate dev --name init

# Seed database
npx ts-node prisma/seed.ts
```

---

## Redis Setup

```bash
# Windows (with Redis installed)
redis-server

# Or start Redis service
net start redis
```

---

## Run Development Server

```bash
npm run start:dev
```

Server starts at: `http://localhost:3000`

---

## API Documentation (Swagger)

```
http://localhost:3000/api/docs
```

---

## WebSocket Connection

Connect via Socket.IO:

```javascript
const socket = io('http://localhost:3000');

// Subscribe to a bus
socket.emit('subscribeToBus', { busId: 'bus-uuid' });

// Receive live updates
socket.on('bus.location.updated', (data) => {
  console.log('Bus update:', data);
  // data = {
  //   busId, busNumber, latitude, longitude, speed, heading,
  //   currentStop, nextStop, distanceToNextStop, distanceRemaining,
  //   etaMinutes, progressPercentage, status, timestamp
  // }
});

// Unsubscribe
socket.emit('unsubscribeFromBus', { busId: 'bus-uuid' });
```

---

## GPS Simulator (Development)

The simulator automatically starts when `SIMULATOR_ENABLED=true`.

It moves 4 buses along realistic Coimbatore routes:
- **12A** and **12A-2**: Ukkadam → Pollachi
- **24**: Pollachi → Coimbatore (Gandhipuram)
- **5B**: Ukkadam → Singanallur

Simulator controls (dev only):

```bash
# Status
GET http://localhost:3000/api/v1/simulator/status

# Control
POST http://localhost:3000/api/v1/simulator/start
POST http://localhost:3000/api/v1/simulator/stop
POST http://localhost:3000/api/v1/simulator/pause
POST http://localhost:3000/api/v1/simulator/resume
POST http://localhost:3000/api/v1/simulator/reset
```

---

## API Examples

### Authentication

```bash
# Send OTP (mock returns 123456 in dev)
POST /api/v1/auth/send-otp
{ "mobileNumber": "+919876543210" }

# Verify OTP and get JWT
POST /api/v1/auth/verify-otp
{ "mobileNumber": "+919876543210", "otp": "123456" }
```

### Live Bus Tracking

```bash
# Get live state of a bus
GET /api/v1/buses/{busId}/live

# Find nearby buses (from Redis, no DB query)
GET /api/v1/buses/nearby?latitude=10.96&longitude=76.95&radiusKm=5

# Find nearby stops
GET /api/v1/stops/nearby?latitude=10.96&longitude=76.95&radiusKm=2
```

### Search

```bash
# Search everything
GET /api/v1/search?q=12A
GET /api/v1/search?q=Pollachi

# Route search (source → destination)
GET /api/v1/routes/search?from=Pollachi&to=Coimbatore
GET /api/v1/routes/search?from=Ukkadam&to=Pollachi
```

### GPS Tracker Ingestion

```bash
# Submit GPS location (requires x-tracker-key header)
POST /api/v1/gps/location
Headers: x-tracker-key: dev-tracker-secret-key-001
{
  "deviceId": "tracker-12a-001",
  "latitude": 10.9601,
  "longitude": 76.9502,
  "speed": 32,
  "heading": 85,
  "accuracy": 5,
  "timestamp": "2026-09-29T15:30:00Z"
}
```

---

## Flutter Integration

Update `lib/core/constants/app_constants.dart`:

```dart
static const String baseUrl = 'http://YOUR_SERVER_IP:3000/api/v1';
static const String wsUrl = 'http://YOUR_SERVER_IP:3000';
```

For local development (Android emulator):
```dart
static const String baseUrl = 'http://10.0.2.2:3000/api/v1';
```

### Flutter API Contract

| Endpoint | Method | Auth |
|----------|--------|------|
| `/auth/send-otp` | POST | None |
| `/auth/verify-otp` | POST | None |
| `/buses/nearby` | GET | None |
| `/buses/:busId` | GET | None |
| `/buses/:busId/live` | GET | None |
| `/routes` | GET | None |
| `/routes/search` | GET | None |
| `/routes/:routeId` | GET | None |
| `/routes/:routeId/stops` | GET | None |
| `/routes/:routeId/buses` | GET | None |
| `/stops/nearby` | GET | None |
| `/stops/:stopId` | GET | None |
| `/search` | GET | None |
| `/favorites` | GET/POST | JWT |
| `/favorites/:id` | DELETE | JWT |
| `/alerts` | GET | None |
| `/health` | GET | None |
| WebSocket `bus.location.updated` | — | None |

---

## Real GPS Tracker Integration

When ready to replace the mock simulator with a real GPS device:

1. **Configure the tracker** to send HTTP POST requests to:
   ```
   POST https://your-server.com/api/v1/gps/location
   Header: x-tracker-key: YOUR_TRACKER_API_KEY
   ```

2. **Register the device** in the database:
   ```sql
   INSERT INTO bus_trackers (device_id, bus_id, provider, status)
   VALUES ('your-real-device-id', 'bus-uuid', 'YourGPSVendor', 'ACTIVE');
   ```

3. **Disable the simulator** in `.env`:
   ```
   SIMULATOR_ENABLED=false
   ```

4. **No other changes required** — Flutter app, WebSocket, ETA engine, and all APIs remain the same.

---

## Seeded Routes

```
Route 12A: Ukkadam → Sundakkamuthur → Madukkarai → Ettimadai → Karpagam → Kinathukadavu → Pollachi (43.5km)
Route 24:  Pollachi → Kinathukadavu → Karpagam → Ettimadai → Madukkarai → Sundakkamuthur → Gandhipuram (40.2km)  
Route 5B:  Ukkadam → Town Hall → Peelamedu → Singanallur (12.8km)
```

---

## Health Check

```bash
GET http://localhost:3000/api/v1/health
```

Returns:
```json
{
  "status": "healthy",
  "timestamp": "2026-09-29T10:00:00Z",
  "services": {
    "api": "healthy",
    "database": "healthy",
    "redis": "healthy"
  }
}
```

---

## Architecture

```
src/
├── auth/           # JWT auth + OTP
├── users/          # User management
├── buses/          # Bus CRUD + live state
├── routes/         # Route management + search
├── stops/          # Bus stop management
├── trips/          # Trip lifecycle
├── tracking/       # Core tracking engines
│   ├── tracking.service.ts      # GPS pipeline orchestrator
│   ├── stop-engine.service.ts   # Current/next stop detection
│   ├── route-progress.service.ts # Distance/progress calculation
│   └── eta.service.ts           # ETA calculation
├── gps/            # GPS ingestion endpoint (for real trackers)
├── nearby/         # Nearby buses (Redis) + stops
├── search/         # Full-text search
├── favorites/      # User favorites
├── alerts/         # Service alerts
├── realtime/       # WebSocket gateway
├── simulator/      # Mock GPS simulator
├── health/         # Health check
├── database/       # PrismaService
└── redis/          # RedisService
```
