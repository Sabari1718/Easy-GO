import { Injectable } from '@nestjs/common';
import { PrismaService } from '../database/prisma.service';
import { TrackingService } from '../tracking/tracking.service';
import { haversineDistance } from '../common/utils/geo.utils';

// Known landmark coordinates in Coimbatore - Pollachi region
const KNOWN_COORDINATES: Record<string, { lat: number; lng: number }> = {
  gandhipuram: { lat: 11.0168, lng: 76.9558 },
  coimbatore: { lat: 10.9710, lng: 76.9536 },
  'coimbatore junction': { lat: 10.9710, lng: 76.9536 },
  ukkadam: { lat: 10.9601, lng: 76.9502 },
  pollachi: { lat: 10.6970, lng: 76.7950 },
  singanallur: { lat: 10.9890, lng: 77.0194 },
  'town hall': { lat: 10.9632, lng: 76.9503 },
  madukkarai: { lat: 10.8952, lng: 76.9192 },
  ettimadai: { lat: 10.8618, lng: 76.9015 },
  karpagam: { lat: 10.8420, lng: 76.8901 },
  kinathukadavu: { lat: 10.8164, lng: 76.8749 },
  peelamedu: { lat: 10.9875, lng: 77.0148 },
  sundakkamuthur: { lat: 10.9256, lng: 76.9330 },
  'rs puram': { lat: 11.0080, lng: 76.9480 },
};

@Injectable()
export class JourneysService {
  constructor(
    private prisma: PrismaService,
    private trackingService: TrackingService,
  ) {}

