// Testa as telas de permissões (pedido, concedidas e negadas) e o serviço que
// pede as permissões. Nenhum teste abre um diálogo do Android: o serviço é falso.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'package:ada_app/core/routes/app_router.dart';
import 'package:ada_app/core/theme/app_theme.dart';
import 'package:ada_app/features/permissions/data/permissions_service.dart';
import 'package:ada_app/features/permissions/pages/permissions_page.dart';

import '../support/app_font.dart';

Future<void> _pumpPage(WidgetTester tester, PermissionsService service) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);

  final router = GoRouter(
    initialLocation: AppRoutes.permissions,
    routes: [
      GoRoute(
        path: AppRoutes.permissions,
        builder: (context, state) => const PermissionsPage(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const Scaffold(body: Text('HOME')),
      ),
    ],
  );

  await tester.pumpWidget(
    Provider<PermissionsService>.value(
      value: service,
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

// Estado de cada permissão, na ordem localização, SMS, telefone.
PermissionStatuses _statuses(
  AppPermissionStatus location,
  AppPermissionStatus sms,
  AppPermissionStatus phone,
) => {
  AppPermission.location: location,
  AppPermission.sms: sms,
  AppPermission.phone: phone,
};

const _granted = AppPermissionStatus.granted;
const _denied = AppPermissionStatus.denied;
const _blocked = AppPermissionStatus.permanentlyDenied;

void main() {
  setUpAll(loadAppFont);

  group('PlatformPermissionsService', () {
    test('traduz o estado do Android para o do ADA', () async {
      final answers = {
        Permission.locationWhenInUse: PermissionStatus.granted,
        Permission.sms: PermissionStatus.denied,
        Permission.phone: PermissionStatus.permanentlyDenied,
      };
      final service = PlatformPermissionsService(
        readStatus: (p) async => answers[p]!,
      );

      expect(await service.statuses(), _statuses(_granted, _denied, _blocked));
    });

    test('só pede o que ainda falta', () async {
      final asked = <Permission>[];
      final service = PlatformPermissionsService(
        readStatus: (p) async => p == Permission.locationWhenInUse
            ? PermissionStatus.granted
            : PermissionStatus.denied,
        requestPermission: (p) async {
          asked.add(p);
          return PermissionStatus.granted;
        },
      );

      final result = await service.request();

      expect(asked, [Permission.sms, Permission.phone]);
      expect(result, _statuses(_granted, _granted, _granted));
    });

    test('abre as configurações do app', () async {
      var opened = 0;
      final service = PlatformPermissionsService(
        openAppSettingsPage: () async {
          opened++;
          return true;
        },
      );

      expect(await service.openSettings(), isTrue);
      expect(opened, 1);
    });
  });

  group('tela de pedido', () {
    testWidgets('explica as três permissões, com SMS no lugar de Contatos', (
      tester,
    ) async {
      await _pumpPage(tester, FakePermissionsService());

      expect(
        find.text('Precisamos de 3 permissões para proteger você'),
        findsOneWidget,
      );
      expect(find.text('Localização'), findsOneWidget);
      expect(find.text('Mensagens (SMS)'), findsOneWidget);
      expect(find.text('Telefone'), findsOneWidget);
      // O ADA não lê a agenda, então não pede essa permissão.
      expect(find.text('Contatos'), findsNothing);
      expect(find.text('Permitir acesso'), findsOneWidget);
      expect(find.text('Agora não'), findsOneWidget);
    });

    testWidgets('Agora não vai para a Home sem pedir nada', (tester) async {
      final service = FakePermissionsService();
      await _pumpPage(tester, service);

      await tester.tap(find.text('Agora não'));
      await tester.pumpAndSettle();

      expect(find.text('HOME'), findsOneWidget);
      expect(service.requests, 0);
    });
  });

  group('tela de concedidas', () {
    testWidgets(
      'com tudo permitido mostra "Tudo pronto!" e segue para a Home',
      (tester) async {
        final service = FakePermissionsService.grantsOnRequest();
        await _pumpPage(tester, service);

        await tester.tap(find.text('Permitir acesso'));
        await tester.pumpAndSettle();

        expect(service.requests, 1);
        expect(find.text('Tudo pronto!'), findsOneWidget);
        expect(find.byIcon(Icons.check_circle), findsNWidgets(3));
        expect(find.text('Permitir acesso'), findsNothing);

        await tester.tap(find.text('Continuar'));
        await tester.pumpAndSettle();
        expect(find.text('HOME'), findsOneWidget);
      },
    );
  });

  group('tela de negadas', () {
    testWidgets('mostra o que faltou e o que acontece sem cada permissão', (
      tester,
    ) async {
      final service = FakePermissionsService(
        afterRequest: _statuses(_granted, _denied, _denied),
      );
      await _pumpPage(tester, service);

      await tester.tap(find.text('Permitir acesso'));
      await tester.pumpAndSettle();

      expect(find.text('Faltam algumas permissões'), findsOneWidget);
      expect(find.text('Tudo pronto!'), findsNothing);
      // Uma concedida e duas negadas.
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsNWidgets(2));
      // Nas negadas, o texto é o do plano B; na concedida, o do motivo.
      expect(find.textContaining('abre o app de mensagens'), findsOneWidget);
      expect(find.textContaining('abre o discador'), findsOneWidget);
      expect(find.textContaining('sem o link do mapa'), findsNothing);
      expect(find.text('Tentar de novo'), findsOneWidget);
      expect(find.text('Abrir configurações'), findsNothing);
    });

    testWidgets(
      'Tentar de novo pede de novo e, se agora der, mostra tudo pronto',
      (tester) async {
        final service = FakePermissionsService(
          afterRequest: _statuses(_granted, _denied, _granted),
        );
        await _pumpPage(tester, service);
        await tester.tap(find.text('Permitir acesso'));
        await tester.pumpAndSettle();
        expect(find.text('Faltam algumas permissões'), findsOneWidget);

        // Desta vez ela permite.
        service.afterRequest = _statuses(_granted, _granted, _granted);
        await tester.tap(find.text('Tentar de novo'));
        await tester.pumpAndSettle();

        expect(service.requests, 2);
        expect(find.text('Tudo pronto!'), findsOneWidget);
      },
    );

    testWidgets(
      'bloqueada de vez: oferece as configurações, e confere ao voltar',
      (tester) async {
        final service = FakePermissionsService(
          afterRequest: _statuses(_granted, _blocked, _granted),
        );
        await _pumpPage(tester, service);
        await tester.tap(find.text('Permitir acesso'));
        await tester.pumpAndSettle();

        expect(find.text('Abrir configurações'), findsOneWidget);
        expect(find.text('Tentar de novo'), findsNothing);

        await tester.tap(find.text('Abrir configurações'));
        await tester.pumpAndSettle();
        expect(service.settingsOpened, 1);
        // Abrir as configurações NÃO pede de novo.
        expect(service.requests, 1);

        // Ela permitiu nas configurações do Android e volta ao app.
        service.setStatuses(_statuses(_granted, _granted, _granted));
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pumpAndSettle();

        expect(find.text('Tudo pronto!'), findsOneWidget);
      },
    );

    testWidgets('Continuar mesmo assim vai para a Home', (tester) async {
      final service = FakePermissionsService(
        afterRequest: _statuses(_denied, _denied, _denied),
      );
      await _pumpPage(tester, service);
      await tester.tap(find.text('Permitir acesso'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continuar mesmo assim'));
      await tester.pumpAndSettle();

      expect(find.text('HOME'), findsOneWidget);
    });
  });
}
