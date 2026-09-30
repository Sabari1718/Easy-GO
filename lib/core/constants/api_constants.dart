class ApiConstants {
  // Use 10.0.2.2 for Android emulator, localhost for web/desktop/iOS simulator
  static const String baseUrl = 'http://10.0.2.2:3000';
  static const String fallbackLocalUrl = 'http://localhost:3000';

  static const String homeEndpoint = '/home';
  static const String journeysSearchEndpoint = '/journeys/search';
  static const String nearbyBusesEndpoint = '/buses/nearby';
  static const String nearbyStopsEndpoint = '/stops/nearby';
  static const String searchEndpoint = '/search';
}