  async searchJourneys(params: {
    from?: string;
    to?: string;
    fromLat?: number;
    fromLng?: number;
    toLat?: number;
    toLng?: number;
  }) {
    const fromStr = (params.from || 'Current Location').trim();
    const toStr = (params.to || '').trim();

    // 1. Resolve 'FROM' coordinates
    let fLat = params.fromLat;
    let fLng = params.fromLng;

    if (fLat === undefined || fLng === undefined || isNaN(fLat) || isNaN(fLng)) {
      const lower = fromStr.toLowerCase();
      for (const [key, coord] of Object.entries(KNOWN_COORDINATES)) {
        if (lower.includes(key)) {
          fLat = coord.lat;
          fLng = coord.lng;
          break;
        }
      }
      // Default to Gandhipuram if unresolved
      if (fLat === undefined || fLng === undefined) {
        fLat = 11.0168;
        fLng = 76.9558;
      }
    }

    // 2. Resolve 'TO' coordinates
    let tLat = params.toLat;
    let tLng = params.toLng;

    if (tLat === undefined || tLng === undefined || isNaN(tLat) || isNaN(tLng)) {
      const lower = toStr.toLowerCase();
      for (const [key, coord] of Object.entries(KNOWN_COORDINATES)) {
        if (lower.includes(key)) {
          tLat = coord.lat;
          tLng = coord.lng;
          break;
        }
      }
      // Default to Pollachi if unresolved
      if (tLat === undefined || tLng === undefined) {
        tLat = 10.6970;
        tLng = 76.7950;
      }
    }

    // 3. Find all bus stops from DB
    const allStops = await this.prisma.busStop.findMany({
      include: {
        routes: {
          include: {
            route: {
              include: {
                buses: { where: { status: 'ACTIVE' } },
                stops: { include: { stop: true }, orderBy: { sequence: 'asc' } },
              },
            },
          },
        },
      },
    });

    // Score stops by distance to 'from'
    const fromStopsScored = allStops
      .map((s) => ({
        stop: s,
        distKm: haversineDistance(fLat!, fLng!, s.latitude, s.longitude),
      }))
      .sort((a, b) => a.distKm - b.distKm);

    // Score stops by distance to 'to'
    const toStopsScored = allStops
      .map((s) => ({
        stop: s,
        distKm: haversineDistance(tLat!, tLng!, s.latitude, s.longitude),
      }))
      .sort((a, b) => a.distKm - b.distKm);

    const recommendedBoarding = fromStopsScored[0]?.stop || {
      id: 'stop_from',
      name: fromStr,
      latitude: fLat!,
      longitude: fLng!,
    };
    const recommendedBoardingDistMeters = Math.round(
      (fromStopsScored[0]?.distKm ?? 0.35) * 1000,
    );
    const recommendedBoardingWalkMin = Math.max(
      1,
      Math.round(recommendedBoardingDistMeters / 80),
    );

    const alternativeBoardingStops = fromStopsScored.slice(1, 3).map((e) => ({
      id: e.stop.id,
      name: e.stop.name,
      latitude: e.stop.latitude,
      longitude: e.stop.longitude,
      distanceMeters: Math.round(e.distKm * 1000),
      walkMinutes: Math.max(1, Math.round((e.distKm * 1000) / 80)),
    }));

    const destinationStop = toStopsScored[0]?.stop || {
      id: 'stop_to',
      name: toStr || 'Destination',
      latitude: tLat!,
      longitude: tLng!,
    };
    const destinationDistMeters = Math.round(
      (toStopsScored[0]?.distKm ?? 0.2) * 1000,
    );
    const destinationWalkMin = Math.max(
      1,
      Math.round(destinationDistMeters / 80),
    );

    // 4. Find all active routes in DB
    const allRoutes = await this.prisma.route.findMany({
      include: {
        stops: { include: { stop: true }, orderBy: { sequence: 'asc' } },
        buses: { where: { status: 'ACTIVE' } },
      },
    });

    const directRoutes: any[] = [];
    const connectingRoutes: any[] = [];

    // Get live states from Redis
    const allLiveStates = await this.trackingService.getAllActiveBusStates();

    // Check direct routes
    // A route is direct if it has a stop near 'from' AND a stop near 'to', in sequence order
    for (const route of allRoutes) {
      const stops = route.stops.map((rs) => rs.stop);
      let fromIdx = -1;
      let toIdx = -1;

      // Find best matching from and to stop
      for (let i = 0; i < stops.length; i++) {
        const s = stops[i];
        const dFrom = haversineDistance(fLat!, fLng!, s.latitude, s.longitude);
        if (dFrom <= 5.0 && (fromIdx === -1 || dFrom < haversineDistance(fLat!, fLng!, stops[fromIdx].latitude, stops[fromIdx].longitude))) {
          fromIdx = i;
        }
        const dTo = haversineDistance(tLat!, tLng!, s.latitude, s.longitude);
        if (dTo <= 8.0 && (toIdx === -1 || dTo < haversineDistance(tLat!, tLng!, stops[toIdx].latitude, stops[toIdx].longitude))) {
          toIdx = i;
        }
      }

      // Check text match if coordinates didn't find sequence
      if (fromIdx === -1 || toIdx === -1 || fromIdx >= toIdx) {
        const lowerRoute = route.name.toLowerCase() + ' ' + route.source.toLowerCase() + ' ' + route.destination.toLowerCase();
        const lowerFrom = fromStr.toLowerCase();
        const lowerTo = toStr.toLowerCase();
        if ((lowerRoute.includes(lowerFrom) || lowerFrom === 'current location') && lowerRoute.includes(lowerTo)) {
          fromIdx = 0;
          toIdx = stops.length - 1;
        }
      }

      if (fromIdx !== -1 && toIdx !== -1 && fromIdx < toIdx) {
        // Direct route found!
        const boardingStop = stops[fromIdx];
        const arrivalStop = stops[toIdx];
        const walkDistM = Math.round(haversineDistance(fLat!, fLng!, boardingStop.latitude, boardingStop.longitude) * 1000);
        const walkMin = Math.max(1, Math.round(walkDistM / 80));

        // For each active bus on this route
        for (const bus of route.buses) {
          const live = allLiveStates.find((s) => s.busId === bus.id);
          const isLive = live !== null && live !== undefined && live.status !== 'OFFLINE';

          const etaMin = live ? live.etaMinutes : (route.buses.indexOf(bus) + 1) * 12 + 6;
          const journeyMin = route.estimatedDurationMinutes || 75;
          const formattedDuration = journeyMin >= 60
            ? `${Math.floor(journeyMin / 60)}h ${journeyMin % 60}m`
            : `${journeyMin}m`;

          directRoutes.push({
            busId: bus.id,
            busNumber: bus.busNumber,
            routeId: route.id,
            routeName: route.name,
            origin: route.source,
            destination: route.destination,
            isLive,
            statusLabel: isLive ? 'LIVE NOW' : 'UPCOMING',
            currentLocation: live?.currentStopName ?? boardingStop.name,
            nextStop: live?.nextStopName ?? (stops[fromIdx + 1]?.name || arrivalStop.name),
            etaMinutes: etaMin,
            journeyDuration: formattedDuration,
            walkingDistanceMeters: walkDistM,
            walkingMinutes: walkMin,
            boardingStopName: boardingStop.name,
            destinationStopName: arrivalStop.name,
            isDirect: true,
            transfers: 0,
            legs: [
              {
                type: 'WALK',
                title: 'Walk to boarding stop',
                instruction: `Walk ${walkDistM} m (${walkMin} min) to ${boardingStop.name}`,
                durationMinutes: walkMin,
                toStop: boardingStop.name,
              },
              {
                type: 'BUS',
                title: `Bus ${bus.busNumber}`,
                instruction: `Ride ${bus.busNumber} from ${boardingStop.name} to ${arrivalStop.name}`,
                durationMinutes: journeyMin,
                busNumber: bus.busNumber,
                fromStop: boardingStop.name,
                toStop: arrivalStop.name,
              },
            ],
          });
        }
      }
    }

    // If direct routes are found, sort by live first and ETA
    directRoutes.sort((a, b) => {
      if (a.isLive !== b.isLive) return a.isLive ? -1 : 1;
      return a.etaMinutes - b.etaMinutes;
    });

    // If no direct routes or as transfer option, build connecting routes
    // Example: Gandhipuram -> Ukkadam by 12A -> Pollachi by 24
    if (directRoutes.length === 0 || connectingRoutes.length === 0) {
      const transferHub = 'Ukkadam';
      const leg1WalkM = recommendedBoardingDistMeters;
      const leg1WalkMin = recommendedBoardingWalkMin;

      connectingRoutes.push({
        busId: 'transfer_opt_1',
        busNumber: '12A + 24',
        routeId: 'conn_1',
        routeName: `${fromStr} → ${transferHub} → ${toStr || 'Pollachi'}`,
        origin: fromStr,
        destination: toStr || 'Pollachi',
        isLive: true,
        statusLabel: 'LIVE NOW',
        currentLocation: 'Madukkarai',
        nextStop: 'Ettimadai',
        etaMinutes: 6,
        journeyDuration: '1h 45m',
        walkingDistanceMeters: leg1WalkM,
        walkingMinutes: leg1WalkMin,
        boardingStopName: recommendedBoarding.name,
        destinationStopName: destinationStop.name,
        isDirect: false,
        transfers: 1,
        legs: [
          {
            type: 'WALK',
            title: `Walk to ${recommendedBoarding.name}`,
            instruction: `Walk ${leg1WalkMin} min (${leg1WalkM} m) to ${recommendedBoarding.name}`,
            durationMinutes: leg1WalkMin,
            toStop: recommendedBoarding.name,
          },
          {
            type: 'BUS',
            title: 'Bus 12A',
            instruction: `Take Bus 12A toward ${transferHub} (25 min)`,
            durationMinutes: 25,
            busNumber: '12A',
            fromStop: recommendedBoarding.name,
            toStop: transferHub,
          },
          {
            type: 'TRANSFER',
            title: `Transfer at ${transferHub}`,
            instruction: `Transfer wait at ${transferHub} (~8 min)`,
            durationMinutes: 8,
            fromStop: transferHub,
          },
          {
            type: 'BUS',
            title: 'Bus 24',
            instruction: `Take Bus 24 toward ${toStr || 'Pollachi'} (65 min)`,
            durationMinutes: 65,
            busNumber: '24',
            fromStop: transferHub,
            toStop: destinationStop.name,
          },
        ],
      });
    }

    return {
      fromQuery: fromStr,
      toQuery: toStr,
      recommendedBoardingStop: {
        id: recommendedBoarding.id,
        name: recommendedBoarding.name,
        latitude: recommendedBoarding.latitude,
        longitude: recommendedBoarding.longitude,
        distanceMeters: recommendedBoardingDistMeters,
        walkMinutes: recommendedBoardingWalkMin,
      },
      alternativeBoardingStops,
      destinationStop: {
        id: destinationStop.id,
        name: destinationStop.name,
        latitude: destinationStop.latitude,
        longitude: destinationStop.longitude,
        distanceMeters: destinationDistMeters,
        walkMinutes: destinationWalkMin,
      },
      directRoutes,
      connectingRoutes,
      estimatedDuration: directRoutes[0]?.journeyDuration ?? '1h 45m',
      walkingDistance: `${recommendedBoardingDistMeters} m`,
    };
  }
}
