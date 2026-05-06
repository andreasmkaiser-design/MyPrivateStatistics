import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:private_statistics/features/statistics/domain/models/time_window.dart';
import 'package:private_statistics/features/statistics/presentation/widgets/time_window_selector.dart';

void main() {
  const options = [HoursTimeWindow(24), HoursTimeWindow(48), DaysTimeWindow(7)];

  group('TimeWindowSelector', () {
    testWidgets('renders all configured option labels', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimeWindowSelector(
              selected: options[0],
              options: options,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('24 h'), findsOneWidget);
      expect(find.text('48 h'), findsOneWidget);
      expect(find.text('7 days'), findsOneWidget);
    });

    testWidgets('calls onChanged with tapped option', (tester) async {
      TimeWindow? selected;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimeWindowSelector(
              selected: options[0],
              options: options,
              onChanged: (TimeWindow w) => selected = w,
            ),
          ),
        ),
      );

      await tester.tap(find.text('48 h'));
      await tester.pump();

      expect(selected, isA<HoursTimeWindow>());
      expect((selected! as HoursTimeWindow).hours, 48);
    });
  });
}
