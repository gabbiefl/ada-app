// Testa a tela Alerta com serviços falsos: nada aqui envia SMS ou liga de verdade.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:ada_app/core/theme/app_theme.dart';
import 'package:ada_app/features/alerts/data/alert_actions.dart';
import 'package:ada_app/features/alerts/pages/alert_page.dart';
import 'package:ada_app/features/alerts/state/alert_controller.dart';
import 'package:ada_app/features/alerts/widgets/delivery_card.dart';
import 'package:ada_app/features/contacts/models/contact.dart';
import 'package:ada_app/features/map/data/location_service.dart';
import 'package:ada_app/features/map/models/geo_point.dart';
import 'package:ada_app/features/messages/models/message_kind.dart';

// Localização que só responde quando o teste mandar (para ver "preparando").
class _SlowLocation implements LocationService {
  final completer = Completer<LocationResult>();

  @override
  Future<LocationResult> current() => completer.future;

  @override
  Future<void> openAppSettings() async {}

  @override
  Future<void> openLocationSettings() async {}
}

const _maria = Contact(id: '1', name: 'Maria', phone: '51999990001');
const _ana = Contact(id: '2', name: 'Ana', phone: '51999990002');
const _bia = Contact(id: '3', name: 'Bia', phone: '51999990003');
const _porto = GeoPoint(latitude: -30.0346, longitude: -51.2177);
const _short = Duration(milliseconds: 300);

// Monta a tela com o controlador dado. Tela alta: a lista cabe sem rolar.
Future<void> _pumpAlert(WidgetTester tester, AlertController controller) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  addTearDown(controller.dispose);

  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: controller,
      child: MaterialApp(theme: AppTheme.light, home: const AlertPage()),
    ),
  );
}

