// Fluxo completo do "Apagar meus dados" no app de verdade: as telas Rede,
// Mensagens e Cobertura refletem o que foi apagado. GPS e envio de SMS falsos.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:ada_app/app.dart';
import 'package:ada_app/core/routes/app_router.dart';
import 'package:ada_app/features/alerts/data/alert_actions.dart';
import 'package:ada_app/features/contacts/data/contacts_repository.dart';
import 'package:ada_app/features/contacts/models/contact.dart';
import 'package:ada_app/features/coverage/data/coverage_repository.dart';
import 'package:ada_app/features/coverage/models/coverage_rule.dart';
import 'package:ada_app/features/map/data/location_service.dart';
import 'package:ada_app/features/map/models/geo_point.dart';
import 'package:ada_app/features/messages/data/messages_repository.dart';
import 'package:ada_app/features/onboarding/data/onboarding_repository.dart';
import 'package:ada_app/features/messages/models/message_kind.dart';

const _short = Duration(milliseconds: 600);

void main() {
  testWidgets('apagar os dados esvazia a Rede, a Cobertura e as Mensagens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final contactsRepo = InMemoryContactsRepository(const [
      Contact(id: 'm', name: 'Maria', phone: '51999990001'),
      Contact(id: 'a', name: 'Ana', phone: '51999990002'),
    ]);
    final coverageRepo = InMemoryCoverageRepository(const [
      CoverageRule(id: 'r', contactId: 'm', start: 480, end: 780),
    ]);
    final messagesRepo = InMemoryMessagesRepository({
      MessageKind.danger: 'Texto que eu mesma escrevi.',
    });

    appRouter.go(AppRoutes.contacts);
    await tester.pumpWidget(
      AdaApp(
        locationService: FakeLocationService(
          const LocationResult.success(GeoPoint(latitude: 0, longitude: 0)),
        ),
        alertActions: FakeAlertActions(),
        contactsRepository: contactsRepo,
        messagesRepository: messagesRepo,
        coverageRepository: coverageRepo,
        onboardingRepository: InMemoryOnboardingRepository(true),
      ),
    );
    await tester.pump(_short);

    // Antes: a rede tem as duas pessoas.
    expect(find.text('Maria'), findsOneWidget);
    expect(find.text('Ana'), findsOneWidget);

    // Configurações -> Apagar meus dados -> Apagar tudo.
    await tester.tap(find.byIcon(LucideIcons.settings));
    await tester.pump(_short);
    await tester.tap(find.text('Apagar meus dados'));
    await tester.pump(_short);
    await tester.tap(find.text('Apagar tudo'));
    await tester.pump(_short);
    expect(find.text('Seus dados foram apagados.'), findsOneWidget);

    // Rede: sem contatos, só os espaços para cadastrar.
    await tester.tap(find.byIcon(LucideIcons.users));
    await tester.pump(_short);
    expect(find.text('Maria'), findsNothing);
    expect(find.text('Ana'), findsNothing);
    expect(find.text('Adicionar contato'), findsWidgets);

    // Mensagens: voltou ao texto padrão.
    appRouter.go(AppRoutes.messages);
    await tester.pump(_short);
    expect(find.text('Texto que eu mesma escrevi.'), findsNothing);
    expect(find.text(MessageKind.danger.defaultText), findsOneWidget);

    // Cobertura: sem contatos, a tela explica.
    appRouter.go(AppRoutes.coverage);
    await tester.pump(_short);
    expect(find.textContaining('ainda não tem contatos'), findsOneWidget);

    // E o armazenamento ficou vazio: nada volta ao reabrir o app.
    expect(await contactsRepo.load(), isEmpty);
    expect(await coverageRepo.load(), isEmpty);
    expect(await messagesRepo.load(), isEmpty);
  });
}
