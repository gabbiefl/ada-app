// Caixa azul informativa da tela de cadastro: lembra de combinar com a pessoa
// antes, porque em caso de alerta ela receberá SMS e ligações do ADA. O texto
// mistura normal e negrito (Text.rich).
//
// O ADA ainda NÃO avisa a pessoa no momento do cadastro (a ideia de mandar um SMS
// de boas-vindas está no backlog, F9-07), então o texto não promete isso.

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:ada_app/core/theme/app_colors.dart';

class InfoBox extends StatelessWidget {
  const InfoBox({super.key});

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
            // Text.rich: um texto com pedaços (TextSpan) de estilos diferentes.
            child: Text.rich(
              TextSpan(
                style: style,
                children: const [
                  TextSpan(
                    text: 'Combine com essa pessoa antes: ',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontVariations: [FontVariation('wght', 700)],
                    ),
                  ),
                  TextSpan(
                    text: 'em caso de alerta, ela receberá SMS e ligações do ADA.',
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