void main() {
  late FakeLocationService location;
  late FakeAlertActions actions;

  AlertController build({bool demoMode = false}) => AlertController(
    locationService: location,
    actions: actions,
    demoMode: demoMode,
  );

  Future<AlertController> danger(
    WidgetTester tester, {
    List<Contact> contacts = const [_maria, _ana, _bia],
    bool demoMode = false,
  }) async {
    final controller = build(demoMode: demoMode);
    await controller.start(
      kind: MessageKind.danger,
      contacts: contacts,
      message: 'Preciso de ajuda.',
    );
    await _pumpAlert(tester, controller);
    return controller;
  }

  setUp(() {
    location = FakeLocationService(const LocationResult.success(_porto));
    actions = FakeAlertActions();
  });

  testWidgets('Sem alerta em andamento, avisa isso', (tester) async {
    await _pumpAlert(tester, build());

    expect(find.text('Alerta'), findsOneWidget);
    expect(find.text('Nenhum alerta em andamento.'), findsOneWidget);
  });

  testWidgets('Enquanto busca a localização, mostra "preparando"', (
    tester,
  ) async {
    final slow = _SlowLocation();
    final controller = AlertController(locationService: slow, actions: actions);
    final running = controller.start(
      kind: MessageKind.danger,
      contacts: [_maria, _ana],
      message: 'Oi.',
    );
    await _pumpAlert(tester, controller);

    // Cartão de progresso da localização girando; as outras etapas aguardam.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Compartilhando localização'), findsOneWidget);
    expect(find.text('Buscando onde você está…'), findsOneWidget);
    expect(find.text('Aguardando a localização…'), findsOneWidget);

    slow.completer.complete(const LocationResult.success(_porto));
    await running;
    await tester.pump(_short);

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Maria'), findsOneWidget);
  });

  testWidgets('Perigo: lista cada contato com o que aconteceu', (tester) async {
    await danger(tester);

    expect(find.text('Modo perigo ativo'), findsOneWidget);
    // Detalhes por contato.
    expect(find.text('Maria'), findsOneWidget);
    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('Bia'), findsOneWidget);
    expect(find.text('SMS enviado'), findsNWidgets(2));
    // Cartões de progresso, um por etapa.
    expect(find.text('Localização compartilhada'), findsOneWidget);
    expect(find.text('Mensagens enviadas'), findsOneWidget);
    expect(find.text('2 de 2 enviadas'), findsOneWidget);
    expect(find.text('Ligando para Maria'), findsOneWidget);
    // "Ligação iniciada" aparece no cartão de progresso e no do contato.
    expect(find.text('Ligação iniciada'), findsNWidgets(2));
    expect(find.text('Detalhes por contato'), findsOneWidget);
  });

  testWidgets('Perigo: botão Ligar em cada contato; Atenção: nenhum', (
    tester,
  ) async {
    await danger(tester);
    expect(find.widgetWithText(TextButton, 'Ligar'), findsNWidgets(3));
  });

  testWidgets('Atenção: sem botão Ligar', (tester) async {
    final controller = build();
    await controller.start(
      kind: MessageKind.attention,
      contacts: [_maria, _ana],
      message: 'Estou insegura.',
    );
    await _pumpAlert(tester, controller);

    expect(find.text('Modo atenção ativo'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Ligar'), findsNothing);
    expect(find.widgetWithText(TextButton, 'WhatsApp'), findsNWidgets(2));
    expect(find.text('SMS enviado'), findsNWidgets(2));
  });

  testWidgets('Avisa o histórico e que o WhatsApp exige o toque', (
    tester,
  ) async {
    await danger(tester);

    expect(find.textContaining('toque em enviar por lá'), findsOneWidget);
    expect(
      find.textContaining('histórico do SMS e do WhatsApp'),
      findsOneWidget,
    );
  });

  testWidgets('Sem localização: avisa que a mensagem foi sem ela', (
    tester,
  ) async {
    location.result = const LocationResult.failure(LocationFailure.timeout);

    await danger(tester);

    expect(find.text('Localização indisponível'), findsOneWidget);
    expect(find.text('As mensagens saem sem o link do mapa.'), findsOneWidget);
    // Mesmo assim, as mensagens saem.
    expect(find.text('Mensagens enviadas'), findsOneWidget);
  });

  testWidgets('SMS que falhou mostra o motivo e "Tentar de novo"', (
    tester,
  ) async {
    actions.results[AlertActionKind.sendSms] = const ActionResult.failure(
      ActionFailure.permissionDenied,
    );

    await danger(tester);

    expect(find.text('Sem permissão para enviar SMS'), findsNWidgets(2));
    expect(find.text('Tentar de novo'), findsNWidgets(2));
    // Nenhum SMS saiu: a etapa de mensagens aparece como falha.
    expect(find.text('Algumas mensagens falharam'), findsOneWidget);
    expect(
      find.text('0 de 2 enviadas. Veja os detalhes abaixo.'),
      findsOneWidget,
    );
  });

  testWidgets('Tentar de novo refaz o envio e atualiza o cartão', (
    tester,
  ) async {
    actions.results[AlertActionKind.sendSms] = const ActionResult.failure(
      ActionFailure.failed,
    );
    await danger(tester, contacts: [_maria, _ana]);
    expect(find.text('Não foi possível enviar o SMS'), findsOneWidget);

    actions.results.remove(AlertActionKind.sendSms);
    await tester.tap(find.text('Tentar de novo'));
    await tester.pump(_short);

    expect(find.text('Não foi possível enviar o SMS'), findsNothing);
    expect(find.text('SMS enviado'), findsOneWidget);
    expect(find.text('Tentar de novo'), findsNothing);
  });

  testWidgets('Ligação pelo discador (plano B) aparece como tal', (
    tester,
  ) async {
    actions.results[AlertActionKind.call] = const ActionResult.failure(
      ActionFailure.permissionDenied,
    );

    await danger(tester);

    // No cartão de progresso e no do contato.
    expect(find.text('Discador aberto'), findsNWidgets(2));
  });

  testWidgets('Rede vazia: explica e oferece cadastrar contato', (
    tester,
  ) async {
    await danger(tester, contacts: const []);

    expect(find.textContaining('ainda não tem contatos'), findsOneWidget);
    expect(find.text('Cadastrar contato'), findsOneWidget);
    expect(actions.calls, isEmpty);
  });

  testWidgets('Modo de demonstração: faixa de aviso e envios simulados', (
    tester,
  ) async {
    await danger(tester, demoMode: true);

    expect(find.textContaining('Modo de demonstração'), findsOneWidget);
    expect(find.text('SMS simulado'), findsNWidgets(2));
    expect(find.text('2 de 2 enviadas (simulado)'), findsOneWidget);
    expect(find.text('Ligação simulada'), findsNWidgets(2));
    expect(actions.calls, isEmpty);
  });

  testWidgets('WhatsApp abre a conversa do contato com o texto', (
    tester,
  ) async {
    final controller = await danger(tester, contacts: [_maria, _ana]);

    await tester.tap(find.widgetWithText(TextButton, 'WhatsApp').first);
    await tester.pump(_short);

    // A lista segue a ordem do envio (SMS primeiro, ligação por último): o
    // primeiro cartão é o da Ana.
    final call = actions.calls.last;
    expect(call.kind, AlertActionKind.openWhatsApp);
    expect(call.phone, '51999990002');
    expect(call.text, controller.text);
  });

  testWidgets('SMS manual abre o app de mensagens', (tester) async {
    await danger(tester, contacts: [_maria, _ana]);

    await tester.tap(find.widgetWithText(TextButton, 'SMS').last);
    await tester.pump(_short);

    // O último cartão é o da Maria (a que recebe a ligação).
    expect(actions.calls.last.kind, AlertActionKind.openSmsComposer);
    expect(actions.calls.last.phone, '51999990001');
  });

  testWidgets('Ligar manual liga para o contato do cartão', (tester) async {
    await danger(tester, contacts: [_maria, _ana]);
    actions.calls.clear();

    await tester.tap(find.widgetWithText(TextButton, 'Ligar').last);
    await tester.pump(_short);

    expect(actions.calls.single.kind, AlertActionKind.call);
    expect(actions.calls.single.phone, '51999990001');
  });

  testWidgets('Se o WhatsApp não abrir, avisa em vez de falhar calado', (
    tester,
  ) async {
    actions.results[AlertActionKind.openWhatsApp] = const ActionResult.failure(
      ActionFailure.notAvailable,
    );
    await danger(tester, contacts: [_maria, _ana]);

    await tester.tap(find.widgetWithText(TextButton, 'WhatsApp').first);
    await tester.pump(_short);

    expect(find.text('Não foi possível abrir o WhatsApp.'), findsOneWidget);
  });

  group('deliveryStatusText', () {
    AlertDelivery sms(DeliveryStatus status, {ActionFailure? failure}) =>
        AlertDelivery(
          contact: _maria,
          action: DeliveryAction.sms,
          status: status,
          failure: failure,
        );

    test('cada situação do SMS tem o seu texto', () {
      expect(deliveryStatusText(sms(DeliveryStatus.pending)), 'Aguardando');
      expect(deliveryStatusText(sms(DeliveryStatus.sending)), 'Enviando SMS…');
      expect(deliveryStatusText(sms(DeliveryStatus.sent)), 'SMS enviado');
      expect(
        deliveryStatusText(
          sms(DeliveryStatus.failed, failure: ActionFailure.notAvailable),
        ),
        'Este aparelho não consegue enviar SMS',
      );
      expect(
        deliveryStatusText(sms(DeliveryStatus.failed)),
        'Não foi possível enviar o SMS',
      );
    });

    test('a ligação tem textos próprios', () {
      const call = AlertDelivery(
        contact: _maria,
        action: DeliveryAction.call,
        status: DeliveryStatus.failed,
        failure: ActionFailure.permissionDenied,
      );

      expect(deliveryStatusText(call), 'Sem permissão para ligar');
    });
  });
}
