import { Test, TestingModule } from '@nestjs/testing';
import { JourneysService } from './journeys.service';
import { PrismaService } from '../database/prisma.service';
import { TrackingService } from '../tracking/tracking.service';

describe('JourneysService', () => {
  let service: JourneysService;

  const mockPrismaService = {
    busStop: {
      findMany: jest.fn().mockResolvedValue([
        { id: 'stop_1', name: 'Gandhipuram Bus Stop', latitude: 11.0168, longitude: 76.9558, routes: [] },
        { id: 'stop_2', name: 'Ukkadam Bus Stand', latitude: 10.9902, longitude: 76.9607, routes: [] },
        { id: 'stop_3', name: 'Pollachi Bus Station', latitude: 10.6588, longitude: 77.0090, routes: [] },
      ]),
    },
    route: {
      findMany: jest.fn().mockResolvedValue([
        {
          id: 'r_12a',
          name: 'Route 12A - Gandhipuram → Pollachi',
          source: 'Gandhipuram',
          destination: 'Pollachi',
          estimatedDurationMinutes: 80,
          stops: [
            { stop: { id: 'stop_1', name: 'Gandhipuram Bus Stop', latitude: 11.0168, longitude: 76.9558 } },
            { stop: { id: 'stop_3', name: 'Pollachi Bus Station', latitude: 10.6588, longitude: 77.0090 } },
          ],
          buses: [
            { id: 'bus_12a', busNumber: '12A', status: 'ACTIVE' },
          ],
        },
      ]),
    },
  };

  const mockTrackingService = {
    getAllActiveBusStates: jest.fn().mockResolvedValue([
      {
        busId: 'bus_12a',
        busNumber: '12A',
        currentStopName: 'Madukkarai',
        nextStopName: 'Ettimadai',
        etaMinutes: 8,
        status: 'MOVING',
      },
    ]),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        JourneysService,
        { provide: PrismaService, useValue: mockPrismaService },
        { provide: TrackingService, useValue: mockTrackingService },
      ],
    }).compile();

    service = module.get<JourneysService>(JourneysService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('should find direct journey from Gandhipuram to Pollachi', async () => {
    const result = await service.searchJourneys({
      from: 'Gandhipuram',
      to: 'Pollachi',
      fromLat: 11.0168,
      fromLng: 76.9558,
    });

    expect(result).toBeDefined();
    expect(result.recommendedBoardingStop.name).toContain('Gandhipuram');
    expect(result.destinationStop.name).toContain('Pollachi');
    expect(result.directRoutes.length).toBeGreaterThan(0);
    expect(result.directRoutes[0].busNumber).toBe('12A');
    expect(result.directRoutes[0].isDirect).toBe(true);
    expect(result.directRoutes[0].isLive).toBe(true);
  });
});
