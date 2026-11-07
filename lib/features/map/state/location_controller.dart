// Guarda o estado da busca de localização para as telas.
//
// Mesmo padrão dos outros controladores: um ChangeNotifier que as telas
// assinam. A busca em si é do LocationService (recebido de fora, como o
// repositório e o Haptics); este controlador só guarda em que etapa estamos:
//
//   parado -> buscando -> sucesso (com o ponto)
//                      -> falha   (com o motivo)
//
// A localização é dado pessoal de alto risco (Fase 0, P6): fica só na memória,
// nunca é gravada nem impressa, e [clear] a esquece.

import 'package:flutter/foundation.dart';

import 'package:ada_app/features/map/data/location_service.dart';
import 'package:ada_app/features/map/models/geo_point.dart';

enum LocationStatus { idle, loading, success, failure }

class LocationController extends ChangeNotifier {
  LocationController({required this.service});

  final LocationService service;

  LocationStatus _status = LocationStatus.idle;
  GeoPoint? _point;
  LocationFailure? _failure;
  bool _disposed = false;

  LocationStatus get status => _status;
  // Só existe quando o status é success.
  GeoPoint? get point => _point;
  // Só existe quando o status é failure.
  LocationFailure? get failure => _failure;

  // Busca a localização atual. Se já há uma busca em andamento, ignora o toque
  // repetido (senão o Android receberia vários pedidos ao mesmo tempo).
  Future<void> refresh() async {
    if (_status == LocationStatus.loading) return;

    _status = LocationStatus.loading;
    _failure = null;
    notifyListeners();

    final result = await service.current();
    // A tela pode ter sido fechada enquanto o GPS buscava.
    if (_disposed) return;

    if (result.isSuccess) {
      _status = LocationStatus.success;
      _point = result.point;
      _failure = null;
    } else {
      // Em falha, esquecemos a posição antiga: mostrar um lugar de antes como
      // se fosse o atual seria enganoso.
      _status = LocationStatus.failure;
      _point = null;
      _failure = result.failure;
    }
    notifyListeners();
  }

  // Esquece a posição e volta ao início.
  void clear() {
    if (_status == LocationStatus.idle) return;
    _status = LocationStatus.idle;
    _point = null;
    _failure = null;
    notifyListeners();
  }

  // Atalhos para a tela oferecer quando só a usuária resolve o problema.
  Future<void> openAppSettings() => service.openAppSettings();
  Future<void> openLocationSettings() => service.openLocationSettings();

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
