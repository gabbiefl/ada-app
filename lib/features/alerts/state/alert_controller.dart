// Conduz o alerta do começo ao fim: localização, texto, SMS e ligação.
//
// Mesmo padrão dos outros controladores: um ChangeNotifier que as telas
// assinam. Ele só ORQUESTRA; quem faz cada coisa é um serviço recebido de fora
// (injeção de dependência): o LocationService busca a posição e o AlertActions
// manda o SMS e liga. Nos testes entram versões falsas, então nenhum teste envia
// mensagem ou liga de verdade.
//
// A ordem importa:
//   1. pede as permissões (SMS e ligação), se ainda não foram dadas;
//   2. busca a localização (com tempo limite) e monta o texto com o link;
//   3. manda o SMS aos contatos;
//   4. SÓ DEPOIS liga: a ligação toma a tela do celular.
//
// Perigo: o SMS vai para os OUTROS contatos e a ligação para o contato de
// plantão (o escolhido pela CallTargetPolicy). Atenção: SMS para todos, sem
// ligar. O alerta sai mesmo sem localização (o texto avisa), e uma falha em um
// contato nunca impede os outros (RNF03 e RNF04).
//
// Privacidade (Fase 0, P6): telefone, texto e coordenadas ficam só na memória,
// nunca vão para print/debugPrint, e reset() apaga tudo.

import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'package:ada_app/features/alerts/data/alert_actions.dart';
import 'package:ada_app/features/contacts/models/contact.dart';
import 'package:ada_app/features/map/data/location_service.dart';
import 'package:ada_app/features/map/models/geo_point.dart';
import 'package:ada_app/features/messages/models/message_kind.dart';
import 'package:ada_app/features/messages/utils/alert_text.dart';

// Em que etapa o alerta está.
enum AlertPhase {
  idle, // nada em andamento
  preparing, // pedindo permissões e buscando a localização
  sending, // mandando os SMS e ligando
  done, // terminou (com sucesso ou não)
}

// O que se faz com cada contato.
enum DeliveryAction { sms, call }

enum DeliveryStatus { pending, sending, sent, failed }

// O que aconteceu (ou vai acontecer) com UM contato.
class AlertDelivery {
  const AlertDelivery({
    required this.contact,
    required this.action,
    this.status = DeliveryStatus.pending,
    this.failure,
    this.viaFallback = false,
    this.simulated = false,
  });

  final Contact contact;
  final DeliveryAction action;
  final DeliveryStatus status;

  // Só quando falhou: o motivo.
  final ActionFailure? failure;

  // A ligação direta falhou e abrimos o discador no lugar (plano B).
  final bool viaFallback;

  // Modo de demonstração: nada foi enviado de verdade.
  final bool simulated;

  AlertDelivery copyWith({
    DeliveryStatus? status,
    ActionFailure? failure,
    bool? viaFallback,
    bool? simulated,
  }) => AlertDelivery(
    contact: contact,
    action: action,
    status: status ?? this.status,
    failure: failure ?? this.failure,
    viaFallback: viaFallback ?? this.viaFallback,
    simulated: simulated ?? this.simulated,
  );

  // Sem telefone nem nome: dado pessoal não vai para logs.
  @override
  String toString() => 'AlertDelivery($action, $status)';
}

// Decide para QUEM ligar no Perigo. Por enquanto é o primeiro da lista; a
// Fase 10 troca por "o contato do horário de cobertura" sem mexer no resto.
abstract class CallTargetPolicy {
  Contact? pick(List<Contact> contacts);
}

class FirstContactPolicy implements CallTargetPolicy {
  const FirstContactPolicy();

  @override
  Contact? pick(List<Contact> contacts) =>
      contacts.isEmpty ? null : contacts.first;
}

class AlertController extends ChangeNotifier {
  AlertController({
    required this.locationService,
    required this.actions,
    this.callTarget = const FirstContactPolicy(),
    this._demoMode = false,
  });

  final LocationService locationService;
  final AlertActions actions;
  final CallTargetPolicy callTarget;

