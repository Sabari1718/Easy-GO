import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  MessageBody,
  ConnectedSocket,
  OnGatewayConnection,
  OnGatewayDisconnect,
  OnGatewayInit,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { Logger } from '@nestjs/common';
import { BusLiveState } from '../common/interfaces/bus-live-state.interface';

@WebSocketGateway({
  cors: {
    origin: '*',
    methods: ['GET', 'POST'],
  },
  transports: ['websocket', 'polling'],
})
export class RealtimeGateway
  implements OnGatewayInit, OnGatewayConnection, OnGatewayDisconnect
{
  @WebSocketServer()
  server: Server;

  private readonly logger = new Logger(RealtimeGateway.name);

  // Map of busId → Set of socket IDs subscribed to it
  private busSubscriptions = new Map<string, Set<string>>();

  afterInit(server: Server) {
    this.logger.log('🔌 WebSocket Gateway initialized');
  }

  handleConnection(client: Socket) {
    this.logger.log(`Client connected: ${client.id}`);
  }

  handleDisconnect(client: Socket) {
    // Clean up all subscriptions for this socket
    this.busSubscriptions.forEach((subscribers, busId) => {
      subscribers.delete(client.id);
      if (subscribers.size === 0) {
        this.busSubscriptions.delete(busId);
      }
    });
    this.logger.log(`Client disconnected: ${client.id}`);
  }

  @SubscribeMessage('subscribeToBus')
  handleSubscribeToBus(
    @MessageBody() data: { busId: string },
    @ConnectedSocket() client: Socket,
  ) {
    const { busId } = data;
    const roomName = `bus:${busId}`;

    client.join(roomName);

    if (!this.busSubscriptions.has(busId)) {
      this.busSubscriptions.set(busId, new Set());
    }
    this.busSubscriptions.get(busId).add(client.id);

    this.logger.log(`Client ${client.id} subscribed to bus ${busId}`);
    client.emit('subscribed', { busId, message: `Subscribed to bus ${busId}` });
  }

  @SubscribeMessage('unsubscribeFromBus')
  handleUnsubscribeFromBus(
    @MessageBody() data: { busId: string },
    @ConnectedSocket() client: Socket,
  ) {
    const { busId } = data;
    const roomName = `bus:${busId}`;

    client.leave(roomName);

    const subscribers = this.busSubscriptions.get(busId);
    if (subscribers) {
      subscribers.delete(client.id);
      if (subscribers.size === 0) {
        this.busSubscriptions.delete(busId);
      }
    }

    this.logger.log(`Client ${client.id} unsubscribed from bus ${busId}`);
    client.emit('unsubscribed', { busId });
  }

  @SubscribeMessage('subscribeToRoute')
  handleSubscribeToRoute(
    @MessageBody() data: { routeId: string },
    @ConnectedSocket() client: Socket,
  ) {
    const { routeId } = data;
    client.join(`route:${routeId}`);
    this.logger.log(`Client ${client.id} subscribed to route ${routeId}`);
    client.emit('subscribed', { routeId });
  }

  @SubscribeMessage('unsubscribeFromRoute')
  handleUnsubscribeFromRoute(
    @MessageBody() data: { routeId: string },
    @ConnectedSocket() client: Socket,
  ) {
    const { routeId } = data;
    client.leave(`route:${routeId}`);
    this.logger.log(`Client ${client.id} unsubscribed from route ${routeId}`);
    client.emit('unsubscribed', { routeId });
  }

  @SubscribeMessage('subscribeToNearby')
  handleSubscribeToNearby(@ConnectedSocket() client: Socket) {
    client.join('nearby');
    this.logger.log(`Client ${client.id} subscribed to nearby buses`);
    client.emit('subscribed', { channel: 'nearby' });
  }

  @SubscribeMessage('unsubscribeFromNearby')
  handleUnsubscribeFromNearby(@ConnectedSocket() client: Socket) {
    client.leave('nearby');
    this.logger.log(`Client ${client.id} unsubscribed from nearby buses`);
    client.emit('unsubscribed', { channel: 'nearby' });
  }

  /**
   * Broadcast a bus location update to all relevant subscribers and global listeners.
   */
  broadcastBusUpdate(liveState: BusLiveState) {
    const payload = {
      busId: liveState.busId,
      busNumber: liveState.busNumber,
      routeId: liveState.routeId,
      routeName: liveState.routeName,
      latitude: liveState.latitude,
      longitude: liveState.longitude,
      speed: liveState.speed,
      heading: liveState.heading,
      currentStop: liveState.currentStopName,
      currentStopId: liveState.currentStopId,
      nextStop: liveState.nextStopName,
      nextStopId: liveState.nextStopId,
      distanceToNextStop: liveState.distanceToNextStop,
      distanceRemaining: liveState.distanceRemainingKm,
      distanceRemainingKm: liveState.distanceRemainingKm,
      distanceTravelled: liveState.distanceTravelledKm,
      distanceTravelledKm: liveState.distanceTravelledKm,
      etaMinutes: liveState.etaMinutes,
      progressPercentage: liveState.progressPercentage,
      status: liveState.status,
      timestamp: liveState.lastUpdated,
    };

    // Emit to specific bus rooms (UUID, busNumber, and BUS_xx aliases)
    this.server.to(`bus:${liveState.busId}`).emit('bus.location.updated', payload);
    this.server.to(`bus:${liveState.busNumber}`).emit('bus.location.updated', payload);
    this.server.to(`bus:BUS_${liveState.busNumber}`).emit('bus.location.updated', payload);

    // Emit to route room
    this.server.to(`route:${liveState.routeId}`).emit('bus.location.updated', payload);

    // Emit to nearby room
    this.server.to('nearby').emit('bus.location.updated', payload);

    // Broadcast globally to all connected clients
    this.server.emit('bus.location.updated', payload);
  }

  /**
   * Broadcast to all connected clients (for nearby bus updates)
   */
  broadcastToAll(event: string, data: any) {
    this.server.emit(event, data);
  }

  getSubscriberCount(busId: string): number {
    return this.busSubscriptions.get(busId)?.size || 0;
  }
}
