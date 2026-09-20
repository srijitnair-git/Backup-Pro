import 'package:flutter_test/flutter_test.dart';
import 'package:backuppro/core/network/retry.dart';
import 'package:backuppro/ui/premium_theme.dart';
import 'package:backuppro/ui/widgets/home_widgets.dart';
import 'package:flutter/material.dart';

void main() {
  test('withRetry returns the result once the action succeeds', () async {
    int attempts = 0;
    final result = await withRetry(() async {
      attempts++;
      if (attempts < 3) throw Exception('transient');
      return 'ok';
    }, initialDelay: Duration.zero);

    expect(result, 'ok');
    expect(attempts, 3);
  });

  test('withRetry rethrows after exhausting attempts', () async {
    int attempts = 0;
    await expectLater(
      () => withRetry(() async {
        attempts++;
        throw Exception('always fails');
      }, maxAttempts: 2, initialDelay: Duration.zero),
      throwsException,
    );
    expect(attempts, 2);
  });

  test('PremiumTheme has dark brightness and correct primary color', () {
    final theme = PremiumTheme.darkTheme;
    expect(theme.brightness, Brightness.dark);
    expect(theme.primaryColor, const Color(0xFF1E3A8A));
  });

  test('HomeWidgetManager has correct names for 3 sizes', () {
    expect(HomeWidgetManager.iOSWidgetNameSmall, 'BackupProWidgetSmall');
    expect(HomeWidgetManager.androidWidgetNameSmall, 'SmallWidgetProvider');

    expect(HomeWidgetManager.iOSWidgetNameMedium, 'BackupProWidgetMedium');
    expect(HomeWidgetManager.androidWidgetNameMedium, 'MediumWidgetProvider');

    expect(HomeWidgetManager.iOSWidgetNameLarge, 'BackupProWidgetLarge');
    expect(HomeWidgetManager.androidWidgetNameLarge, 'LargeWidgetProvider');
  });
}
