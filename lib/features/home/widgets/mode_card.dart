// Card de um modo de alerta (Perigo ou Atenção) da Home.
//
// Um único widget serve para os dois modos: o que muda (título, frase, ícone e
// cores) chega por parâmetros. Isso é composição: escrevemos o visual uma vez e
// reaproveitamos. As cores vêm do ModeColors, e não são escritas aqui.
//
// Acessibilidade: a altura é MÍNIMA (88), e não fixa, e o texto fica num Expanded.
// Com a fonte do sistema aumentada, o texto quebra de linha e o card cresce em
// vez de estourar a largura da tela.

import 'package:flutter/material.dart';

class ModeCard extends StatelessWidget {
  const ModeCard({
    super.key,
    required this.title,
    required this.caption,
    required this.icon,
    required this.color,
    required this.textColor,
    this.onTap,
  });

  final String title; // "MODO PERIGO"
  final String caption; // "Clique em caso de emergências."
  final IconData icon;
  final Color color; // círculo do ícone, fundo e borda (com transparência)
  final Color textColor; // título e sublinhado
  final VoidCallback? onTap; // o que fazer ao tocar (null = nada, por enquanto)

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Material + InkWell: dão o efeito de "toque" (ondinha) dentro do card.
    return Material(
      color: color.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: color.withValues(alpha: 0.5)),
      ),
      // clipBehavior: a ondinha do toque não passa das bordas arredondadas.
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        // minHeight: no tamanho normal o card tem 88, como no Figma; com texto
        // grande ele cresce.
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 88),
          child: Row(
            children: [
              const SizedBox(width: 21),
              // Círculo do ícone (46 x 44 no Figma).
              Container(
                width: 46,
                height: 44,
                decoration: ShapeDecoration(
                  color: color,
                  shape: const StadiumBorder(),
                ),
                child: Icon(icon, size: 28, color: theme.colorScheme.onPrimary),
              ),
              const SizedBox(width: 19),
              // Expanded: o texto usa o espaço que sobra e QUEBRA de linha se
              // não couber. O padding vertical dá folga quando o card cresce.
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // O sublinhado é uma borda embaixo do texto: tem a largura dele.
                      DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: textColor)),
                        ),
                        child: Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: textColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(caption, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
        ),
      ),
    );
  }
}
