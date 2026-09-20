import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:backuppro/ui/dashboard/live_transfer_dashboard.dart';
import 'package:backuppro/ui/dashboard/manual_folder_selection.dart';

void main() {
  testWidgets('LiveTransferDashboard displays correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LiveTransferDashboard(
            progress: 0.5,
            currentFile: 'IMG_1234.jpg',
          ),
        ),
      ),
    );

    expect(find.text('Live Transfer Dashboard'), findsOneWidget);
    expect(find.text('Syncing: IMG_1234.jpg'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('ManualFolderSelection shows empty state with no folders configured', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const MaterialApp(
        home: ManualFolderSelection(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Select Backup Folders'), findsOneWidget);
    expect(find.text('No folders selected for backup yet.'), findsOneWidget);
    expect(find.text('Add New Folder Pair'), findsOneWidget);
  });
}
