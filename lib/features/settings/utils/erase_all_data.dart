// "Apagar meus dados" (RF10): remove tudo o que o ADA guarda da usuária.
//
// A ORDEM importa:
//   1. desfaz o alerta e o modo, para nada ser enviado a contatos que vão sumir;
//   2. apaga o que está guardado, pelos controladores. Assim a memória e o
//      armazenamento ficam iguais, e as telas se atualizam na hora (se só o
//      armazenamento fosse apagado, a tela mostraria os dados antigos até o app
//      ser fechado).
//
// O que o ADA guarda: contatos, mensagens editadas, faixas de horário e o "já viu
// o onboarding" (no armazenamento seguro). A localização nunca é gravada: só fica na memória
// enquanto é usada, e aqui também é esquecida.

import 'package:ada_app/core/state/mode_controller.dart';
import 'package:ada_app/features/alerts/state/alert_controller.dart';
import 'package:ada_app/features/contacts/state/contacts_controller.dart';
import 'package:ada_app/features/coverage/state/coverage_controller.dart';
import 'package:ada_app/features/map/state/location_controller.dart';
import 'package:ada_app/features/messages/state/messages_controller.dart';
import 'package:ada_app/features/onboarding/data/onboarding_repository.dart';
import 'package:ada_app/features/profile/state/profile_controller.dart';

Future<void> eraseAllData({
  required ModeController mode,
  required AlertController alert,
  required ContactsController contacts,
  required MessagesController messages,
  required CoverageController coverage,
  required LocationController location,
  OnboardingRepository? onboarding,
  ProfileController? profile,
}) async {
  // 1. Para qualquer envio em andamento e volta ao modo Normal.
  alert.reset();
  mode.deactivate();
  location.clear();

  // 2. Apaga o que está guardado e espera as gravações terminarem.
  await Future.wait([
    contacts.clear(),
    messages.resetAll(),
    coverage.clear(),
    // O app volta a ser "recém-instalado": o onboarding aparece de novo.
    // Se isso falhar, o resto continua apagado: é só a apresentação voltando.
    ?onboarding?.reset().catchError((_) {}),
    // O nome também: a pergunta volta a aparecer.
    ?profile?.clear().catchError((_) {}),
  ]);
}
