import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'unirent_main';
  static const String _channelName = 'UniRent';
  static const String _ntfyBase = 'https://ntfy.sh';

  // call this in main() before runApp
  static Future<void> init() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      ),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: 'UniRent booking and message notifications',
            importance: Importance.high,
          ),
        );

  }

  // ask for permission after the user lands on home, not at startup
  static Future<void> requestPermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> bookingConfirmed({
    required String itemTitle,
    required String period,
    int userId = 0,
  }) async {
    await _showLocal(
      id: 1001,
      title: 'Booking Confirmed!',
      body: '$itemTitle  •  $period',
    );
    _pushToApi(
      userId: userId,
      title: 'Booking Confirmed!',
      body: '$itemTitle  •  $period',
      tags: 'white_check_mark,house',
    );
  }

  static Future<void> newMessage({
    required String from,
    required String preview,
    int userId = 0,
  }) async {
    await _showLocal(
      id: 1002,
      title: 'New message from $from',
      body: preview,
    );
    _pushToApi(
      userId: userId,
      title: 'New message from $from',
      body: preview,
      tags: 'speech_balloon',
    );
  }

  static Future<void> itemListed({required String itemTitle}) async {
    await _showLocal(
      id: 1003,
      title: 'Item Listed Successfully',
      body: '"$itemTitle" is now visible to other students.',
    );
  }

  static Future<void> _showLocal({
    required int id,
    required String title,
    required String body,
  }) async {
    try {
      await _plugin.show(
        id,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(),
          macOS: DarwinNotificationDetails(),
        ),
      );
    } catch (_) {}
  }

  // fire-and-forget push to ntfy.sh topic unirent-user-{userId}
  static void _pushToApi({
    required int userId,
    required String title,
    required String body,
    String tags = '',
  }) {
    final topic = 'unirent-user-$userId';
    http
        .post(
          Uri.parse('$_ntfyBase/$topic'),
          headers: {
            'Title': title,
            'Priority': 'high',
            if (tags.isNotEmpty) 'Tags': tags,
            'Content-Type': 'text/plain; charset=utf-8',
          },
          body: body,
        )
        .timeout(const Duration(seconds: 6))
        .catchError((_) => http.Response('', 0));
  }
}
