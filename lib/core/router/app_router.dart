import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/otp_screen.dart';
import '../../features/auth/presentation/screens/driver_login_screen.dart';
import '../../features/passenger/presentation/screens/passenger_home_screen.dart';
import '../../features/passenger/presentation/screens/passenger_tracking_screen.dart';
import '../../features/passenger/presentation/screens/passenger_routes_screen.dart';
import '../../features/passenger/presentation/screens/passenger_notifications_screen.dart';
import '../../features/passenger/presentation/screens/passenger_profile_screen.dart';
import '../../features/passenger/presentation/screens/profile_screen.dart';
import '../../features/passenger/presentation/screens/location_permission_screen.dart';
import '../../features/passenger/presentation/screens/bus_details_screen.dart';
import '../../features/passenger/presentation/screens/route_details_screen.dart';
import '../../features/passenger/presentation/widgets/passenger_bottom_nav.dart';
import '../../features/driver/presentation/screens/driver_dashboard_screen.dart';
import '../../features/driver/presentation/screens/driver_current_trip_screen.dart';
import '../../features/driver/presentation/screens/driver_tracking_screen.dart';
import '../../features/driver/presentation/screens/driver_status_screen.dart';
import '../../features/driver/presentation/screens/driver_profile_screen.dart';
import '../../features/driver/presentation/widgets/driver_bottom_nav.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _passengerShellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'passengerShell');
final GlobalKey<NavigatorState> _driverShellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'driverShell');

final goRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/otp',
      builder: (context, state) {
        final phone = state.extra as String;
        return OtpScreen(phoneNumber: phone);
      },
    ),
    GoRoute(
      path: '/driver-login',
      builder: (context, state) => const DriverLoginScreen(),
    ),
    GoRoute(
      path: '/location-permission',
      builder: (context, state) => const LocationPermissionScreen(),
    ),
    
    // Passenger Routes with ShellRoute for BottomNav
    ShellRoute(
      navigatorKey: _passengerShellNavigatorKey,
      builder: (context, state, child) => PassengerBottomNav(child: child),
      routes: [
        GoRoute(
          path: '/passenger/home',
          builder: (context, state) => const PassengerHomeScreen(),
        ),
        GoRoute(
          path: '/passenger/tracking',
          builder: (context, state) => const PassengerTrackingScreen(),
        ),
        GoRoute(
          path: '/passenger/routes',
          builder: (context, state) => const PassengerRoutesScreen(),
        ),
        GoRoute(
          path: '/passenger/notifications',
          builder: (context, state) => const PassengerNotificationsScreen(),
        ),
        GoRoute(
          path: '/passenger/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
    
    // Passenger Sub-routes (No BottomNav)
    GoRoute(
      path: '/passenger/bus/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => BusDetailsScreen(busId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/passenger/route/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => RouteDetailsScreen(routeId: state.pathParameters['id']!),
    ),

    // Driver Routes with ShellRoute for BottomNav
    ShellRoute(
      navigatorKey: _driverShellNavigatorKey,
      builder: (context, state, child) => DriverBottomNav(child: child),
      routes: [
        GoRoute(
          path: '/driver/dashboard',
          builder: (context, state) => const DriverDashboardScreen(),
        ),
        GoRoute(
          path: '/driver/trip',
          builder: (context, state) => const DriverCurrentTripScreen(),
        ),
        GoRoute(
          path: '/driver/tracking',
          builder: (context, state) => const DriverTrackingScreen(),
        ),
        GoRoute(
          path: '/driver/status',
          builder: (context, state) => const DriverStatusScreen(),
        ),
        GoRoute(
          path: '/driver/profile',
          builder: (context, state) => const DriverProfileScreen(),
        ),
      ],
    ),
  ],
);
