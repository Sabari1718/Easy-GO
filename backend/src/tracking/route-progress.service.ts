import { Injectable } from '@nestjs/common';
import { RoutePoint } from '../common/interfaces/bus-live-state.interface';
import {
  haversineDistance,
  calculateRouteDistance,
  distanceTravelledAlongRoute,
  findNearestPointIndex,
} from '../common/utils/geo.utils';

@Injectable()
export class RouteProgressService {
  /**
   * Calculate route progress for a bus at a given position.
   * Returns distanceTravelled, distanceRemaining, progressPercentage.
   */
  calculateProgress(
    busLat: number,
    busLng: number,
    routeGeometry: RoutePoint[],
    lastPointIndex: number = 0,
  ): {
    distanceTravelledKm: number;
    distanceRemainingKm: number;
    progressPercentage: number;
    nearestPointIndex: number;
  } {
    if (!routeGeometry || routeGeometry.length < 2) {
      return {
        distanceTravelledKm: 0,
        distanceRemainingKm: 0,
        progressPercentage: 0,
        nearestPointIndex: 0,
      };
    }

    const totalDistance = calculateRouteDistance(routeGeometry);

    // Find nearest point on route (search forward from last known position)
    const searchStart = Math.max(0, lastPointIndex - 2);
    const nearestIdx = findNearestPointIndex(routeGeometry, busLat, busLng, searchStart);

    // Distance travelled = distance along route to nearest point
    const distTravelled = distanceTravelledAlongRoute(routeGeometry, nearestIdx);

    // Add the small remaining gap from nearest point to bus
    const gapToBus = haversineDistance(
      busLat,
      busLng,
      routeGeometry[nearestIdx].lat,
      routeGeometry[nearestIdx].lng,
    );

    const effectiveTravelled = Math.min(distTravelled + gapToBus * 0.5, totalDistance);
    const remaining = Math.max(0, totalDistance - effectiveTravelled);
    const progress = totalDistance > 0 ? (effectiveTravelled / totalDistance) * 100 : 0;

    return {
      distanceTravelledKm: Math.round(effectiveTravelled * 100) / 100,
      distanceRemainingKm: Math.round(remaining * 100) / 100,
      progressPercentage: Math.round(progress * 10) / 10,
      nearestPointIndex: nearestIdx,
    };
  }
}
