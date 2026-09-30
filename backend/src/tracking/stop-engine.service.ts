import { Injectable, Logger } from '@nestjs/common';
import { StopInfo } from '../common/interfaces/bus-live-state.interface';
import { haversineDistance } from '../common/utils/geo.utils';

@Injectable()
export class StopEngineService {
  private readonly logger = new Logger(StopEngineService.name);

  private readonly APPROACHING_RADIUS_KM = 0.3;
  private readonly AT_STOP_RADIUS_KM = 0.08;

  /**
   * Determines current stop and next stop based on bus position and route stops.
   * Uses route sequence to ensure the "next stop" is always ahead of the bus.
   */
  determineStops(
    busLat: number,
    busLng: number,
    stops: StopInfo[],
    currentSequenceIndex: number = 0,
  ): {
    currentStopId: string;
    currentStopName: string;
    nextStopId: string;
    nextStopName: string;
    distanceToNextStop: number;
    isApproaching: boolean;
    isAtStop: boolean;
    currentSequenceIndex: number;
  } {
    if (!stops || stops.length === 0) {
      return {
        currentStopId: '',
        currentStopName: 'Unknown',
        nextStopId: '',
        nextStopName: 'Unknown',
        distanceToNextStop: 0,
        isApproaching: false,
        isAtStop: false,
        currentSequenceIndex: 0,
      };
    }

    // Find the nearest stop that hasn't been passed yet (based on sequence)
    // We look ahead from currentSequenceIndex
    let nearestAheadIdx = currentSequenceIndex;
    let nearestAheadDist = Infinity;

    for (let i = currentSequenceIndex; i < stops.length; i++) {
      const dist = haversineDistance(busLat, busLng, stops[i].latitude, stops[i].longitude);
      if (dist < nearestAheadDist) {
        nearestAheadDist = dist;
        nearestAheadIdx = i;
      }
      // Once we're significantly past (dist increasing much), break
      if (i > currentSequenceIndex && dist > nearestAheadDist * 3) break;
    }

    // Check if bus has passed a stop (distance to stop before nearest is decreasing)
    // Determine current position in sequence
    let newSequenceIndex = currentSequenceIndex;
    if (nearestAheadDist < this.AT_STOP_RADIUS_KM) {
      // At the stop
      newSequenceIndex = nearestAheadIdx;
    } else if (nearestAheadIdx > currentSequenceIndex) {
      // We've advanced past some stops
      newSequenceIndex = Math.max(currentSequenceIndex, nearestAheadIdx - 1);
    }

    const currentStop = stops[Math.min(newSequenceIndex, stops.length - 1)];
    const nextStopIdx = Math.min(newSequenceIndex + 1, stops.length - 1);
    const nextStop = stops[nextStopIdx];

    const distToNext = haversineDistance(
      busLat,
      busLng,
      nextStop.latitude,
      nextStop.longitude,
    );

    const distToCurrent = haversineDistance(
      busLat,
      busLng,
      currentStop.latitude,
      currentStop.longitude,
    );

    const isAtStop = distToCurrent < this.AT_STOP_RADIUS_KM;
    const isApproaching = !isAtStop && distToNext < this.APPROACHING_RADIUS_KM;

    return {
      currentStopId: currentStop.stopId,
      currentStopName: currentStop.name,
      nextStopId: nextStop.stopId,
      nextStopName: nextStop.name,
      distanceToNextStop: distToNext,
      isApproaching,
      isAtStop,
      currentSequenceIndex: newSequenceIndex,
    };
  }

  /**
   * Update sequence index when bus departs a stop
   */
  advanceToNextStop(currentSequenceIndex: number, totalStops: number): number {
    return Math.min(currentSequenceIndex + 1, totalStops - 1);
  }
}
