import { Test, TestingModule } from '@nestjs/testing';
import { HomeService } from './home.service';
import { PrismaService } from '../database/prisma.service';
import { TrackingService } from '../tracking/tracking.service';

describe('HomeService', () => {
  let service: HomeService;

  const mockPrismaService = {
    busStop: {
      findMany: jest.fn().mockResolvedValue([
        {
          id: 'stop_1',
          name: 'Gandhipuram Bus Stop',
          latitude: 11.0168,
          longitude: 76.9558,
          routes: [
            {
              route: {
                id: 'r_12a',
                name: 'Route 12A',
                source: 'Gandhipuram',
                destination: 'Pollachi',
                buses: [{ id: 'bus_12a', busNumber: '12A' }],
              },
            },
          ],
        },
      ]),
    },
    bus: {
      findMany: jest.fn().mockResolvedValue([
        {
          id: 'bus_12a',
          busNumber: '12A',
          routeId: 'r_12a',
          route: {
            id: 'r_12a',
            name: 'Route 12A',
            source: 'Gandhipuram',
            destination: 'Ukkadam',
            stops: [
              { stop: { name: 'Gandhipuram', latitude: 11.0168, longitude: 76.9558 } },
            ],
          },
        },
      ]),
    },
  };

  const mockTrackingService = {
    getAllActiveBusStates: jest.fn().mockResolvedValue([
      {
        busId: 'bus_12a',
        busNumber: '12A',
        latitude: 11.0180,
        longitude: 76.9560,
        status: 'MOVING',
        currentStopName: 'Gandhipuram',
        nextStopName: 'Ukkadam',
        etaMinutes: 5,
        speed: 24,
      },
    ]),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        HomeService,
        { provide: PrismaService, useValue: mockPrismaService },
        { provide: TrackingService, useValue: mockTrackingService },
      ],
    }).compile();

    service = module.get<HomeService>(HomeService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('should return location-aware data for Home', async () => {
    const result = await service.getHomeData(11.0168, 76.9558);
    expect(result).toBeDefined();
    expect(result.locationSummary).toContain('Gandhipuram');
    expect(result.nearbyBuses.length).toBeGreaterThan(0);
    expect(result.nearbyBuses[0].busNumber).toBe('12A');
    expect(result.nearbyStops.length).toBeGreaterThan(0);
    expect(result.nearbyRoutes.length).toBeGreaterThan(0);
  });
});
