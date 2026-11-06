// Link de mapa para colocar na mensagem de alerta.
//
// O endereço abre direto no app de mapas de qualquer celular (e no navegador).
// Seis casas decimais dão precisão de cerca de 10 cm, mais do que suficiente.
// toStringAsFixed sempre usa ponto como separador, mesmo com o celular em
// português, que é o que o link exige.

import 'package:ada_app/features/map/models/geo_point.dart';

String mapLink(GeoPoint point) {
  final lat = point.latitude.toStringAsFixed(6);
  final lng = point.longitude.toStringAsFixed(6);
  return 'https://maps.google.com/?q=$lat,$lng';
}
