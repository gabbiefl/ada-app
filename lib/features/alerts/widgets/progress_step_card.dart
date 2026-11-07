// Cartão de uma etapa do alerta, com um ícone de estado: carregando (girando),
// concluído, com ressalva ou com falha. É o "indicador de progresso" da tela.

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:ada_app/core/theme/app_colors.dart';
import 'package:ada_app/features/alerts/state/alert_progress.dart';

class ProgressStepCard extends StatelessWidget {
  const ProgressStepCard({super.key, required this.step});

  final ProgressStep step;

  Color get _color {
    switch (step.state) {
      case ProgressState.pending:
        return AppColors.textSecondary;
      case ProgressState.loading:
        return AppColors.info;
      case ProgressState.done:
        return AppColors.avatarGreen;
      case ProgressState.warning:
        return AppColors.modeAttentionText;
      case ProgressState.failed:
        return AppColors.modeDangerText;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _color;

    // Semantics: o leitor de tela lê o cartão como uma frase só.
    return Semantics(
      container: true,
      label: '${step.title}. ${step.detail}',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              _StateIcon(state: step.state, color: color),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(step.title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      step.detail,
                      style: theme.textTheme.bodySmall?.copyWith(color: color),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// O ícone da esquerda: gira enquanto carrega e vira ✓ ou aviso depois.
class _StateIcon extends StatelessWidget {
  const _StateIcon({required this.state, required this.color});

  final ProgressState state;
  final Color color;

  @override
  Widget build(BuildContext context) {
    const size = 26.0;

    if (state == ProgressState.loading) {
      return SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(strokeWidth: 3, color: color),
      );
    }

    final icon = switch (state) {
      ProgressState.pending => LucideIcons.clock,
      ProgressState.done => LucideIcons.circleCheck,
      ProgressState.warning => LucideIcons.triangleAlert,
      _ => LucideIcons.circleX,
    };
    return Icon(icon, size: size, color: color);
  }
}
