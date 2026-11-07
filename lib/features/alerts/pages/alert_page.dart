// Tela "Alerta": acompanha o alerta depois de ativar o Modo Perigo ou o Modo
// Atenção.
//
// No topo, um cartão de PROGRESSO para cada etapa (localização, mensagens,
// ligação), com um ícone que gira e vira ✓. Embaixo, os DETALHES por contato,
// onde a usuária tenta de novo o que falhou e usa o WhatsApp (que só abre a
// conversa: ela precisa tocar em enviar).
//
// A tela só DESENHA o estado do AlertController: nada de lógica aqui.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import 'package:ada_app/core/routes/app_router.dart';
import 'package:ada_app/core/theme/app_colors.dart';
import 'package:ada_app/core/widgets/page_header.dart';
import 'package:ada_app/features/alerts/data/alert_actions.dart';
import 'package:ada_app/features/alerts/state/alert_controller.dart';
import 'package:ada_app/features/alerts/state/alert_progress.dart';
import 'package:ada_app/features/alerts/widgets/delivery_card.dart';
import 'package:ada_app/features/alerts/widgets/progress_step_card.dart';
import 'package:ada_app/features/messages/models/message_kind.dart';

class AlertPage extends StatelessWidget {
  const AlertPage({super.key});

  // Abre WhatsApp, SMS ou discador e, se não der, avisa em vez de falhar calado.
  Future<void> _manual(
    BuildContext context,
    Future<ActionResult> Function() action,
    String errorMessage,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await action();
    if (!result.isSuccess) {
      messenger.showSnackBar(SnackBar(content: Text(errorMessage)));
    }
  }

  @override
  Widget build(BuildContext context) {
    // watch: a tela se redesenha a cada passo do alerta.
    final alert = context.watch<AlertController>();
    final isDanger = alert.kind == MessageKind.danger;
    final subtitle = switch (alert.kind) {
      MessageKind.danger => 'Modo perigo ativo',
      MessageKind.attention => 'Modo atenção ativo',
      _ => 'Aviso à sua rede',
    };

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(40, 30, 40, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHeader(
                title: 'Alerta',
                subtitle: subtitle,
                trailing: IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(LucideIcons.arrowLeft),
                  color: AppColors.placeholder,
                  tooltip: 'Voltar',
                ),
              ),
              const SizedBox(height: 24),
              if (alert.demoMode) ...[
                const _Notice(
                  icon: LucideIcons.flaskConical,
                  color: AppColors.info,
                  text:
                      'Modo de demonstração: nada está sendo enviado de '
                      'verdade, nem ligações.',
                ),
                const SizedBox(height: 16),
              ],
              ..._body(context, alert, isDanger),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _body(
    BuildContext context,
    AlertController alert,
    bool isDanger,
  ) {
    if (alert.phase == AlertPhase.idle) {
      return const [
        _Notice(
          icon: LucideIcons.info,
          color: AppColors.info,
          text: 'Nenhum alerta em andamento.',
        ),
      ];
    }
    if (alert.hasNoContacts) return [_NoContacts()];

    return [
      // Progresso: um cartão por etapa.
      for (final step in buildProgressSteps(alert)) ...[
        ProgressStepCard(step: step),
        const SizedBox(height: 12),
      ],
      const SizedBox(height: 12),
      Text(
        'Detalhes por contato',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 12),
      for (final delivery in alert.deliveries) ...[
        DeliveryCard(
          delivery: delivery,
          canCall: isDanger,
          onWhatsApp: () => _manual(
            context,
            () => alert.openWhatsApp(delivery.contact),
            'Não foi possível abrir o WhatsApp.',
          ),
          onSms: () => _manual(
            context,
            () => alert.openSmsComposer(delivery.contact),
            'Não foi possível abrir o app de mensagens.',
          ),
          onCall: () => _manual(
            context,
            () => alert.callContact(delivery.contact),
            'Não foi possível ligar.',
          ),
          onRetry: () => alert.retry(delivery.contact),
        ),
        const SizedBox(height: 12),
      ],
      const SizedBox(height: 4),
      const _Notice(
        icon: LucideIcons.info,
        color: AppColors.info,
        text:
            'O SMS é enviado automaticamente. O WhatsApp só abre a '
            'conversa: toque em enviar por lá. A mensagem fica no '
            'histórico do SMS e do WhatsApp deste celular.',
      ),
    ];
  }
}

class _NoContacts extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Notice(
          icon: LucideIcons.triangleAlert,
          color: AppColors.modeDangerText,
          text:
              'Você ainda não tem contatos na sua rede, então ninguém foi '
              'avisado. Cadastre alguém de confiança para o ADA poder avisar.',
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => context.push(AppRoutes.newContact),
          child: const Text('Cadastrar contato'),
        ),
      ],
    );
  }
}

// Caixa colorida com ícone e texto, no mesmo estilo das outras telas.
class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
