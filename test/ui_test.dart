import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

    expect(find.text('Live Transfer'), findsOneWidget);
    expect(find.text('Syncing: IMG_1234.jpg'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('ManualFolderSelection allows selecting a folder', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ManualFolderSelection(),
      ),
    );

    expect(find.text('Select Folders'), findsOneWidget);
    expect(find.text('Camera'), findsOneWidget);
    
    await tester.tap(find.text('Camera'));
    await tester.pump();
    
    // Test that the checkbox state changed.
    final CheckboxListTile tile = tester.widget(find.widgetWithText(CheckboxListTile, 'Camera'));
    expect(tile.value, true);
  });
}
