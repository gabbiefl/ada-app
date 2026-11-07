// Monta o texto final do alerta: a mensagem escolhida + o link da localização.
//
// A mensagem guardada (Fase 6) é só um MODELO. O link de mapa muda a cada
// alerta, então é acrescentado aqui, na hora de enviar (Fase 9). Sem
// localização, o alerta sai mesmo assim, avisando que ela não veio: quem
// recebe fica sabendo e pode ligar para a pessoa (RNF03: nunca travar um pedido
// de ajuda esperando o GPS).
//
// Função pura: só recebe dados e devolve texto, sem guardar nem imprimir nada.
// Isso a deixa fácil de testar e protege a localização (Fase 0, P6).

import 'package:ada_app/features/map/models/geo_point.dart';
import 'package:ada_app/features/map/utils/map_link.dart';

String buildAlertText({required String message, GeoPoint? location}) {
  final base = message.trim();

  if (location == null) {
    return '$base\n\nNão consegui compartilhar a minha localização.';
  }
  return '$base\n\nMinha localização: ${mapLink(location)}';
}
