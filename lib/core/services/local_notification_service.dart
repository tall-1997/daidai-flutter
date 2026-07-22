import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalNotificationService {
  static final LocalNotificationService _instance =
      LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _prefsKeyTaskEnabled = 'local_notify_task_enabled';
  static const _prefsKeySystemEnabled = 'local_notify_system_enabled';

  /// 后台通知回调 - 当应用在后台运行且收到通知时由系统调用
  @pragma('vm:entry-point')
  static void _onDidReceiveBackgroundNotificationResponse(
      NotificationResponse response) {
    // 后台通知点击处理 - 当前无需特殊动作
  }

  Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
      onDidReceiveBackgroundNotificationResponse:
          _onDidReceiveBackgroundNotificationResponse,
    );
  }

  void _onNotificationTap(NotificationResponse response) {
    // 可在后续扩展中处理通知点击跳转
  }

  Future<bool> requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    return true;
  }

  Future<bool> areNotificationsEnabled() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.areNotificationsEnabled() ?? true;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final permissions = await ios.checkPermissions();
      return permissions?.isEnabled ?? false;
    }
    return true;
  }

  Future<void> showTaskNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'task_channel',
      '任务通知',
      channelDescription: '任务执行结果通知',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    await _plugin.show(id, title, body, details, payload: payload);
  }

  Future<void> showSystemNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'system_channel',
      '系统通知',
      channelDescription: '面板系统与安全通知',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      showWhen: true,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    await _plugin.show(id, title, body, details, payload: payload);
  }

  Future<void> showTestNotification(NotificationChannel channel) async {
    final details = _channelDetails(channel);
    await _plugin.show(
      0,
      '测试通知',
      '这是一条来自呆呆面板的本地测试通知',
      details,
    );
  }

  NotificationDetails _channelDetails(NotificationChannel channel) {
    switch (channel) {
      case NotificationChannel.task:
        return const NotificationDetails(
          android: AndroidNotificationDetails(
            'task_channel',
            '任务通知',
            channelDescription: '任务执行结果通知',
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        );
      case NotificationChannel.system:
        return const NotificationDetails(
          android: AndroidNotificationDetails(
            'system_channel',
            '系统通知',
            channelDescription: '面板系统与安全通知',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            showWhen: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        );
    }
  }

  Future<bool> getChannelEnabled(NotificationChannel channel) async {
    final prefs = await SharedPreferences.getInstance();
    final key = channel == NotificationChannel.task
        ? _prefsKeyTaskEnabled
        : _prefsKeySystemEnabled;
    return prefs.getBool(key) ?? true;
  }

  Future<void> setChannelEnabled(
      NotificationChannel channel, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    final key = channel == NotificationChannel.task
        ? _prefsKeyTaskEnabled
        : _prefsKeySystemEnabled;
    await prefs.setBool(key, enabled);
  }
}

enum NotificationChannel { task, system }
