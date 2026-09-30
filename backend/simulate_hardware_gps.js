/**
 * EasyGo Physical Hardware GPS Device Simulator
 *
 * This script simulates the real network behavior of a physical GPS hardware device
 * installed inside a bus, making HTTPS/HTTP POST requests to the EasyGo ingestion endpoint.
 *
 * Capabilities:
 *  - Authenticates using trackerId and device secret
 *  - Sends realistic coordinate progressions, speed, heading, accuracy, and UTC timestamp
 *  - Handles network failures, connection drops, and automatic retries with backoff
 *  - Buffers packets in memory during simulated cellular outages and flushes on reconnect
 *  - Logs all HTTP requests, responses, and network transitions
 */

const http = require('http');
const https = require('https');
const { URL } = require('url');

// Configuration
const CONFIG = {
  baseUrl: process.env.GPS_SERVER_URL || 'http://localhost:3000',
  trackerId: process.env.TRACKER_ID || 'TRK001',
  trackerSecret: process.env.TRACKER_SECRET || 'trk001-secret-key',
  busId: process.env.BUS_ID || 'BUS_12A',
  updateIntervalMs: parseInt(process.env.UPDATE_INTERVAL_MS || '3000', 10),
  simulateOutageAfter: parseInt(process.env.SIMULATE_OUTAGE_AFTER || '4', 10), // Simulate network drop after packet 4
  outageDurationMs: parseInt(process.env.OUTAGE_DURATION_MS || '8000', 10), // Cellular outage lasts 8s
  maxRetries: 5,
};

// Route waypoints: Ukkadam -> Madukkarai -> Ettimadai (Coimbatore)
const WAYPOINTS = [
  { lat: 10.9601, lng: 76.9502, speed: 32.0, heading: 140.0 },
  { lat: 10.9525, lng: 76.9465, speed: 36.5, heading: 145.0 },
  { lat: 10.9410, lng: 76.9412, speed: 40.0, heading: 150.0 },
  { lat: 10.9312, lng: 76.9370, speed: 38.0, heading: 155.0 },
  { lat: 10.9256, lng: 76.9330, speed: 28.0, heading: 160.0 },
  { lat: 10.9120, lng: 76.9275, speed: 42.0, heading: 165.0 },
  { lat: 10.8952, lng: 76.9192, speed: 35.0, heading: 170.0 },
  { lat: 10.8780, lng: 76.9100, speed: 44.0, heading: 175.0 },
  { lat: 10.8618, lng: 76.9015, speed: 30.0, heading: 180.0 },
];

let waypointIndex = 0;
let packetSequence = 0;
let isNetworkSimulatedDown = false;
const offlineQueue = [];

function makeHttpRequest(targetUrl, headers, payload) {
  return new Promise((resolve, reject) => {
    const parsed = new URL(targetUrl);
    const isHttps = parsed.protocol === 'https:';
    const client = isHttps ? https : http;

    const dataString = JSON.stringify(payload);

    const options = {
      hostname: parsed.hostname,
      port: parsed.port || (isHttps ? 443 : 80),
      path: parsed.pathname + parsed.search,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(dataString),
        ...headers,
      },
      timeout: 5000,
    };

    const req = client.request(options, (res) => {
      let body = '';
      res.on('data', (chunk) => (body += chunk));
      res.on('end', () => {
        try {
          resolve({
            statusCode: res.statusCode,
            headers: res.headers,
            body: body ? JSON.parse(body) : null,
          });
        } catch {
          resolve({
            statusCode: res.statusCode,
            headers: res.headers,
            body,
          });
        }
      });
    });

    req.on('error', (err) => reject(err));
    req.on('timeout', () => {
      req.destroy();
      reject(new Error('Connection timed out'));
    });

    req.write(dataString);
    req.end();
  });
}

