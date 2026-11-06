// Testa o serviço real de localização trocando o GPS por um falso: cada teste
// combina o que o "aparelho" responde e confere o que o serviço devolve.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

import 'package:ada_app/features/map/data/geolocator_location_service.dart';
import 'package:ada_app/features/map/data/location_service.dart';
import 'package:ada_app/features/map/models/geo_point.dart';

// GPS falso. `extends` (e não `implements`) é o que o pacote pede para
// plataformas; só sobrescrevemos o que o serviço usa.
class _FakePlatform extends GeolocatorPlatform {
  bool serviceEnabled = true;
  LocationPermission permission = LocationPermission.whileInUse;
  LocationPermission permissionAfterRequest = LocationPermission.whileInUse;
  Object? positionError; // se preenchido, getCurrentPosition lança isso
  int permissionRequests = 0;
  int positionRequests = 0;
  int appSettingsOpened = 0;
  int locationSettingsOpened = 0;
  Duration? lastTimeLimit;

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationPermission> checkPermission() async => permission;

  @override
  Future<LocationPermission> requestPermission() async {
    permissionRequests++;
    return permissionAfterRequest;
  }

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    positionRequests++;
    lastTimeLimit = locationSettings?.timeLimit;
    final error = positionError;
    if (error != null) throw error;
    return Position(
      latitude: -30.0346,
      longitude: -51.2177,
      timestamp: DateTime(2026, 11, 6),
      accuracy: 5,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }

  @override
  Future<bool> openAppSettings() async {
    appSettingsOpened++;
    return true;
  }

  @override
  Future<bool> openLocationSettings() async {
    locationSettingsOpened++;
    return true;
  }
}

void main() {
  late _FakePlatform platform;
  late GeolocatorLocationService service;

  setUp(() {
    platform = _FakePlatform();
    service = GeolocatorLocationService(platform: platform);
  });

  test('com GPS ligado e permissão, devolve o ponto', () async {
    final result = await service.current();

    expect(result.isSuccess, isTrue);
    expect(
      result.point,
      const GeoPoint(latitude: -30.0346, longitude: -51.2177),
    );
    expect(platform.permissionRequests, 0); // já tinha permissão: não pergunta
  });

  test('GPS desligado: falha sem nem pedir permissão ou posição', () async {
    platform.serviceEnabled = false;

    final result = await service.current();

    expect(result.failure, LocationFailure.serviceDisabled);
    expect(platform.permissionRequests, 0);
    expect(platform.positionRequests, 0);
  });

  test('permissão ainda não pedida: pergunta e, se aceita, devolve', () async {
    platform.permission = LocationPermission.denied;
    platform.permissionAfterRequest = LocationPermission.whileInUse;

    final result = await service.current();

    expect(platform.permissionRequests, 1);
    expect(result.isSuccess, isTrue);
  });

  test(
    'permissão negada ao perguntar: falha, mas dá para tentar de novo',
    () async {
      platform.permission = LocationPermission.denied;
      platform.permissionAfterRequest = LocationPermission.denied;

      final result = await service.current();

      expect(result.failure, LocationFailure.permissionDenied);
      expect(platform.positionRequests, 0);
    },
  );

  test('negada para sempre: falha sem perguntar de novo', () async {
    platform.permission = LocationPermission.deniedForever;

    final result = await service.current();

    expect(result.failure, LocationFailure.permissionDeniedForever);
    expect(platform.permissionRequests, 0);
  });

  test('negada para sempre ao perguntar também é reconhecida', () async {
    platform.permission = LocationPermission.denied;
    platform.permissionAfterRequest = LocationPermission.deniedForever;

    final result = await service.current();

    expect(result.failure, LocationFailure.permissionDeniedForever);
  });

  test('GPS demora demais: falha por tempo esgotado', () async {
    platform.positionError = TimeoutException('demorou');

    expect((await service.current()).failure, LocationFailure.timeout);
  });

  test('o tempo limite é repassado ao GPS', () async {
    service = GeolocatorLocationService(
      platform: platform,
      timeLimit: const Duration(seconds: 3),
    );

    await service.current();

    expect(platform.lastTimeLimit, const Duration(seconds: 3));
  });

  test('erros do pacote viram o motivo certo', () async {
    platform.positionError = const LocationServiceDisabledException();
    expect((await service.current()).failure, LocationFailure.serviceDisabled);

    platform.positionError = const PermissionDeniedException('negado');
    expect((await service.current()).failure, LocationFailure.permissionDenied);
  });

  test('erro inesperado vira falha desconhecida, sem fechar o app', () async {
    platform.positionError = StateError('algo estranho');

    expect((await service.current()).failure, LocationFailure.unknown);
  });

  test('abrir as configurações chama o aparelho', () async {
    await service.openAppSettings();
    await service.openLocationSettings();

    expect(platform.appSettingsOpened, 1);
    expect(platform.locationSettingsOpened, 1);
  });
}
