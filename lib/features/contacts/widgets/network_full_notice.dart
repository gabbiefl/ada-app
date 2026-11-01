// Aviso da rede cheia (5/5): aparece no lugar dos espaços "Adicionar contato".
//
// Não existe no Figma. O visual é derivado da InfoBox (caixa azul com ícone),
// para combinar com o resto do app. Revisar com a designer se necessário.

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:ada_app/core/theme/app_colors.dart';

class NetworkFullNotice extends StatelessWidget {
  const NetworkFullNotice({super.key, required this.limit});

  // Limite da rede (5), para o texto não repetir o número fixo.
  final int limit;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: AppColors.info);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.badgeInfo, size: 22, color: AppColors.info),
          const SizedBox(width: 19),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: style,
                children: [
                  TextSpan(
                    text: 'Sua rede está completa ($limit/$limit). ',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontVariations: [FontVariation('wght', 700)],
                    ),
                  ),
                  const TextSpan(
                    text: 'Para adicionar outra pessoa, remova um contato.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
