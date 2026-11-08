// Item de menu da tela Configurações: ícone rosa num círculo, título, descrição
// e uma seta à direita. Cada item leva a outra tela (a navegação entra na Fase 4).

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:ada_app/core/theme/app_colors.dart';

class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.onTap,
    this.accent,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onTap;

  // Cor do ícone e do círculo (padrão: o rosa da marca). O item que apaga dados
  // usa vermelho, para a usuária perceber que é uma ação delicada.
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = this.accent ?? theme.colorScheme.tertiary; // rosa da marca

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
          padding: const EdgeInsets.symmetric(horizontal: 21, vertical: 21),
          child: Row(
            // start: o círculo do ícone fica alinhado ao topo do texto.
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 44,
                decoration: ShapeDecoration(
                  color: accent.withValues(alpha: 0.15),
                  shape: const StadiumBorder(),
                ),
                child: Icon(icon, size: 24, color: accent),
              ),
              const SizedBox(width: 19),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(description, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Padding no topo para a seta ficar na altura do título e da descrição.
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Icon(
                  LucideIcons.arrowRight,
                  size: 21,
                  color: AppColors.placeholder,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
