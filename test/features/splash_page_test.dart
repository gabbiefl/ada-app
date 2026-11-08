import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ada_app/core/theme/app_colors.dart';
import 'package:ada_app/core/theme/app_theme.dart';
import 'package:ada_app/features/splash/pages/splash_page.dart';

Widget _app(Widget home) => MaterialApp(theme: AppTheme.light, home: home);

void main() {
  testWidgets('A splash mostra a logo e uma barra que enche', (tester) async {
    await tester.pumpWidget(
      _app(
        SplashPage(duration: const Duration(seconds: 1), onFinished: () {}),
      ),
    );

    expect(find.byType(Image), findsOneWidget);
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, AppColors.modeNormal);

    double progress() => tester
        .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
        .value!;

    expect(progress(), 0);
    await tester.pump(const Duration(milliseconds: 500));
    expect(progress(), closeTo(0.5, 0.01));
    await tester.pump(const Duration(milliseconds: 500));
    expect(progress(), 1);
  });

  testWidgets('Quando a barra enche, a splash avisa que terminou', (
    tester,
  ) async {
    var finished = 0;
    await tester.pumpWidget(
      _app(
        SplashPage(
          duration: const Duration(seconds: 1),
          onFinished: () => finished++,
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 900));
    expect(finished, 0);
    await tester.pump(const Duration(milliseconds: 200));
    expect(finished, 1);
  });

  testWidgets('Sair da splash antes do fim não deixa nada pendente', (
    tester,
  ) async {
    var finished = 0;
    await tester.pumpWidget(
      _app(
        SplashPage(
          duration: const Duration(seconds: 1),
          onFinished: () => finished++,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    // Troca a tela no meio da animação: o controlador é descartado.
    await tester.pumpWidget(_app(const SizedBox()));
    await tester.pump(const Duration(seconds: 2));

    expect(finished, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('A splash tem nome para o leitor de tela', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(
        _app(
          SplashPage(duration: const Duration(seconds: 1), onFinished: () {}),
        ),
      );
      expect(find.bySemanticsLabel('Carregando o ADA'), findsOneWidget);
      expect(
        find.bySemanticsLabel('ADA — Alerta, Defesa e Apoio'),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 1));
    } finally {
      semantics.dispose();
    }
  });
}
