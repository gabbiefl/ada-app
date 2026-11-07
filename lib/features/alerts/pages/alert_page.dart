// Tela "Alerta": acompanha o alerta depois de ativar o Modo Perigo ou o Modo
// Atenção. Segue o desenho do Figma: fundo na cor do modo, o símbolo do ADA com
// anéis, o título, cartões de PROGRESSO (localização, mensagens, ligação) e o
// botão "Cancelar alerta" fixo embaixo.
//
// Além do Figma, mostra PARA QUEM o aviso foi enviado e para quem falhou, em
// grupos separados. É ali que a usuária tenta de novo o que falhou e usa o
// WhatsApp (que só abre a conversa: ela precisa tocar em enviar).
//
// A tela só DESENHA o estado do AlertController: nada de lógica aqui.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import 'package:ada_app/core/routes/app_router.dart';
import 'package:ada_app/core/state/mode_controller.dart';
import 'package:ada_app/core/theme/app_colors.dart';
import 'package:ada_app/core/theme/mode_colors.dart';
import 'package:ada_app/core/widgets/confirm_dialog.dart';
import 'package:ada_app/features/alerts/data/alert_actions.dart';
import 'package:ada_app/features/alerts/state/alert_controller.dart';
import 'package:ada_app/features/alerts/state/alert_progress.dart';
import 'package:ada_app/features/alerts/widgets/delivery_card.dart';
import 'package:ada_app/features/alerts/widgets/progress_step_card.dart';
import 'package:ada_app/features/home/widgets/mode_rings.dart';
import 'package:ada_app/features/messages/models/message_kind.dart';

// StatefulWidget: guarda a animação dos anéis (como a Home).
class AlertPage extends StatefulWidget {
  const AlertPage({super.key});

  @override
  State<AlertPage> createState() => _AlertPageState();
}

class _AlertPageState extends State<AlertPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  // Abre WhatsApp, SMS ou discador e, se não der, avisa em vez de falhar calado.
  Future<void> _manual(
    Future<ActionResult> Function() action,
    String errorMessage,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await action();
    if (!result.isSuccess) {
      messenger.showSnackBar(SnackBar(content: Text(errorMessage)));
    }
  }

  // Cancelar o alerta é o mesmo que desativar o modo: confirma, volta ao Normal
  // e cancela os envios que faltam.
  Future<void> _cancelAlert() async {
    final mode = context.read<ModeController>();
    final alert = context.read<AlertController>();

    final confirmed = await showConfirmDialog(
      context,
      title: 'Cancelar o alerta?',
      message: 'O ADA volta ao modo normal e para de avisar a sua rede.',
      confirmLabel: 'Cancelar alerta',
      cancelLabel: 'Continuar',
    );
    if (!confirmed) return;

    mode.deactivate();
    alert.reset();
    if (mounted && context.canPop()) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    // watch: a tela se redesenha a cada passo do alerta.
    final alert = context.watch<AlertController>();
    final palette = _Palette.of(context, alert.kind);
    final active = alert.phase != AlertPhase.idle;

    return Scaffold(
      key: const Key('alert-page'),
      backgroundColor: palette.background,
      body: SafeArea(
        child: Column(
          children: [
            // Barra de cima: seta de voltar.
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 0, 0),
                child: IconButton(
                  onPressed: () => context.pop(),
                  icon: Icon(LucideIcons.arrowLeft, color: palette.foreground),
                  tooltip: 'Voltar',
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(32, 8, 32, 16),
                child: active
                    ? _Content(
                        alert: alert,
                        palette: palette,
                        pulse: _pulse,
                        onManual: _manual,
                      )
                    : _Idle(palette: palette),
              ),
            ),
            if (active && !alert.hasNoContacts)
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 24),
                child: _CancelButton(palette: palette, onPressed: _cancelAlert),
              ),
          ],
        ),
      ),
    );
  }
}

// Cores da tela, conforme o modo: Perigo em vermelho com texto branco; Atenção em
// amarelo com texto azul-marinho (o branco não teria contraste sobre o amarelo).
class _Palette {
  const _Palette({
    required this.background,
    required this.foreground,
    required this.card,
    required this.symbol,
    required this.title,
  });

  final Color background;
  final Color foreground;
  final Color card; // fundo escuro e translúcido dos cartões
  final String? symbol; // imagem do círculo central
  final String title;

  static _Palette of(BuildContext context, MessageKind? kind) {
    final colors = ModeColors.of(context);
    switch (kind) {
      case MessageKind.danger:
        return _Palette(
          background: colors.danger,
          foreground: Colors.white,
          card: Colors.black.withValues(alpha: 0.18),
          symbol: 'assets/images/simbolo_perigo.png',
          title: 'MODO PERIGO',
        );
      case MessageKind.attention:
        return _Palette(
          background: colors.attention,
          foreground: colors.normal,
          card: Colors.black.withValues(alpha: 0.08),
          symbol: 'assets/images/simbolo_atencao.png',
          title: 'MODO ATENÇÃO',
        );
      case MessageKind.arrived:
      case null:
        return _Palette(
          background: AppColors.background,
          foreground: AppColors.textPrimary,
          card: Colors.black.withValues(alpha: 0.06),
          symbol: null,
          title: 'Alerta',
        );
    }
  }
}

// Sem alerta em andamento (por exemplo, abrir a tela sem ter ativado nada).
class _Idle extends StatelessWidget {
  const _Idle({required this.palette});

