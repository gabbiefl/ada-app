// Card de um contato de confiança: avatar com iniciais, nome, telefone e um "x"
// para remover. Os dados chegam por parâmetro (por enquanto vêm da tela, fixos).

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:ada_app/core/theme/app_colors.dart';

class ContactCard extends StatelessWidget {
  const ContactCard({
    super.key,
    required this.name,
    required this.phone,
    required this.color,
    this.onTap,
    this.onRemove,
  });

  final String name;
  final String phone;
  final Color color; // cor do avatar
  final VoidCallback? onTap; // tocar no card (abre a edição)
  final VoidCallback? onRemove; // tocar no "x"

  // Iniciais: primeira letra do primeiro e do último nome ("Gabriela Flores" -> "GF").
  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // GestureDetector: faz o card inteiro reagir ao toque. O "x" abaixo tem o
    // próprio toque e tem prioridade sobre este.
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: _buildCard(theme),
    );
  }

  Widget _buildCard(ThemeData theme) {
    // minHeight (e não height): no tamanho normal o card tem 88, como no Figma; com a
    // fonte do sistema aumentada ele cresce em vez de estourar a altura.
    return Container(
      constraints: const BoxConstraints(minHeight: 88),
      padding: const EdgeInsets.symmetric(horizontal: 21, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.placeholder.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 44,
            alignment: Alignment.center,
            decoration: ShapeDecoration(
              color: color,
              shape: const StadiumBorder(),
            ),
            child: Text(
              _initials,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ),
          const SizedBox(width: 19),
          // Expanded: o texto ocupa o espaço entre o avatar e o "x".
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: theme.textTheme.titleMedium),
                Text(phone, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          // O ícone é pequeno (12), mas a área de toque tem 48x48 e o leitor
          // de tela anuncia "Remover <nome>" (acessibilidade).
          Semantics(
            button: true,
            label: 'Remover $name',
            child: InkResponse(
              onTap: onRemove,
              child: const SizedBox(
                width: 48,
                height: 48,
                child: Icon(
                  LucideIcons.x,
                  size: 12,
                  color: AppColors.iconMuted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
