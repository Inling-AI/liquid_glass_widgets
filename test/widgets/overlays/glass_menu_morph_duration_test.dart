import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

void main() {
  test('opening duration scale preserves the scaled-time spring trajectory',
      () {
    final defaultOpen = GlassMenuMorph.openSimulation(0, 0);
    final normalOpen = GlassMenuMorph.openSimulation(0, 0, durationScale: 1);
    final slowerOpen = GlassMenuMorph.openSimulation(0, 0, durationScale: 1.3);

    expect(normalOpen.x(0.2), closeTo(defaultOpen.x(0.2), 1e-9));
    for (final time in [0.05, 0.1, 0.2, 0.4, 0.7]) {
      expect(slowerOpen.x(1.3 * time), closeTo(normalOpen.x(time), 1e-8));
    }
  });

  test('opening reversal keeps the supplied live velocity', () {
    final simulation =
        GlassMenuMorph.openSimulation(0.4, 1.5, durationScale: 1.3);

    expect(simulation.dx(0), closeTo(1.5, 1e-9));
  });

  testWidgets('open duration scale slows opening and leaves closing unchanged',
      (tester) async {
    addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
    Future<double> openAt(double durationScale) async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      final controller = GlassMenuController();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: GlassMenu(
              controller: controller,
              openDurationScale: durationScale,
              triggerBuilder: (context, toggle) => GlassButton.custom(
                onTap: toggle,
                useOwnLayer: true,
                child: const SizedBox(
                  width: 80,
                  height: 40,
                  child: Center(child: Text('Open')),
                ),
              ),
              items: List.generate(
                4,
                (index) => GlassMenuItem(
                  title: 'Action $index',
                  onTap: () {},
                ),
              ),
            ),
          ),
        ),
      ));
      controller.open();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      final openingHeight =
          tester.getSize(find.byType(GlassMenuMorphContent)).height;
      await tester.pumpAndSettle();
      expect(find.text('Action 0'), findsOneWidget);
      return openingHeight;
    }

    final normalOpeningHeight = await openAt(1.0);
    final slowerOpeningHeight = await openAt(1.3);
    expect(slowerOpeningHeight, lessThan(normalOpeningHeight));

    Future<double> closeAt(double durationScale) async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      final controller = GlassMenuController();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: GlassMenu(
              controller: controller,
              openDurationScale: durationScale,
              triggerBuilder: (context, toggle) => GlassButton.custom(
                onTap: toggle,
                useOwnLayer: true,
                child: const SizedBox(
                  width: 80,
                  height: 40,
                  child: Center(child: Text('Open')),
                ),
              ),
              items: List.generate(
                4,
                (index) => GlassMenuItem(
                  title: 'Action $index',
                  onTap: () {},
                ),
              ),
            ),
          ),
        ),
      ));
      controller.open();
      await tester.pumpAndSettle();
      controller.close();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      return tester.getSize(find.byType(GlassMenuMorphContent)).height;
    }

    final normalClosingHeight = await closeAt(1.0);
    final slowerClosingHeight = await closeAt(1.3);
    expect(slowerClosingHeight, closeTo(normalClosingHeight, 0.5));
  });

  testWidgets('reduce motion ignores opening duration scale', (tester) async {
    addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
    Future<double> openReducedMotionAt(double durationScale) async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      final controller = GlassMenuController();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: GlassAccessibilityScope(
            reduceMotion: true,
            child: Center(
              child: GlassMenu(
                controller: controller,
                openDurationScale: durationScale,
                triggerBuilder: (context, toggle) => GlassButton.custom(
                  onTap: toggle,
                  useOwnLayer: true,
                  child: const SizedBox(
                    width: 80,
                    height: 40,
                    child: Center(child: Text('Open')),
                  ),
                ),
                items: List.generate(
                  4,
                  (index) => GlassMenuItem(
                    title: 'Action $index',
                    onTap: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      ));
      controller.open();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      final height = tester.getSize(find.byType(GlassMenuMorphContent)).height;
      await tester.pumpAndSettle();
      expect(find.text('Action 0'), findsOneWidget);
      return height;
    }

    final normalHeight = await openReducedMotionAt(1.0);
    final scaledHeight = await openReducedMotionAt(1.3);
    expect(scaledHeight, closeTo(normalHeight, 0.01));
  });
}
