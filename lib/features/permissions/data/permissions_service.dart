// As permissões do Android que o ADA usa, e como pedi-las.
//
// PermissionsService é um "contrato" (classe abstrata): diz O QUE se pode fazer,
// sem dizer COMO. O app usa a versão real (que abre o diálogo do Android); os
// testes usam a versão falsa, e nenhum teste depende do aparelho. Mesma ideia do
// AlertActions (Fase 9).
//
// Três permissões, e para quê:
//   - localização: o link do mapa que vai junto do alerta;
//   - SMS: avisar a rede automaticamente;
//   - telefone: ligar para o contato de plantão (e para o 190 e o 180).

import 'package:permission_handler/permission_handler.dart';

enum AppPermission { location, sms, phone }

enum AppPermissionStatus {
  granted, // a usuária permitiu
  denied, // negou, mas o Android ainda pergunta de novo
  permanentlyDenied, // o Android não pergunta mais: só pelas configurações
}

typedef PermissionStatuses = Map<AppPermission, AppPermissionStatus>;

abstract class PermissionsService {
  // Como estão as permissões agora (sem perguntar nada).
  Future<PermissionStatuses> statuses();

  // Pede as que faltam, uma a uma (o Android mostra um aviso para cada), e devolve
  // como ficaram.
  Future<PermissionStatuses> request();

  // Abre as configurações do app no Android (para quem negou "de vez").
  Future<bool> openSettings();
}

// Os "ganchos" abaixo existem para os testes trocarem o mundo real por falsos.
typedef PermissionStatusReader = Future<PermissionStatus> Function(
  Permission p,
);
typedef PermissionRequester = Future<PermissionStatus> Function(Permission p);
typedef SettingsOpener = Future<bool> Function();

class PlatformPermissionsService implements PermissionsService {
  PlatformPermissionsService({
    PermissionStatusReader? readStatus,
    PermissionRequester? requestPermission,
    SettingsOpener? openAppSettingsPage,
  }) : _readStatus = readStatus ?? ((p) => p.status),
       _requestPermission = requestPermission ?? ((p) => p.request()),
       _openSettings = openAppSettingsPage ?? openAppSettings;

  final PermissionStatusReader _readStatus;
  final PermissionRequester _requestPermission;
  final SettingsOpener _openSettings;

  static Permission _permissionOf(AppPermission permission) =>
      switch (permission) {
        AppPermission.location => Permission.locationWhenInUse,
        AppPermission.sms => Permission.sms,
        AppPermission.phone => Permission.phone,
      };

  static AppPermissionStatus _map(PermissionStatus status) {
    if (status.isGranted) {
      return AppPermissionStatus.granted;
    }
    if (status.isPermanentlyDenied) {
      return AppPermissionStatus.permanentlyDenied;
    }
    return AppPermissionStatus.denied;
  }

  @override
  Future<PermissionStatuses> statuses() async {
    final result = <AppPermission, AppPermissionStatus>{};
    for (final permission in AppPermission.values) {
      result[permission] = _map(await _readStatus(_permissionOf(permission)));
    }
    return result;
  }

  @override
  Future<PermissionStatuses> request() async {
    final result = <AppPermission, AppPermissionStatus>{};
    for (final permission in AppPermission.values) {
      final platform = _permissionOf(permission);
      var status = await _readStatus(platform);
      // Só pergunta o que ainda não foi dado: se já foi, não repete o aviso.
      if (!status.isGranted) status = await _requestPermission(platform);
      result[permission] = _map(status);
    }
    return result;
  }

  @override
  Future<bool> openSettings() => _openSettings();
}

// Versão para testes: o estado atual e a "resposta" da usuária ao pedido são
// combinados de antemão, e ela anota o que foi pedido.
class FakePermissionsService implements PermissionsService {
  FakePermissionsService({PermissionStatuses? current, this.afterRequest})
    : _current = {
        for (final p in AppPermission.values)
          p: current?[p] ?? AppPermissionStatus.denied,
      };

  PermissionStatuses _current;

  // O que a usuária responde ao ser perguntada (null = nada muda).
  PermissionStatuses? afterRequest;

  int requests = 0;
  int settingsOpened = 0;

  // Atalhos para os testes.
  factory FakePermissionsService.allGranted() => FakePermissionsService(
    current: {
      for (final p in AppPermission.values) p: AppPermissionStatus.granted,
    },
  );

  // A usuária concede tudo ao ser perguntada.
  factory FakePermissionsService.grantsOnRequest() => FakePermissionsService(
    afterRequest: {
      for (final p in AppPermission.values) p: AppPermissionStatus.granted,
    },
  );

  // Muda o estado "de fora" (como se a usuária tivesse ido às configurações).
  void setStatuses(PermissionStatuses statuses) =>
      _current = {..._current, ...statuses};

  @override
  Future<PermissionStatuses> statuses() async => {..._current};

  @override
  Future<PermissionStatuses> request() async {
    requests++;
    final answer = afterRequest;
    if (answer != null) _current = {..._current, ...answer};
    return {..._current};
  }

  @override
  Future<bool> openSettings() async {
    settingsOpened++;
    return true;
  }
}
