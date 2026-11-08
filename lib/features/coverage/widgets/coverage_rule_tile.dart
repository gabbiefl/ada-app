// Cartão de uma faixa de horário, como no Figma: ícone do período (sol, pôr do sol
// ou lua), o horário, "Ligar para <contato>" e a chave liga/desliga.
//
// Faixa desligada fica apagada e diz "Desligada": continua salva, mas não vale.

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:ada_app/core/theme/app_colors.dart';
import 'package:ada_app/features/coverage/models/coverage_rule.dart';
import 'package:ada_app/features/coverage/utils/coverage_logic.dart';

class CoverageRuleTile extends StatelessWidget {
  const CoverageRuleTile({
    super.key,
    required this.rule,
    required this.contactName,
    required this.onToggle,
    this.onTap,
  });

  final CoverageRule rule;
  final String contactName;

  // A usuária mexeu na chave (true = ligar, false = desligar).
  final ValueChanged<bool> onToggle;

  // Tocar no cartão (abre a edição).
  final VoidCallback? onTap;

  // Ícone e cores de cada período do dia.
  ({IconData icon, Color tint, Color color}) get _look {
    switch (periodOf(rule.start)) {
      case CoveragePeriod.day:
        return (
          icon: LucideIcons.sun,
          tint: AppColors.modeAttention,
          color: AppColors.modeAttentionText,
        );
      case CoveragePeriod.sunset:
        return (
          icon: LucideIcons.sunset,
          tint: AppColors.brand,
          color: AppColors.brand,
        );
      case CoveragePeriod.night:
        return (
          icon: LucideIcons.moonStar,
          tint: AppColors.modeNormal,
          color: AppColors.modeNormal,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final look = _look;

    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.placeholder.withValues(alpha: 0.3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          // Opacity: a faixa desligada fica "apagada", mas continua legível.
          child: Opacity(
            opacity: rule.enabled ? 1 : 0.55,
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: look.tint.withValues(alpha: 0.15),
                  ),
                  child: Icon(look.icon, size: 24, color: look.color),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formatRange(rule),
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      // Text.rich: "Ligar para" normal e o nome em destaque.
                      Text.rich(
                        TextSpan(
                          style: theme.textTheme.bodySmall,
                          children: [
                            const TextSpan(text: 'Ligar para '),
                            TextSpan(
                              text: contactName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontVariations: [FontVariation('wght', 700)],
                              ),
                            ),
                            if (!rule.enabled)
                              const TextSpan(text: ' · Desligada'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Semantics: o leitor de tela anuncia o que a chave faz.
                Semantics(
                  label: 'Faixa ${formatRange(rule)}, $contactName',
                  child: Switch(value: rule.enabled, onChanged: onToggle),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
