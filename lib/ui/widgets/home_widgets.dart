import 'package:home_widget/home_widget.dart';

class HomeWidgetManager {
  static const String appGroupId = 'group.backuppro.widget';
  
  // 3 widget sizes requested in Task 5
  static const String iOSWidgetNameSmall = 'BackupProWidgetSmall';
  static const String iOSWidgetNameMedium = 'BackupProWidgetMedium';
  static const String iOSWidgetNameLarge = 'BackupProWidgetLarge';

  static const String androidWidgetNameSmall = 'BackupProWidgetProviderSmall';
  static const String androidWidgetNameMedium = 'BackupProWidgetProviderMedium';
  static const String androidWidgetNameLarge = 'BackupProWidgetProviderLarge';

  static Future<void> initialize() async {
    await HomeWidget.setAppGroupId(appGroupId);
  }

  static Future<void> updateWidgetInfo(double progress, String status) async {
    await HomeWidget.saveWidgetData<double>('progress', progress);
    await HomeWidget.saveWidgetData<String>('status', status);
    
    // Update all 3 sizes
    await HomeWidget.updateWidget(
      name: androidWidgetNameSmall,
      iOSName: iOSWidgetNameSmall,
    );
    await HomeWidget.updateWidget(
      name: androidWidgetNameMedium,
      iOSName: iOSWidgetNameMedium,
    );
    await HomeWidget.updateWidget(
      name: androidWidgetNameLarge,
      iOSName: iOSWidgetNameLarge,
    );
  }
}
