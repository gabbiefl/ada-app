// Testa o cadastro local do nome: repositório, controlador, tela, saudação na
// Home, edição em Configurações e "Apagar meus dados".

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
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
import 'package:ada_app/features/profile/data/profile_repository.dart';
import 'package:ada_app/features/profile/pages/profile_page.dart';
import 'package:ada_app/features/profile/state/profile_controller.dart';

import '../support/app_font.dart';

const _short = Duration(milliseconds: 600);

// Repositório que sempre falha, para conferir que o app segue mesmo assim.
class _BrokenProfileRepository implements ProfileRepository {
  @override
  Future<String?> loadName() async => throw Exception('ilegível');

  @override
  Future<void> saveName(String name) async => throw Exception('sem espaço');

  @override
  Future<void> clear() async => throw Exception('sem espaço');
}

Future<void> settle() => Future<void>.delayed(Duration.zero);

// Monta só a tela do nome, com um roteador de brinquedo (a tela usa go e pop).
Future<ProfileController> _pumpPage(
  WidgetTester tester, {
  required bool editing,
  ProfileRepository? repository,
}) async {
  final controller = ProfileController(repository: repository)..load();
  await controller.ready;

  final router = GoRouter(
    initialLocation: '/start',
    routes: [
      GoRoute(
        path: '/start',
        builder: (context, state) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => context.push('/page'),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/page',
        builder: (context, state) => ProfilePage(editing: editing),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const Scaffold(body: Text('HOME')),
      ),
    ],
  );

  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: controller,
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  // Editar abre a tela por cima (push, dá para voltar); a primeira vez usa go.
  if (editing) {
    await tester.tap(find.text('abrir'));
  } else {
    router.go('/page');
  }
  await tester.pumpAndSettle();
  return controller;
}

Future<void> _pumpApp(
  WidgetTester tester, {
  required String route,
  required ProfileRepository profile,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);

  appRouter.go(route);
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
      onboardingRepository: InMemoryOnboardingRepository(true),
      profileRepository: profile,
    ),
  );
  await tester.pump(_short);
}

