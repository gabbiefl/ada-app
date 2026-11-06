// A versão REAL do LocationService: fala com o GPS pelo pacote geolocator.
//
// Etapas, na ordem:
//   1. a localização do aparelho está ligada?
//   2. o app tem permissão? Se nunca perguntamos, pergunta agora (é aqui que o
//      diálogo do Android aparece; a tela já explicou o motivo antes).
//   3. busca a posição, com tempo limite, para o alerta nunca ficar esperando.
// Cada problema vira um LocationFailure; nenhuma exceção chega à tela.
//
// A posição NUNCA é impressa nem guardada (Fase 0, P6).

import 'dart:async';

import 'package:geolocator/geolocator.dart';

import 'package:ada_app/features/map/data/location_service.dart';
import 'package:ada_app/features/map/models/geo_point.dart';

class GeolocatorLocationService implements LocationService {
  // `platform` existe para os testes trocarem o GPS por um falso. No app fica
  // o padrão: o GeolocatorPlatform.instance, que é o GPS de verdade.
  GeolocatorLocationService({
    GeolocatorPlatform? platform,
    this.timeLimit = const Duration(seconds: 10),
  }) : _platform = platform ?? GeolocatorPlatform.instance;

  final GeolocatorPlatform _platform;
  final Duration timeLimit;

  @override
  Future<LocationResult> current() async {
    try {
      if (!await _platform.isLocationServiceEnabled()) {
        return const LocationResult.failure(LocationFailure.serviceDisabled);
      }

      var permission = await _platform.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await _platform.requestPermission();
      }
      switch (permission) {
        case LocationPermission.denied:
          return const LocationResult.failure(LocationFailure.permissionDenied);
        case LocationPermission.deniedForever:
          return const LocationResult.failure(
            LocationFailure.permissionDeniedForever,
          );
        case LocationPermission.unableToDetermine:
          return const LocationResult.failure(LocationFailure.unknown);
        case LocationPermission.whileInUse:
        case LocationPermission.always:
          break; // pode seguir
      }

      final position = await _platform.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: timeLimit,
        ),
      );
      return LocationResult.success(
        GeoPoint(latitude: position.latitude, longitude: position.longitude),
      );
    } on TimeoutException {
      return const LocationResult.failure(LocationFailure.timeout);
    } on LocationServiceDisabledException {
      return const LocationResult.failure(LocationFailure.serviceDisabled);
    } on PermissionDeniedException {
      return const LocationResult.failure(LocationFailure.permissionDenied);
    } catch (_) {
      // Qualquer outro problema: sem detalhes, para não vazar dado pessoal.
      return const LocationResult.failure(LocationFailure.unknown);
    }
  }

  @override
  Future<void> openAppSettings() async {
    await _platform.openAppSettings();
  }

  @override
  Future<void> openLocationSettings() async {
    await _platform.openLocationSettings();
  }
}
