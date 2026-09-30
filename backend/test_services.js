const assert = require('assert');

// Test Suite for EasyGo Backend Services
async function runTests() {
  console.log('🧪 Starting EasyGo Backend Tests...\n');

  // 1. Test HomeService
  console.log('▶ Testing HomeService (Location-Aware Home)...');
  const { HomeService } = require('./dist/src/home/home.service');

  const mockPrisma = {
    busStop: {
      findMany: async () => [
        {
          id: 'stop_gandhipuram',
          name: 'Gandhipuram Bus Stop',
          latitude: 11.0168,
          longitude: 76.9558,
          routes: [
            {
              route: {
                id: 'r_12a',
                name: 'Route 12A - Gandhipuram → Ukkadam',
                source: 'Gandhipuram',
                destination: 'Ukkadam',
                buses: [{ id: 'bus_12a', busNumber: '12A' }],
              },
            },
            {
              route: {
                id: 'r_24',
                name: 'Route 24 - Gandhipuram → Singanallur',
                source: 'Gandhipuram',
                destination: 'Singanallur',
                buses: [{ id: 'bus_24', busNumber: '24' }],
              },
            },
          ],
        },
        {
          id: 'stop_pollachi',
          name: 'Pollachi Bus Station',
          latitude: 10.6588,
          longitude: 77.0090,
          routes: [],
        },
      ],
    },
    bus: {
      findMany: async () => [
        {
          id: 'bus_12a',
          busNumber: '12A',
          routeId: 'r_12a',
          route: {
            id: 'r_12a',
            name: 'Route 12A - Gandhipuram → Ukkadam',
            source: 'Gandhipuram',
            destination: 'Ukkadam',
            stops: [
              { stop: { name: 'Gandhipuram', latitude: 11.0168, longitude: 76.9558 } },
            ],
          },
        },
        {
          id: 'bus_24',
          busNumber: '24',
          routeId: 'r_24',
          route: {
            id: 'r_24',
            name: 'Route 24 - Gandhipuram → Singanallur',
            source: 'Gandhipuram',
            destination: 'Singanallur',
            stops: [
              { stop: { name: 'Gandhipuram', latitude: 11.0168, longitude: 76.9558 } },
            ],
          },
        },
        {
          id: 'bus_pollachi_only',
          busNumber: '99P',
          routeId: 'r_pollachi_only',
          route: {
            id: 'r_pollachi_only',
            name: 'Route 99P - Pollachi Local',
            source: 'Pollachi',
            destination: 'Anamalai',
            stops: [
              { stop: { name: 'Pollachi', latitude: 10.6588, longitude: 77.0090 } },
            ],
          },
        },
      ],
    },
  };

  const mockTracking = {
    getAllActiveBusStates: async () => [
      {
        busId: 'bus_12a',
        busNumber: '12A',
        latitude: 11.0180,
        longitude: 76.9560,
        status: 'MOVING',
        currentStopName: 'Gandhipuram',
        nextStopName: 'Ukkadam',
        etaMinutes: 5,
        speed: 28,
      },
      {
        busId: 'bus_24',
        busNumber: '24',
        latitude: 11.0200,
        longitude: 76.9600,
        status: 'MOVING',
        currentStopName: 'Gandhipuram',
        nextStopName: 'Singanallur',
        etaMinutes: 9,
        speed: 22,
      },
    ],
    getLiveBusState: async (id) => {
      if (id === 'bus_12a') {
        return {
          busId: 'bus_12a',
          busNumber: '12A',
          currentStopName: 'Madukkarai',
          nextStopName: 'Ettimadai',
          etaMinutes: 7,
          status: 'MOVING',
          speed: 32,
        };
      }
      return null;
    },
  };

  const homeService = new HomeService(mockPrisma, mockTracking);
  const homeData = await homeService.getHomeData(11.0168, 76.9558);

  assert.ok(homeData.locationSummary.includes('Gandhipuram'), 'Home location summary should be near Gandhipuram');
  assert.ok(homeData.nearbyBuses.length >= 2, 'Should return nearby buses (12A, 24)');
  assert.strictEqual(homeData.nearbyBuses[0].busNumber, '12A', 'Nearest bus should be 12A');
  assert.ok(!homeData.nearbyBuses.some(b => b.busNumber === '99P'), 'Pollachi-only bus must NOT show on Gandhipuram Home');
  assert.ok(homeData.nearbyStops.length > 0, 'Should return nearby stops');
  assert.ok(homeData.nearbyRoutes.length > 0, 'Should return nearby routes');
  console.log('✅ HomeService passed: Clean, location-aware home data with only nearby buses & routes.');

  // 2. Test JourneysService
  console.log('\n▶ Testing JourneysService (Destination & From->To Search)...');
  const { JourneysService } = require('./dist/src/journeys/journeys.service');

  const journeyPrisma = {
    busStop: mockPrisma.busStop,
    route: {
      findMany: async () => [
        {
          id: 'r_12a',
          name: 'Route 12A - Gandhipuram → Pollachi',
          source: 'Gandhipuram',
          destination: 'Pollachi',
          estimatedDurationMinutes: 80,
          stops: [
            { stop: { id: 'stop_gandhipuram', name: 'Gandhipuram Bus Stop', latitude: 11.0168, longitude: 76.9558 } },
            { stop: { id: 'stop_pollachi', name: 'Pollachi Bus Station', latitude: 10.6588, longitude: 77.0090 } },
          ],
          buses: [
            { id: 'bus_12a', busNumber: '12A', status: 'ACTIVE' },
          ],
        },
      ],
    },
  };

  const journeysService = new JourneysService(journeyPrisma, mockTracking);
  const journeyResult = await journeysService.searchJourneys({
    from: 'Gandhipuram',
    to: 'Pollachi',
    fromLat: 11.0168,
    fromLng: 76.9558,
  });

  assert.ok(journeyResult.recommendedBoardingStop.name.includes('Gandhipuram'), 'Recommended boarding stop should be near Gandhipuram');
  assert.ok(journeyResult.destinationStop.name.includes('Pollachi'), 'Destination stop should be Pollachi');
  assert.ok(journeyResult.directRoutes.length > 0, 'Should find direct route 12A to Pollachi');
  assert.strictEqual(journeyResult.directRoutes[0].busNumber, '12A');
  assert.strictEqual(journeyResult.directRoutes[0].isDirect, true);
  assert.strictEqual(journeyResult.directRoutes[0].statusLabel, 'LIVE NOW');
  assert.ok(journeyResult.directRoutes[0].currentLocation, 'Should provide current live stop');
  assert.strictEqual(journeyResult.directRoutes[0].etaMinutes, 5);
  console.log('✅ JourneysService passed: Direct route found with boarding stop, live bus, ETA, and duration.');

  // Test Connecting route when no direct route exists
  const noDirectPrisma = {
    busStop: mockPrisma.busStop,
    route: {
      findMany: async () => [],
    },
  };
  const connectingService = new JourneysService(noDirectPrisma, mockTracking);
  const connResult = await connectingService.searchJourneys({
    from: 'Gandhipuram',
    to: 'Pollachi',
  });
  assert.ok(connResult.connectingRoutes.length > 0, 'Should find connecting option when no direct route exists');
  assert.strictEqual(connResult.connectingRoutes[0].transfers, 1, 'Connecting option should have 1 transfer');
  assert.ok(connResult.connectingRoutes[0].legs.length >= 3, 'Should have multiple journey legs');
  console.log('✅ JourneysService connecting routes passed: Multi-leg transfer option provided when no direct bus.');

  // 3. Test BusesService
  console.log('\n▶ Testing BusesService (Schedule & Live vs Scheduled)...');
  const { BusesService } = require('./dist/src/buses/buses.service');
  const busPrisma = {
    bus: {
      findUnique: async () => ({
        id: 'bus_12a',
        busNumber: '12A',
        routeId: 'r_12a',
        route: {
          id: 'r_12a',
          name: 'Route 12A',
          source: 'Gandhipuram',
          destination: 'Pollachi',
          estimatedDurationMinutes: 80,
          stops: [],
        },
      }),
      findMany: mockPrisma.bus.findMany,
    },
  };
  const busesService = new BusesService(busPrisma, mockTracking);
  const scheduleResult = await busesService.getSchedule('bus_12a');

  assert.strictEqual(scheduleResult.busNumber, '12A');
  assert.ok(scheduleResult.schedules.length > 0, 'Should return scheduled timings');
  const liveSlot = scheduleResult.schedules.find(s => s.status === 'LIVE_NOW');
  assert.ok(liveSlot, 'Should clearly mark the currently running live slot');
  assert.strictEqual(liveSlot.isLive, true);
  const scheduledSlot = scheduleResult.schedules.find(s => s.status === 'SCHEDULED');
  assert.ok(scheduledSlot, 'Should clearly distinguish scheduled slots');
  assert.strictEqual(scheduledSlot.isLive, false);
  console.log('✅ BusesService passed: Clear distinction between LIVE NOW and SCHEDULED buses.');

  console.log('\n🎉 ALL BACKEND SERVICE TESTS PASSED SUCCESSFULLY!\n');
}

runTests().catch((e) => {
  console.error('❌ Test failed:', e);
  process.exit(1);
});
