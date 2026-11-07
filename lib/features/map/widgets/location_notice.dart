// Caixa azul que explica, ANTES do diálogo do Android, por que o ADA precisa da
// localização e o que faz com ela (Fase 0, P2: pedir a permissão com contexto).

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:ada_app/core/theme/app_colors.dart';

class LocationNotice extends StatelessWidget {
  const LocationNotice({super.key});

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
            child: Text(
              'O ADA usa a sua localização só quando você toca no botão '
              'abaixo, para mostrar onde você está e, nos alertas, avisar a '
              'sua rede. Ela não é guardada no aparelho.',
              style: style,
            ),
          ),
        ],
      ),
    );
  }
}
