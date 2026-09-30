import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

// Realistic road-following route geometry for Ukkadam → Pollachi
// Coordinates follow actual road path through Coimbatore district
const UKKADAM_POLLACHI_GEOMETRY = [
  { lat: 10.9601, lng: 76.9502 }, // Ukkadam
  { lat: 10.9558, lng: 76.9471 },
  { lat: 10.9512, lng: 76.9445 },
  { lat: 10.9467, lng: 76.9421 },
  { lat: 10.9415, lng: 76.9398 },
  { lat: 10.9362, lng: 76.9375 }, // Sundakkamuthur approach
  { lat: 10.9305, lng: 76.9352 },
  { lat: 10.9256, lng: 76.9330 }, // Near Sundakkamuthur
  { lat: 10.9201, lng: 76.9308 },
  { lat: 10.9148, lng: 76.9285 },
  { lat: 10.9095, lng: 76.9261 },
  { lat: 10.9042, lng: 76.9238 }, // Madukkarai approach
  { lat: 10.8998, lng: 76.9215 },
  { lat: 10.8952, lng: 76.9192 }, // Madukkarai
  { lat: 10.8905, lng: 76.9168 },
  { lat: 10.8858, lng: 76.9144 },
  { lat: 10.8810, lng: 76.9120 },
  { lat: 10.8762, lng: 76.9095 },
  { lat: 10.8712, lng: 76.9068 }, // Ettimadai approach
  { lat: 10.8665, lng: 76.9042 },
  { lat: 10.8618, lng: 76.9015 }, // Ettimadai
  { lat: 10.8570, lng: 76.8988 },
  { lat: 10.8521, lng: 76.8960 },
  { lat: 10.8471, lng: 76.8931 },
  { lat: 10.8420, lng: 76.8901 }, // Karpagam area
  { lat: 10.8370, lng: 76.8872 },
  { lat: 10.8319, lng: 76.8842 },
  { lat: 10.8268, lng: 76.8812 },
  { lat: 10.8216, lng: 76.8781 },
  { lat: 10.8164, lng: 76.8749 }, // Kinathukadavu area
  { lat: 10.8112, lng: 76.8717 },
  { lat: 10.8059, lng: 76.8685 },
  { lat: 10.8006, lng: 76.8652 },
  { lat: 10.7952, lng: 76.8619 },
  { lat: 10.7898, lng: 76.8585 },
  { lat: 10.7844, lng: 76.8550 },
  { lat: 10.7789, lng: 76.8515 },
  { lat: 10.7733, lng: 76.8479 },
  { lat: 10.7678, lng: 76.8443 },
  { lat: 10.7622, lng: 76.8406 },
  { lat: 10.7565, lng: 76.8368 },
  { lat: 10.7508, lng: 76.8330 },
  { lat: 10.7450, lng: 76.8291 },
  { lat: 10.7392, lng: 76.8251 },
  { lat: 10.7334, lng: 76.8211 },
  { lat: 10.7275, lng: 76.8170 },
  { lat: 10.7215, lng: 76.8128 },
  { lat: 10.7155, lng: 76.8085 },
  { lat: 10.7094, lng: 76.8041 },
  { lat: 10.7032, lng: 76.7996 },
  { lat: 10.6970, lng: 76.7950 }, // Pollachi
];

