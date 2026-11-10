// Cartão de uma permissão: ícone, nome, para que serve e o estado à direita.
//
// Três estados, e a cor muda com eles:
//   - pending: ainda não pedida (azul claro, bolinha vazia);
//   - granted: concedida (verde, com ✓);
//   - denied: negada (vermelho, com ✕).
//
// Não é tocável: só informa. O leitor de tela recebe uma frase única com o nome,
// o motivo e o estado, em vez de ler as partes soltas.

import 'package:flutter/material.dart';

import 'package:ada_app/core/theme/app_colors.dart';
import 'package:ada_app/features/permissions/data/permissions_service.dart';

enum PermissionCardState { pending, granted, denied }

class PermissionCard extends StatelessWidget {
  const PermissionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.state,
  });

  final IconData icon;
  final String title;
  final String description;
  final PermissionCardState state;

  // Estado do cartão a partir do resultado do pedido. null = ainda não pedida.
  static PermissionCardState stateOf(AppPermissionStatus? status) =>
      switch (status) {
        null => PermissionCardState.pending,
        AppPermissionStatus.granted => PermissionCardState.granted,
        _ => PermissionCardState.denied,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final (accent, indicator, stateLabel) = switch (state) {
      PermissionCardState.pending => (
        AppColors.info,
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.info.withValues(alpha: 0.12),
          ),
        ),
        'ainda não pedida',
      ),
      PermissionCardState.granted => (
        AppColors.avatarGreen,
        const Icon(Icons.check_circle, size: 24, color: AppColors.avatarGreen),
        'permitida',
      ),
      PermissionCardState.denied => (
        AppColors.modeDangerText,
        const Icon(Icons.cancel, size: 24, color: AppColors.modeDangerText),
        'não permitida',
      ),
    };

    return Semantics(
      container: true,
      label: '$title, $stateLabel. $description',
      child: ExcludeSemantics(
        child: Material(
          color: Colors.white,
          elevation: 3,
          shadowColor: Colors.black.withValues(alpha: 0.25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.border),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 88),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent.withValues(alpha: 0.12),
                    ),
                    child: Icon(icon, size: 22, color: accent),
                  ),
                  const SizedBox(width: 16),
                  // Expanded: com texto grande o texto quebra e o cartão cresce.
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: theme.textTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text(description, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  indicator,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
