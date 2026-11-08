// Testa o texto da caixa azul do cadastro de contato: ele não pode prometer um
// aviso que o ADA não faz (F9-06).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ada_app/core/theme/app_theme.dart';
import 'package:ada_app/features/contacts/widgets/info_box.dart';

void main() {
  testWidgets('pede para combinar com a pessoa e diz o que ela receberá', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: InfoBox()),
      ),
    );

    final texto = tester
        .widget<Text>(find.byType(Text))
        .textSpan!
        .toPlainText();

    expect(
      texto,
      'Combine com essa pessoa antes: em caso de alerta, ela receberá SMS e '
      'ligações do ADA.',
    );
  });

  testWidgets('não promete mais um aviso por WhatsApp no cadastro', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: InfoBox()),
      ),
    );

    final texto = tester
        .widget<Text>(find.byType(Text))
        .textSpan!
        .toPlainText()
        .toLowerCase();

    expect(texto, isNot(contains('whatsapp')));
    expect(texto, isNot(contains('foi cadastrado')));
  });
}
