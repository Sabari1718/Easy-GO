# EasyGo — Production Deployment Checklist

This document is the operational checklist for deploying the EasyGo Real-Time Transit Platform to a production cloud environment before connecting physical GPS hardware devices.

---

## 1. Domain & DNS Configuration
- [ ] Registered public domain (e.g., `easygo.yourdomain.com`).
- [ ] Configured DNS A / CNAME records pointing to the load balancer or cloud VM public IP:
  - `api.easygo.yourdomain.com` → Backend API & WebSocket server.
  - `admin.easygo.yourdomain.com` → Fleet operations dashboard (if applicable).
- [ ] Verified global DNS propagation (`dig api.easygo.yourdomain.com +short`).

---

## 2. HTTPS & TLS Termination
- [ ] Provisioned valid SSL/TLS certificate (Let's Encrypt, AWS ACM, Cloudflare, or commercial CA).
- [ ] Configured TLS 1.2 and TLS 1.3 only (disabled insecure SSLv3, TLS 1.0, TLS 1.1).
- [ ] Configured automatic certificate renewal (Certbot timer or cloud provider managed).
- [ ] Verified certificate validity and trust chain via SSL Labs (`Grade A+` recommended).

---

## 3. Firewall & Network Routing
- [ ] Inbound TCP Port `443` (HTTPS) open to internet / cellular APN IP blocks.
- [ ] Inbound TCP Port `80` redirected to `443` (HTTP → HTTPS 301 redirect).
- [ ] Inbound Port `5432` (PostgreSQL) strictly restricted to private VPC / backend security group.
- [ ] Inbound Port `6379` (Redis) strictly restricted to private VPC / backend security group.
- [ ] Inbound SSH Port `22` restricted to authorized bastion host or VPN CIDRs.

---

## 4. WebSocket & Reverse Proxy Configuration
- [ ] Configured Nginx / Caddy / Cloud Load Balancer with WebSocket upgrade headers:
  ```nginx
  proxy_http_version 1.1;
  proxy_set_header Upgrade $http_upgrade;
  proxy_set_header Connection "upgrade";
  proxy_set_header Host $host;
  proxy_set_header X-Real-IP $remote_addr;
  proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
  proxy_set_header X-Forwarded-Proto $scheme;
  ```
- [ ] Configured proxy read and write timeouts to `>= 3600s` to prevent WebSocket drops during bus idle states.
- [ ] Tested WebSocket connection over `wss://api.easygo.yourdomain.com/socket.io/`.

---

## 5. PostgreSQL Database Deployment
- [ ] Managed PostgreSQL 15+ cluster deployed (AWS RDS, GCP Cloud SQL, or DigitalOcean Managed DB).
- [ ] Automated daily database backups enabled with point-in-time recovery (PITR) retention >= 7 days.
- [ ] Database connection pooling configured (`pgBouncer` or Prisma connection pool limits adjusted for concurrent requests).
- [ ] Required indexes verified:
  - `bus_trackers`: `trackerId`, `deviceId`, `busId`, `lastSeenAt`
  - `bus_locations`: `busId`, `tripId`, `timestamp`
  - `route_stops`: `routeId`, `stopId`, `sequence`
- [ ] Run Prisma production migrations:
  ```bash
  npx prisma migrate deploy
  ```

---

## 6. Redis In-Memory Cache
- [ ] Redis 7+ instance running with persistence (`AOF` or `RDB` snapshots).
- [ ] Password authentication enabled (`requirepass <STRONG_REDIS_PASSWORD>`).
- [ ] Memory eviction policy set to `volatile-lru` or `allkeys-lru` with appropriate maxmemory limit.
- [ ] Backend verified connecting to Redis (`redisStatus: 'healthy'` in `GET /health`).

---

## 7. Environment Variables (.env) Validation
- [ ] Production `.env` securely populated (never committed to Git):
  ```ini
  NODE_ENV=production
  APP_PORT=3000
  DATABASE_URL=postgresql://easygo_user:STRONG_PWD@db-cluster.internal:5432/easygo_prod?sslmode=require
  REDIS_HOST=redis-cluster.internal
  REDIS_PORT=6379
  REDIS_PASSWORD=STRONG_REDIS_SECRET
  JWT_SECRET=MINIMUM_32_CHARACTERS_SECURE_RANDOM_STRING
  ADMIN_API_KEY=MINIMUM_32_CHARACTERS_SECURE_ADMIN_KEY
  GPS_API_BASE_URL=https://api.easygo.yourdomain.com
  WEBSOCKET_URL=https://api.easygo.yourdomain.com
  GPS_MAX_ACCURACY_METERS=100
  SIMULATOR_ENABLED=false
  ```
- [ ] `SIMULATOR_ENABLED` explicitly set to `false` in production.

---

## 8. GPS Ingestion Endpoint Accessibility
- [ ] Confirmed `POST /gps/location` is publicly reachable over HTTPS.
- [ ] Verified device secret authentication rejected with `401 Unauthorized` when key is missing or invalid.
- [ ] Verified rate limiting allows sustained 3-5s pings per bus without triggering false-positive 429 errors.
- [ ] Verified payload size limits allow standard JSON packets (`client_max_body_size 1m`).

---

## 9. Logging & Observability
- [ ] Structured JSON logging enabled in production.
- [ ] Sensitive credential masking verified:
  - Secrets, API keys, passwords, and passenger tokens are never printed in logs.
- [ ] Log shipping configured (Datadog, CloudWatch, Grafana Loki, or ELK Stack).
- [ ] Log rotation configured (`logrotate` for file-based logs) to prevent disk exhaustion.

---

## 10. Monitoring & Alerting
- [ ] Uptime monitoring configured for `GET /health` (every 30 seconds).
- [ ] Alerting rules established for:
  - HTTP 5xx error rate > 1%.
  - High response latency (p95 > 500ms).
  - High database connection pool utilization (> 85%).
  - Redis memory usage (> 80%).
  - Disk space utilization (> 80%).
- [ ] Stale bus detection alert: Notification triggered when an active route bus stops sending telemetry for > 5 minutes during operating hours.

---

## 11. Security Hardening
- [ ] Running application under non-root system user (`nodejs` / `easygo`).
- [ ] Helmet security headers active (`X-Frame-Options`, `X-Content-Type-Options`, `Strict-Transport-Security`).
- [ ] CORS policies locked down to trusted Flutter app origins and management portals.
- [ ] Operating system security updates applied (`unattended-upgrades`).

---

## 12. Pre-Go-Live Verification Checklist
- [ ] `GET https://api.easygo.yourdomain.com/health` returns `{"status":"healthy","services":{"api":"healthy","database":"healthy","redis":"healthy","websocket":"healthy"}}`.
- [ ] Registered first test tracker `TRK001` via `POST /admin/trackers`.
- [ ] Performed hardware simulator test against the production HTTPS endpoint.
- [ ] Verified live bus location update reflected on Flutter mobile application via WebSocket.
