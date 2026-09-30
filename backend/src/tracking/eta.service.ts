import { Injectable } from '@nestjs/common';
import { StopInfo } from '../common/interfaces/bus-live-state.interface';

const AVERAGE_SPEED_KMH = 30;
const MIN_SPEED_KMH = 10;
const DWELL_TIME_SECONDS = 20;

@Injectable()
export class EtaService {
  /**
   * Calculate ETA to destination in minutes.
   * Considers: remaining distance, current speed, dwell times at upcoming stops.
   */
  calculateEta(
    distanceRemainingKm: number,
    currentSpeedKmh: number,
    isAtStop: boolean,
    remainingStops: number,
    dwellTimeSeconds: number = DWELL_TIME_SECONDS,
  ): number {
    if (distanceRemainingKm <= 0) return 0;

    // Use effective speed (never too low)
    const effectiveSpeed = Math.max(
      isAtStop ? 0 : currentSpeedKmh,
      MIN_SPEED_KMH,
    );

    // Travel time in minutes
    const travelMinutes = (distanceRemainingKm / effectiveSpeed) * 60;

    // Add dwell time for remaining stops
    const dwellMinutes = (remainingStops * dwellTimeSeconds) / 60;

    // If bus is currently stopped, add remaining dwell
    const currentDwellMinutes = isAtStop ? dwellTimeSeconds / 60 : 0;

    const totalEta = travelMinutes + dwellMinutes + currentDwellMinutes;
    return Math.max(1, Math.round(totalEta));
  }

  /**
   * Calculate ETA to a specific stop.
   */
  calculateEtaToStop(
    distanceToStopKm: number,
    currentSpeedKmh: number,
    stopsInBetween: number,
  ): number {
    if (distanceToStopKm <= 0) return 0;
    const effectiveSpeed = Math.max(currentSpeedKmh, MIN_SPEED_KMH);
    const travelMinutes = (distanceToStopKm / effectiveSpeed) * 60;
    const dwellMinutes = (stopsInBetween * DWELL_TIME_SECONDS) / 60;
    return Math.max(1, Math.round(travelMinutes + dwellMinutes));
  }
}
