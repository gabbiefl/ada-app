// Teste de widget: monta o app em um ambiente de teste (sem emulador)
// e verifica o que aparece na tela.
//
// Rode com: flutter test

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:ada_app/app.dart';
import 'package:ada_app/core/state/mode_controller.dart';
import 'package:ada_app/core/state/security_mode.dart';
import 'package:ada_app/core/theme/app_theme.dart';
import 'package:ada_app/features/home/pages/home_page.dart';

// Tela de teste mais alta, para os dois cards caberem sem rolar.
void _tallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  // `testWidgets` cria um teste que recebe um `tester`, o "controle remoto"
  // para montar widgets, tocar na tela e consultar o que está visível.
  testWidgets('A tela inicial mostra a saudação', (tester) async {
    // Monta o app e espera o primeiro quadro ser desenhado.
    await tester.pumpWidget(const AdaApp());

    // `find.text` procura um Text com exatamente esse conteúdo.
    expect(find.text('Olá, Gabriela'), findsOneWidget);
    expect(find.text('Estamos com você!'), findsOneWidget);
    // Os dois cards dos modos aparecem.
    expect(find.text('MODO PERIGO'), findsOneWidget);
    expect(find.text('MODO ATENÇÃO'), findsOneWidget);
  });

  testWidgets('O app aplica o tema do ADA', (tester) async {
    await tester.pumpWidget(const AdaApp());

    // Procura o MaterialApp montado e confere o fundo do tema que ele recebeu.
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.theme?.scaffoldBackgroundColor, const Color(0xFFF8FAFC));
  });

  testWidgets('A Home acompanha o modo do controlador', (tester) async {
    final controller = ModeController();
    addTearDown(controller.dispose);

    // .value: fornece um controlador que já existe (o teste guarda a referência
    // para poder mudar o modo depois).
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: controller,
        child: MaterialApp(theme: AppTheme.light, home: const HomePage()),
      ),
    );

    // Começa no Normal.
    expect(find.text('Nenhum alerta ativo no momento.'), findsOneWidget);
    expect(find.text('Modo perigo ativo'), findsNothing);

    // Muda o modo: a Home deve se redesenhar sozinha.
    // pump(Duration) em vez de pumpAndSettle: os anéis pulsam para sempre.
    controller.activate(SecurityMode.danger);
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Modo perigo ativo'), findsOneWidget);
    expect(find.text('Toque no ícone para desativar.'), findsOneWidget);
    expect(find.text('Nenhum alerta ativo no momento.'), findsNothing);

    // E volta ao Normal.
    controller.deactivate();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Nenhum alerta ativo no momento.'), findsOneWidget);
    expect(find.text('Modo perigo ativo'), findsNothing);
  });

  testWidgets('Tocar no card Atenção ativa o Modo Atenção', (tester) async {
    _tallScreen(tester);
    final controller = ModeController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: controller,
        child: MaterialApp(theme: AppTheme.light, home: const HomePage()),
      ),
    );

    await tester.tap(find.text('MODO ATENÇÃO'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(controller.mode, SecurityMode.attention);
  });

  testWidgets('No Perigo, tocar na Atenção é recusado com aviso', (
    tester,
  ) async {
    _tallScreen(tester);
    final controller = ModeController()..activate(SecurityMode.danger);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: controller,
        child: MaterialApp(theme: AppTheme.light, home: const HomePage()),
      ),
    );

    await tester.tap(find.text('MODO ATENÇÃO'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(controller.mode, SecurityMode.danger);
    expect(
      find.text('Desative o Modo perigo antes de mudar para Atenção.'),
      findsOneWidget,
    );
  });

  // Monta a Home com um controlador que o teste guarda para conferir depois.
  Future<ModeController> pumpHome(WidgetTester tester) async {
    _tallScreen(tester);
    final controller = ModeController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: controller,
        child: MaterialApp(theme: AppTheme.light, home: const HomePage()),
      ),
    );
    return controller;
  }

  const short = Duration(milliseconds: 300);

  testWidgets('Perigo: o toque no card só pergunta; Ativar confirma', (
    tester,
  ) async {
    final controller = await pumpHome(tester);

    await tester.tap(find.text('MODO PERIGO'));
    await tester.pump(short);

    // 1º toque: só o diálogo. O modo ainda não mudou.
    expect(find.text('Ativar o Modo perigo?'), findsOneWidget);
    expect(controller.mode, SecurityMode.normal);

    await tester.tap(find.text('Ativar'));
    await tester.pump(short);

    expect(controller.mode, SecurityMode.danger);
    expect(find.text('Modo perigo ativo'), findsOneWidget);
  });

  testWidgets('Perigo: Cancelar não ativa nada', (tester) async {
    final controller = await pumpHome(tester);

    await tester.tap(find.text('MODO PERIGO'));
    await tester.pump(short);
    await tester.tap(find.text('Cancelar'));
    await tester.pump(short);

    expect(controller.mode, SecurityMode.normal);
    expect(find.text('Ativar o Modo perigo?'), findsNothing);
  });

  testWidgets('Desativar: tocar no símbolo pergunta; Desativar confirma', (
    tester,
  ) async {
    final controller = await pumpHome(tester);
    controller.activate(SecurityMode.danger);
    await tester.pump(short);

    await tester.tap(find.bySemanticsLabel('Desativar alerta'));
    await tester.pump(short);

    expect(find.text('Desativar o alerta?'), findsOneWidget);
    expect(controller.mode, SecurityMode.danger); // ainda ativo

    await tester.tap(find.text('Desativar'));
    await tester.pump(short);

    expect(controller.mode, SecurityMode.normal);
  });

  testWidgets('Desativar: Cancelar mantém o alerta ativo', (tester) async {
    final controller = await pumpHome(tester);
    controller.activate(SecurityMode.danger);
    await tester.pump(short);

    await tester.tap(find.bySemanticsLabel('Desativar alerta'));
    await tester.pump(short);
    await tester.tap(find.text('Cancelar'));
    await tester.pump(short);

    expect(controller.mode, SecurityMode.danger);
  });

  testWidgets('No modo Normal, tocar no símbolo não abre diálogo', (
    tester,
  ) async {
    await pumpHome(tester);

    await tester.tap(find.byType(Image).at(1)); // o símbolo central
    await tester.pump(short);

    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('Atenção ativa: a Home mostra chip e instrução do modo', (
    tester,
  ) async {
    final controller = await pumpHome(tester);

    controller.activate(SecurityMode.attention);
    await tester.pump(short);

    expect(find.text('Modo atenção ativo'), findsOneWidget);
    expect(find.text('Toque no ícone para desativar.'), findsOneWidget);
    expect(find.text('Modo perigo ativo'), findsNothing);
    expect(find.text('Nenhum alerta ativo no momento.'), findsNothing);
  });

  testWidgets('Atenção: o símbolo desativa com confirmação', (tester) async {
    final controller = await pumpHome(tester);
    controller.activate(SecurityMode.attention);
    await tester.pump(short);

    await tester.tap(find.bySemanticsLabel('Desativar alerta'));
    await tester.pump(short);
    await tester.tap(find.text('Desativar'));
    await tester.pump(short);

    expect(controller.mode, SecurityMode.normal);
    expect(find.text('Nenhum alerta ativo no momento.'), findsOneWidget);
  });

  testWidgets('Da Atenção, o card Perigo sobe o alerta após confirmar', (
    tester,
  ) async {
    final controller = await pumpHome(tester);
    controller.activate(SecurityMode.attention);
    await tester.pump(short);

    await tester.tap(find.text('MODO PERIGO'));
    await tester.pump(short);
    await tester.tap(find.text('Ativar'));
    await tester.pump(short);

    expect(controller.mode, SecurityMode.danger);
    expect(find.text('Modo perigo ativo'), findsOneWidget);
  });
}
