import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'session.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  Timer? _pollingTimer;
  String? _ip;
  String? _port;
  int? _uid;

  /// 알림 권한 요청 (앱 시작 시 호출)
  Future<void> requestNotificationPermission() async {
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// 서버 정보 세팅 (로그인 후 호출)
  void configure({required String ip, required String port, required int uid}) {
    _ip = ip;
    _port = port;
    _uid = uid;
  }

  /// 알림 플러그인 초기화
  Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
    const InitializationSettings initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _notificationsPlugin.initialize(initSettings);
  }

  void startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkNotifications();
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _checkNotifications() async {
    if (_ip == null || _port == null || _uid == null) return;

    try {
      final url = Uri.parse('http://$_ip:$_port/notifications');
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final List<dynamic> notifications = json.decode(response.body);
        for (var notification in notifications) {
          if (notification['uid'] == _uid) {
            await _showNotification(
              notification['title'] ?? 'New Notification',
              notification['body'] ?? '',
            );
          }
        }
      }
    } catch (e) {
      print('Error checking notifications: $e');
    }
  }

  /// 직접 호출 가능한 알림 표시 (테스트용)
  Future<void> showNotification({
    String title = '테스트 알림',
    String body = '이것은 테스트 알림입니다.',
  }) async {
    await _showNotification(title, body);
  }

  /// 내부용 알림 표시
  Future<void> _showNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'default_channel',
      'Default Channel',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    
    await _notificationsPlugin.show(
      DateTime.now().millisecond,
      title,
      body,
      details,
    );
  }
}
