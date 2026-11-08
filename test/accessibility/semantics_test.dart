// Confere os NOMES que o leitor de tela anuncia nas correções da Fase 11. As
// guidelines do Flutter só dizem que existe um nome; aqui se confere qual é.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ada_app/app.dart';
import 'package:ada_app/core/routes/app_router.dart';
import 'package:ada_app/features/alerts/data/alert_actions.dart';
import 'package:ada_app/features/contacts/data/contacts_repository.dart';
import 'package:ada_app/features/coverage/data/coverage_repository.dart';
import 'package:ada_app/features/map/data/location_service.dart';
import 'package:ada_app/features/map/models/geo_point.dart';
import 'package:ada_app/features/messages/data/messages_repository.dart';
import 'package:ada_app/features/messages/models/message_kind.dart';

import '../support/app_font.dart';

const _short = Duration(milliseconds: 600);

Future<void> _pumpApp(WidgetTester tester, String route) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);

  appRouter.go(route);
  await tester.pumpWidget(
    AdaApp(
      locationService: FakeLocationService(
        const LocationResult.success(GeoPoint(latitude: 0, longitude: 0)),
      ),
      alertActions: FakeAlertActions(),
      contactsRepository: InMemoryContactsRepository(),
      messagesRepository: InMemoryMessagesRepository(),
      coverageRepository: InMemoryCoverageRepository(),
    ),
  );
  await tester.pump(_short);
}

void main() {
  // A fonte de verdade: sem ela o texto é desenhado largo demais (Ahem).
  setUpAll(loadAppFont);

  group('barra inferior', () {
    testWidgets('cada item tem nome, e só o atual está selecionado', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        await _pumpApp(tester, AppRoutes.home);

        for (final name in ['Início', 'Rede', 'Mapa', 'Configurações']) {
          expect(find.bySemanticsLabel(name), findsWidgets, reason: name);
        }
        expect(
          tester.getSemantics(find.bySemanticsLabel('Início').first),
          matchesSemantics(
            label: 'Início',
            isButton: true,
            isSelected: true,
            hasSelectedState: true,
            hasTapAction: true,
            hasFocusAction: true,
            isFocusable: true,
          ),
        );
        expect(
          tester.getSemantics(find.bySemanticsLabel('Rede').first),
          matchesSemantics(
            label: 'Rede',
            isButton: true,
            hasSelectedState: true,
            hasTapAction: true,
            hasFocusAction: true,
            isFocusable: true,
          ),
        );
      } finally {
        semantics.dispose();
      }
    });
  });

  group('Home', () {
    testWidgets('no modo Normal o símbolo central não é um botão', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        await _pumpApp(tester, AppRoutes.home);

        expect(find.bySemanticsLabel('Desativar alerta'), findsNothing);
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('com alerta ativo o símbolo vira "Desativar alerta"', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        await _pumpApp(tester, AppRoutes.home);
        await tester.tap(find.text('MODO ATENÇÃO'));
        await tester.pump(_short);
        await tester.tap(find.text('Ativar'));
        await tester.pump(_short);
        await tester.tap(find.byTooltip('Voltar'));
        await tester.pump(_short);

        expect(find.bySemanticsLabel('Desativar alerta'), findsOneWidget);
      } finally {
        semantics.dispose();
      }
    });
  });

  group('Mensagens', () {
    testWidgets('cada "Editar" diz qual mensagem edita', (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await _pumpApp(tester, AppRoutes.messages);

        for (final kind in MessageKind.values) {
          expect(
            find.bySemanticsLabel('Editar ${kind.title}'),
            findsOneWidget,
            reason: kind.title,
          );
        }
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('a área de toque de "Editar" tem pelo menos 48 x 48', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        await _pumpApp(tester, AppRoutes.messages);

        final size = tester.getSize(
          find.bySemanticsLabel('Editar Modo perigo'),
        );

        expect(size.width, greaterThanOrEqualTo(48));
        expect(size.height, greaterThanOrEqualTo(48));
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('as setas de voltar se chamam "Voltar"', (tester) async {
      await _pumpApp(tester, AppRoutes.messages);
      expect(find.byTooltip('Voltar'), findsOneWidget);

      await _pumpApp(tester, AppRoutes.editMessage(MessageKind.danger));
      expect(find.byTooltip('Voltar'), findsOneWidget);
    });
  });

  group('Configurações', () {
    testWidgets('a chave do Modo de demonstração tem nome', (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await _pumpApp(tester, AppRoutes.settings);

        expect(find.bySemanticsLabel('Modo de demonstração'), findsWidgets);
      } finally {
        semantics.dispose();
      }
    });
  });
}