  final _Palette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Text(
        'Nenhum alerta em andamento.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyLarge
            ?.copyWith(color: palette.foreground),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.alert,
    required this.palette,
    required this.pulse,
    required this.onManual,
  });

  final AlertController alert;
  final _Palette palette;
  final Animation<double> pulse;
  final Future<void> Function(Future<ActionResult> Function(), String) onManual;

  // A frase abaixo do título muda conforme o andamento.
  String get _subtitle {
    final danger = alert.kind == MessageKind.danger;
    if (alert.hasNoContacts) return 'Ninguém foi avisado.';
    if (alert.phase != AlertPhase.done) {
      return danger
          ? 'Sua rede está sendo alertada.'
          : 'Sua rede está sendo avisada.';
    }
    final failed = alert.deliveries.any(
      (d) => d.status == DeliveryStatus.failed,
    );
    if (failed) return 'Alguns avisos não saíram.';
    return danger ? 'Sua rede foi alertada.' : 'Sua rede foi avisada.';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final fg = palette.foreground;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // O símbolo do ADA, menor que na Home, com os anéis pulsando.
        Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              ModeRings(color: Colors.white, size: 150, pulse: pulse),
              if (palette.symbol != null)
                Container(
                  width: 92,
                  height: 92,
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: Image.asset(palette.symbol!),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          palette.title,
          textAlign: TextAlign.center,
          style: textTheme.headlineMedium?.copyWith(
            color: fg,
            fontWeight: FontWeight.w700,
            fontVariations: const [FontVariation('wght', 700)],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _subtitle,
          textAlign: TextAlign.center,
          style: textTheme.bodyLarge?.copyWith(color: fg),
        ),
        const SizedBox(height: 28),
        if (alert.demoMode) ...[
          _Banner(
            text:
                'Modo de demonstração: nada está sendo enviado de verdade, '
                'nem ligações.',
            palette: palette,
          ),
          const SizedBox(height: 12),
        ],
        if (alert.hasNoContacts)
          _NoContacts(palette: palette)
        else ...[
          for (final step in buildProgressSteps(alert)) ...[
            ProgressStepCard(
              step: step,
              foreground: fg,
              background: palette.card,
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 12),
          ..._recipients(context),
          const SizedBox(height: 4),
          Text(
            'O SMS é enviado automaticamente. O WhatsApp só abre a conversa: '
            'toque em enviar por lá. A mensagem fica no histórico do SMS e do '
            'WhatsApp deste celular.',
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(
              color: fg.withValues(alpha: 0.85),
            ),
          ),
        ],
      ],
    );
  }

  // Quem foi avisado e quem não, em grupos. Os que ainda estão sendo avisados
  // aparecem primeiro; grupos vazios não aparecem.
  List<Widget> _recipients(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDanger = alert.kind == MessageKind.danger;

    final groups = <(String, List<AlertDelivery>)>[
      (
        'Em andamento',
        [
          for (final d in alert.deliveries)
            if (d.status == DeliveryStatus.pending ||
                d.status == DeliveryStatus.sending)
              d,
        ],
      ),
      (
        'Avisados',
        [
          for (final d in alert.deliveries)
            if (d.status == DeliveryStatus.sent) d,
        ],
      ),
      (
        'Não foi possível avisar',
        [
          for (final d in alert.deliveries)
            if (d.status == DeliveryStatus.failed) d,
        ],
      ),
    ];

    return [
      for (final (title, deliveries) in groups)
        if (deliveries.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              '$title (${deliveries.length})',
              style: textTheme.titleMedium?.copyWith(color: palette.foreground),
            ),
          ),
          for (final delivery in deliveries) ...[
            DeliveryCard(
              delivery: delivery,
              canCall: isDanger,
              onWhatsApp: () => onManual(
                () => alert.openWhatsApp(delivery.contact),
                'Não foi possível abrir o WhatsApp.',
              ),
              onSms: () => onManual(
                () => alert.openSmsComposer(delivery.contact),
                'Não foi possível abrir o app de mensagens.',
              ),
              onCall: () => onManual(
                () => alert.callContact(delivery.contact),
                'Não foi possível ligar.',
              ),
              onRetry: () => alert.retry(delivery.contact),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 8),
        ],
    ];
  }
}

// Faixa de aviso (ex.: modo de demonstração) no mesmo estilo dos cartões.
class _Banner extends StatelessWidget {
  const _Banner({required this.text, required this.palette});

  final String text;
  final _Palette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.flaskConical, size: 20, color: palette.foreground),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: palette.foreground),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoContacts extends StatelessWidget {
  const _NoContacts({required this.palette});

  final _Palette palette;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Banner(
          text:
              'Você ainda não tem contatos na sua rede, então ninguém foi '
              'avisado. Cadastre alguém de confiança para o ADA poder avisar.',
          palette: palette,
        ),
        const SizedBox(height: 16),
        _WhiteButton(
          palette: palette,
          label: 'Cadastrar contato',
          onPressed: () => context.push(AppRoutes.newContact),
        ),
      ],
    );
  }
}

// Botão branco com texto na cor do modo: o "Cancelar alerta" do Figma.
class _CancelButton extends StatelessWidget {
  const _CancelButton({required this.palette, required this.onPressed});

  final _Palette palette;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return _WhiteButton(
      palette: palette,
      label: 'Cancelar alerta',
      icon: LucideIcons.x,
      onPressed: onPressed,
    );
  }
}

class _WhiteButton extends StatelessWidget {
  const _WhiteButton({
    required this.palette,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final _Palette palette;
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    // O texto do botão usa a cor escura do modo (vermelho no Perigo, azul-marinho
    // na Atenção) sobre o branco.
    final color = palette.foreground == Colors.white
        ? palette.background
        : palette.foreground;

    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: color,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
          Text(label),
        ],
      ),
    );
  }
}
