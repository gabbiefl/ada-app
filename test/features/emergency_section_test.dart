// Testa a seção "Segurança pública" da Home: ligar para o 190 e o 180.
// Nenhum teste liga de verdade: o AlertActions é a versão falsa.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:ada_app/core/theme/app_theme.dart';
import 'package:ada_app/features/alerts/data/alert_actions.dart';
import 'package:ada_app/features/emergency/widgets/emergency_section.dart';

Future<FakeAlertActions> _pump(
  WidgetTester tester, [
  FakeAlertActions? actions,
]) async {
  final fake = actions ?? FakeAlertActions();
  await tester.pumpWidget(
    Provider<AlertActions>.value(
      value: fake,
      child: MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: EmergencySection(),
          ),
        ),
      ),
    ),
  );
  return fake;
}

void main() {
  testWidgets('mostra o título, o subtítulo e os dois serviços', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('Segurança pública'), findsOneWidget);
    expect(find.textContaining('A sua rede não é avisada'), findsOneWidget);
    expect(find.textContaining('Ligue 190'), findsOneWidget);
    expect(find.textContaining('Polícia Militar'), findsWidgets);
    expect(find.textContaining('Ligue 180'), findsOneWidget);
    expect(
      find.textContaining('Central de Atendimento à Mulher'),
      findsWidgets,
    );
  });

  testWidgets('tocar pergunta antes e não liga ainda', (tester) async {
    final actions = await _pump(tester);

    await tester.tap(find.textContaining('Ligue 190'));
    await tester.pumpAndSettle();

    expect(find.text('Ligar para o 190?'), findsOneWidget);
    expect(actions.calls, isEmpty);
  });

  testWidgets('Cancelar não liga para ninguém', (tester) async {
    final actions = await _pump(tester);

    await tester.tap(find.textContaining('Ligue 190'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(actions.calls, isEmpty);
  });

  testWidgets('confirmar liga SÓ para o 190: sem SMS e sem a rede', (
    tester,
  ) async {
    final actions = await _pump(tester);

    await tester.tap(find.textContaining('Ligue 190'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ligar'));
    await tester.pumpAndSettle();

    expect(actions.calls, hasLength(1));
    expect(actions.calls.single.kind, AlertActionKind.call);
    expect(actions.calls.single.phone, '190');
    expect(actions.count(AlertActionKind.sendSms), 0);
    expect(actions.permissionRequests, 0);
  });

  testWidgets('o 180 liga para o 180', (tester) async {
    final actions = await _pump(tester);

    await tester.tap(find.textContaining('Ligue 180'));
    await tester.pumpAndSettle();
    expect(find.text('Ligar para o 180?'), findsOneWidget);
    await tester.tap(find.text('Ligar'));
    await tester.pumpAndSettle();

    expect(actions.calls.single.phone, '180');
  });

  testWidgets('sem ligação direta, abre o discador com o número', (
    tester,
  ) async {
    final actions = FakeAlertActions()
      ..results[AlertActionKind.call] = const ActionResult.failure(
        ActionFailure.permissionDenied,
      );
    await _pump(tester, actions);

    await tester.tap(find.textContaining('Ligue 190'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ligar'));
    await tester.pumpAndSettle();

    expect(actions.count(AlertActionKind.call), 1);
    expect(actions.count(AlertActionKind.openDialer), 1);
    expect(actions.calls.last.phone, '190');
    expect(find.textContaining('Não foi possível ligar'), findsNothing);
  });

  testWidgets('se nem o discador abrir, avisa para discar pelo telefone', (
    tester,
  ) async {
    final actions = FakeAlertActions()
      ..results[AlertActionKind.call] = const ActionResult.failure(
        ActionFailure.notAvailable,
      )
      ..results[AlertActionKind.openDialer] = const ActionResult.failure(
        ActionFailure.notAvailable,
      );
    await _pump(tester, actions);

    await tester.tap(find.textContaining('Ligue 180'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ligar'));
    await tester.pumpAndSettle();

    expect(
      find.text('Não foi possível ligar. Disque 180 pelo telefone.'),
      findsOneWidget,
    );
  });
}
