// Feedback háptico: a vibração do celular.
//
// Haptics é um "contrato" (classe abstrata): diz O QUE se pode fazer (vibrar em
// alerta), sem dizer COMO. O ModeController recebe um Haptics de fora (injeção
// de dependência, a mesma ideia dos repositórios). No app é o SystemHaptics; nos
// testes, uma versão falsa que só anota que "vibrou".

import 'package:flutter/services.dart';

abstract class Haptics {
  // Vibração forte, usada ao ativar o Modo Perigo.
  Future<void> alert();
}

// Usa a vibração do sistema (HapticFeedback já vem no Flutter, sem pacote).
// No Chrome e em aparelhos sem vibração, simplesmente não faz nada.
class SystemHaptics implements Haptics {
  const SystemHaptics();

  @override
  Future<void> alert() async {
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {
      // Vibrar é um reforço: se falhar, o alerta segue normalmente.
    }
  }
}
