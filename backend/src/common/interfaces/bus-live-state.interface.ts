// Bus live state stored in Redis
export interface BusLiveState {
  busId: string;
  tripId: string;
  busNumber: string;
  routeId: string;
  routeName: string;
  latitude: number;
  longitude: number;
  speed: number;
  heading: number;
  currentStopId: string;
  currentStopName: string;
  nextStopId: string;
  nextStopName: string;
  distanceToNextStop: number;
  distanceTravelledKm: number;
  distanceRemainingKm: number;
  totalRouteDistanceKm: number;
  etaMinutes: number;
  progressPercentage: number;
  status: BusRealtimeStatus;
  lastUpdated: string; // ISO string
  locationStatus?: 'LIVE' | 'RECENT' | 'STALE' | 'OFFLINE';
  secondsSinceUpdate?: number;
  trackerOnline?: boolean;
}

export enum BusRealtimeStatus {
  NOT_STARTED = 'NOT_STARTED',
  MOVING = 'MOVING',
  APPROACHING_STOP = 'APPROACHING_STOP',
  STOPPED_AT_STOP = 'STOPPED_AT_STOP',
  LEFT_STOP = 'LEFT_STOP',
  COMPLETED = 'COMPLETED',
  OFFLINE = 'OFFLINE',
}

export interface GpsUpdate {
  deviceId?: string;
  trackerId?: string;
  busId?: string;
  latitude: number;
  longitude: number;
  speed: number;
  heading: number;
  accuracy?: number;
  timestamp: string;
}

export interface RoutePoint {
  lat: number;
  lng: number;
}

export interface StopInfo {
  stopId: string;
  name: string;
  latitude: number;
  longitude: number;
  sequence: number;
  distanceFromStartKm: number;
  estimatedMinutesFromPreviousStop: number;
}
