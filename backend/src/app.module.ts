import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ThrottlerModule } from '@nestjs/throttler';
import { DatabaseModule } from './database/database.module';
import { RedisModule } from './redis/redis.module';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { BusesModule } from './buses/buses.module';
import { RoutesModule } from './routes/routes.module';
import { StopsModule } from './stops/stops.module';
import { TripsModule } from './trips/trips.module';
import { TrackingModule } from './tracking/tracking.module';
import { GpsModule } from './gps/gps.module';
import { NearbyModule } from './nearby/nearby.module';
import { SearchModule } from './search/search.module';
import { FavoritesModule } from './favorites/favorites.module';
import { AlertsModule } from './alerts/alerts.module';
import { RealtimeModule } from './realtime/realtime.module';
import { HealthModule } from './health/health.module';
import { SimulatorModule } from './simulator/simulator.module';
import { HomeModule } from './home/home.module';
import { JourneysModule } from './journeys/journeys.module';
import { TrackersModule } from './trackers/trackers.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: '.env',
    }),
    ThrottlerModule.forRoot([
      {
        ttl: 60000,
        limit: 100,
      },
    ]),
    DatabaseModule,
    RedisModule,
    AuthModule,
    UsersModule,
    BusesModule,
    RoutesModule,
    StopsModule,
    TripsModule,
    TrackingModule,
    GpsModule,
    NearbyModule,
    SearchModule,
    FavoritesModule,
    AlertsModule,
    RealtimeModule,
    HealthModule,
    SimulatorModule,
    HomeModule,
    JourneysModule,
    TrackersModule,
  ],
})
export class AppModule {}
