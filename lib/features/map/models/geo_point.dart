// Um ponto na Terra: latitude e longitude.
//
// É um modelo nosso, e não o `Position` do pacote geolocator: assim o resto do
// app não depende do pacote, e os testes criam pontos sem GPS.
//
// A localização é dado pessoal de alto risco (Fase 0, P6): toString NÃO mostra
// as coordenadas, para elas não irem parar em logs sem querer.

class GeoPoint {
  const GeoPoint({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  @override
  bool operator ==(Object other) =>
      other is GeoPoint &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() => 'GeoPoint(…)';
}
