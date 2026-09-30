/**
 * EasyGo — End-to-End Acceptance Test for Real GPS Pipeline & Admin Hardware Integration
 */
const http = require('http');

const BASE_URL = 'http://localhost:3000';
const ADMIN_KEY = process.env.ADMIN_API_KEY || 'easygo-admin-secret-key-2026';

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
  console.log('🧪 RUNNING EASYGO REAL GPS INTEGRATION ACCEPTANCE TESTS');
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

  // --- TEST 1: Health Check (API, Database, Redis, WebSocket) ---
  console.log('--- TEST 1: Health Check (GET /health) ---');
  {
    const res = await request({
      hostname: 'localhost',
      port: 3000,
      path: '/health',
      method: 'GET',
    });
    assert(res.statusCode === 200, `GET /health returned HTTP 200 (got ${res.statusCode})`);
    assert(res.body && typeof res.body.status === 'string', `Health status present: ${res.body?.status}`);
    assert(res.body?.services?.api === 'healthy', `API service healthy`);
    assert(res.body?.services?.websocket === 'healthy', `WebSocket service healthy`);
    assert(res.body?.services?.redis !== undefined, `Redis service reported`);
    assert(res.body?.services?.database !== undefined, `Database service reported`);
  }

  // --- TEST 2: Admin Onboard New Tracker with Generated Credentials ---
  console.log('\n--- TEST 2: Admin Tracker Registration (POST /admin/trackers) ---');
  let newTrackerSecret = '';
  {
    const res = await request(
      {
        hostname: 'localhost',
        port: 3000,
        path: '/admin/trackers',
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-admin-key': ADMIN_KEY,
        },
      },
      {
        trackerId: 'TRK_TEST_NEW',
        deviceName: 'Bus 12A Backup Unit',
        busId: 'BUS_12A',
        deviceType: 'TELTONIKA_FMB920',
        simNumber: '+919876543299',
      }
    );

    assert(res.statusCode === 201 || res.statusCode === 200, `POST /admin/trackers returned 201 (got ${res.statusCode})`);
    assert(res.body && res.body.trackerId === 'TRK_TEST_NEW', `Tracker registered as TRK_TEST_NEW`);
    assert(res.body && res.body.deviceSecret, `Secure device secret generated on creation`);
    newTrackerSecret = res.body?.deviceSecret;

    // Verify secret is NOT leaked in subsequent GET requests
    const getRes = await request({
      hostname: 'localhost',
      port: 3000,
      path: '/admin/trackers/TRK_TEST_NEW',
      method: 'GET',
      headers: { 'x-admin-key': ADMIN_KEY },
    });
    assert(getRes.statusCode === 200, `GET /admin/trackers/TRK_TEST_NEW returned 200`);
    assert(!getRes.body?.deviceSecret, `Device secret is NOT leaked in passenger/admin GET`);
    assert(getRes.body?.hasSecret === true, `hasSecret flag is true`);
  }

  // --- TEST 3: Tracker Assignment & Replacement (Old tracker unassigned) ---
  console.log('\n--- TEST 3: Tracker Assignment & Replacement Protection ---');
  {
    // Re-assign TRK001 to BUS_12A (this replaces TRK_TEST_NEW on BUS_12A)
    const assignRes = await request(
      {
        hostname: 'localhost',
        port: 3000,
        path: '/admin/trackers/TRK001/assign',
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-admin-key': ADMIN_KEY,
        },
      },
      { busId: 'BUS_12A' }
    );
    assert(assignRes.statusCode === 200, `POST /admin/trackers/TRK001/assign returned 200`);
    assert(assignRes.body && assignRes.body.bus?.busNumber === '12A', `TRK001 assigned to Bus 12A`);

    // Verify old tracker TRK_TEST_NEW is now unassigned
    const oldTrackerRes = await request({
      hostname: 'localhost',
      port: 3000,
      path: '/admin/trackers/TRK_TEST_NEW',
      method: 'GET',
      headers: { 'x-admin-key': ADMIN_KEY },
    });
    assert(oldTrackerRes.body?.bus === null, `Old tracker TRK_TEST_NEW was automatically unassigned from BUS_12A`);

    // Attempting to send GPS from unassigned TRK_TEST_NEW must be rejected
    const unassignedSend = await request(
      {
        hostname: 'localhost',
        port: 3000,
        path: '/gps/location',
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-tracker-key': newTrackerSecret,
          'x-tracker-id': 'TRK_TEST_NEW',
        },
      },
      {
        latitude: 10.9601,
        longitude: 76.9502,
        timestamp: new Date().toISOString(),
      }
    );
    assert(unassignedSend.statusCode === 403, `Unassigned tracker rejected with 403 Forbidden (got ${unassignedSend.statusCode})`);
  }

  // --- TEST 4: Real GPS Ingestion via POST /gps/location for TRK001 ---
  console.log('\n--- TEST 4: Real GPS Ingestion via POST /gps/location for TRK001 ---');
  let packetATimestamp = new Date().toISOString();
  {
    const payload = {
      latitude: 10.912345,
      longitude: 76.956789,
      speed: 34.5,
      heading: 120.0,
      accuracy: 4.5,
      timestamp: packetATimestamp,
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
    assert(Math.abs(live.body.latitude - 10.912345) < 0.0001, `Live latitude updated to 10.912345`);
    assert(Math.abs(live.body.longitude - 76.956789) < 0.0001, `Live longitude updated to 76.956789`);
    assert(live.body.locationStatus === 'LIVE', `Location status is LIVE`);
    assert(live.body.trackerOnline === true, `trackerOnline is true`);
  }

  // --- TEST 5: Out-of-Order GPS Packet Protection (Requirement 11) ---
  console.log('\n--- TEST 5: Out-of-Order GPS Packet Protection ---');
  {
    // Send Packet B with an OLDER timestamp (e.g. 30 seconds before Packet A)
    const packetBTimestamp = new Date(new Date(packetATimestamp).getTime() - 30000).toISOString();
    const olderPacket = await request(
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
        latitude: 10.800000, // Deliberately different coordinates
        longitude: 76.800000,
        speed: 10.0,
        heading: 0,
        accuracy: 4.0,
        timestamp: packetBTimestamp,
      }
    );

    assert(olderPacket.body?.reason === 'OUT_OF_ORDER_PACKET' || olderPacket.body?.success === false,
      `Out-of-order older packet detected and rejected`);

    // Verify that the live position of BUS_12A was NOT overwritten by the older packet
    const liveCheck = await request({
      hostname: 'localhost',
      port: 3000,
      path: '/buses/BUS_12A/live',
      method: 'GET',
    });
    assert(Math.abs(liveCheck.body.latitude - 10.912345) < 0.0001, `Live position preserved at 10.912345 (older packet did not overwrite)`);
  }

  // --- TEST 6: Poor Accuracy GPS Rejection (Requirement 12) ---
  console.log('\n--- TEST 6: GPS Accuracy Quality Filtering ---');
  {
    // Send packet with poor accuracy (e.g. 500 meters)
    const poorAccRes = await request(
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
        latitude: 10.500000,
        longitude: 76.500000,
        accuracy: 500, // Exceeds threshold (100m)
        timestamp: new Date().toISOString(),
      }
    );

    assert(poorAccRes.body?.reason === 'POOR_ACCURACY' || poorAccRes.body?.success === false,
      `Poor accuracy coordinate rejected from live map`);

    // Verify live position is still preserved
    const liveCheck = await request({
      hostname: 'localhost',
      port: 3000,
      path: '/buses/BUS_12A/live',
      method: 'GET',
    });
    assert(liveCheck.body.latitude !== 10.500000, `Poor accuracy position did not jump live bus`);
  }

  // --- TEST 7: Tracker Key Rotation (Requirement 7) ---
  console.log('\n--- TEST 7: Tracker Key Rotation ---');
  let rotatedKey = '';
  {
    const rotateRes = await request({
      hostname: 'localhost',
      port: 3000,
      path: '/admin/trackers/TRK001/rotate-key',
      method: 'POST',
      headers: { 'x-admin-key': ADMIN_KEY },
    });
    assert(rotateRes.statusCode === 200, `POST /admin/trackers/TRK001/rotate-key returned 200`);
    assert(rotateRes.body && rotateRes.body.newDeviceSecret, `New device secret generated`);
    rotatedKey = rotateRes.body?.newDeviceSecret;

    // Old key must now be rejected
    const oldKeySend = await request(
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
        latitude: 10.913,
        longitude: 76.957,
        timestamp: new Date().toISOString(),
      }
    );
    assert(oldKeySend.statusCode === 401, `Old secret rejected with 401 Unauthorized`);

    // New rotated key must be accepted
    const newKeySend = await request(
      {
        hostname: 'localhost',
        port: 3000,
        path: '/gps/location',
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-tracker-key': rotatedKey,
          'x-tracker-id': 'TRK001',
        },
      },
      {
        latitude: 10.913,
        longitude: 76.957,
        timestamp: new Date().toISOString(),
      }
    );
    assert(newKeySend.statusCode === 200, `Rotated secret accepted with 200 OK`);
  }

  // --- TEST 8: Tracker Deactivation & Reactivation ---
  console.log('\n--- TEST 8: Tracker Deactivation & Reactivation ---');
  {
    // Deactivate TRK001
    const deactRes = await request({
      hostname: 'localhost',
      port: 3000,
      path: '/admin/trackers/TRK001/deactivate',
      method: 'POST',
      headers: { 'x-admin-key': ADMIN_KEY },
    });
    assert(deactRes.statusCode === 200, `Deactivate TRK001 returned 200`);

    // Sending GPS must fail with 403
    const sendAfterDeact = await request(
      {
        hostname: 'localhost',
        port: 3000,
        path: '/gps/location',
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-tracker-key': rotatedKey,
          'x-tracker-id': 'TRK001',
        },
      },
      {
        latitude: 10.914,
        longitude: 76.958,
        timestamp: new Date().toISOString(),
      }
    );
    assert(sendAfterDeact.statusCode === 403, `Deactivated tracker rejected with 403 Forbidden`);

    // Reactivate TRK001
    const reactRes = await request({
      hostname: 'localhost',
      port: 3000,
      path: '/admin/trackers/TRK001/activate',
      method: 'POST',
      headers: { 'x-admin-key': ADMIN_KEY },
    });
    assert(reactRes.statusCode === 200, `Activate TRK001 returned 200`);

    // Sending GPS now succeeds
    const sendAfterReact = await request(
      {
        hostname: 'localhost',
        port: 3000,
        path: '/gps/location',
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-tracker-key': rotatedKey,
          'x-tracker-id': 'TRK001',
        },
      },
      {
        latitude: 10.914,
        longitude: 76.958,
        timestamp: new Date().toISOString(),
      }
    );
    assert(sendAfterReact.statusCode === 200, `Reactivated tracker successfully ingested (200 OK)`);
  }

  // --- TEST 9: Heartbeat Endpoint & Status ---
  console.log('\n--- TEST 9: Device Heartbeat & Status Computation ---');
  {
    const hbRes = await request(
      {
        hostname: 'localhost',
        port: 3000,
        path: '/gps/heartbeat',
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-tracker-key': rotatedKey,
          'x-tracker-id': 'TRK001',
        },
      },
      {
        batteryLevel: 98,
        gsmSignal: 28,
        timestamp: new Date().toISOString(),
      }
    );
    assert(hbRes.statusCode === 200, `POST /gps/heartbeat returned 200 OK`);
    assert(hbRes.body?.success === true, `Heartbeat acknowledged`);

    // Verify tracker status shows ONLINE
    const statusRes = await request({
      hostname: 'localhost',
      port: 3000,
      path: '/admin/trackers/TRK001',
      method: 'GET',
      headers: { 'x-admin-key': ADMIN_KEY },
    });
    assert(statusRes.body?.status === 'ONLINE', `Tracker status correctly computed as ONLINE (got ${statusRes.body?.status})`);
    assert(statusRes.body?.lastHeartbeatAt !== null, `lastHeartbeatAt is recorded`);
  }

  // Restore TRK001 key back to standard test key for other tools / Postman default
  await request(
    {
      hostname: 'localhost',
      port: 3000,
      path: '/admin/trackers/TRK001',
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'x-admin-key': ADMIN_KEY,
      },
    },
    { deviceSecret: 'trk001-secret-key' }
  );

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