void main() {
  setUpAll(loadAppFont);

  group('repositório do nome', () {
    setUp(() => FlutterSecureStorage.setMockInitialValues({}));

    test('começa sem nada e lembra o que foi salvo', () async {
      expect(await SecureProfileRepository().loadName(), isNull);

      await SecureProfileRepository().saveName('Ana');

      // Outro repositório, como se o app tivesse sido fechado e reaberto.
      expect(await SecureProfileRepository().loadName(), 'Ana');
    });

    test('vazio é guardado como "já perguntei"', () async {
      await SecureProfileRepository().saveName('');

      expect(await SecureProfileRepository().loadName(), '');
    });

    test('clear volta a "ainda não perguntou"', () async {
      final repository = SecureProfileRepository();
      await repository.saveName('Ana');

      await repository.clear();

      expect(await repository.loadName(), isNull);
    });
  });

  group('ProfileController', () {
    test('sem nome guardado: não perguntou, e a saudação é "Olá!"', () async {
      final controller = ProfileController(
        repository: InMemoryProfileRepository(),
      );
      await controller.load();

      expect(controller.asked, isFalse);
      expect(controller.hasName, isFalse);
      expect(controller.greeting, 'Olá!');
    });

    test('carrega o nome guardado e cumprimenta por ele', () async {
      final controller = ProfileController(
        repository: InMemoryProfileRepository('Ana'),
      );
      await controller.load();

      expect(controller.asked, isTrue);
      expect(controller.name, 'Ana');
      expect(controller.greeting, 'Olá, Ana');
    });

    test('save tira espaços das pontas e repetidos, e grava', () async {
      final repository = InMemoryProfileRepository();
      final controller = ProfileController(repository: repository);

      expect(controller.save('  Ana   Maria '), isNull);
      await settle();

      expect(controller.name, 'Ana Maria');
      expect(await repository.loadName(), 'Ana Maria');
    });

    test('recusa nome vazio ou com mais de 30 letras', () {
      final controller = ProfileController();

      expect(controller.save('   '), ProfileError.empty);
      expect(controller.save('a' * 31), ProfileError.tooLong);
      expect(controller.save('a' * 30), isNull);
    });

    test('skip lembra que já perguntou, sem nome', () async {
      final repository = InMemoryProfileRepository();
      final controller = ProfileController(repository: repository);

      controller.skip();
      await settle();

      expect(controller.asked, isTrue);
      expect(controller.hasName, isFalse);
      expect(await repository.loadName(), '');
    });

    test('clear esquece o nome e a pergunta volta', () async {
      final repository = InMemoryProfileRepository('Ana');
      final controller = ProfileController(repository: repository);
      await controller.load();

      await controller.clear();

      expect(controller.asked, isFalse);
      expect(controller.greeting, 'Olá!');
      expect(await repository.loadName(), isNull);
    });

    test(
      'se a leitura falhar, segue sem nome e NÃO volta a perguntar',
      () async {
        final controller = ProfileController(
          repository: _BrokenProfileRepository(),
        );
        await controller.load();

        expect(controller.asked, isTrue);
        expect(controller.greeting, 'Olá!');
      },
    );

    test('se a gravação falhar, o app segue com o nome na memória', () async {
      final controller = ProfileController(
        repository: _BrokenProfileRepository(),
      );

      expect(controller.save('Ana'), isNull);
      await settle();

      expect(controller.name, 'Ana');
    });

    test('avisa as telas quando o nome muda', () {
      final controller = ProfileController();
      var notified = 0;
      controller.addListener(() => notified++);

      controller.save('Ana');
      controller.skip();

      expect(notified, 2);
    });
  });

  group('tela do nome (primeira vez)', () {
    testWidgets('pergunta, e Continuar sem nome pede um nome ou Pular', (
      tester,
    ) async {
      final controller = await _pumpPage(tester, editing: false);

      expect(find.text('Como podemos te chamar?'), findsOneWidget);
      expect(find.textContaining('só neste celular'), findsOneWidget);

      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      expect(find.text('Digite um nome ou toque em Pular.'), findsOneWidget);
      expect(controller.asked, isFalse);
    });

    testWidgets('Continuar com um nome grava e vai para a Home', (
      tester,
    ) async {
      final repository = InMemoryProfileRepository();
      final controller = await _pumpPage(
        tester,
        editing: false,
        repository: repository,
      );

      await tester.enterText(find.byType(TextFormField), 'Ana');
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      expect(controller.name, 'Ana');
      expect(await repository.loadName(), 'Ana');
      expect(find.text('HOME'), findsOneWidget);
    });

    testWidgets('Pular vai para a Home sem nome', (tester) async {
      final controller = await _pumpPage(tester, editing: false);

      await tester.tap(find.text('Pular'));
      await tester.pumpAndSettle();

      expect(controller.asked, isTrue);
      expect(controller.hasName, isFalse);
      expect(find.text('HOME'), findsOneWidget);
    });

    testWidgets('recusa mais de 30 letras', (tester) async {
      final controller = await _pumpPage(tester, editing: false);

      await tester.enterText(find.byType(TextFormField), 'a' * 31);
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      expect(find.text('Use até 30 letras.'), findsOneWidget);
      expect(controller.asked, isFalse);
    });
  });

  group('tela do nome (editar)', () {
    testWidgets('vem preenchida e Salvar troca o nome', (tester) async {
      final controller = await _pumpPage(
        tester,
        editing: true,
        repository: InMemoryProfileRepository('Ana'),
      );

      expect(find.text('Seu nome'), findsOneWidget);
      expect(find.text('Ana'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), 'Bia');
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(controller.name, 'Bia');
      expect(find.text('abrir'), findsOneWidget); // voltou
    });

    testWidgets('deixar em branco remove o nome', (tester) async {
      final controller = await _pumpPage(
        tester,
        editing: true,
        repository: InMemoryProfileRepository('Ana'),
      );

      await tester.enterText(find.byType(TextFormField), '');
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(controller.hasName, isFalse);
      expect(controller.asked, isTrue);
    });

    testWidgets('Cancelar não muda o nome', (tester) async {
      final controller = await _pumpPage(
        tester,
        editing: true,
        repository: InMemoryProfileRepository('Ana'),
      );

      await tester.enterText(find.byType(TextFormField), 'Bia');
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(controller.name, 'Ana');
      expect(find.text('abrir'), findsOneWidget);
    });
  });

  group('no app', () {
    testWidgets('a Home cumprimenta pelo nome', (tester) async {
      await _pumpApp(
        tester,
        route: AppRoutes.home,
        profile: InMemoryProfileRepository('Ana'),
      );

      expect(find.text('Olá, Ana'), findsOneWidget);
    });

    testWidgets('Configurações mostra o nome e permite trocar', (tester) async {
      final repository = InMemoryProfileRepository('Ana');
      await _pumpApp(tester, route: AppRoutes.settings, profile: repository);

      expect(find.text('Meu nome'), findsOneWidget);
      expect(find.text('Ana'), findsOneWidget);

      await tester.tap(find.text('Meu nome'));
      await tester.pump(_short);
      await tester.pump(_short);
      await tester.enterText(find.byType(TextFormField), 'Bia');
      await tester.tap(find.text('Salvar'));
      await tester.pump(_short);
      await tester.pump(_short);

      expect(find.text('Bia'), findsOneWidget);
      expect(await repository.loadName(), 'Bia');
    });

    testWidgets('sem nome, Configurações explica que é opcional', (
      tester,
    ) async {
      await _pumpApp(
        tester,
        route: AppRoutes.settings,
        profile: InMemoryProfileRepository(''),
      );

      expect(find.textContaining('Opcional'), findsOneWidget);
    });

    testWidgets('"Apagar meus dados" apaga o nome e a pergunta volta', (
      tester,
    ) async {
      final repository = InMemoryProfileRepository('Ana');
      await _pumpApp(tester, route: AppRoutes.settings, profile: repository);

      await tester.tap(find.text('Apagar meus dados'));
      await tester.pump(_short);
      await tester.tap(find.text('Apagar tudo'));
      await tester.pump(_short);
      await tester.pump(_short);

      expect(await repository.loadName(), isNull);
    });
  });
}
