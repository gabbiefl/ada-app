// Telas de permissões: explica o que o ADA usa, pede tudo de uma vez e mostra o
// resultado. É UMA página com três "fases", que trocam conforme as respostas:
//
//   ask     "Precisamos de 3 permissões para proteger você": o pedido;
//   granted "Tudo pronto!": as três foram dadas;
//   denied  "Faltam algumas permissões": mostra o que faltou e o que acontece
//           sem cada uma (o plano B que o app já tem), com "Tentar de novo" ou,
//           se o Android bloqueou de vez, "Abrir configurações".
//
// "Agora não" e "Continuar mesmo assim" levam à Home: a usuária nunca fica presa
// aqui, e o app volta a pedir cada permissão no momento em que precisa dela.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import 'package:ada_app/core/routes/app_router.dart';
import 'package:ada_app/core/theme/app_colors.dart';
import 'package:ada_app/features/permissions/data/permissions_service.dart';
import 'package:ada_app/features/permissions/widgets/permission_card.dart';

enum _Phase { ask, granted, denied }

// O que cada permissão mostra: ícone, nome, para que serve e o que acontece sem ela.
class _Info {
  const _Info(this.icon, this.title, this.purpose, this.without);

  final IconData icon;
  final String title;
  final String purpose;
  final String without;
}

const _infos = {
  AppPermission.location: _Info(
    LucideIcons.mapPin,
    'Localização',
    'Para enviar onde você está junto com o alerta.',
    'Sem ela, o alerta vai sem o link do mapa.',
  ),
  AppPermission.sms: _Info(
    LucideIcons.messageSquare,
    'Mensagens (SMS)',
    'Para avisar a sua rede por SMS quando você ativar um alerta.',
    'Sem ela, o ADA abre o app de mensagens e você toca em enviar.',
  ),
  AppPermission.phone: _Info(
    LucideIcons.phone,
    'Telefone',
    'Para ligar rápido ao seu contato de segurança.',
    'Sem ela, o ADA abre o discador e você toca em ligar.',
  ),
};

class PermissionsPage extends StatefulWidget {
  const PermissionsPage({super.key});

  @override
  State<PermissionsPage> createState() => _PermissionsPageState();
}

class _PermissionsPageState extends State<PermissionsPage>
    with WidgetsBindingObserver {
  late final PermissionsService _service = context.read<PermissionsService>();

  _Phase _phase = _Phase.ask;
  PermissionStatuses? _statuses; // null = ainda não pedimos
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // Para saber quando a usuária volta das configurações do Android.
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Voltou das configurações: confere de novo, sem perguntar nada.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _phase == _Phase.denied) {
      _refresh();
    }
  }

  Future<void> _refresh() async {
    final statuses = await _service.statuses();
    if (!mounted) return;
    _show(statuses);
  }

  Future<void> _request() async {
    if (_busy) return;
    setState(() => _busy = true);
    final statuses = await _service.request();
    if (!mounted) return;
    _busy = false;
    _show(statuses);
  }

  // Guarda o resultado e escolhe a fase: tudo dado = granted; senão, denied.
  void _show(PermissionStatuses statuses) {
    final allGranted = statuses.values.every(
      (s) => s == AppPermissionStatus.granted,
    );
    setState(() {
      _statuses = statuses;
      _phase = allGranted ? _Phase.granted : _Phase.denied;
    });
  }

  // Alguma foi bloqueada de vez? Então pedir de novo não adianta.
  bool get _needsSettings =>
      _statuses?.values.any(
        (s) => s == AppPermissionStatus.permanentlyDenied,
      ) ??
      false;

  Future<void> _retryOrSettings() async {
    if (_needsSettings) {
      await _service.openSettings();
    } else {
      await _request();
    }
  }

  void _goHome() => context.go(AppRoutes.home);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(32, 40, 32, 16),
                child: Column(
                  crossAxisAlignment: _phase == _Phase.ask
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.center,
                  children: [
                    _Header(phase: _phase),
                    const SizedBox(height: 28),
                    for (final permission in AppPermission.values) ...[
                      _card(permission),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
              child: _buttons(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(AppPermission permission) {
    final info = _infos[permission]!;
    final status = _statuses?[permission];
    final state = PermissionCard.stateOf(status);
    return PermissionCard(
      icon: info.icon,
      title: info.title,
      // Negada: mostra o que deixa de funcionar. Senão, para que ela serve.
      description: state == PermissionCardState.denied
          ? info.without
          : info.purpose,
      state: state,
    );
  }

  Widget _buttons() {
    switch (_phase) {
      case _Phase.ask:
        return Column(
          children: [
            FilledButton(
              onPressed: _busy ? null : _request,
              child: const Text('Permitir acesso'),
            ),
            const SizedBox(height: 8),
            _TextAction(label: 'Agora não', onPressed: _goHome),
          ],
        );
      case _Phase.granted:
        return FilledButton(onPressed: _goHome, child: const Text('Continuar'));
      case _Phase.denied:
        return Column(
          children: [
            FilledButton(
              onPressed: _busy ? null : _retryOrSettings,
              child: Text(
                _needsSettings ? 'Abrir configurações' : 'Tentar de novo',
              ),
            ),
            const SizedBox(height: 8),
            _TextAction(label: 'Continuar mesmo assim', onPressed: _goHome),
          ],
        );
    }
  }
}

// Botão de texto com alvo de toque de 48, como as outras ações secundárias.
class _TextAction extends StatelessWidget {
  const _TextAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
      child: Text(label),
    );
  }
}

// Cabeçalho de cada fase: o pedido (alinhado à esquerda) ou o resultado (com um
// selo no alto: verde de "tudo pronto" ou amarelo de "faltou algo").
class _Header extends StatelessWidget {
  const _Header({required this.phase});

  final _Phase phase;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (phase == _Phase.ask) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Semantics(
            header: true,
            child: Text(
              'Precisamos de 3 permissões para proteger você',
              style: textTheme.headlineSmall?.copyWith(fontSize: 28),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Usamos cada uma para o alerta funcionar. Você pode mudar quando '
            'quiser.',
            style: textTheme.bodyLarge?.copyWith(color: AppColors.textPrimary),
          ),
        ],
      );
    }

    final granted = phase == _Phase.granted;
    return Column(
      children: [
        ExcludeSemantics(
          child: Container(
            width: 80,
            height: 80,
            decoration: ShapeDecoration(
              color: granted ? AppColors.avatarGreen : AppColors.modeAttention,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26),
              ),
            ),
            child: Icon(
              granted ? LucideIcons.check : LucideIcons.triangleAlert,
              size: 44,
              color: granted ? Colors.white : AppColors.modeNormal,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Semantics(
          header: true,
          child: Text(
            granted ? 'Tudo pronto!' : 'Faltam algumas permissões',
            textAlign: TextAlign.center,
            style: textTheme.headlineSmall?.copyWith(fontSize: 32),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          granted
              ? 'O ADA já pode enviar sua localização, mandar SMS e fazer '
                    'chamadas rápidas.'
              : 'O ADA continua funcionando, mas de um jeito menos rápido. Você '
                    'pode tentar de novo ou seguir assim.',
          textAlign: TextAlign.center,
          style: textTheme.bodyLarge?.copyWith(color: AppColors.textPrimary),
        ),
      ],
    );
  }
}
