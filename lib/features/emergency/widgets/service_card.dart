// Cartão de um serviço público (190 ou 180) na Home.
//
// Branco com borda, para parecer diferente dos cartões coloridos dos modos: aqui
// a ação é ligar para um serviço de fora, e não ativar o ADA.
//
// Acessibilidade: a altura é MÍNIMA (88) e o texto fica num Expanded, então com a
// fonte do sistema aumentada o texto quebra de linha e o cartão cresce.

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:ada_app/core/theme/app_colors.dart';
import 'package:ada_app/features/emergency/models/emergency_service.dart';

class ServiceCard extends StatelessWidget {
  const ServiceCard({
    super.key,
    required this.service,
    required this.icon,
    this.onTap,
  });

  final EmergencyService service;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Um nome só para o leitor de tela, com o que o toque faz.
    return Semantics(
      button: true,
      label: 'Ligar para o ${service.number}, ${service.name}',
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 88),
            child: Row(
              children: [
                const SizedBox(width: 21),
                Container(
                  width: 46,
                  height: 44,
                  decoration: const ShapeDecoration(
                    color: AppColors.modeNormal,
                    shape: StadiumBorder(),
                  ),
                  child: Icon(
                    icon,
                    size: 24,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(width: 19),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${service.title} · ${service.name}',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 3),
                        Text(service.summary, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Ícone de cada serviço (190: telefone; 180: atendimento).
IconData serviceIcon(EmergencyService service) =>
    service.number == '180' ? LucideIcons.headset : LucideIcons.phoneCall;
