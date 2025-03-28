import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_api_availability/google_api_availability.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static const _channelId = 'anime_release_channel';
  static const _channelName = 'Anime Releases';
  static const _channelDescription = 'Notifications for new anime releases';

  static Future<bool> checkGooglePlayServices() async {
    try {
      final availability =
          await GoogleApiAvailability.instance
              .checkGooglePlayServicesAvailability();
      return availability == GooglePlayServicesAvailability.success;
    } catch (e) {
      print('Error checking Google Play Services: $e');
      return false;
    }
  }

  static Future<void> initialize() async {
    try {
      if (!await checkGooglePlayServices()) {
        print('Google Play Services not available');
        return;
      }

      // Request permissions first
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        print('Notification permissions not granted');
        return;
      }

      // Initialize local notifications
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _handleNotificationTap,
      );

      // Create the notification channel for Android
      final androidChannel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
        enableVibration: true,
      );

      await _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(androidChannel);

      // Set up token refresh listener
      _messaging.onTokenRefresh.listen((token) async {
        debugPrint('FCM Token refreshed: $token');
        await _updateStoredToken(token);
      });

      // Get initial token
      final token = await getFCMToken();
      if (token != null) {
        await _updateStoredToken(token);
      }

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(handleForegroundMessage);

      // Handle background/terminated messages
      FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

      // Schedule release checks
      await scheduleReleaseChecks();

      print('Notification service initialized successfully');
    } catch (e) {
      print('Error initializing notification service: $e');
    }
  }

  static void _handleNotificationTap(NotificationResponse details) {
    print('Notification tapped: ${details.payload}');
    // TODO: Implement navigation to anime details page
  }

  static Future<void> handleForegroundMessage(RemoteMessage message) async {
    try {
      final notification = message.notification;
      final data = message.data;

      if (notification == null) return;

      final notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/launcher_icon',
          enableVibration: true,
          styleInformation: BigTextStyleInformation(
            notification.body ?? '',
            htmlFormatBigText: true,
            contentTitle: notification.title,
            htmlFormatContentTitle: true,
            summaryText: data['releaseInfo'] ?? 'New episode available',
          ),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await _notifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        notificationDetails,
        payload: message.data['animeId'],
      );
    } catch (e) {
      print('Error showing notification: $e');
    }
  }

  static Future<void> checkAndNotifyNewReleases() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Query Firestore for anime releasing today
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('trackedAnime')
              .where(
                'nextEpisodeDate',
                isGreaterThanOrEqualTo: Timestamp.fromDate(today),
              )
              .where(
                'nextEpisodeDate',
                isLessThan: Timestamp.fromDate(
                  today.add(const Duration(days: 1)),
                ),
              )
              .get();

      if (querySnapshot.docs.isEmpty) {
        debugPrint('No new releases found for today');
        return;
      }

      debugPrint('Found ${querySnapshot.docs.length} new releases');

      for (var doc in querySnapshot.docs) {
        final animeData = doc.data();
        final title = animeData['title'] as String;
        final nextEpisode = (animeData['currentEpisode'] as int) + 1;

        await _notifications.show(
          doc.id.hashCode,
          'New Episode Released!',
          '$title Episode $nextEpisode is now available!',
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              _channelName,
              channelDescription: _channelDescription,
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/launcher_icon',
              enableVibration: true,
              styleInformation: BigTextStyleInformation(
                '$title Episode $nextEpisode is now available to watch!',
                htmlFormatBigText: true,
                contentTitle: 'New Episode Released!',
                htmlFormatContentTitle: true,
                summaryText: 'Tap to view details',
              ),
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: doc.id,
        );

        await _updateNextEpisodeDate(doc.reference, animeData);
      }
    } catch (e) {
      debugPrint('Error checking new releases: $e');
    }
  }

  static Future<void> _updateStoredToken(String token) async {
    try {
      await FirebaseFirestore.instance
          .collection('deviceTokens')
          .doc(token)
          .set({
            'lastUpdated': FieldValue.serverTimestamp(),
            'platform': 'android',
          });
    } catch (e) {
      debugPrint('Error updating FCM token: $e');
    }
  }

  static Future<void> startTrackingFromToday(
    Map<String, dynamic> animeData,
  ) async {
    try {
      final now = DateTime.now();
      final malId = animeData['malId'].toString();

      // Create a document reference
      final docRef = FirebaseFirestore.instance
          .collection('trackedAnime')
          .doc(malId);

      // Check if already tracking
      final doc = await docRef.get();
      if (doc.exists) {
        debugPrint('Already tracking anime: ${animeData['title']}');
        return;
      }

      // Prepare tracking data
      final trackingData = {
        ...animeData,
        'currentEpisode': 1,
        'startDate': Timestamp.fromDate(now),
        'broadcastDay': _getBroadcastDay(now),
        'nextEpisodeDate': Timestamp.fromDate(
          _calculateNextBroadcastDate(now, _getBroadcastDay(now)),
        ),
      };

      await docRef.set(trackingData);
      await subscribeToAnime(malId);

      debugPrint(
        'Started tracking anime: ${animeData['title']} from ${now.toIso8601String()}',
      );
    } catch (e) {
      debugPrint('Error starting to track anime: $e');
      rethrow;
    }
  }

  static String _getBroadcastDay(DateTime date) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[date.weekday - 1];
  }

  static Future<void> _updateNextEpisodeDate(
    DocumentReference docRef,
    Map<String, dynamic> animeData,
  ) async {
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) return;

        final currentEpisode = snapshot.get('currentEpisode') as int;
        final nextDate = _calculateNextBroadcastDate(
          (animeData['nextEpisodeDate'] as Timestamp).toDate(),
          animeData['broadcastDay'] as String,
        );

        transaction.update(docRef, {
          'nextEpisodeDate': Timestamp.fromDate(nextDate),
          'currentEpisode': currentEpisode + 1,
        });
      });
    } catch (e) {
      debugPrint('Error updating next episode date: $e');
    }
  }

  static Future<void> removeTracking(String animeId) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('trackedAnime')
          .doc(animeId);

      await docRef.delete();
      await unsubscribeFromAnime(animeId);

      debugPrint('Stopped tracking anime: $animeId');
    } catch (e) {
      debugPrint('Error removing anime tracking: $e');
      rethrow;
    }
  }

  static Future<bool> isTracking(String animeId) async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('trackedAnime')
              .doc(animeId)
              .get();

      return doc.exists;
    } catch (e) {
      debugPrint('Error checking tracking status: $e');
      return false;
    }
  }

  static Future<void> updateEpisodeProgress(
    String animeId,
    int currentEpisode,
  ) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('trackedAnime')
          .doc(animeId);

      await docRef.update({'currentEpisode': currentEpisode});

      debugPrint('Updated episode progress for anime: $animeId');
    } catch (e) {
      debugPrint('Error updating episode progress: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getTrackedAnime() async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance.collection('trackedAnime').get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('Error getting tracked anime: $e');
      return [];
    }
  }

  static DateTime _calculateNextBroadcastDate(
    DateTime current,
    String broadcastDay,
  ) {
    final days = {
      'Monday': 1,
      'Tuesday': 2,
      'Wednesday': 3,
      'Thursday': 4,
      'Friday': 5,
      'Saturday': 6,
      'Sunday': 7,
    };

    final targetDay = days[broadcastDay] ?? 1;
    var next = current.add(const Duration(days: 7));

    while (next.weekday != targetDay) {
      next = next.add(const Duration(days: 1));
    }

    return next;
  }

  // Method to schedule periodic checks
  static Future<void> scheduleReleaseChecks() async {
    const interval = Duration(hours: 1);
    Timer.periodic(interval, (timer) async {
      await checkAndNotifyNewReleases();
    });
  }

  @pragma('vm:entry-point')
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    print('Handling background message: ${message.messageId}');
    // Background message handling is limited, so we just log it
  }

  static Future<String?> getFCMToken() async {
    try {
      if (!await checkGooglePlayServices()) return null;
      return await _messaging.getToken();
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  static Future<void> subscribeToAnime(String animeId) async {
    try {
      await _messaging.subscribeToTopic('anime_$animeId');
      print('Subscribed to anime_$animeId');
    } catch (e) {
      print('Error subscribing to anime: $e');
      throw Exception('Failed to subscribe to anime notifications');
    }
  }

  static Future<void> unsubscribeFromAnime(String animeId) async {
    try {
      await _messaging.unsubscribeFromTopic('anime_$animeId');
      print('Unsubscribed from anime_$animeId');
    } catch (e) {
      print('Error unsubscribing from anime: $e');
      throw Exception('Failed to unsubscribe from anime notifications');
    }
  }

  static Future<void> testNotification() async {
    try {
      // Test local notification
      await _notifications.show(
        1,
        'Test Notification',
        'This is a test notification',
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/launcher_icon',
            enableVibration: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );

      // Add test data to Firestore
      final testAnime = {
        'malId': 1,
        'title': 'Test Anime',
        'imageUrl': 'https://example.com/image.jpg',
        'currentEpisode': 1,
        'broadcastDay': 'Monday',
        'nextEpisodeDate': Timestamp.fromDate(
          DateTime.now().add(const Duration(minutes: 1)),
        ),
      };

      await FirebaseFirestore.instance
          .collection('trackedAnime')
          .doc('test_anime')
          .set(testAnime);

      debugPrint('Test notification sent and test data added to Firestore');
    } catch (e) {
      debugPrint('Error testing notifications: $e');
    }
  }

  static void dispose() {
    _notifications.cancelAll();
  }
}
