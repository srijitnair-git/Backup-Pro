import 'package:flutter_test/flutter_test.dart';
import 'package:backuppro/core/background_service.dart';
import 'package:backuppro/ui/premium_theme.dart';
import 'package:backuppro/ui/widgets/home_widgets.dart';
import 'package:flutter/material.dart';

void main() {
  test('PremiumTheme has dark brightness and correct primary color', () {
    final theme = PremiumTheme.darkTheme;
    expect(theme.brightness, Brightness.dark);
    expect(theme.primaryColor, const Color(0xFF1E3A8A));
  });

  test('HomeWidgetManager has correct names for 3 sizes', () {
    expect(HomeWidgetManager.iOSWidgetNameSmall, 'BackupProWidgetSmall');
    expect(HomeWidgetManager.androidWidgetNameSmall, 'BackupProWidgetProviderSmall');
    
    expect(HomeWidgetManager.iOSWidgetNameMedium, 'BackupProWidgetMedium');
    expect(HomeWidgetManager.androidWidgetNameMedium, 'BackupProWidgetProviderMedium');
    
    expect(HomeWidgetManager.iOSWidgetNameLarge, 'BackupProWidgetLarge');
    expect(HomeWidgetManager.androidWidgetNameLarge, 'BackupProWidgetProviderLarge');
  });
}
