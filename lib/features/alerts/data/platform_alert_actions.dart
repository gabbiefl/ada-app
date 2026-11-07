// A versão REAL do AlertActions: manda SMS e liga de verdade.
//
// Três peças trabalham juntas:
//   - o código nativo em Kotlin (MainActivity), pelo MethodChannel: envia o SMS
//     direto e faz a ligação direta, sem abrir outro app;
//   - o permission_handler: pede à usuária as permissões de SMS e de ligação;
//   - o url_launcher: abre o app de SMS, o discador ou o WhatsApp (plano B e
//     reforço), onde a usuária toca em enviar ou ligar.
//
// Plano B é decidido por QUEM USA esta classe (o AlertController): aqui cada
// ação só devolve se deu certo ou o motivo da falha.
//
// O telefone e o texto NUNCA são impressos nem guardados (Fase 0, P6).

import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:ada_app/features/alerts/data/alert_actions.dart';
import 'package:ada_app/features/alerts/utils/alert_urls.dart';

// Os "ganchos" abaixo existem para os testes trocarem o mundo real por falsos.
// No app ficam os valores padrão (permission_handler e url_launcher de verdade).
typedef PermissionAsker = Future<bool> Function(Permission permission);
typedef UrlOpener = Future<bool> Function(Uri uri);

class PlatformAlertActions implements AlertActions {
  PlatformAlertActions({
    MethodChannel? channel,
    PermissionAsker? askPermission,
    UrlOpener? openUrl,
  }) : _channel = channel ?? const MethodChannel(channelName),
       _askPermission = askPermission ?? _defaultAsk,
       _openUrl = openUrl ?? _defaultOpen;

  // Precisa ser igual ao CHANNEL do MainActivity.kt.
  static const channelName = 'br.academico.cesuca.ada/emergency';

  final MethodChannel _channel;
  final PermissionAsker _askPermission;
  final UrlOpener _openUrl;

  static Future<bool> _defaultAsk(Permission permission) async {
    // Se já foi dada, não pergunta de novo; senão, abre o diálogo do Android.
    if (await permission.isGranted) return true;
    return (await permission.request()).isGranted;
  }

  // externalApplication: abre FORA do ADA (no app de SMS, no discador, etc.).
  static Future<bool> _defaultOpen(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);

  @override
  Future<bool> requestPermissions() async {
    final sms = await _askPermission(Permission.sms);
    final phone = await _askPermission(Permission.phone);
    return sms && phone;
  }

  @override
  Future<ActionResult> sendSms(String phone, String text) async {
    if (!await _askPermission(Permission.sms)) {
      return const ActionResult.failure(ActionFailure.permissionDenied);
    }
    return _invoke('sendSms', {
      'phone': internationalPhone(phone),
      'text': text,
    });
  }

  @override
  Future<ActionResult> call(String phone) async {
    if (!await _askPermission(Permission.phone)) {
      return const ActionResult.failure(ActionFailure.permissionDenied);
    }
    return _invoke('call', {'phone': internationalPhone(phone)});
  }

  @override
  Future<ActionResult> openSmsComposer(String phone, String text) =>
      _open(smsComposerUri(phone, text));

  @override
  Future<ActionResult> openDialer(String phone) => _open(dialerUri(phone));

  @override
  Future<ActionResult> openWhatsApp(String phone, String text) =>
      _open(whatsAppUri(phone, text));

  // Chama o Kotlin e traduz o código de erro dele para um ActionFailure.
  Future<ActionResult> _invoke(
    String method,
    Map<String, String> arguments,
  ) async {
    try {
      await _channel.invokeMethod<bool>(method, arguments);
      return const ActionResult.success();
    } on PlatformException catch (e) {
      switch (e.code) {
        case 'permission_denied':
          return const ActionResult.failure(ActionFailure.permissionDenied);
        case 'not_available':
          return const ActionResult.failure(ActionFailure.notAvailable);
        default:
          return const ActionResult.failure(ActionFailure.failed);
      }
    } on MissingPluginException {
      // Sem o lado nativo (por exemplo, no Chrome): indisponível, sem quebrar.
      return const ActionResult.failure(ActionFailure.notAvailable);
    } catch (_) {
      return const ActionResult.failure(ActionFailure.failed);
    }
  }

  Future<ActionResult> _open(Uri uri) async {
    try {
      final opened = await _openUrl(uri);
      return opened
          ? const ActionResult.success()
          : const ActionResult.failure(ActionFailure.notAvailable);
    } catch (_) {
      return const ActionResult.failure(ActionFailure.notAvailable);
    }
  }
}
