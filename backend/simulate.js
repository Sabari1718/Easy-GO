/**
 * EasyGo Standalone Mock GPS Simulator
 * Sends simulated real-time GPS coordinates directly to POST /gps/location
 * using HTTP with x-tracker-key authentication.
 *
 * Usage:
 *   node simulate.js
 *   npm run simulate
 */

const http = require('http');

const BACKEND_HOST = process.env.APP_HOST || 'localhost';
const BACKEND_PORT = process.env.APP_PORT || 3000;
const TRACKER_KEY = process.env.TRACKER_API_KEY || 'dev-tracker-secret-key-001';
const INTERVAL_MS = parseInt(process.env.SIM_INTERVAL_MS || '3000', 10);

// Predefined route geometries
const ROUTE_12A = [
  { lat: 10.9601, lng: 76.9502, stop: 'Ukkadam' },
  { lat: 10.9558, lng: 76.9471 },
  { lat: 10.9512, lng: 76.9445 },
  { lat: 10.9415, lng: 76.9398 },
  { lat: 10.9362, lng: 76.9375, stop: 'Sundakkamuthur' },
  { lat: 10.9256, lng: 76.9330 },
  { lat: 10.9148, lng: 76.9285 },
  { lat: 10.9042, lng: 76.9238 },
  { lat: 10.8952, lng: 76.9192, stop: 'Madukkarai' },
  { lat: 10.8858, lng: 76.9144 },
  { lat: 10.8712, lng: 76.9068 },
  { lat: 10.8618, lng: 76.9015, stop: 'Ettimadai' },
  { lat: 10.8471, lng: 76.8931 },
  { lat: 10.8420, lng: 76.8901, stop: 'Karpagam' },
  { lat: 10.8268, lng: 76.8812 },
  { lat: 10.8164, lng: 76.8749, stop: 'Kinathukadavu' },
  { lat: 10.7952, lng: 76.8619 },
  { lat: 10.7678, lng: 76.8443 },
  { lat: 10.7334, lng: 76.8211 },
  { lat: 10.7094, lng: 76.8041 },
  { lat: 10.6970, lng: 76.7950, stop: 'Pollachi' },
];

const ROUTE_21 = [
  { lat: 10.6970, lng: 76.7950, stop: 'Pollachi' },
  { lat: 10.7130, lng: 76.8070 },
  { lat: 10.7290, lng: 76.8185 },
  { lat: 10.7450, lng: 76.8295 },
  { lat: 10.7605, lng: 76.8400, stop: 'Kinathukadavu' },
  { lat: 10.7758, lng: 76.8500 },
  { lat: 10.7980, lng: 76.8640 },
  { lat: 10.8191, lng: 76.8768, stop: 'Karpagam' },
  { lat: 10.8392, lng: 76.8885 },
  { lat: 10.8521, lng: 76.8957, stop: 'Ettimadai' },
  { lat: 10.8707, lng: 76.9058 },
  { lat: 10.8941, lng: 76.9180, stop: 'Madukkarai' },
  { lat: 10.9106, lng: 76.9263 },
  { lat: 10.9262, lng: 76.9338, stop: 'Sundakkamuthur' },
  { lat: 10.9409, lng: 76.9407 },
  { lat: 10.9548, lng: 76.9467 },
  { lat: 10.9592, lng: 76.9485, stop: 'Gandhipuram' },
  { lat: 10.9710, lng: 76.9536, stop: 'Coimbatore Junction' },
];

const buses = [
  {
    trackerId: 'TRK001',
    busId: 'BUS_12A',
    busNumber: '12A',
    route: ROUTE_12A,
    currentIndex: 8, // Near Madukkarai
    speed: 34,
  },
  {
    trackerId: 'TRK002',
    busId: 'BUS_21',
    busNumber: '21',
    route: ROUTE_21,
    currentIndex: 4, // Near Kinathukadavu
    speed: 38,
  },
];

function calculateBearing(lat1, lon1, lat2, lon2) {
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const y = Math.sin(dLon) * Math.cos((lat2 * Math.PI) / 180);
  const x =
    Math.cos((lat1 * Math.PI) / 180) * Math.sin((lat2 * Math.PI) / 180) -
    Math.sin((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.cos(dLon);
  const brng = (Math.atan2(y, x) * 180) / Math.PI;
  return (brng + 360) % 360;
}

function sendGpsLocation(payload) {
  return new Promise((resolve, reject) => {
    const data = JSON.stringify(payload);
    const options = {
      hostname: BACKEND_HOST,
      port: BACKEND_PORT,
      path: '/gps/location',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(data),
        'x-tracker-key': TRACKER_KEY,
      },
    };

    const req = http.request(options, (res) => {
      let body = '';
      res.on('data', (chunk) => (body += chunk));
      res.on('end', () => {
        resolve({ statusCode: res.statusCode, body });
      });
    });

    req.on('error', (e) => reject(e));
    req.write(data);
    req.end();
  });
}

async function tick() {
  for (const b of buses) {
    const cur = b.route[b.currentIndex];
    const nextIdx = (b.currentIndex + 1) % b.route.length;
    const next = b.route[nextIdx];

    const heading = calculateBearing(cur.lat, cur.lng, next.lat, next.lng);
    const speedVariation = b.speed + (Math.random() * 4 - 2);

    const payload = {
      trackerId: b.trackerId,
      busId: b.busId,
      latitude: cur.lat,
      longitude: cur.lng,
      speed: Math.round(speedVariation),
      heading: Math.round(heading),
      accuracy: 5,
      timestamp: new Date().toISOString(),
    };

    try {
      const res = await sendGpsLocation(payload);
      if (res.statusCode === 200 || res.statusCode === 201) {
        console.log(
          `[GPS SUCCESS] 🚌 ${b.busNumber} (${b.trackerId}) -> lat:${cur.lat.toFixed(4)}, lng:${cur.lng.toFixed(4)}, speed:${payload.speed}km/h (HTTP ${res.statusCode})`
        );
      } else {
        console.warn(
          `[GPS WARN] 🚌 ${b.busNumber} -> HTTP ${res.statusCode}: ${res.body}`
        );
      }
    } catch (err) {
      console.error(
        `[GPS ERROR] Could not reach backend at ${BACKEND_HOST}:${BACKEND_PORT}: ${err.message}`
      );
    }

    // Advance point
    b.currentIndex = nextIdx;
  }
}

console.log('====================================================');
console.log('📡 EasyGo Mock GPS Simulator (Standalone Runner)');
console.log(`🎯 Target: http://${BACKEND_HOST}:${BACKEND_PORT}/gps/location`);
console.log(`⏱️  Interval: ${INTERVAL_MS}ms`);
console.log('🚌 Active Buses: BUS_12A (Ukkadam → Pollachi), BUS_21 (Pollachi → Coimbatore)');
console.log('====================================================\n');

setInterval(tick, INTERVAL_MS);
tick();