async function sendGpsPacketWithRetry(packet, attempt = 1) {
  // If simulated network is down, simulate carrier disconnection
  if (isNetworkSimulatedDown) {
    console.warn(`[HardwareSim] ⚠️ CELLULAR LINK DOWN: Packet #${packet.seq} queued in device buffer.`);
    offlineQueue.push(packet);
    return;
  }

  const endpoint = `${CONFIG.baseUrl}/gps/location`;
  const headers = {
    'x-tracker-key': CONFIG.trackerSecret,
    'x-tracker-id': CONFIG.trackerId,
  };

  const payload = {
    trackerId: CONFIG.trackerId,
    busId: CONFIG.busId,
    latitude: packet.lat,
    longitude: packet.lng,
    speed: packet.speed,
    heading: packet.heading,
    accuracy: packet.accuracy,
    timestamp: packet.timestamp,
    batteryLevel: 96,
    gsmSignal: 29,
  };

  try {
    const res = await makeHttpRequest(endpoint, headers, payload);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      console.log(
        `[HardwareSim] ✅ [HTTP ${res.statusCode}] Sent Packet #${packet.seq} (${packet.lat.toFixed(4)}, ${packet.lng.toFixed(4)}) Speed: ${packet.speed} km/h → Server Bus: ${res.body?.busId || 'OK'}`,
      );
    } else {
      console.error(
        `[HardwareSim] ❌ [HTTP ${res.statusCode}] Server Error for Packet #${packet.seq}: ${JSON.stringify(res.body)}`,
      );
    }
  } catch (err) {
    console.warn(
      `[HardwareSim] ⚠️ Network Error sending Packet #${packet.seq} (Attempt ${attempt}/${CONFIG.maxRetries}): ${err.message}`,
    );

    if (attempt < CONFIG.maxRetries) {
      const delayMs = Math.min(1000 * Math.pow(2, attempt), 10000);
      console.log(`[HardwareSim] ⏳ Retrying Packet #${packet.seq} in ${delayMs / 1000}s...`);
      setTimeout(() => sendGpsPacketWithRetry(packet, attempt + 1), delayMs);
    } else {
      console.error(`[HardwareSim] 🚨 Max retries reached for Packet #${packet.seq}. Saving to offline queue.`);
      offlineQueue.push(packet);
    }
  }
}

async function flushOfflineQueue() {
  if (offlineQueue.length === 0) return;
  console.log(`[HardwareSim] 🔄 Cellular connection restored! Flushing ${offlineQueue.length} buffered packets...`);

  while (offlineQueue.length > 0) {
    const packet = offlineQueue.shift();
    await sendGpsPacketWithRetry(packet);
    // Short pause between flushed packets
    await new Promise((r) => setTimeout(r, 400));
  }
}

function generateNextPacket() {
  packetSequence++;
  const wp = WAYPOINTS[waypointIndex];
  waypointIndex = (waypointIndex + 1) % WAYPOINTS.length;

  return {
    seq: packetSequence,
    lat: wp.lat + (Math.random() - 0.5) * 0.0005,
    lng: wp.lng + (Math.random() - 0.5) * 0.0005,
    speed: Math.round((wp.speed + (Math.random() - 0.5) * 4) * 10) / 10,
    heading: wp.heading,
    accuracy: 3.5 + Math.random() * 1.5,
    timestamp: new Date().toISOString(),
  };
}

async function startSimulation(maxPackets = 12) {
  console.log('================================================================');
  console.log('📡 EasyGo Physical Hardware GPS Device Simulator');
  console.log('================================================================');
  console.log(`Device ID:         ${CONFIG.trackerId}`);
  console.log(`Assigned Bus:      ${CONFIG.busId}`);
  console.log(`Target URL:        ${CONFIG.baseUrl}/gps/location`);
  console.log(`Telemetry Rate:    Every ${CONFIG.updateIntervalMs / 1000}s`);
  console.log(`Simulated Outage:  Trigger at Packet #${CONFIG.simulateOutageAfter} for ${CONFIG.outageDurationMs / 1000}s`);
  console.log('================================================================\n');

  let currentPacketCount = 0;

  const timer = setInterval(async () => {
    currentPacketCount++;
    const packet = generateNextPacket();

    // Trigger simulated network outage test
    if (packet.seq === CONFIG.simulateOutageAfter && !isNetworkSimulatedDown) {
      console.log(`\n🚨 SIMULATING CELLULAR OUTAGE (Tunnel / Dead-Zone for ${CONFIG.outageDurationMs / 1000}s) 🚨`);
      isNetworkSimulatedDown = true;

      setTimeout(async () => {
        console.log(`\n📶 CELLULAR SIGNAL RE-ACQUIRED (Restoring online state) 📶`);
        isNetworkSimulatedDown = false;
        await flushOfflineQueue();
      }, CONFIG.outageDurationMs);
    }

    await sendGpsPacketWithRetry(packet);

    if (maxPackets > 0 && currentPacketCount >= maxPackets) {
      clearInterval(timer);
      setTimeout(async () => {
        if (offlineQueue.length > 0) {
          isNetworkSimulatedDown = false;
          await flushOfflineQueue();
        }
        console.log('\n================================================================');
        console.log('🏁 Hardware GPS Simulation Completed Successfully.');
        console.log('================================================================');
        process.exit(0);
      }, CONFIG.outageDurationMs + 2000);
    }
  }, CONFIG.updateIntervalMs);
}

// Run simulation
const maxPackets = process.argv[2] ? parseInt(process.argv[2], 10) : 10;
startSimulation(maxPackets);
