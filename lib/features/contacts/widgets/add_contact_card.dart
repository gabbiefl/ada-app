// Espaço vazio da rede: "Adicionar contato", com borda tracejada.
//
// O Flutter não tem borda tracejada pronta, então desenhamos com CustomPainter:
// um "pincel" próprio que recebe a tela de desenho (canvas) e traça o contorno.
//
// Acessibilidade: a altura é MÍNIMA (88) e o texto fica num Expanded, então com a
// fonte do sistema aumentada o texto quebra de linha e o card cresce.

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:ada_app/core/theme/app_colors.dart';

class AddContactCard extends StatelessWidget {
  const AddContactCard({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: CustomPaint(
        painter: const _DashedBorderPainter(
          color: AppColors.placeholder,
          radius: 20,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 88),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 21, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 44,
                  decoration: const ShapeDecoration(
                    color: AppColors.placeholder,
                    shape: StadiumBorder(),
                  ),
                  child: Icon(
                    LucideIcons.plus,
                    size: 24,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 19),
                // Expanded: o texto quebra de linha se não couber.
                Expanded(
                  child: Text(
                    'Adicionar contato',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // O contorno do card como um caminho (path) de cantos arredondados.
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      );

    // Percorremos o caminho de pedaço em pedaço: desenha 5, pula 4, e repete.
    const dash = 5.0;
    const gap = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + dash), paint);
        distance += dash + gap;
      }
    }
  }

  // Só redesenha se a cor ou o raio mudarem.
  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}
