import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:iq_core/core/constants/app_strings.dart';

/// Manages a persistent foreground notification for the driver app.
///
/// Keeps the app alive while the driver is online or on an active trip,
/// preventing the OS from killing the process in the background.
class DriverForegroundService {
  DriverForegroundService._();

  static bool _initialized = false;

  /// Initialize the foreground task configuration. Call once at app startup.
  static void init() {
    if (_initialized) return;
    _initialized = true;

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'iq_driver_foreground',
        channelName: AppStrings.appNameDriver,
        channelDescription: AppStrings.foregroundChannelDesc,
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  /// Start the foreground service (call when driver goes online).
  static Future<void> start() async {
    init();
    if (await FlutterForegroundTask.isRunningService) return;
    await FlutterForegroundTask.startService(
      notificationTitle: AppStrings.appNameDriver,
      notificationText: AppStrings.driverOnlineReady,
      callback: _taskCallback,
    );
  }

  /// Update the notification text (e.g. during an active trip).
  static Future<void> updateText(String text) async {
    if (!await FlutterForegroundTask.isRunningService) return;
    await FlutterForegroundTask.updateService(
      notificationText: text,
    );
  }

  /// Stop the foreground service (call when driver goes offline).
  static Future<void> stop() async {
    if (!await FlutterForegroundTask.isRunningService) return;
    await FlutterForegroundTask.stopService();
  }
}

/// Top-level callback required by flutter_foreground_task.
/// We don't need periodic work since the Dart isolate stays alive.
@pragma('vm:entry-point')
void _taskCallback() {
  FlutterForegroundTask.setTaskHandler(_EmptyTaskHandler());
}

class _EmptyTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp) async {}
}
