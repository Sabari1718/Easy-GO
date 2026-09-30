/**
 * Calculate distance between two GPS coordinates using Haversine formula
 * Returns distance in kilometers
 */
export function haversineDistance(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number,
): number {
  const R = 6371; // Earth's radius in kilometers
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) *
      Math.cos(toRad(lat2)) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

function toRad(deg: number): number {
  return (deg * Math.PI) / 180;
}

/**
 * Calculate bearing from point A to point B in degrees (0-360)
 */
export function calculateBearing(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number,
): number {
  const dLon = toRad(lon2 - lon1);
  const lat1Rad = toRad(lat1);
  const lat2Rad = toRad(lat2);

  const y = Math.sin(dLon) * Math.cos(lat2Rad);
  const x =
    Math.cos(lat1Rad) * Math.sin(lat2Rad) -
    Math.sin(lat1Rad) * Math.cos(lat2Rad) * Math.cos(dLon);

  let brng = Math.atan2(y, x);
  brng = (brng * 180) / Math.PI;
  return (brng + 360) % 360;
}

/**
 * Interpolate a point between two coordinates by fraction (0.0 to 1.0)
 */
export function interpolatePoint(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number,
  fraction: number,
): { lat: number; lng: number } {
  return {
    lat: lat1 + (lat2 - lat1) * fraction,
    lng: lon1 + (lon2 - lon1) * fraction,
  };
}

/**
 * Calculate total distance of a route geometry (array of {lat, lng} points)
 */
export function calculateRouteDistance(points: { lat: number; lng: number }[]): number {
  let total = 0;
  for (let i = 0; i < points.length - 1; i++) {
    total += haversineDistance(points[i].lat, points[i].lng, points[i + 1].lat, points[i + 1].lng);
  }
  return total;
}

/**
 * Find nearest point index on route geometry to current position
 */
export function findNearestPointIndex(
  points: { lat: number; lng: number }[],
  lat: number,
  lng: number,
  startIndex = 0,
): number {
  let minDist = Infinity;
  let minIdx = startIndex;
  for (let i = startIndex; i < points.length; i++) {
    const d = haversineDistance(lat, lng, points[i].lat, points[i].lng);
    if (d < minDist) {
      minDist = d;
      minIdx = i;
    }
  }
  return minIdx;
}

/**
 * Calculate distance travelled along route from start to a given point index
 */
export function distanceTravelledAlongRoute(
  points: { lat: number; lng: number }[],
  upToIndex: number,
): number {
  let total = 0;
  for (let i = 0; i < Math.min(upToIndex, points.length - 1); i++) {
    total += haversineDistance(points[i].lat, points[i].lng, points[i + 1].lat, points[i + 1].lng);
  }
  return total;
}
