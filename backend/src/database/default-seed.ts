import { PrismaService } from './prisma.service';

export async function ensureDefaultSeed(prisma: PrismaService) {
  try {
    const routeCount = await prisma.route.count();
    if (routeCount > 0) return;

    // Bus stops
    const stopsData = [
      { id: 'stop_ukkadam', name: 'Ukkadam', latitude: 10.9601, longitude: 76.9502 },
      { id: 'stop_sundakkamuthur', name: 'Sundakkamuthur', latitude: 10.9256, longitude: 76.9330 },
      { id: 'stop_madukkarai', name: 'Madukkarai', latitude: 10.8952, longitude: 76.9192 },
      { id: 'stop_ettimadai', name: 'Ettimadai', latitude: 10.8618, longitude: 76.9015 },
      { id: 'stop_karpagam', name: 'Karpagam', latitude: 10.8420, longitude: 76.8901 },
      { id: 'stop_kinathukadavu', name: 'Kinathukadavu', latitude: 10.8164, longitude: 76.8749 },
      { id: 'stop_pollachi', name: 'Pollachi', latitude: 10.6970, longitude: 76.7950 },
      { id: 'stop_gandhipuram', name: 'Gandhipuram', latitude: 10.9710, longitude: 76.9536 },
      { id: 'stop_cbe_jnc', name: 'Coimbatore Junction', latitude: 10.9710, longitude: 76.9536 },
      { id: 'stop_singanallur', name: 'Singanallur', latitude: 10.9890, longitude: 77.0194 },
    ];

    for (const stop of stopsData) {
      await prisma.busStop.create({ data: stop });
    }

    const defaultGeometry = [
      { lat: 10.9601, lng: 76.9502 },
      { lat: 10.9256, lng: 76.9330 },
      { lat: 10.8952, lng: 76.9192 },
      { lat: 10.8618, lng: 76.9015 },
      { lat: 10.8420, lng: 76.8901 },
      { lat: 10.8164, lng: 76.8749 },
      { lat: 10.6970, lng: 76.7950 },
    ];

    // Route 12A
    const route12A = await prisma.route.create({
      data: {
        id: 'r12a',
        name: 'Route 12A - Ukkadam → Pollachi',
        source: 'Ukkadam',
        destination: 'Pollachi',
        distanceKm: 43.5,
        estimatedDurationMinutes: 75,
        routeGeometry: defaultGeometry,
      },
    });

    // Route 24
    const route24 = await prisma.route.create({
      data: {
        id: 'r24',
        name: 'Route 24 - Pollachi → Coimbatore',
        source: 'Pollachi',
        destination: 'Coimbatore',
        distanceKm: 40.2,
        estimatedDurationMinutes: 70,
        routeGeometry: defaultGeometry,
      },
    });

    // Route 5B
    const route5B = await prisma.route.create({
      data: {
        id: 'r5b',
        name: 'Route 5B - Ukkadam → Singanallur',
        source: 'Ukkadam',
        destination: 'Singanallur',
        distanceKm: 12.8,
        estimatedDurationMinutes: 35,
        routeGeometry: defaultGeometry,
      },
    });

    // Route stops for 12A
    const route12AStops = [
      { routeId: route12A.id, stopId: 'stop_ukkadam', sequence: 1, distanceFromStartKm: 0, estimatedMinutesFromPreviousStop: 0 },
      { routeId: route12A.id, stopId: 'stop_sundakkamuthur', sequence: 2, distanceFromStartKm: 7.2, estimatedMinutesFromPreviousStop: 12 },
      { routeId: route12A.id, stopId: 'stop_madukkarai', sequence: 3, distanceFromStartKm: 14.5, estimatedMinutesFromPreviousStop: 12 },
      { routeId: route12A.id, stopId: 'stop_ettimadai', sequence: 4, distanceFromStartKm: 22.8, estimatedMinutesFromPreviousStop: 14 },
      { routeId: route12A.id, stopId: 'stop_karpagam', sequence: 5, distanceFromStartKm: 28.3, estimatedMinutesFromPreviousStop: 10 },
      { routeId: route12A.id, stopId: 'stop_kinathukadavu', sequence: 6, distanceFromStartKm: 33.9, estimatedMinutesFromPreviousStop: 11 },
      { routeId: route12A.id, stopId: 'stop_pollachi', sequence: 7, distanceFromStartKm: 43.5, estimatedMinutesFromPreviousStop: 16 },
    ];
    for (const rs of route12AStops) {
      await prisma.routeStop.create({ data: rs });
    }

    // Buses
    await prisma.bus.create({
      data: {
        id: 'BUS_12A',
        busNumber: '12A',
        vehicleNumber: 'TN-38-N-1234',
        operator: 'TNSTC Coimbatore',
        routeId: route12A.id,
        status: 'ACTIVE',
      },
    });

    await prisma.bus.create({
      data: {
        id: 'BUS_21',
        busNumber: '21',
        vehicleNumber: 'TN-38-N-5678',
        operator: 'TNSTC Coimbatore',
        routeId: route24.id,
        status: 'ACTIVE',
      },
    });

    // Trackers
    await prisma.busTracker.create({
      data: {
        id: 'trk-12a',
        trackerId: 'TRK001',
        deviceId: 'TRK001',
        deviceSecret: 'trk001-secret-key',
        busId: 'BUS_12A',
        deviceType: 'TELTONIKA_FMB920',
        simNumber: '+919876543210',
        isActive: true,
        status: 'ACTIVE',
      },
    });

    await prisma.busTracker.create({
      data: {
        id: 'trk-21',
        trackerId: 'TRK002',
        deviceId: 'TRK002',
        deviceSecret: 'trk002-secret-key',
        busId: 'BUS_21',
        deviceType: 'TELTONIKA_FMB920',
        simNumber: '+919876543211',
        isActive: true,
        status: 'ACTIVE',
      },
    });
  } catch (e) {
    // quiet in case of concurrent init
  }
}