  AlertPhase _phase = AlertPhase.idle;
  MessageKind? _kind;
  List<AlertDelivery> _deliveries = const [];
  GeoPoint? _location;
  LocationFailure? _locationFailure;
  String? _text;
  bool _demoMode;
  bool _disposed = false;

  // Cada alerta tem um número. reset() muda o número, e um alerta antigo que
  // ainda esteja no meio do caminho percebe isso e PARA de enviar.
  int _generation = 0;

  AlertPhase get phase => _phase;
  MessageKind? get kind => _kind;
  UnmodifiableListView<AlertDelivery> get deliveries =>
      UnmodifiableListView(_deliveries);
  GeoPoint? get location => _location;
  LocationFailure? get locationFailure => _locationFailure;
  // O texto final enviado (mensagem + link). Só existe depois de preparar.
  String? get text => _text;
  bool get demoMode => _demoMode;

  // Alerta com a rede vazia: terminou sem ter para quem enviar.
  bool get hasNoContacts => _phase == AlertPhase.done && _deliveries.isEmpty;

  // Modo de demonstração: faz tudo, menos enviar e ligar (para ensaiar).
  set demoMode(bool value) {
    if (value == _demoMode) return;
    _demoMode = value;
    notifyListeners();
  }

  // Dispara o alerta. Só roda uma vez por ativação: se já há um alerta em
  // andamento ou terminado, ignora (evita enviar duas vezes e gastar o plano).
  // Para começar outro, é preciso chamar reset() antes (ao desativar o modo).
  Future<void> start({
    required MessageKind kind,
    required List<Contact> contacts,
    required String message,
  }) async {
    if (_phase != AlertPhase.idle) return;

    final generation = ++_generation;
    bool cancelled() => _disposed || generation != _generation;

    _kind = kind;
    _location = null;
    _locationFailure = null;
    _text = null;
    _deliveries = _plan(kind, contacts);

    // Sem contatos não há para quem enviar: nem busca a localização.
    if (_deliveries.isEmpty) {
      _phase = AlertPhase.done;
      notifyListeners();
      return;
    }

    _phase = AlertPhase.preparing;
    notifyListeners();

    // 1. Permissões de SMS e ligação, antes de precisar delas. No modo de
    // demonstração nada é enviado, então não há o que pedir.
    if (!_demoMode) {
      try {
        await actions.requestPermissions();
      } catch (_) {
        // Se falhar, cada ação trata a sua própria falta de permissão.
      }
      if (cancelled()) return;
    }

    // 2. Localização e texto. Sem localização o alerta sai mesmo assim.
    final located = await locationService.current();
    if (cancelled()) return;
    _location = located.point;
    _locationFailure = located.failure;
    _text = buildAlertText(message: message, location: located.point);

    _phase = AlertPhase.sending;
    notifyListeners();

    // 3. Primeiro os SMS, 4. depois a ligação (ela toma a tela).
    for (final action in [DeliveryAction.sms, DeliveryAction.call]) {
      for (var i = 0; i < _deliveries.length; i++) {
        if (_deliveries[i].action != action) continue;
        await _deliver(i, cancelled);
        // Se a usuária desativou o alerta no meio, não envia mais nada.
        if (cancelled()) return;
      }
    }

    _phase = AlertPhase.done;
    notifyListeners();
  }

  // Esquece tudo e volta ao início. Chamado ao desativar o modo. Se um alerta
  // estiver no meio, ele para antes do próximo envio.
  void reset() {
    _generation++;
    _phase = AlertPhase.idle;
    _kind = null;
    _deliveries = const [];
    _location = null;
    _locationFailure = null;
    _text = null;
    notifyListeners();
  }

  // Tenta de novo o envio que FALHOU para este contato (SMS ou ligação). Só vale
  // depois de o alerta terminar.
  Future<void> retry(Contact contact) async {
    if (_phase != AlertPhase.done) return;
    final index = _deliveries.indexWhere(
      (d) => d.contact.id == contact.id && d.status == DeliveryStatus.failed,
    );
    if (index == -1) return;

    final generation = _generation;
    await _deliver(index, () => _disposed || generation != _generation);
  }

