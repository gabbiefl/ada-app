// Testa a tela Configurações: o menu e a chave do modo de demonstração.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:ada_app/core/theme/app_theme.dart';
import 'package:ada_app/features/alerts/data/alert_actions.dart';
import 'package:ada_app/features/alerts/state/alert_controller.dart';
import 'package:ada_app/features/map/data/location_service.dart';
import 'package:ada_app/features/map/models/geo_point.dart';
import 'package:ada_app/features/settings/pages/settings_page.dart';

AlertController _alert() => AlertController(
  locationService: FakeLocationService(
    const LocationResult.success(GeoPoint(latitude: 0, longitude: 0)),
  ),
  actions: FakeAlertActions(),
);

Future<void> _pump(WidgetTester tester, AlertController controller) async {
  // Tela alta: o último item do menu cabe sem rolar.
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  addTearDown(controller.dispose);

  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: controller,
      child: MaterialApp(theme: AppTheme.light, home: const SettingsPage()),
    ),
  );
}

void main() {
  testWidgets('Configurações mostra os itens do menu', (tester) async {
    await _pump(tester, _alert());

    expect(find.text('Configurações'), findsOneWidget);
    expect(find.text('Horário de cobertura'), findsOneWidget);
    expect(find.text('Histórico de alertas'), findsOneWidget);
    expect(find.text('Mensagens personalizadas'), findsOneWidget);
    expect(find.text('Modo de demonstração'), findsOneWidget);
  });

  testWidgets('A chave do modo de demonstração liga e desliga', (tester) async {
    final controller = _alert();
    await _pump(tester, controller);

    // Começa desligado.
    expect(controller.demoMode, isFalse);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);

    await tester.tap(find.byType(Switch));
    await tester.pump();

    expect(controller.demoMode, isTrue);
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);

    await tester.tap(find.byType(Switch));
    await tester.pump();

    expect(controller.demoMode, isFalse);
  });
}
