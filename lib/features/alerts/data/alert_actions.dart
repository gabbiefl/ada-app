// As ações de comunicação do alerta: mandar SMS, ligar e abrir outros apps.
//
// AlertActions é um "contrato" (classe abstrata): diz O QUE se pode fazer, sem
// dizer COMO. O app usa a versão real (que manda o SMS e liga de verdade); os
// testes usam a FakeAlertActions, que só anota o que foi pedido. Assim NENHUM
// teste envia mensagem ou liga para alguém. Mesma ideia do Haptics (Fase 7) e do
// LocationService (Fase 8).
//
// Como no LocationResult, nada lança erro: cada ação devolve um ActionResult,
// com sucesso ou com o motivo da falha. A tela e o controlador decidem o que
// fazer (por exemplo, usar o plano B).

// Motivos pelos quais uma ação pode falhar.
enum ActionFailure {
  permissionDenied, // a usuária não deu a permissão (SMS ou ligação)
  notAvailable, // não há app ou recurso para isso (sem chip, sem WhatsApp...)
  failed, // qualquer outro problema
}

class ActionResult {
  const ActionResult.success() : failure = null;
  const ActionResult.failure(ActionFailure this.failure);

  final ActionFailure? failure;

  bool get isSuccess => failure == null;
}

abstract class AlertActions {
  // Pede, de uma vez e com antecedência, as permissões de SMS e de ligação, para
  // o alerta não parar no meio esperando a usuária responder ao Android.
  // Devolve true se as duas foram dadas.
  Future<bool> requestPermissions();

  // Automáticas: não pedem toque da usuária (precisam de permissão).
  Future<ActionResult> sendSms(String phone, String text);
  Future<ActionResult> call(String phone);

  // Plano B e reforço: abrem outro app, e a usuária toca em enviar ou ligar.
  Future<ActionResult> openSmsComposer(String phone, String text);
  Future<ActionResult> openDialer(String phone);
  Future<ActionResult> openWhatsApp(String phone, String text);
}

// Tipos de ação, só para a versão falsa registrar o que foi pedido.
enum AlertActionKind {
  sendSms,
  call,
  openSmsComposer,
  openDialer,
  openWhatsApp,
}

// Um pedido registrado pela versão falsa. toString NÃO mostra telefone nem
// texto: são dados pessoais e não devem ir parar em logs de teste (Fase 0, P6).
class AlertActionCall {
  const AlertActionCall(this.kind, this.phone, [this.text]);

  final AlertActionKind kind;
  final String phone;
  final String? text;

  @override
  String toString() => 'AlertActionCall($kind)';
}

// Versão para testes: registra os pedidos em [calls] e devolve o resultado
// combinado para cada tipo de ação (sucesso, se nada for combinado).
class FakeAlertActions implements AlertActions {
  final List<AlertActionCall> calls = [];
  final Map<AlertActionKind, ActionResult> results = {};

  // O que requestPermissions devolve, e quantas vezes foi chamado.
  bool permissionsGranted = true;
  int permissionRequests = 0;

  @override
  Future<bool> requestPermissions() async {
    permissionRequests++;
    return permissionsGranted;
  }

  ActionResult _record(AlertActionKind kind, String phone, [String? text]) {
    calls.add(AlertActionCall(kind, phone, text));
    return results[kind] ?? const ActionResult.success();
  }

  // Quantos pedidos de um tipo foram feitos.
  int count(AlertActionKind kind) => calls.where((c) => c.kind == kind).length;

  @override
  Future<ActionResult> sendSms(String phone, String text) async =>
      _record(AlertActionKind.sendSms, phone, text);

  @override
  Future<ActionResult> call(String phone) async =>
      _record(AlertActionKind.call, phone);

  @override
  Future<ActionResult> openSmsComposer(String phone, String text) async =>
      _record(AlertActionKind.openSmsComposer, phone, text);

  @override
  Future<ActionResult> openDialer(String phone) async =>
      _record(AlertActionKind.openDialer, phone);

  @override
  Future<ActionResult> openWhatsApp(String phone, String text) async =>
      _record(AlertActionKind.openWhatsApp, phone, text);
}
