// Testa o onboarding: o "já viu" guardado, as 3 telas e o fluxo
// splash -> onboarding -> Home.

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:ada_app/app.dart';
import 'package:ada_app/core/routes/app_router.dart';
import 'package:ada_app/core/theme/app_theme.dart';
import 'package:ada_app/features/alerts/data/alert_actions.dart';
import 'package:ada_app/features/contacts/data/contacts_repository.dart';
import 'package:ada_app/features/coverage/data/coverage_repository.dart';
import 'package:ada_app/features/map/data/location_service.dart';
import 'package:ada_app/features/map/models/geo_point.dart';
import 'package:ada_app/features/messages/data/messages_repository.dart';
import 'package:ada_app/features/onboarding/data/onboarding_repository.dart';
import 'package:ada_app/features/onboarding/pages/onboarding_page.dart';
import 'package:ada_app/features/permissions/data/permissions_service.dart';

import '../support/app_font.dart';

const _short = Duration(milliseconds: 600);

// Repositório que sempre falha, para conferir que o app segue mesmo assim.
class _BrokenOnboardingRepository implements OnboardingRepository {
  @override
  Future<bool> hasSeen() async => throw Exception('ilegível');

  @override
  Future<void> markSeen() async => throw Exception('sem espaço');

  @override
  Future<void> reset() async => throw Exception('sem espaço');
}

Widget _page(OnboardingRepository repository, {VoidCallback? onFinished}) {
  return Provider<OnboardingRepository>.value(
    value: repository,
    child: MaterialApp(
      theme: AppTheme.light,
      home: OnboardingPage(onFinished: onFinished),
    ),
  );
}

Future<void> _pumpApp(
  WidgetTester tester,
  OnboardingRepository repository,
) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);

  appRouter.go(AppRoutes.splash);
  await tester.pumpWidget(
    AdaApp(
      locationService: FakeLocationService(
        const LocationResult.success(
          GeoPoint(latitude: -30.0346, longitude: -51.2177),
        ),
      ),
      alertActions: FakeAlertActions(),
      contactsRepository: InMemoryContactsRepository(),
      messagesRepository: InMemoryMessagesRepository(),
      coverageRepository: InMemoryCoverageRepository(),
      onboardingRepository: repository,
      permissionsService: FakePermissionsService(),
    ),
  );
  await tester.pump(_short);
}

void main() {
  setUpAll(loadAppFont);

  group('repositório do "já viu"', () {
    setUp(() => FlutterSecureStorage.setMockInitialValues({}));

    test('começa como "não viu" e lembra depois de marcado', () async {
      final repository = SecureOnboardingRepository();
      expect(await repository.hasSeen(), isFalse);

      await repository.markSeen();

      // Outro repositório, como se o app tivesse sido fechado e reaberto.
      expect(await SecureOnboardingRepository().hasSeen(), isTrue);
    });

    test('reset volta a "não viu"', () async {
      final repository = SecureOnboardingRepository();
      await repository.markSeen();

      await repository.reset();

      expect(await repository.hasSeen(), isFalse);
    });
  });

  group('as 3 telas', () {
    testWidgets('mostram os textos em ordem, e a última diz "Começar"', (
      tester,
    ) async {
      await tester.pumpWidget(_page(InMemoryOnboardingRepository()));

      expect(find.text('Sua segurança em um toque.'), findsOneWidget);
      expect(find.text('Continuar'), findsOneWidget);
      expect(find.text('Pular'), findsOneWidget);

      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      expect(find.text('Sua rede sempre por perto.'), findsOneWidget);
      expect(find.textContaining('até 5 pessoas'), findsOneWidget);
      expect(find.text('Pular'), findsOneWidget);

      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      expect(find.text('Você no controle.'), findsOneWidget);
      // O texto diz o que o app faz de verdade: nada de acompanhar em tempo real.
      expect(find.textContaining('só é enviada quando você ativa'), findsOne);
      expect(find.text('Começar'), findsOneWidget);
      expect(find.text('Continuar'), findsNothing);
      expect(find.text('Pular'), findsNothing);
    });

    testWidgets('dá para deslizar entre as telas', (tester) async {
      await tester.pumpWidget(_page(InMemoryOnboardingRepository()));

      await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
      await tester.pumpAndSettle();

      expect(find.text('Sua rede sempre por perto.'), findsOneWidget);
    });

    testWidgets('Pular grava que viu e termina', (tester) async {
      final repository = InMemoryOnboardingRepository();
      var finished = 0;
      await tester.pumpWidget(_page(repository, onFinished: () => finished++));

      await tester.tap(find.text('Pular'));
      await tester.pump();
      await tester.pump();

      expect(await repository.hasSeen(), isTrue);
      expect(finished, 1);
    });

    testWidgets('Começar, na última tela, grava que viu e termina', (
      tester,
    ) async {
      final repository = InMemoryOnboardingRepository();
      var finished = 0;
      await tester.pumpWidget(_page(repository, onFinished: () => finished++));

      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Começar'));
      await tester.pump();
      await tester.pump();

      expect(await repository.hasSeen(), isTrue);
      expect(finished, 1);
    });

    testWidgets('se não conseguir gravar, termina do mesmo jeito', (
      tester,
    ) async {
      var finished = 0;
      await tester.pumpWidget(
        _page(_BrokenOnboardingRepository(), onFinished: () => finished++),
      );

      await tester.tap(find.text('Pular'));
      await tester.pump();
      await tester.pump();

      expect(finished, 1);
    });
  });

  group('fluxo no app', () {
    testWidgets('primeira vez: splash, onboarding e Home; depois só a Home', (
      tester,
    ) async {
      final repository = InMemoryOnboardingRepository();
      await _pumpApp(tester, repository);

      // A splash termina e, como nunca viu, abre o onboarding.
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(_short);
      expect(find.text('Sua segurança em um toque.'), findsOneWidget);

      await tester.tap(find.text('Pular'));
      await tester.pump(_short);
      await tester.pump(_short);
      expect(await repository.hasSeen(), isTrue);

      // Depois do onboarding, o ADA explica e pede as permissões.
      expect(
        find.text('Precisamos de 3 permissões para proteger você'),
        findsOneWidget,
      );
      await tester.tap(find.text('Agora não'));
      await tester.pump(_short);
      await tester.pump(_short);
      expect(find.text('Olá!'), findsOneWidget);

      // Reabrir o app: a splash vai direto à Home.
      await _pumpApp(tester, repository);
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(_short);
      expect(find.text('Sua segurança em um toque.'), findsNothing);
      expect(find.text('Olá!'), findsOneWidget);
    });

    testWidgets('se não conseguir ler, a splash vai para a Home', (
      tester,
    ) async {
      await _pumpApp(tester, _BrokenOnboardingRepository());

      await tester.pump(const Duration(seconds: 3));
      await tester.pump(_short);

      expect(find.text('Olá!'), findsOneWidget);
    });

    testWidgets('"Apagar meus dados" faz o onboarding voltar', (tester) async {
      final repository = InMemoryOnboardingRepository(true);
      await _pumpApp(tester, repository);
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(_short);
      expect(find.text('Olá!'), findsOneWidget);

      appRouter.go(AppRoutes.settings);
      await tester.pump(_short);
      await tester.tap(find.text('Apagar meus dados'));
      await tester.pump(_short);
      await tester.tap(find.text('Apagar tudo'));
      await tester.pump(_short);
      await tester.pump(_short);

      expect(await repository.hasSeen(), isFalse);
    });
  });
}
