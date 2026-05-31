import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as fln;
import 'package:provider/provider.dart';

import '../providers/notification_provider.dart';
import '../views/auth/splash_screen.dart';
import '../views/profile/notification_navigation.dart';
import '../views/profile/notifications_view.dart';
import '../firebase_options.dart';
import 'api_service_base.dart';
import 'secure_storage_service.dart';

class FcmService extends ApiService {
  FcmService._();

  static final FcmService instance = FcmService._();

  static const fln.AndroidNotificationChannel _androidChannel =
      fln.AndroidNotificationChannel(
        'smarttrip_notifications',
        'SmartTrip Notifications',
        description: 'Thong bao tu Skynet Smart Trip',
        importance: fln.Importance.high,
      );

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final fln.FlutterLocalNotificationsPlugin _localNotifications =
      fln.FlutterLocalNotificationsPlugin();

  GlobalKey<NavigatorState>? _navigatorKey;
  StreamSubscription<String>? _tokenRefreshSubscription;
  bool _initialized = false;

  Future<void> initialize(GlobalKey<NavigatorState> navigatorKey) async {
    _navigatorKey = navigatorKey;
    if (_initialized) {
      return;
    }

    await _initializeLocalNotifications();
    _listenForForegroundMessages();
    _listenForNotificationTaps();

    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((_) {
      registerCurrentToken();
    });

    _initialized = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(requestNotificationPermissions());
    });
    unawaited(_handleInitialMessage());
  }

  Future<void> requestNotificationPermissions() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
            fln.AndroidFlutterLocalNotificationsPlugin
          >();
      final androidGranted = await androidPlugin
          ?.requestNotificationsPermission();

      if (kDebugMode) {
        debugPrint(
          '[FCM] Permission authorization=${settings.authorizationStatus.name}, '
          'androidGranted=$androidGranted',
        );
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[FCM] Permission request failed: $error');
      }
    }
  }

  Future<void> registerCurrentToken() async {
    try {
      await requestNotificationPermissions();
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) {
        if (kDebugMode) {
          debugPrint('[FCM] Token is empty, skip backend registration.');
        }
        return;
      }

      await postWithFallback(
        '/notifications/fcm-token',
        requireAuth: true,
        body: jsonEncode({'token': token, 'platform': _platformName}),
      );

      if (kDebugMode) {
        debugPrint('[FCM] Token registered: ${_maskToken(token)}');
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[FCM] Token registration failed: $error');
      }
    }
  }

  Future<void> unregisterCurrentToken() async {
    try {
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) {
        return;
      }

      await deleteWithFallback(
        '/notifications/fcm-token',
        requireAuth: true,
        body: jsonEncode({'token': token, 'platform': _platformName}),
      );

      if (kDebugMode) {
        debugPrint('[FCM] Token unregistered: ${_maskToken(token)}');
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[FCM] Token unregister failed: $error');
      }
    }
  }

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = fln.AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = fln.DarwinInitializationSettings();
    const settings = fln.InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) {
          _openFallbackNotificationList();
          return;
        }

        final decoded = jsonDecode(payload);
        if (decoded is Map<String, dynamic>) {
          unawaited(_handleNotificationData(decoded));
        }
      },
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          fln.AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(_androidChannel);
  }

  void _listenForForegroundMessages() {
    FirebaseMessaging.onMessage.listen((message) async {
      if (kDebugMode) {
        debugPrint('[FCM] Foreground message received: ${message.messageId}');
      }
      _refreshNotificationState();
      await _showForegroundNotification(message);
    });
  }

  void _listenForNotificationTaps() {
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _refreshNotificationState();
      unawaited(_handleNotificationData(message.data));
    });
  }

  Future<void> _handleInitialMessage() async {
    final message = await _messaging.getInitialMessage();
    if (message == null) {
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 600));
    _refreshNotificationState();
    await _handleNotificationData(message.data);
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final title =
        message.notification?.title ??
        message.data['title']?.toString() ??
        'Skynet Smart Trip';
    final body =
        message.notification?.body ??
        message.data['body']?.toString() ??
        message.data['message']?.toString() ??
        '';

    await _localNotifications.show(
      id: message.hashCode,
      title: title,
      body: body,
      notificationDetails: fln.NotificationDetails(
        android: fln.AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: fln.Importance.high,
          priority: fln.Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const fln.DarwinNotificationDetails(),
        macOS: const fln.DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );

    if (kDebugMode) {
      debugPrint('[FCM] Foreground local notification shown.');
    }
  }

  Future<void> _handleNotificationData(Map<String, dynamic> data) async {
    final context = _navigatorKey?.currentContext;
    if (context == null) {
      return;
    }

    final accessToken = await SecureStorageService.read('access_token');
    final activeContext = _navigatorKey?.currentContext;
    final navigator = _navigatorKey?.currentState;
    if (activeContext == null || navigator == null) {
      return;
    }
    if (!activeContext.mounted) {
      return;
    }

    if (accessToken == null || accessToken.isEmpty) {
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SplashScreen()),
        (route) => false,
      );
      return;
    }

    final notification = NotificationNavigation.fromFcmData(data);
    final opened = await NotificationNavigation.open(
      activeContext,
      notification,
    );
    if (!opened) {
      await navigator.push(
        MaterialPageRoute(builder: (_) => const NotificationsView()),
      );
    }
  }

  void _openFallbackNotificationList() {
    unawaited(_handleNotificationData(const <String, dynamic>{}));
  }

  void _refreshNotificationState() {
    final context = _navigatorKey?.currentContext;
    if (context == null) {
      return;
    }

    final provider = context.read<NotificationProvider>();
    unawaited(provider.fetchNotifications(silent: true));
    unawaited(provider.fetchUnreadCount());
  }

  String get _platformName {
    if (kIsWeb) {
      return 'web';
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      TargetPlatform.macOS => 'macos',
      TargetPlatform.windows => 'windows',
      TargetPlatform.linux => 'linux',
      TargetPlatform.fuchsia => 'fuchsia',
    };
  }

  String _maskToken(String token) {
    if (token.length <= 16) {
      return token;
    }

    return '${token.substring(0, 8)}...${token.substring(token.length - 8)}';
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}
