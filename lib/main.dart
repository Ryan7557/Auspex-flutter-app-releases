import 'dart:async';
import 'package:auspex/API_services/firebase_notifications.dart';
import 'package:auspex/ViewModel/anime_viewmodel.dart';
import 'package:auspex/ViewModel/notification_viewModel.dart';
import 'package:auspex/Views/home.dart';
import 'package:auspex/firebase_options.dart';
import 'package:auspex/themes.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('Handling background message: ${message.messageId}');
}

void main() async {
  await runZonedGuarded(
    () async {
      WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
      FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

      // Set up error handling for Flutter errors
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.dumpErrorToConsole(details);
        debugPrint('Flutter Error: ${details.exception}');
        debugPrint('Stack trace: ${details.stack}');
      };

      try {
        // Enable performance optimizations
        PaintingBinding.instance.imageCache.maximumSize = 1000;
        PaintingBinding.instance.imageCache.maximumSizeBytes = 50 << 20; // 50MB
        GoogleFonts.config.allowRuntimeFetching = false;

        // Initialize Firebase
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );

        // Initialize notification service
        await NotificationService.initialize();

        // Remove splash screen after initialization
        FlutterNativeSplash.remove();

        // Set up Firebase messaging
        FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler,
        );
        final messaging = FirebaseMessaging.instance;

        // Request notification permissions with retry logic
        NotificationSettings? settings;
        int retryCount = 0;
        while (settings == null && retryCount < 3) {
          try {
            settings = await messaging.requestPermission(
              alert: true,
              badge: true,
              sound: true,
              provisional: false,
            );
          } catch (e) {
            retryCount++;
            debugPrint(
              'Failed to request permissions, attempt $retryCount: $e',
            );
            await Future.delayed(Duration(seconds: retryCount));
          }
        }

        if (settings?.authorizationStatus == AuthorizationStatus.authorized) {
          // Get FCM token
          String? token = await NotificationService.getFCMToken();
          if (token != null) {
            debugPrint('FCM Token: $token');
          }

          // Set up message handlers
          FirebaseMessaging.onMessage.listen(
            NotificationService.handleForegroundMessage,
            onError: (error) => debugPrint('FCM message error: $error'),
          );

          messaging.onTokenRefresh.listen(
            (token) => debugPrint('FCM Token refreshed: $token'),
            onError: (error) => debugPrint('Token refresh error: $error'),
          );
        } else {
          debugPrint('Notification permissions not granted');
        }

        // Run the app
        runApp(
          MultiProvider(
            providers: [
              ChangeNotifierProvider(
                create: (_) => ThemeProvider(),
                lazy: false,
              ),
              ChangeNotifierProvider(
                create: (_) => AnimeViewModel(),
                lazy: false,
              ),
              ChangeNotifierProvider(
                create: (_) => NotificationProvider()..loadSettings(),
                lazy: false,
              ),
            ],
            child: const MyApp(),
          ),
        );
      } catch (e, stackTrace) {
        FlutterNativeSplash.remove();
        debugPrint('Initialization error: $e');
        debugPrint('Stack trace: $stackTrace');
        rethrow;
      }
    },
    (error, stackTrace) {
      debugPrint('Uncaught error: $error');
      debugPrint('Stack trace: $stackTrace');
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder:
          (context, themeProvider, _) => MaterialApp(
            title: 'AUSPEX',
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: themeProvider.themeMode,
            debugShowCheckedModeBanner: false,
            home: const HomeScreen(),
            builder: (context, child) {
              ErrorWidget.builder = (FlutterErrorDetails details) {
                debugPrint('UI Error: ${details.exception}');
                return Material(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 60,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'An error occurred',
                          style: GoogleFonts.vt323(
                            fontSize: 24,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (kDebugMode)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              '${details.exception}',
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              };
              return child ?? const SizedBox.shrink();
            },
          ),
    );
  }
}
