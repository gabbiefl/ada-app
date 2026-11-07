// Cartão de uma etapa do alerta, com um ícone de estado: carregando (girando),
// concluído, com ressalva ou com falha. É o "indicador de progresso" da tela.
//
// Como a tela Alerta tem o fundo na cor do modo (vermelho no Perigo, amarelo na
// Atenção), o cartão não escolhe cores sozinho: recebe a cor do texto e do fundo.
// O estado (✓, aviso, relógio, girando) aparece no ÍCONE, e não numa cor.

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:ada_app/features/alerts/state/alert_progress.dart';

class ProgressStepCard extends StatelessWidget {
  const ProgressStepCard({
    super.key,
    required this.step,
    required this.foreground,
    required this.background,
  });

  final ProgressStep step;

  // Cor do texto e dos ícones.
  final Color foreground;

  // Cor de fundo do cartão (escura e translúcida, como no Figma).
  final Color background;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Semantics: o leitor de tela lê o cartão como uma frase só.
    return Semantics(
      container: true,
      label: '${step.title}. ${step.detail}',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: foreground,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      step.detail,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: foreground.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              _StateIcon(state: step.state, color: foreground),
            ],
          ),
        ),
      ),
    );
  }
}

// O ícone da direita: gira enquanto carrega e vira ✓ ou aviso depois.
class _StateIcon extends StatelessWidget {
  const _StateIcon({required this.state, required this.color});

  final ProgressState state;
  final Color color;

  @override
  Widget build(BuildContext context) {
    const size = 24.0;

    if (state == ProgressState.loading) {
      return SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(strokeWidth: 2.5, color: color),
      );
    }

    final icon = switch (state) {
      ProgressState.pending => LucideIcons.clock,
      ProgressState.done => LucideIcons.check,
      ProgressState.warning => LucideIcons.triangleAlert,
      _ => LucideIcons.circleX,
    };
    return Icon(icon, size: size, color: color);
  }
}
