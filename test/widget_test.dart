import 'package:flutter_test/flutter_test.dart';
import 'package:mazikty/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mazikty/presentation/providers/service_providers.dart';
import 'package:mazikty/data/services/music_api_service.dart';

void main() {
  testWidgets('Mazikty app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Use 0 latency in widget test to avoid pending timers
          musicApiServiceProvider.overrideWithValue(
            const MockMusicApiService(latencyMs: 0),
          ),
        ],
        child: const MaziktyApp(),
      ),
    );

    // Initial pump
    await tester.pump();
    expect(find.byType(MaziktyApp), findsOneWidget);
  });
}
