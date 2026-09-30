/**
 * Phase 18 — End-to-End Acceptance Test for Real GPS Pipeline
 */
const http = require('http');

const BASE_URL = 'http://localhost:3000';

function request(options, body = null) {
  return new Promise((resolve, reject) => {
    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => (data += chunk));
      res.on('end', () => {
        try {
          resolve({
            statusCode: res.statusCode,
            headers: res.headers,
            body: data ? JSON.parse(data) : null,
            rawBody: data,
          });
        } catch {
          resolve({
            statusCode: res.statusCode,
            headers: res.headers,
            body: data,
            rawBody: data,
          });
        }
      });
    });
    req.on('error', reject);
    if (body) {
      req.write(typeof body === 'string' ? body : JSON.stringify(body));
    }
    req.end();
  });
}

async function runTests() {
  console.log('========================================================');
  console.log('🧪 RUNNING PHASE 18 REAL GPS INTEGRATION ACCEPTANCE TESTS');
  console.log('========================================================\n');

  let passed = 0;
  let failed = 0;

  function assert(condition, message) {
    if (condition) {
      console.log(`  ✅ PASS: ${message}`);
      passed++;
    } else {
      console.error(`  ❌ FAIL: ${message}`);
      failed++;
    }
  }

  // --- TEST 1: Check Live Endpoint & Freshness Fields ---
  console.log('--- TEST 1: Verify GET /buses/:busId/live has freshness fields ---');
  {
    const res = await request({
      hostname: 'localhost',
      port: 3000,
      path: '/buses/BUS_12A/live',
      method: 'GET',
    });
    assert(res.statusCode === 200, `GET /buses/BUS_12A/live status 200 (got ${res.statusCode})`);
    assert(res.body && res.body.busId === 'BUS_12A', `Response contains busId: BUS_12A`);
    assert(res.body && typeof res.body.locationStatus === 'string', `Response contains locationStatus: ${res.body?.locationStatus}`);
    assert(res.body && typeof res.body.secondsSinceUpdate === 'number', `Response contains secondsSinceUpdate: ${res.body?.secondsSinceUpdate}`);
    assert(res.body && typeof res.body.trackerOnline === 'boolean', `Response contains trackerOnline: ${res.body?.trackerOnline}`);
  }

  // --- TEST 2: Real GPS Ingestion for BUS_12A using TRK001 ---
  console.log('\n--- TEST 2: Real GPS Ingestion via POST /gps/location for TRK001 ---');
  {
    const now = new Date().toISOString();
    const payload = {
      latitude: 10.912345,
      longitude: 76.956789,
      speed: 34.5,
      heading: 120.0,
      accuracy: 4.5,
      timestamp: now,
    };
    const res = await request(
      {
        hostname: 'localhost',
        port: 3000,
        path: '/gps/location',
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-tracker-key': 'trk001-secret-key',
          'x-tracker-id': 'TRK001',
        },
      },
      payload
    );

    assert(res.statusCode === 200, `POST /gps/location status 200 (got ${res.statusCode})`);
    assert(res.body && res.body.success === true, `Response success is true`);
    assert(res.body && res.body.busId === 'BUS_12A', `Auto-resolved to BUS_12A`);

    // Verify GET /buses/BUS_12A/live matches the real GPS location
    const live = await request({
      hostname: 'localhost',
      port: 3000,
      path: '/buses/BUS_12A/live',
      method: 'GET',
    });
    assert(Math.abs(live.body.latitude - 10.912345) < 0.0001, `Live latitude updated to 10.912345 (got ${live.body?.latitude})`);
    assert(Math.abs(live.body.longitude - 76.956789) < 0.0001, `Live longitude updated to 76.956789 (got ${live.body?.longitude})`);
    assert(live.body.locationStatus === 'LIVE', `Location status is LIVE`);
  }

  // --- TEST 3: Multi-bus Independence (TRK002 -> BUS_21) ---
  console.log('\n--- TEST 3: Multi-bus Independence (TRK002 -> BUS_21) ---');
  {
    const now = new Date().toISOString();
    const payload = {
      latitude: 10.771234,
      longitude: 76.845678,
      speed: 25.0,
      heading: 90.0,
      accuracy: 3.0,
      timestamp: now,
    };
    const res = await request(
      {
        hostname: 'localhost',
        port: 3000,
        path: '/gps/location',
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-tracker-key': 'trk002-secret-key',
          'x-tracker-id': 'TRK002',
        },
      },
      payload
    );

    assert(res.statusCode === 200, `TRK002 POST /gps/location status 200`);
    assert(res.body && res.body.busId === 'BUS_21', `TRK002 auto-resolved to BUS_21`);

    // Check BUS_21 live
    const live21 = await request({
      hostname: 'localhost',
      port: 3000,
      path: '/buses/BUS_21/live',
      method: 'GET',
    });
    assert(Math.abs(live21.body.latitude - 10.771234) < 0.0001, `BUS_21 latitude is independent: 10.771234`);

    // Check BUS_12A was NOT overwritten
    const live12A = await request({
      hostname: 'localhost',
      port: 3000,
      path: '/buses/BUS_12A/live',
      method: 'GET',
    });
    assert(Math.abs(live12A.body.latitude - 10.912345) < 0.0001, `BUS_12A remained unaffected by BUS_21 update`);
  }

  // --- TEST 4: Invalid Tracker Credentials Rejected (401) ---
  console.log('\n--- TEST 4: Reject Invalid Tracker Key (401) ---');
  {
    const res = await request(
      {
        hostname: 'localhost',
        port: 3000,
        path: '/gps/location',
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-tracker-key': 'WRONG-SECRET-KEY',
          'x-tracker-id': 'TRK001',
        },
      },
      {
        latitude: 10.9,
        longitude: 76.9,
        timestamp: new Date().toISOString(),
      }
    );
    assert(res.statusCode === 401, `Invalid key rejected with 401 Unauthorized (got ${res.statusCode})`);
  }

  // --- TEST 5: Cross-Bus Protection (TRK001 trying to update BUS_21) ---
  console.log('\n--- TEST 5: Reject Cross-Bus Impersonation (403) ---');
  {
    const res = await request(
      {
        hostname: 'localhost',
        port: 3000,
        path: '/gps/location',
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-tracker-key': 'trk001-secret-key',
          'x-tracker-id': 'TRK001',
        },
      },
      {
        busId: 'BUS_21', // TRK001 is mapped to BUS_12A, NOT BUS_21!
        latitude: 10.9,
        longitude: 76.9,
        timestamp: new Date().toISOString(),
      }
    );
    assert(res.statusCode === 403, `Cross-bus update rejected with 403 Forbidden (got ${res.statusCode})`);
  }

  // --- TEST 6: Heartbeat Endpoint ---
  console.log('\n--- TEST 6: Device Heartbeat via POST /gps/heartbeat ---');
  {
    const res = await request(
      {
        hostname: 'localhost',
        port: 3000,
        path: '/gps/heartbeat',
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-tracker-key': 'trk001-secret-key',
          'x-tracker-id': 'TRK001',
        },
      },
      {
        batteryLevel: 98,
        gsmSignal: 28,
        firmwareVersion: 'v1.4.2',
        timestamp: new Date().toISOString(),
      }
    );
    assert(res.statusCode === 200, `POST /gps/heartbeat status 200 (got ${res.statusCode})`);
    assert(res.body && res.body.success === true, `Heartbeat response success is true`);
    assert(res.body && res.body.busId === 'BUS_12A', `Heartbeat returned mapped bus BUS_12A`);
  }

  // --- TEST 7: Tracker Management APIs ---
  console.log('\n--- TEST 7: Tracker Management APIs (/trackers) ---');
  {
    // List trackers
    const listRes = await request({
      hostname: 'localhost',
      port: 3000,
      path: '/trackers',
      method: 'GET',
    });
    assert(listRes.statusCode === 200, `GET /trackers status 200`);
    assert(Array.isArray(listRes.body) && listRes.body.length >= 2, `GET /trackers returned ${listRes.body?.length} trackers`);

    // Get specific tracker
    const getRes = await request({
      hostname: 'localhost',
      port: 3000,
      path: '/trackers/TRK001',
      method: 'GET',
    });
    assert(getRes.statusCode === 200, `GET /trackers/TRK001 status 200`);
    assert(getRes.body && getRes.body.trackerId === 'TRK001', `Found TRK001 with busId ${getRes.body?.busId}`);
    assert(!getRes.body?.deviceSecret, `Device secret is NOT leaked in response`);

    // Deactivate TRK001
    const deactRes = await request({
      hostname: 'localhost',
      port: 3000,
      path: '/trackers/TRK001/deactivate',
      method: 'POST',
    });
    assert(deactRes.statusCode === 200, `POST /trackers/TRK001/deactivate status 200`);

    // Try to send GPS location with deactivated TRK001 -> MUST FAIL with 403
    const sendAfterDeact = await request(
      {
        hostname: 'localhost',
        port: 3000,
        path: '/gps/location',
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-tracker-key': 'trk001-secret-key',
          'x-tracker-id': 'TRK001',
        },
      },
      {
        latitude: 10.9,
        longitude: 76.9,
        timestamp: new Date().toISOString(),
      }
    );
    assert(sendAfterDeact.statusCode === 403, `Deactivated tracker rejected with 403 (got ${sendAfterDeact.statusCode})`);

    // Reactivate TRK001
    const reactRes = await request({
      hostname: 'localhost',
      port: 3000,
      path: '/trackers/TRK001/activate',
      method: 'POST',
    });
    assert(reactRes.statusCode === 200, `POST /trackers/TRK001/activate status 200`);

    // Send GPS again -> MUST SUCCEED now
    const sendAfterReact = await request(
      {
        hostname: 'localhost',
        port: 3000,
        path: '/gps/location',
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-tracker-key': 'trk001-secret-key',
          'x-tracker-id': 'TRK001',
        },
      },
      {
        latitude: 10.915,
        longitude: 76.958,
        timestamp: new Date().toISOString(),
      }
    );
    assert(sendAfterReact.statusCode === 200, `Reactivated tracker successfully ingested (got ${sendAfterReact.statusCode})`);
  }

  // --- TEST 8: GPS Payload Validation (Coordinates out of range, stale timestamps) ---
  console.log('\n--- TEST 8: GPS Payload Validation ---');
  {
    // Out of range latitude (95 > 90)
    const badLat = await request(
      {
        hostname: 'localhost',
        port: 3000,
        path: '/gps/location',
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-tracker-key': 'trk001-secret-key',
          'x-tracker-id': 'TRK001',
        },
      },
      {
        latitude: 95.0, // Invalid!
        longitude: 76.9,
        timestamp: new Date().toISOString(),
      }
    );
    assert(badLat.statusCode === 400, `Latitude > 90 rejected with 400 Bad Request (got ${badLat.statusCode})`);

    // Extremely old timestamp (>24 hours)
    const oldTimestamp = new Date(Date.now() - 48 * 3600 * 1000).toISOString();
    const staleTime = await request(
      {
        hostname: 'localhost',
        port: 3000,
        path: '/gps/location',
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-tracker-key': 'trk001-secret-key',
          'x-tracker-id': 'TRK001',
        },
      },
      {
        latitude: 10.9,
        longitude: 76.9,
        timestamp: oldTimestamp,
      }
    );
    assert(staleTime.statusCode === 400, `Stale timestamp (>24h) rejected with 400 Bad Request (got ${staleTime.statusCode})`);
  }

  console.log('\n========================================================');
  console.log(`TEST SUMMARY: ${passed} PASSED, ${failed} FAILED`);
  console.log('========================================================\n');

  if (failed > 0) {
    process.exit(1);
  } else {
    process.exit(0);
  }
}

runTests().catch((err) => {
  console.error('Test run failed with unexpected error:', err);
  process.exit(1);
});
