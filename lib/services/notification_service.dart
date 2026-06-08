import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../utils/helpers.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

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
    await _plugin.initialize(settings);
  }

  Future<void> showBudgetLimitWarning({
    required double limit,
    required double spending,
    required String month,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'budget_alerts',
      'Budget Alerts',
      channelDescription: 'Notifications when budget limit is reached',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    final percentage = ((spending / limit) * 100).round();

    if (spending >= limit) {
      await _plugin.show(
        0,
        'Budget Limit Reached! 🚨',
        'You have reached your monthly limit of ${Helpers.formatCurrency(limit)} for $month.',
        details,
      );
    } else if (percentage >= 80) {
      await _plugin.show(
        0,
        'Budget Warning ⚠️',
        'You have used $percentage% of your monthly budget for $month. (${Helpers.formatCurrency(spending)} / ${Helpers.formatCurrency(limit)})',
        details,
      );
    }
  }

  Future<void> showTransactionAdded({
    required String title,
    required double amount,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'transactions',
      'Transactions',
      channelDescription: 'Transaction notifications',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.show(
      1,
      'Transaction Added',
      '$title: ${Helpers.formatCurrency(amount)}',
      details,
    );
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
