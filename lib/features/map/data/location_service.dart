// De onde vem a localização atual.
//
// LocationService é um "contrato" (classe abstrata): diz O QUE se pode fazer
// (obter a posição atual), sem dizer COMO. O app usa a versão que fala com o
// GPS; os testes usam a FakeLocationService, que devolve o que o teste mandar.
// Mesma ideia dos repositórios (Fase 5) e do Haptics (Fase 7).
//
// Em vez de lançar erros, o serviço devolve um LocationResult: ou deu certo
// (com o ponto) ou falhou (com o motivo). A tela escolhe o texto de cada caso,
// e o app nunca fecha por falta de permissão ou de GPS (RNF04).

import 'package:ada_app/features/map/models/geo_point.dart';

// Motivos pelos quais a localização pode não vir.
enum LocationFailure {
  serviceDisabled, // o GPS (localização do aparelho) está desligado
  permissionDenied, // a usuária negou, mas dá para pedir de novo
  permissionDeniedForever, // negou "para sempre": só pelas configurações
  timeout, // o GPS demorou demais
  unknown, // qualquer outro problema
}

// O resultado: ou há um [point], ou há uma [failure]. Nunca os dois.
class LocationResult {
  const LocationResult.success(GeoPoint this.point) : failure = null;
  const LocationResult.failure(LocationFailure this.failure) : point = null;

  final GeoPoint? point;
  final LocationFailure? failure;

  bool get isSuccess => point != null;
}

abstract class LocationService {
  Future<LocationResult> current();

  // Atalhos para quando só a própria usuária resolve: liberar a permissão
  // (negada "para sempre") ou ligar o GPS do aparelho.
  Future<void> openAppSettings();
  Future<void> openLocationSettings();
}

// Versão para testes: devolve sempre o resultado combinado e conta os pedidos.
class FakeLocationService implements LocationService {
  FakeLocationService(this.result);

  LocationResult result;
  int requests = 0;
  int appSettingsOpened = 0;
  int locationSettingsOpened = 0;

  @override
  Future<LocationResult> current() async {
    requests++;
    return result;
  }

  @override
  Future<void> openAppSettings() async => appSettingsOpened++;

  @override
  Future<void> openLocationSettings() async => locationSettingsOpened++;
}
