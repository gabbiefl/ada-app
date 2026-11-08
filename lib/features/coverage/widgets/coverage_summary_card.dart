// Cartão "Cobertura das 24 horas": uma barra do dia (de 0h a 24h) com os trechos
// cobertos em verde e os BURACOS (horas sem faixa) em amarelo, e um texto que diz
// o que acontece nos buracos.
//
// Quando as faixas cobrem o dia inteiro, o título é "Cobertura das 24 horas", como
// no Figma. Quando há buracos, o título diz quanto está coberto ("Cobertura de 22
// horas") e o texto lista os buracos e para quem o ADA liga neles.
//
// A barra é feita com uma Row de trechos, cada um com `flex` igual aos seus
// minutos: o Flutter reparte a largura na proporção certa, sem desenho manual.

import 'package:flutter/material.dart';

import 'package:ada_app/core/theme/app_colors.dart';
import 'package:ada_app/features/coverage/models/coverage_rule.dart';
import 'package:ada_app/features/coverage/utils/coverage_logic.dart';

// 90 -> '1 h 30 min'; 120 -> '2 horas'; 45 -> '45 min'.
String formatDuration(int minutes) {
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  if (hours == 0) return '$rest min';
  if (rest > 0) return '$hours h $rest min';
  return hours == 1 ? '1 hora' : '$hours horas';
}

// O título do cartão, conforme quanto do dia está coberto.
String coverageTitle({required int coveredMinutes, required bool hasRules}) {
  if (coveredMinutes >= minutesPerDay) return 'Cobertura das 24 horas';
  if (!hasRules) return 'Nenhuma faixa criada';
  if (coveredMinutes == 0) return 'Nenhuma faixa ligada';
  return 'Cobertura de ${formatDuration(coveredMinutes)}';
}

// '13:00 - 15:00' (o fim do dia aparece como 24:00).
String formatSpan(Span span) =>
    '${formatMinutes(span.start)} - ${formatMinutes(span.end)}';

class CoverageSummaryCard extends StatelessWidget {
  const CoverageSummaryCard({
    super.key,
    required this.rules,
    required this.fallbackName,
  });

  // As faixas que a usuária está vendo na lista (a barra mostra as ligadas).
  final List<CoverageRule> rules;

  // Quem o ADA liga fora das faixas (o primeiro da lista), ou null sem contatos.
  final String? fallbackName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final covered = coveredSpans(rules);
    final holes = gaps(rules);
    final minutes = coveredMinutes(rules);
    final title = coverageTitle(
      coveredMinutes: minutes,
      hasRules: rules.isNotEmpty,
    );

    // Trechos cobertos e buracos, juntos e em ordem, para desenhar a barra.
    final segments = <({Span span, bool isCovered})>[
      for (final s in covered) (span: s, isCovered: true),
      for (final s in holes) (span: s, isCovered: false),
    ]..sort((a, b) => a.span.start.compareTo(b.span.start));

    final holesText = holes.map(formatSpan).join(', ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.placeholder.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 14),
          // A barra do dia: cada trecho ocupa a largura proporcional aos minutos.
          Semantics(
            label: holes.isEmpty
                ? title
                : '$title. Sem faixa nos horários: $holesText.',
            child: ExcludeSemantics(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  height: 8,
                  child: Row(
                    children: [
                      for (final seg in segments)
                        Expanded(
                          flex: seg.span.end - seg.span.start,
                          child: ColoredBox(
                            color: seg.isCovered
                                ? AppColors.avatarGreen
                                : AppColors.modeAttention,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          ExcludeSemantics(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final hour in const ['0h', '6h', '12h', '18h', '24h'])
                  Text(hour, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          if (holes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              rules.isEmpty
                  ? 'Sem faixas, o ADA liga sempre'
                        '${fallbackName == null ? '' : ' para $fallbackName'}'
                        ' (o primeiro da lista).'
                  : 'Sem faixa: $holesText.'
                        '${fallbackName == null ? '' : ' Nesses horários, o ADA liga para $fallbackName (o primeiro da lista).'}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