// Pollachi → Coimbatore (opposite direction, via different path)
const POLLACHI_COIMBATORE_GEOMETRY = [
  { lat: 10.6970, lng: 76.7950 }, // Pollachi
  { lat: 10.7050, lng: 76.8010 },
  { lat: 10.7130, lng: 76.8070 },
  { lat: 10.7210, lng: 76.8128 },
  { lat: 10.7290, lng: 76.8185 },
  { lat: 10.7370, lng: 76.8240 },
  { lat: 10.7450, lng: 76.8295 },
  { lat: 10.7528, lng: 76.8348 },
  { lat: 10.7605, lng: 76.8400 }, // Kinathukadavu
  { lat: 10.7682, lng: 76.8450 },
  { lat: 10.7758, lng: 76.8500 },
  { lat: 10.7833, lng: 76.8548 },
  { lat: 10.7907, lng: 76.8595 },
  { lat: 10.7980, lng: 76.8640 },
  { lat: 10.8052, lng: 76.8684 },
  { lat: 10.8122, lng: 76.8726 },
  { lat: 10.8191, lng: 76.8768 }, // Karpagam
  { lat: 10.8259, lng: 76.8808 },
  { lat: 10.8326, lng: 76.8847 },
  { lat: 10.8392, lng: 76.8885 },
  { lat: 10.8457, lng: 76.8921 },
  { lat: 10.8521, lng: 76.8957 }, // Ettimadai
  { lat: 10.8584, lng: 76.8991 },
  { lat: 10.8646, lng: 76.9025 },
  { lat: 10.8707, lng: 76.9058 },
  { lat: 10.8767, lng: 76.9090 },
  { lat: 10.8826, lng: 76.9121 },
  { lat: 10.8884, lng: 76.9151 },
  { lat: 10.8941, lng: 76.9180 }, // Madukkarai
  { lat: 10.8997, lng: 76.9208 },
  { lat: 10.9052, lng: 76.9236 },
  { lat: 10.9106, lng: 76.9263 },
  { lat: 10.9159, lng: 76.9289 },
  { lat: 10.9211, lng: 76.9314 },
  { lat: 10.9262, lng: 76.9338 }, // Sundakkamuthur
  { lat: 10.9312, lng: 76.9362 },
  { lat: 10.9361, lng: 76.9385 },
  { lat: 10.9409, lng: 76.9407 },
  { lat: 10.9456, lng: 76.9428 },
  { lat: 10.9503, lng: 76.9448 },
  { lat: 10.9548, lng: 76.9467 },
  { lat: 10.9592, lng: 76.9485 }, // Gandhipuram / Coimbatore
  { lat: 10.9632, lng: 76.9503 },
  { lat: 10.9672, lng: 76.9520 },
  { lat: 10.9710, lng: 76.9536 }, // Coimbatore Junction
];

// Ukkadam → Singanallur (urban route)
const UKKADAM_SINGANALLUR_GEOMETRY = [
  { lat: 10.9601, lng: 76.9502 }, // Ukkadam
  { lat: 10.9625, lng: 76.9548 },
  { lat: 10.9648, lng: 76.9595 },
  { lat: 10.9670, lng: 76.9641 },
  { lat: 10.9692, lng: 76.9688 },
  { lat: 10.9713, lng: 76.9734 },
  { lat: 10.9734, lng: 76.9780 },
  { lat: 10.9754, lng: 76.9826 },
  { lat: 10.9773, lng: 76.9872 },
  { lat: 10.9792, lng: 76.9918 },
  { lat: 10.9810, lng: 76.9964 },
  { lat: 10.9827, lng: 77.0010 },
  { lat: 10.9844, lng: 77.0056 },
  { lat: 10.9860, lng: 77.0102 },
  { lat: 10.9875, lng: 77.0148 },
  { lat: 10.9890, lng: 77.0194 }, // Singanallur
];

