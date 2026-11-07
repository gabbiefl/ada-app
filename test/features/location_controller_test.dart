// Testa o estado da busca de localização, sem GPS e sem tela.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:ada_app/features/map/data/location_service.dart';
import 'package:ada_app/features/map/models/geo_point.dart';
import 'package:ada_app/features/map/state/location_controller.dart';

// Serviço que só responde quando o teste mandar: serve para observar o estado
// "buscando" no meio do caminho.
class _SlowService implements LocationService {
  final _completer = Completer<LocationResult>();
  int requests = 0;

  void finish(LocationResult result) => _completer.complete(result);

  @override
  Future<LocationResult> current() {
    requests++;
    return _completer.future;
  }

  @override
  Future<void> openAppSettings() async {}

  @override
  Future<void> openLocationSettings() async {}
}

void main() {
  const porto = GeoPoint(latitude: -30.0346, longitude: -51.2177);

  test('começa parado, sem ponto nem falha', () {
    final controller = LocationController(
      service: FakeLocationService(const LocationResult.success(porto)),
    );

    expect(controller.status, LocationStatus.idle);
    expect(controller.point, isNull);
    expect(controller.failure, isNull);
  });

  test('refresh com sucesso guarda o ponto', () async {
    final controller = LocationController(
      service: FakeLocationService(const LocationResult.success(porto)),
    );

    await controller.refresh();

    expect(controller.status, LocationStatus.success);
    expect(controller.point, porto);
    expect(controller.failure, isNull);
  });

  test('refresh com falha guarda o motivo e nenhum ponto', () async {
    final controller = LocationController(
      service: FakeLocationService(
        const LocationResult.failure(LocationFailure.serviceDisabled),
      ),
    );

    await controller.refresh();

    expect(controller.status, LocationStatus.failure);
    expect(controller.failure, LocationFailure.serviceDisabled);
    expect(controller.point, isNull);
  });

  test('passa por "buscando" antes do resultado', () async {
    final service = _SlowService();
    final controller = LocationController(service: service);

    final future = controller.refresh();
    expect(controller.status, LocationStatus.loading);

    service.finish(const LocationResult.success(porto));
    await future;
    expect(controller.status, LocationStatus.success);
  });

  test('toque repetido durante a busca não faz outro pedido', () async {
    final service = _SlowService();
    final controller = LocationController(service: service);

    final first = controller.refresh();
    await controller.refresh(); // ignorado: já está buscando
    service.finish(const LocationResult.success(porto));
    await first;

    expect(service.requests, 1);
  });

  test('avisa quem ouve ao começar e ao terminar a busca', () async {
    final controller = LocationController(
      service: FakeLocationService(const LocationResult.success(porto)),
    );
    var avisos = 0;
    controller.addListener(() => avisos++);

    await controller.refresh();

    expect(avisos, 2); // buscando + resultado
  });

  test('uma falha depois de um sucesso esquece o ponto antigo', () async {
    final service = FakeLocationService(const LocationResult.success(porto));
    final controller = LocationController(service: service);
    await controller.refresh();

    service.result = const LocationResult.failure(LocationFailure.timeout);
    await controller.refresh();

    expect(controller.point, isNull);
    expect(controller.failure, LocationFailure.timeout);
  });

  test('tentar de novo depois de uma falha pode dar certo', () async {
    final service = FakeLocationService(
      const LocationResult.failure(LocationFailure.permissionDenied),
    );
    final controller = LocationController(service: service);
    await controller.refresh();

    service.result = const LocationResult.success(porto);
    await controller.refresh();

    expect(controller.status, LocationStatus.success);
    expect(controller.failure, isNull);
    expect(controller.point, porto);
  });

  test('clear esquece a posição e só avisa se havia algo', () async {
    final controller = LocationController(
      service: FakeLocationService(const LocationResult.success(porto)),
    );
    var avisos = 0;
    controller.addListener(() => avisos++);

    controller.clear(); // parado: não avisa
    await controller.refresh();
    avisos = 0;

    controller.clear();

    expect(controller.status, LocationStatus.idle);
    expect(controller.point, isNull);
    expect(avisos, 1);
  });

  test('abrir as configurações é repassado ao serviço', () async {
    final service = FakeLocationService(const LocationResult.success(porto));
    final controller = LocationController(service: service);

    await controller.openAppSettings();
    await controller.openLocationSettings();

    expect(service.appSettingsOpened, 1);
    expect(service.locationSettingsOpened, 1);
  });

  test('se a tela for fechada durante a busca, nada quebra', () async {
    final service = _SlowService();
    final controller = LocationController(service: service);

    final future = controller.refresh();
    controller.dispose();
    service.finish(const LocationResult.success(porto));

    await future; // não pode lançar erro por notificar um controlador morto
  });
}
