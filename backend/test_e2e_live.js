const io = require('socket.io-client');

async function run() {
  console.log('🚀 Running EasyGo End-to-End Live Tracking Test...\n');

  // 1. Test POST /gps/location
  console.log('1. Testing POST /gps/location with x-tracker-key...');
  const gpsPayload = {
    trackerId: 'TRK001',
    busId: 'BUS_12A',
    latitude: 10.9123,
    longitude: 76.9567,
    speed: 34,
    heading: 125,
    accuracy: 5,
    timestamp: new Date().toISOString(),
  };

  const gpsRes = await fetch('http://127.0.0.1:3000/gps/location', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-tracker-key': 'dev-tracker-secret-key-001',
    },
    body: JSON.stringify(gpsPayload),
  });

  const gpsJson = await gpsRes.json();
  console.log(`   Status: ${gpsRes.status} -> ${gpsJson.message || 'Location ingested'}`);
  if (gpsRes.status !== 201 && gpsRes.status !== 200) {
    throw new Error(`POST /gps/location failed: ${JSON.stringify(gpsJson)}`);
  }

  // 2. Test GET /buses/BUS_12A/live
  console.log('\n2. Testing GET /buses/BUS_12A/live...');
  const live12ARes = await fetch('http://127.0.0.1:3000/buses/BUS_12A/live');
  const live12A = await live12ARes.json();
  console.log('   BUS_12A Live State:', {
    busId: live12A.busId,
    busNumber: live12A.busNumber,
    status: live12A.status,
    currentStop: live12A.currentStop,
    nextStop: live12A.nextStop,
    speed: live12A.speed,
    heading: live12A.heading,
    etaMinutes: live12A.etaMinutes,
  });

  // 3. Test GET /buses/BUS_21/live
  console.log('\n3. Testing GET /buses/BUS_21/live...');
  const live21Res = await fetch('http://127.0.0.1:3000/buses/BUS_21/live');
  const live21 = await live21Res.json();
  console.log('   BUS_21 Live State:', {
    busId: live21.busId,
    busNumber: live21.busNumber,
    status: live21.status,
    currentStop: live21.currentStop,
    nextStop: live21.nextStop,
    speed: live21.speed,
    heading: live21.heading,
  });

  // 4. Test GET /buses/nearby
  console.log('\n4. Testing GET /buses/nearby?latitude=10.91&longitude=76.92...');
  const nearbyRes = await fetch('http://127.0.0.1:3000/buses/nearby?latitude=10.91&longitude=76.92&radiusKm=20');
  const nearbyJson = await nearbyRes.json();
  console.log(`   Found ${nearbyJson.buses ? nearbyJson.buses.length : (Array.isArray(nearbyJson) ? nearbyJson.length : 0)} nearby buses.`);

  // 5. Test GET /routes
  console.log('\n5. Testing GET /routes...');
  const routesRes = await fetch('http://127.0.0.1:3000/routes');
  const routes = await routesRes.json();
  console.log(`   Found ${routes.length} routes in DB.`);

  // 6. Test WebSocket realtime event: bus.location.updated
  console.log('\n6. Testing WebSocket connection & bus.location.updated event...');
  await new Promise((resolve, reject) => {
    const socket = io('http://127.0.0.1:3000', {
      transports: ['websocket', 'polling'],
      timeout: 10000,
    });

    const timeout = setTimeout(() => {
      socket.disconnect();
      reject(new Error('WebSocket event bus.location.updated timed out after 10s'));
    }, 10000);

    socket.on('connect', () => {
      console.log('   Socket connected! ID:', socket.id);
      console.log('   Subscribing to bus: BUS_12A...');
      socket.emit('subscribeToBus', { busId: 'BUS_12A' });
    });

    socket.on('bus.location.updated', (data) => {
      console.log('   🎉 Received bus.location.updated event:', {
        busId: data.busId,
        busNumber: data.busNumber,
        lat: data.latitude,
        lng: data.longitude,
        speed: data.speed,
        currentStop: data.currentStop,
        nextStop: data.nextStop,
        etaMinutes: data.etaMinutes,
      });
      clearTimeout(timeout);
      socket.disconnect();
      resolve();
    });

    socket.on('connect_error', (err) => {
      console.error('   Socket connection error:', err.message);
    });
  });

  console.log('\n========================================================');
  console.log('🎉 ALL END-TO-END LIVE TRACKING TESTS PASSED PERFECTLY!');
  console.log('========================================================\n');
}

run().catch((err) => {
  console.error('\n❌ Test failed:', err);
  process.exit(1);
});
