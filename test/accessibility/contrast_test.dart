// Contraste das cores do ADA, calculado com a fórmula EXATA do WCAG 2.1.
//
// Por que não usar só a guideline de contraste do Flutter (textContrastGuideline)?
// Ela mede por CAPTURA DE TELA, e o texto do ADA usa a fonte em peso fino (300), em
// que os traços finos se misturam ao fundo: ela acusa contraste baixo (1,9) para
// uma cor que, calculada, tem 4,6. Aqui o número é exato e não depende do desenho.
//
// Mínimos do WCAG AA:
//   - texto normal: 4,5 para 1
//   - ícones e elementos de interface que carregam informação: 3 para 1
//
// Um par que ainda não passa fica em [_knownIssues], com o motivo: o teste é
// PULADO e aparece no relatório. Ao corrigir a cor, a linha é apagada.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ada_app/core/theme/app_colors.dart';

// Luminância relativa (WCAG): o quanto uma cor "brilha", de 0 (preto) a 1 (branco).
double _luminance(Color color) {
  double channel(double c) =>
      c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(color.r) +
      0.7152 * channel(color.g) +
      0.0722 * channel(color.b);
}

// Razão de contraste entre duas cores, de 1 (iguais) a 21 (preto e branco).
double contrastRatio(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

// A cor `fg` com transparência [alpha] desenhada sobre `bg` (como um fundo
// translúcido de cartão).
Color _over(Color fg, Color bg, double alpha) =>
    Color.alphaBlend(fg.withValues(alpha: alpha), bg);

class _Pair {
  const _Pair(this.name, this.foreground, this.background, {this.min = 4.5});

  final String name;
  final Color foreground;
  final Color background;
  final double min; // 4,5 para texto; 3 para ícones
}

// Achados conhecidos e ainda não corrigidos: nome do par -> motivo.
const _knownIssues = <String, String>{};

final _pairs = <_Pair>[
  // Texto sobre o fundo e sobre cartões brancos.
  _Pair(
    'texto cinza sobre o fundo',
    AppColors.textSecondary,
    AppColors.background,
  ),
  _Pair(
    'texto cinza sobre cartão branco',
    AppColors.textSecondary,
    Colors.white,
  ),
  _Pair(
    'texto preto sobre o fundo',
    AppColors.textPrimary,
    AppColors.background,
  ),
  _Pair('azul-marinho sobre branco', AppColors.modeNormal, Colors.white),

  // Caixas informativas (azul) e de erro (vermelho).
  _Pair(
    'azul informativo sobre a caixa azul (12%, sobre branco)',
    AppColors.info,
    _over(AppColors.info, Colors.white, 0.12),
  ),
  _Pair(
    'azul informativo sobre a caixa azul (14%, sobre o fundo)',
    AppColors.info,
    _over(AppColors.info, AppColors.background, 0.14),
  ),
  _Pair(
    'vermelho de texto sobre a caixa vermelha (12%)',
    AppColors.modeDangerText,
    _over(AppColors.modeDanger, Colors.white, 0.12),
  ),
  _Pair(
    'vermelho de texto sobre cartão branco',
    AppColors.modeDangerText,
    Colors.white,
  ),

  // Cartões dos modos na Home.
  _Pair(
    'vermelho de texto sobre o cartão do Perigo (15%)',
    AppColors.modeDangerText,
    _over(AppColors.modeDanger, AppColors.background, 0.15),
  ),
  _Pair(
    'marrom da Atenção sobre o cartão da Atenção (15%)',
    AppColors.modeAttentionText,
    _over(AppColors.modeAttention, AppColors.background, 0.15),
  ),
  _Pair(
    'marrom da Atenção sobre branco',
    AppColors.modeAttentionText,
    Colors.white,
  ),

  // Tela Alerta: branco sobre o vermelho do Perigo e azul-marinho sobre o amarelo.
  _Pair(
    'branco sobre o vermelho do Perigo',
    Colors.white,
    AppColors.modeDanger,
  ),
  _Pair(
    'branco sobre o cartão escuro do Perigo',
    Colors.white,
    _over(Colors.black, AppColors.modeDanger, 0.18),
  ),
  _Pair(
    'azul-marinho sobre o amarelo da Atenção',
    AppColors.modeNormal,
    AppColors.modeAttention,
  ),
  _Pair(
    'azul-marinho sobre o cartão escuro da Atenção',
    AppColors.modeNormal,
    _over(Colors.black, AppColors.modeAttention, 0.08),
  ),
  _Pair(
    'vermelho do Perigo sobre o botão branco',
    AppColors.modeDanger,
    Colors.white,
  ),

  // Ícones (mínimo 3, e não 4,5): carregam informação, como "voltar" e "+".
  _Pair(
    'ícones (setas, x, setinhas) sobre o fundo',
    AppColors.iconMuted,
    AppColors.background,
    min: 3,
  ),
  _Pair(
    'ícones (setas, x, setinhas) sobre cartão branco',
    AppColors.iconMuted,
    Colors.white,
    min: 3,
  ),
  _Pair(
    'ícone verde (✓) sobre branco',
    AppColors.avatarGreen,
    Colors.white,
    min: 3,
  ),
  _Pair(
    'ícone rosa da marca sobre branco',
    AppColors.brand,
    Colors.white,
    min: 3,
  ),
];

void main() {
  test('a fórmula bate com os valores conhecidos do WCAG', () {
    expect(contrastRatio(Colors.black, Colors.white), closeTo(21, 0.01));
    expect(contrastRatio(Colors.white, Colors.white), closeTo(1, 0.001));
    // A ordem não importa.
    expect(
      contrastRatio(Colors.black, Colors.white),
      contrastRatio(Colors.white, Colors.black),
    );
    // Exemplo clássico do WCAG: cinza #767676 sobre branco dá 4,54.
    expect(
      contrastRatio(const Color(0xFF767676), Colors.white),
      closeTo(4.54, 0.02),
    );
  });

  group('contraste dos pares de cores do app', () {
    for (final pair in _pairs) {
      final issue = _knownIssues[pair.name];

      test(pair.name, () {
        final ratio = contrastRatio(pair.foreground, pair.background);

        expect(
          ratio,
          greaterThanOrEqualTo(pair.min),
          reason:
              '${pair.name}: contraste ${ratio.toStringAsFixed(2)} '
              '(mínimo ${pair.min})',
        );
      }, skip: issue != null);
    }
  });
}
