import 'package:home_widget/home_widget.dart';

class HomeWidgetManager {
  static const String appGroupId = 'group.backuppro.widget';
  static const String iOSWidgetName = 'BackupProWidget';
  static const String androidWidgetName = 'BackupProWidgetProvider';

  static Future<void> initialize() async {
    await HomeWidget.setAppGroupId(appGroupId);
  }

  static Future<void> updateWidgetInfo(double progress, String status) async {
    await HomeWidget.saveWidgetData<double>('progress', progress);
    await HomeWidget.saveWidgetData<String>('status', status);
    await HomeWidget.updateWidget(
      name: androidWidgetName,
      iOSName: iOSWidgetName,
    );
  }
}
