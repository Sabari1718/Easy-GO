export interface NormalizedGpsPoint {
  trackerId: string;
  deviceId?: string;
  busId?: string;
  latitude: number;
  longitude: number;
  speed: number; // km/h
  heading: number; // degrees (0-360)
  accuracy: number; // meters
  timestamp: string; // ISO 8601 string
  extra?: {
    batteryLevel?: number;
    gsmSignal?: number;
    satellites?: number;
    ignition?: boolean;
    altitude?: number;
    odometer?: number;
    rawPayload?: any;
  };
}

export interface GpsDeviceAdapter {
  readonly name: string;
  readonly protocol: string;
  supports(payload: any, headers?: Record<string, any>): boolean;
  adapt(payload: any, headers?: Record<string, any>): NormalizedGpsPoint;
}
