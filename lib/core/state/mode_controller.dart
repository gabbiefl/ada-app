// Guarda o modo atual do app em um único lugar.
//
// ChangeNotifier: quando o modo muda, avisa (notifyListeners) quem está
// "ouvindo". Assim a Home pode se redesenhar sozinha, sem a lógica ficar
// misturada com a tela.
//
// As regras de transição (de qual modo se pode ir para qual) ficam no próprio
// SecurityMode.canGoTo; este controlador só as aplica.

import 'package:flutter/foundation.dart';

import 'package:ada_app/core/state/security_mode.dart';

// Motivo pelo qual uma mudança de modo pode ser recusada.
enum ModeError { deactivateFirst }

class ModeController extends ChangeNotifier {
  SecurityMode _mode = SecurityMode.normal;

  // Só leitura por fora: para mudar, é preciso passar por activate/deactivate.
  SecurityMode get mode => _mode;

  // Padrão de retorno dos outros controladores: null = deu certo (ou já estava
  // nesse modo); senão, o motivo da recusa.
  ModeError? activate(SecurityMode mode) {
    // Evita avisar à toa quando o modo não mudou.
    if (mode == _mode) return null;
    if (!_mode.canGoTo(mode)) return ModeError.deactivateFirst;

    _mode = mode;
    notifyListeners();
    return null;
  }

  // Sempre permitido: de qualquer modo se pode voltar ao Normal.
  void deactivate() => activate(SecurityMode.normal);
}
