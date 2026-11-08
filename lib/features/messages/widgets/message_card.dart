// Card de uma mensagem pré-definida: ponto colorido do modo, título, texto e o
// link "Editar".

import 'package:flutter/material.dart';

import 'package:ada_app/core/theme/app_colors.dart';

class MessageCard extends StatelessWidget {
  const MessageCard({
    super.key,
    required this.title,
    required this.text,
    required this.color,
    this.onEdit,
  });

  final String title;
  final String text;
  final Color color; // cor do pontinho (modo ao qual a mensagem pertence)
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 21, 18, 21),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.placeholder.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // O ponto fica um pouco abaixo do topo para alinhar com o título.
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(text, style: theme.textTheme.bodySmall),
                // Espaço no fim: o card tem altura mínima (139 no Figma).
                const SizedBox(height: 30),
              ],
            ),
          ),
          // Área de toque de 48 x 48 (o texto sozinho é pequeno demais). O nome
          // inclui o título, porque há três links "Editar" na mesma tela.
          Semantics(
            button: true,
            label: 'Editar $title',
            child: InkWell(
              onTap: onEdit,
              child: ExcludeSemantics(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  // O texto continua no canto de cima, onde estava no Figma.
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Text(
                      'Editar',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontVariations: const [FontVariation('wght', 600)],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