  // ---- Ações manuais da tela Alerta (reforço e plano B) ----
  // Abrem OUTRO app, onde a usuária toca em enviar. Só funcionam depois de o
  // texto do alerta estar pronto.

  Future<ActionResult> openWhatsApp(Contact contact) =>
      _manual((text) => actions.openWhatsApp(contact.phone, text));

  Future<ActionResult> openSmsComposer(Contact contact) =>
      _manual((text) => actions.openSmsComposer(contact.phone, text));

  // Liga para este contato, com o discador como plano B. No modo de
  // demonstração não liga de verdade.
  Future<ActionResult> callContact(Contact contact) async {
    if (_demoMode) return const ActionResult.success();
    final result = await _safe(() => actions.call(contact.phone));
    if (result.isSuccess) return result;
    return _safe(() => actions.openDialer(contact.phone));
  }

  Future<ActionResult> _manual(
    Future<ActionResult> Function(String text) action,
  ) {
    final text = _text;
    if (text == null) {
      return Future.value(const ActionResult.failure(ActionFailure.failed));
    }
    return _safe(() => action(text));
  }

  // Quem recebe o quê. Perigo: SMS para os outros e ligação para o contato de
  // plantão. Os demais casos: SMS para todos.
  List<AlertDelivery> _plan(MessageKind kind, List<Contact> contacts) {
    AlertDelivery sms(Contact c) =>
        AlertDelivery(contact: c, action: DeliveryAction.sms);

    final target = kind == MessageKind.danger
        ? callTarget.pick(contacts)
        : null;
    if (target == null) return [for (final c in contacts) sms(c)];

    final others = [
      for (final c in contacts)
        if (c.id != target.id) c,
    ];
    return [
      // Com um único contato ele recebe o SMS também: senão não saberia onde
      // a pessoa está.
      for (final c in others.isEmpty ? [target] : others) sms(c),
      AlertDelivery(contact: target, action: DeliveryAction.call),
    ];
  }

  Future<void> _deliver(int index, bool Function() cancelled) async {
    _update(index, (d) => d.copyWith(status: DeliveryStatus.sending));

    final delivery = _deliveries[index];

    // Demonstração: marca como enviado sem tocar em SMS nem em ligação.
    if (_demoMode) {
      _update(
        index,
        (d) => d.copyWith(status: DeliveryStatus.sent, simulated: true),
      );
      return;
    }

    final phone = delivery.contact.phone;
    if (delivery.action == DeliveryAction.sms) {
      final result = await _safe(() => actions.sendSms(phone, _text!));
      if (cancelled()) return;
      _update(index, (d) => _withResult(d, result));
      return;
    }

    // Ligação direta; se não der, abre o discador com o número (plano B).
    final result = await _safe(() => actions.call(phone));
    if (cancelled()) return;
    if (result.isSuccess) {
      _update(index, (d) => _withResult(d, result));
      return;
    }
    final fallback = await _safe(() => actions.openDialer(phone));
    if (cancelled()) return;
    _update(
      index,
      (d) => fallback.isSuccess
          ? d.copyWith(status: DeliveryStatus.sent, viaFallback: true)
          : _withResult(d, result), // falhou: guarda o motivo da ligação
    );
  }

  AlertDelivery _withResult(AlertDelivery delivery, ActionResult result) =>
      result.isSuccess
      ? delivery.copyWith(status: DeliveryStatus.sent)
      : delivery.copyWith(
          status: DeliveryStatus.failed,
          failure: result.failure,
        );

  // As ações não deveriam lançar erro, mas um alerta de emergência não pode
  // parar por causa de uma surpresa: qualquer exceção vira "falhou".
  Future<ActionResult> _safe(Future<ActionResult> Function() action) async {
    try {
      return await action();
    } catch (_) {
      return const ActionResult.failure(ActionFailure.failed);
    }
  }

  void _update(int index, AlertDelivery Function(AlertDelivery) change) {
    _deliveries = [
      for (var i = 0; i < _deliveries.length; i++)
        i == index ? change(_deliveries[i]) : _deliveries[i],
    ];
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