async function main() {
  console.log('🌱 Starting EasyGo database seed...\n');

  // Clean existing data
  await prisma.busLocation.deleteMany();
  await prisma.otpRecord.deleteMany();
  await prisma.favorite.deleteMany();
  await prisma.alert.deleteMany();
  await prisma.trip.deleteMany();
  await prisma.busTracker.deleteMany();
  await prisma.bus.deleteMany();
  await prisma.routeStop.deleteMany();
  await prisma.busStop.deleteMany();
  await prisma.route.deleteMany();
  await prisma.user.deleteMany();

  console.log('✅ Cleaned existing data');

  // ============================================================
  // USERS
  // ============================================================
  const user1 = await prisma.user.create({
    data: { mobileNumber: '+919876543210', name: 'Arjun Kumar' },
  });
  const user2 = await prisma.user.create({
    data: { mobileNumber: '+919865432109', name: 'Priya Devi' },
  });
  console.log('✅ Created users');

  // ============================================================
  // BUS STOPS
  // ============================================================
  const stops = await Promise.all([
    prisma.busStop.create({ data: { name: 'Ukkadam', latitude: 10.9601, longitude: 76.9502 } }),
    prisma.busStop.create({ data: { name: 'Sundakkamuthur', latitude: 10.9256, longitude: 76.9330 } }),
    prisma.busStop.create({ data: { name: 'Madukkarai', latitude: 10.8952, longitude: 76.9192 } }),
    prisma.busStop.create({ data: { name: 'Ettimadai', latitude: 10.8618, longitude: 76.9015 } }),
    prisma.busStop.create({ data: { name: 'Karpagam', latitude: 10.8420, longitude: 76.8901 } }),
    prisma.busStop.create({ data: { name: 'Kinathukadavu', latitude: 10.8164, longitude: 76.8749 } }),
    prisma.busStop.create({ data: { name: 'Pollachi', latitude: 10.6970, longitude: 76.7950 } }),
    prisma.busStop.create({ data: { name: 'Gandhipuram', latitude: 10.9710, longitude: 76.9536 } }),
    prisma.busStop.create({ data: { name: 'Coimbatore Junction', latitude: 10.9710, longitude: 76.9536 } }),
    prisma.busStop.create({ data: { name: 'Singanallur', latitude: 10.9890, longitude: 77.0194 } }),
    prisma.busStop.create({ data: { name: 'Town Hall', latitude: 10.9632, longitude: 76.9503 } }),
    prisma.busStop.create({ data: { name: 'Peelamedu', latitude: 10.9875, longitude: 77.0148 } }),
  ]);

  const [ukkadam, sundakkamuthur, madukkarai, ettimadai, karpagam, kinathukadavu, pollachi, gandhipuram, coimbatoreJunction, singanallur, townHall, peelamedu] = stops;
  console.log('✅ Created bus stops');

  // ============================================================
  // ROUTES
  // ============================================================
  const route12A = await prisma.route.create({
    data: {
      name: 'Route 12A - Ukkadam → Pollachi',
      source: 'Ukkadam',
      destination: 'Pollachi',
      distanceKm: 43.5,
      estimatedDurationMinutes: 75,
      routeGeometry: UKKADAM_POLLACHI_GEOMETRY,
    },
  });

  const route24 = await prisma.route.create({
    data: {
      name: 'Route 24 - Pollachi → Coimbatore',
      source: 'Pollachi',
      destination: 'Coimbatore',
      distanceKm: 40.2,
      estimatedDurationMinutes: 70,
      routeGeometry: POLLACHI_COIMBATORE_GEOMETRY,
    },
  });

  const route5B = await prisma.route.create({
    data: {
      name: 'Route 5B - Ukkadam → Singanallur',
      source: 'Ukkadam',
      destination: 'Singanallur',
      distanceKm: 12.8,
      estimatedDurationMinutes: 35,
      routeGeometry: UKKADAM_SINGANALLUR_GEOMETRY,
    },
  });

  console.log('✅ Created routes');

  // ============================================================
  // ROUTE STOPS (sequence order)
  // ============================================================
  // Route 12A: Ukkadam → Pollachi
  await prisma.routeStop.createMany({
    data: [
      { routeId: route12A.id, stopId: ukkadam.id, sequence: 1, distanceFromStartKm: 0, estimatedMinutesFromPreviousStop: 0 },
      { routeId: route12A.id, stopId: sundakkamuthur.id, sequence: 2, distanceFromStartKm: 7.2, estimatedMinutesFromPreviousStop: 14 },
      { routeId: route12A.id, stopId: madukkarai.id, sequence: 3, distanceFromStartKm: 14.5, estimatedMinutesFromPreviousStop: 13 },
      { routeId: route12A.id, stopId: ettimadai.id, sequence: 4, distanceFromStartKm: 22.8, estimatedMinutesFromPreviousStop: 15 },
      { routeId: route12A.id, stopId: karpagam.id, sequence: 5, distanceFromStartKm: 28.3, estimatedMinutesFromPreviousStop: 10 },
      { routeId: route12A.id, stopId: kinathukadavu.id, sequence: 6, distanceFromStartKm: 33.9, estimatedMinutesFromPreviousStop: 10 },
      { routeId: route12A.id, stopId: pollachi.id, sequence: 7, distanceFromStartKm: 43.5, estimatedMinutesFromPreviousStop: 13 },
    ],
  });

  // Route 24: Pollachi → Coimbatore
  await prisma.routeStop.createMany({
    data: [
      { routeId: route24.id, stopId: pollachi.id, sequence: 1, distanceFromStartKm: 0, estimatedMinutesFromPreviousStop: 0 },
      { routeId: route24.id, stopId: kinathukadavu.id, sequence: 2, distanceFromStartKm: 9.6, estimatedMinutesFromPreviousStop: 17 },
      { routeId: route24.id, stopId: karpagam.id, sequence: 3, distanceFromStartKm: 15.2, estimatedMinutesFromPreviousStop: 10 },
      { routeId: route24.id, stopId: ettimadai.id, sequence: 4, distanceFromStartKm: 20.8, estimatedMinutesFromPreviousStop: 10 },
      { routeId: route24.id, stopId: madukkarai.id, sequence: 5, distanceFromStartKm: 26.9, estimatedMinutesFromPreviousStop: 11 },
      { routeId: route24.id, stopId: sundakkamuthur.id, sequence: 6, distanceFromStartKm: 33.5, estimatedMinutesFromPreviousStop: 12 },
      { routeId: route24.id, stopId: gandhipuram.id, sequence: 7, distanceFromStartKm: 40.2, estimatedMinutesFromPreviousStop: 10 },
    ],
  });

  // Route 5B: Ukkadam → Singanallur
  await prisma.routeStop.createMany({
    data: [
      { routeId: route5B.id, stopId: ukkadam.id, sequence: 1, distanceFromStartKm: 0, estimatedMinutesFromPreviousStop: 0 },
      { routeId: route5B.id, stopId: townHall.id, sequence: 2, distanceFromStartKm: 3.5, estimatedMinutesFromPreviousStop: 8 },
      { routeId: route5B.id, stopId: peelamedu.id, sequence: 3, distanceFromStartKm: 9.2, estimatedMinutesFromPreviousStop: 15 },
      { routeId: route5B.id, stopId: singanallur.id, sequence: 4, distanceFromStartKm: 12.8, estimatedMinutesFromPreviousStop: 8 },
    ],
  });

  console.log('✅ Created route stops');

  // ============================================================
  // BUSES
  // ============================================================
  const bus12A = await prisma.bus.create({
    data: {
      busNumber: '12A',
      vehicleNumber: 'TN 38 N 1201',
      routeId: route12A.id,
      status: 'ACTIVE',
    },
  });

  const bus12A_2 = await prisma.bus.create({
    data: {
      busNumber: '12A-2',
      vehicleNumber: 'TN 38 N 1202',
      routeId: route12A.id,
      status: 'ACTIVE',
    },
  });

  const bus24 = await prisma.bus.create({
    data: {
      busNumber: '24',
      vehicleNumber: 'TN 38 N 2401',
      routeId: route24.id,
      status: 'ACTIVE',
    },
  });

  const bus5B = await prisma.bus.create({
    data: {
      busNumber: '5B',
      vehicleNumber: 'TN 38 N 0501',
      routeId: route5B.id,
      status: 'ACTIVE',
    },
  });

  console.log('✅ Created buses');

  // ============================================================
  // GPS TRACKERS
  // ============================================================
  await prisma.busTracker.createMany({
    data: [
      {
        deviceId: 'tracker-12a-001',
        busId: bus12A.id,
        provider: 'MockGPS',
        status: 'ACTIVE',
      },
      {
        deviceId: 'tracker-12a-002',
        busId: bus12A_2.id,
        provider: 'MockGPS',
        status: 'ACTIVE',
      },
      {
        deviceId: 'tracker-24-001',
        busId: bus24.id,
        provider: 'MockGPS',
        status: 'ACTIVE',
      },
      {
        deviceId: 'tracker-5b-001',
        busId: bus5B.id,
        provider: 'MockGPS',
        status: 'ACTIVE',
      },
    ],
  });

  console.log('✅ Created GPS trackers');

  // ============================================================
  // TRIPS (initial running trips)
  // ============================================================
  await prisma.trip.createMany({
    data: [
      { busId: bus12A.id, routeId: route12A.id, status: 'RUNNING', startedAt: new Date() },
      { busId: bus12A_2.id, routeId: route12A.id, status: 'RUNNING', startedAt: new Date() },
      { busId: bus24.id, routeId: route24.id, status: 'RUNNING', startedAt: new Date() },
      { busId: bus5B.id, routeId: route5B.id, status: 'RUNNING', startedAt: new Date() },
    ],
  });

  console.log('✅ Created trips');

  // ============================================================
  // ALERTS
  // ============================================================
  await prisma.alert.createMany({
    data: [
      {
        title: 'Route 12A - Service Running',
        message: 'Route 12A Ukkadam to Pollachi is running on time. Buses every 30 minutes.',
        type: 'ROUTE_ALERT',
        routeId: route12A.id,
        expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000),
      },
      {
        title: 'Peak Hour Congestion',
        message: 'Expected delays near Madukkarai between 8am-10am. Please plan accordingly.',
        type: 'GENERAL',
        expiresAt: new Date(Date.now() + 12 * 60 * 60 * 1000),
      },
      {
        title: 'New Route 5B Service',
        message: 'Route 5B now connects Ukkadam to Singanallur with increased frequency.',
        type: 'ROUTE_ALERT',
        routeId: route5B.id,
        expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
      },
    ],
  });

  console.log('✅ Created alerts');

  // ============================================================
  // FAVORITES
  // ============================================================
  await prisma.favorite.createMany({
    data: [
      { userId: user1.id, type: 'ROUTE', referenceId: route12A.id, referenceName: 'Route 12A - Ukkadam → Pollachi' },
      { userId: user1.id, type: 'STOP', referenceId: madukkarai.id, referenceName: 'Madukkarai' },
      { userId: user2.id, type: 'BUS', referenceId: bus24.id, referenceName: 'Bus 24' },
    ],
  });

  console.log('✅ Created favorites');

  console.log('\n🎉 Seed complete!\n');
  console.log('='.repeat(60));
  console.log('📊 Summary:');
  console.log(`  Users: 2`);
  console.log(`  Routes: 3 (12A, 24, 5B)`);
  console.log(`  Bus Stops: ${stops.length}`);
  console.log(`  Buses: 4`);
  console.log(`  Trackers: 4`);
  console.log(`  Trips: 4 (all RUNNING)`);
  console.log(`  Alerts: 3`);
  console.log(`  Favorites: 3`);
  console.log('='.repeat(60));
  console.log('\n🚌 Routes seeded:');
  console.log('  12A: Ukkadam → Sundakkamuthur → Madukkarai → Ettimadai → Karpagam → Kinathukadavu → Pollachi');
  console.log('  24:  Pollachi → Kinathukadavu → Karpagam → Ettimadai → Madukkarai → Sundakkamuthur → Gandhipuram');
  console.log('  5B:  Ukkadam → Town Hall → Peelamedu → Singanallur');
  console.log('\n🔑 Mock OTP: 123456');
  console.log('🔑 Tracker API Key: dev-tracker-secret-key-001');
  console.log(`\n📡 Trackers: tracker-12a-001, tracker-12a-002, tracker-24-001, tracker-5b-001`);
}

main()
  .catch((e) => {
    console.error('❌ Seed failed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
