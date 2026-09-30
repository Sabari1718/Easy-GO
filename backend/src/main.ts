import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { ValidationPipe } from '@nestjs/common';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { IoAdapter } from '@nestjs/platform-socket.io';
import { ConfigService } from '@nestjs/config';

async function bootstrap() {
  const app = await NestFactory.create(AppModule, {
    logger: ['log', 'warn', 'error', 'debug'],
  });

  const configService = app.get(ConfigService);
  const port = Number(configService.get('APP_PORT')) || 3000;

  // Enable CORS
  app.enableCors({
    origin: configService.get('CORS_ORIGIN') || '*',
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    credentials: true,
  });

  // Global validation pipe
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      forbidNonWhitelisted: false,
    }),
  );

  // WebSocket adapter
  app.useWebSocketAdapter(new IoAdapter(app));

  // API prefix (with exclusions so root-level endpoints work directly)
  app.setGlobalPrefix('api/v1', {
    exclude: [
      'gps/(.*)',
      'buses/(.*)',
      'stops/(.*)',
      'routes/(.*)',
      'simulator/(.*)',
      'home',
      'journeys/(.*)',
      'search',
      'trackers',
      'trackers/(.*)',
    ],
  });

  // Swagger setup
  const config = new DocumentBuilder()
    .setTitle('EasyGo API')
    .setDescription(
      `
      EasyGo Real-Time Bus Tracking API
      
      ## WebSocket Events
      Connect to ws://localhost:${port} with Socket.IO
      
      ### Subscribe to bus
      \`\`\`
      socket.emit('subscribeToBus', { busId: 'bus-uuid' })
      \`\`\`
      
      ### Receive updates  
      \`\`\`
      socket.on('bus.location.updated', (data) => { ... })
      \`\`\`
      
      ### Unsubscribe
      \`\`\`
      socket.emit('unsubscribeFromBus', { busId: 'bus-uuid' })
      \`\`\`
    `,
    )
    .setVersion('1.0')
    .addBearerAuth()
    .addApiKey({ type: 'apiKey', in: 'header', name: 'x-tracker-key' }, 'tracker-auth')
    .build();

  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('api/docs', app, document, {
    swaggerOptions: {
      persistAuthorization: true,
    },
  });

  await app.listen(port);
  console.log(`\n🚀 EasyGo Backend running on: http://localhost:${port}`);
  console.log(`📚 Swagger API Docs: http://localhost:${port}/api/docs`);
  console.log(`🔌 WebSocket: ws://localhost:${port}`);
  console.log(`\n✅ All systems ready!\n`);
}

bootstrap();
