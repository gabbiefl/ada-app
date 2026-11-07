// Transforma o estado do alerta nos CARTÕES DE PROGRESSO da tela (um por etapa):
//   Compartilhando localização -> Enviando mensagens -> Ligando para <contato>
//
// É uma função pura: recebe o AlertController e devolve a lista de passos já com
// título, detalhe e estado. A tela só desenha; o texto e a regra de cada estado
// ficam aqui, onde são fáceis de testar sem desenhar nada.

import 'package:ada_app/features/alerts/state/alert_controller.dart';
import 'package:ada_app/features/alerts/widgets/delivery_card.dart';

// Estado visual de uma etapa.
enum ProgressState {
  pending, // ainda não chegou a vez (relógio)
  loading, // acontecendo agora (ícone girando)
  done, // deu certo (✓)
  warning, // terminou, mas com ressalva (ex.: sem localização)
  failed, // não deu certo (aviso)
}

class ProgressStep {
  const ProgressStep({
    required this.title,
    required this.detail,
    required this.state,
  });

  final String title;
  final String detail;
  final ProgressState state;
}

List<ProgressStep> buildProgressSteps(AlertController alert) {
  if (alert.phase == AlertPhase.idle || alert.hasNoContacts) return const [];

  return [
    _locationStep(alert),
    _messagesStep(alert),
    ?_callStep(alert), // `?` : só entra na lista se não for null
  ];
}

ProgressStep _locationStep(AlertController alert) {
  if (alert.phase == AlertPhase.preparing) {
    return const ProgressStep(
      title: 'Compartilhando localização',
      detail: 'Buscando onde você está…',
      state: ProgressState.loading,
    );
  }
  if (alert.location != null) {
    return const ProgressStep(
      title: 'Localização compartilhada',
      detail: 'O link do mapa vai nas mensagens.',
      state: ProgressState.done,
    );
  }
  return const ProgressStep(
    title: 'Localização indisponível',
    detail: 'As mensagens saem sem o link do mapa.',
    state: ProgressState.warning,
  );
}

ProgressStep _messagesStep(AlertController alert) {
  final sms = alert.deliveries
      .where((d) => d.action == DeliveryAction.sms)
      .toList();
  final total = sms.length;
  final sent = sms.where((d) => d.status == DeliveryStatus.sent).length;
  final failed = sms.where((d) => d.status == DeliveryStatus.failed).length;
  final simulated = sms.any((d) => d.simulated) ? ' (simulado)' : '';

  if (alert.phase == AlertPhase.preparing) {
    return const ProgressStep(
      title: 'Enviando mensagens',
      detail: 'Aguardando a localização…',
      state: ProgressState.pending,
    );
  }
  if (alert.phase == AlertPhase.sending) {
    return ProgressStep(
      title: 'Enviando mensagens',
      detail: '$sent de $total enviadas$simulated',
      state: ProgressState.loading,
    );
  }
  if (failed == 0) {
    return ProgressStep(
      title: 'Mensagens enviadas',
      detail: '$sent de $total enviadas$simulated',
      state: ProgressState.done,
    );
  }
  return ProgressStep(
    title: 'Algumas mensagens falharam',
    detail: '$sent de $total enviadas. Veja os detalhes abaixo.',
    // Nenhuma saiu = falha; algumas saíram = ressalva.
    state: sent == 0 ? ProgressState.failed : ProgressState.warning,
  );
}

// A etapa de ligação só existe no Perigo (quando há um contato para ligar).
ProgressStep? _callStep(AlertController alert) {
  final calls = alert.deliveries.where((d) => d.action == DeliveryAction.call);
  if (calls.isEmpty) return null;

  final call = calls.first;
  final name = call.contact.name;

  switch (call.status) {
    case DeliveryStatus.pending:
      return ProgressStep(
        title: 'Ligar para $name',
        detail: 'Depois das mensagens',
        state: ProgressState.pending,
      );
    case DeliveryStatus.sending:
      return ProgressStep(
        title: 'Ligando para $name',
        detail: 'Aguarde…',
        state: ProgressState.loading,
      );
    case DeliveryStatus.sent:
      return ProgressStep(
        title: 'Ligando para $name',
        detail: deliveryStatusText(call),
        state: ProgressState.done,
      );
    case DeliveryStatus.failed:
      return ProgressStep(
        title: 'Não foi possível ligar para $name',
        detail: deliveryStatusText(call),
        state: ProgressState.failed,
      );
  }
}
