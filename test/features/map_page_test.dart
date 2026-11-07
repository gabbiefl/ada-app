// Testa a aba Mapa com um serviço de localização falso (sem GPS).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:ada_app/core/theme/app_theme.dart';
import 'package:ada_app/features/map/data/location_service.dart';
import 'package:ada_app/features/map/models/geo_point.dart';
import 'package:ada_app/features/map/pages/map_page.dart';
import 'package:ada_app/features/map/state/location_controller.dart';
import 'package:ada_app/features/map/widgets/location_error_box.dart';

// Serviço que só responde quando o teste mandar (para ver o "buscando").
class _SlowService implements LocationService {
  final _completer = Completer<LocationResult>();

  void finish(LocationResult result) => _completer.complete(result);

  @override
  Future<LocationResult> current() => _completer.future;

  @override
  Future<void> openAppSettings() async {}

  @override
  Future<void> openLocationSettings() async {}
}

const _porto = GeoPoint(latitude: -30.0346, longitude: -51.2177);

// Monta a aba Mapa com o serviço dado. Tela alta: tudo cabe sem rolar.
Future<void> _pumpMap(WidgetTester tester, LocationService service) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final controller = LocationController(service: service);
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: controller,
      child: MaterialApp(theme: AppTheme.light, home: const MapPage()),
    ),
  );
}

void main() {
  testWidgets(
    'Antes de tocar: explica o uso da localização e não mostra nada',
    (tester) async {
      await _pumpMap(
        tester,
        FakeLocationService(const LocationResult.success(_porto)),
      );

      expect(find.text('Mapa'), findsOneWidget);
      expect(
        find.textContaining('Ela não é guardada no aparelho.'),
        findsOneWidget,
      );
      expect(find.text('Ver minha localização'), findsOneWidget);
      expect(find.text('Sua localização atual'), findsNothing);
    },
  );

  testWidgets('Tocar no botão mostra a localização e o link', (tester) async {
    final service = FakeLocationService(const LocationResult.success(_porto));
    await _pumpMap(tester, service);

    await tester.tap(find.text('Ver minha localização'));
    await tester.pump();

    expect(service.requests, 1);
    expect(find.text('Sua localização atual'), findsOneWidget);
    expect(find.textContaining('Latitude -30.03460'), findsOneWidget);
    expect(find.textContaining('Longitude -51.21770'), findsOneWidget);
    expect(
      find.text('https://maps.google.com/?q=-30.034600,-51.217700'),
      findsOneWidget,
    );
    // Depois de achar, o botão passa a atualizar.
    expect(find.text('Atualizar localização'), findsOneWidget);
  });

  testWidgets('Durante a busca: indicador de progresso e botão desligado', (
    tester,
  ) async {
    final service = _SlowService();
    await _pumpMap(tester, service);

    await tester.tap(find.text('Ver minha localização'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);

    service.finish(const LocationResult.success(_porto));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Sua localização atual'), findsOneWidget);
  });

  for (final failure in LocationFailure.values) {
    testWidgets('Falha ($failure): mostra a explicação e "Tentar de novo"', (
      tester,
    ) async {
      await _pumpMap(
        tester,
        FakeLocationService(LocationResult.failure(failure)),
      );

      await tester.tap(find.text('Ver minha localização'));
      await tester.pump();

      expect(find.text(locationFailureMessage(failure)), findsOneWidget);
      expect(find.text('Tentar de novo'), findsOneWidget);
      expect(find.text('Sua localização atual'), findsNothing);
    });
  }

  testWidgets('Bloqueada para sempre: oferece abrir as configurações do app', (
    tester,
  ) async {
    final service = FakeLocationService(
      const LocationResult.failure(LocationFailure.permissionDeniedForever),
    );
    await _pumpMap(tester, service);

    await tester.tap(find.text('Ver minha localização'));
    await tester.pump();
    await tester.tap(find.text('Abrir configurações do app'));
    await tester.pump();

    expect(service.appSettingsOpened, 1);
  });

  testWidgets('GPS desligado: oferece ligar a localização', (tester) async {
    final service = FakeLocationService(
      const LocationResult.failure(LocationFailure.serviceDisabled),
    );
    await _pumpMap(tester, service);

    await tester.tap(find.text('Ver minha localização'));
    await tester.pump();
    await tester.tap(find.text('Ligar a localização'));
    await tester.pump();

    expect(service.locationSettingsOpened, 1);
  });

  testWidgets('Os atalhos só aparecem nos casos que precisam deles', (
    tester,
  ) async {
    await _pumpMap(
      tester,
      FakeLocationService(
        const LocationResult.failure(LocationFailure.permissionDenied),
      ),
    );

    await tester.tap(find.text('Ver minha localização'));
    await tester.pump();

    expect(find.text('Abrir configurações do app'), findsNothing);
    expect(find.text('Ligar a localização'), findsNothing);
  });

  testWidgets('Tentar de novo depois de uma falha pode dar certo', (
    tester,
  ) async {
    final service = FakeLocationService(
      const LocationResult.failure(LocationFailure.timeout),
    );
    await _pumpMap(tester, service);

    await tester.tap(find.text('Ver minha localização'));
    await tester.pump();
    expect(find.text('Sua localização atual'), findsNothing);

    service.result = const LocationResult.success(_porto);
    await tester.tap(find.text('Tentar de novo'));
    await tester.pump();

    expect(find.text('Sua localização atual'), findsOneWidget);
    expect(
      find.text(locationFailureMessage(LocationFailure.timeout)),
      findsNothing,
    );
  });
}
