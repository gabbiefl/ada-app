// Testa o modelo de ponto, o link de mapa e o serviço falso de localização.

import 'package:flutter_test/flutter_test.dart';

import 'package:ada_app/features/map/data/location_service.dart';
import 'package:ada_app/features/map/models/geo_point.dart';
import 'package:ada_app/features/map/utils/map_link.dart';

void main() {
  const porto = GeoPoint(latitude: -30.0346, longitude: -51.2177);

  group('GeoPoint', () {
    test('pontos iguais são iguais', () {
      expect(porto, const GeoPoint(latitude: -30.0346, longitude: -51.2177));
      expect(
        porto.hashCode,
        const GeoPoint(latitude: -30.0346, longitude: -51.2177).hashCode,
      );
    });

    test('toString não revela as coordenadas', () {
      expect(porto.toString(), isNot(contains('30')));
      expect(porto.toString(), isNot(contains('51')));
    });
  });

  group('mapLink', () {
    test('monta o link com latitude e longitude', () {
      expect(
        mapLink(porto),
        'https://maps.google.com/?q=-30.034600,-51.217700',
      );
    });

    test('sempre usa ponto (e não vírgula) nas casas decimais', () {
      expect(mapLink(porto), isNot(contains(',-51.2177,')));
      expect(mapLink(porto).split('?q=').last.split(',').length, 2);
    });

    test('arredonda para seis casas', () {
      const ponto = GeoPoint(latitude: 1.23456789, longitude: -2.98765432);
      expect(mapLink(ponto), 'https://maps.google.com/?q=1.234568,-2.987654');
    });
  });

  group('LocationResult e FakeLocationService', () {
    test('sucesso carrega o ponto e nenhuma falha', () {
      const result = LocationResult.success(porto);

      expect(result.isSuccess, isTrue);
      expect(result.point, porto);
      expect(result.failure, isNull);
    });

    test('falha carrega o motivo e nenhum ponto', () {
      const result = LocationResult.failure(LocationFailure.timeout);

      expect(result.isSuccess, isFalse);
      expect(result.point, isNull);
      expect(result.failure, LocationFailure.timeout);
    });

    test(
      'o serviço falso devolve o resultado combinado e conta pedidos',
      () async {
        final service = FakeLocationService(
          const LocationResult.success(porto),
        );

        expect((await service.current()).point, porto);

        service.result = const LocationResult.failure(
          LocationFailure.permissionDenied,
        );
        expect(
          (await service.current()).failure,
          LocationFailure.permissionDenied,
        );
        expect(service.requests, 2);
      },
    );
  });
}
