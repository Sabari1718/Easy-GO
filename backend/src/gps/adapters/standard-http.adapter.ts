import { Injectable, BadRequestException } from '@nestjs/common';
import { GpsDeviceAdapter, NormalizedGpsPoint } from './gps-adapter.interface';

@Injectable()
export class StandardHttpAdapter implements GpsDeviceAdapter {
  readonly name = 'StandardHttpGpsAdapter';
  readonly protocol = 'HTTP_JSON';

  supports(payload: any, headers?: Record<string, any>): boolean {
    return (
      payload &&
      (typeof payload.latitude === 'number' || typeof payload.lat === 'number') &&
      (typeof payload.longitude === 'number' || typeof payload.lng === 'number' || typeof payload.lon === 'number')
    );
  }

  adapt(payload: any, headers?: Record<string, any>): NormalizedGpsPoint {
    const trackerId =
      payload.trackerId ||
      payload.deviceId ||
      payload.imei ||
      headers?.['x-tracker-id'] ||
      headers?.['x-device-id'];

    if (!trackerId) {
      throw new BadRequestException('Tracker ID is missing in payload (trackerId/deviceId) or x-tracker-id header');
    }

    const rawLat = payload.latitude ?? payload.lat;
    const rawLng = payload.longitude ?? payload.lng ?? payload.lon;

    const latitude = Number(rawLat);
    const longitude = Number(rawLng);

    if (isNaN(latitude) || latitude < -90 || latitude > 90) {
      throw new BadRequestException(`Invalid latitude: ${rawLat}. Must be between -90 and 90 degrees.`);
    }

    if (isNaN(longitude) || longitude < -180 || longitude > 180) {
      throw new BadRequestException(`Invalid longitude: ${rawLng}. Must be between -180 and 180 degrees.`);
    }

    const speed = Math.max(0, Number(payload.speed ?? 0));
    const heading = Math.max(0, Math.min(360, Number(payload.heading ?? payload.course ?? payload.bearing ?? 0)));
    const accuracy = Math.max(0, Number(payload.accuracy ?? payload.hdop ?? 5));

    const rawTimestamp = payload.timestamp ?? payload.time ?? payload.recordedAt ?? new Date().toISOString();
    const parsedDate = new Date(rawTimestamp);
    if (isNaN(parsedDate.getTime())) {
      throw new BadRequestException(`Invalid timestamp: ${rawTimestamp}. Must be valid ISO 8601.`);
    }

    return {
      trackerId: String(trackerId),
      deviceId: payload.deviceId ? String(payload.deviceId) : undefined,
      busId: payload.busId ? String(payload.busId) : undefined,
      latitude,
      longitude,
      speed,
      heading,
      accuracy,
      timestamp: parsedDate.toISOString(),
      extra: {
        batteryLevel: payload.batteryLevel ?? payload.battery,
        gsmSignal: payload.gsmSignal ?? payload.csq,
        satellites: payload.satellites ?? payload.sats,
        altitude: payload.altitude,
        ignition: payload.ignition,
        rawPayload: payload,
      },
    };
  }
}
