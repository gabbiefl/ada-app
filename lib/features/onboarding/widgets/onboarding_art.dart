// As três ilustrações do onboarding.
//
// As duas primeiras são desenhadas em código (anéis e círculos com as cores do
// tema), então ficam nítidas em qualquer tela. A terceira é uma imagem exportada
// do Figma. Todas são decorativas: o texto da tela já diz o que importa, então o
// leitor de tela as ignora.

import 'package:flutter/material.dart';

import 'package:ada_app/core/theme/app_colors.dart';
import 'package:ada_app/features/home/widgets/mode_rings.dart';

// Lado do quadrado onde cada ilustração é desenhada (320 no Figma).
const double kOnboardingArtSize = 320;

// Círculo navy com a logo (A branco com coração) no centro.
class _LogoDisc extends StatelessWidget {
  const _LogoDisc({required this.diameter, required this.logoWidth});

  final double diameter;
  final double logoWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.modeNormal,
      ),
      alignment: Alignment.center,
      child: Image.asset(
        'assets/images/logo_ada_branca.png',
        width: logoWidth,
        excludeFromSemantics: true,
      ),
    );
  }
}

// Tela 1: a logo no centro de dois anéis.
class OnboardingArtSecurity extends StatelessWidget {
  const OnboardingArtSecurity({super.key});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: kOnboardingArtSize,
        height: kOnboardingArtSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Os mesmos anéis da Home, parados e na cor do modo Normal.
            const ModeRings(color: AppColors.modeNormal, size: 270),
            const _LogoDisc(diameter: 163, logoWidth: 92),
          ],
        ),
      ),
    );
  }
}

// Fundo cinza claro e redondo das telas 2 e 3.
class _SoftCircle extends StatelessWidget {
  const _SoftCircle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: kOnboardingArtSize,
      height: kOnboardingArtSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.placeholder.withValues(alpha: 0.25),
      ),
    );
  }
}

// Tela 2: a logo no meio e cinco pessoas em volta, ligadas por linhas.
class OnboardingArtNetwork extends StatelessWidget {
  const OnboardingArtNetwork({super.key});

  static const double _avatar = 63;

  // Centros, a partir do canto de cima à esquerda do quadrado de 320 (medidos no
  // Figma).
  static const _center = Offset(160, 144);
  static const _people = [
    _Person('GF', Offset(160, 52), AppColors.brand),
    _Person('YC', Offset(253, 153), AppColors.avatarGreen),
    _Person('MA', Offset(216, 249), AppColors.modeAttention),
    _Person('TR', Offset(104, 249), AppColors.info),
  ];
  static const _emptySlot = Offset(61, 148);

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: kOnboardingArtSize,
        height: kOnboardingArtSize,
        child: Stack(
          children: [
            const _SoftCircle(),
            // As linhas ficam por baixo das pessoas.
            Positioned.fill(
              child: CustomPaint(
                painter: _LinesPainter(
                  center: _center,
                  targets: [for (final p in _people) p.at, _emptySlot],
                ),
              ),
            ),
            _at(_emptySlot, const _EmptySlot(diameter: _avatar)),
            for (final p in _people)
              _at(p.at, _Avatar(initials: p.initials, color: p.color)),
            _at(_center, const _LogoDisc(diameter: 90, logoWidth: 52)),
          ],
        ),
      ),
    );
  }

  // Põe o widget com o CENTRO em [center].
  static Widget _at(Offset center, Widget child) {
    return Positioned(
      left: center.dx - _avatar / 2,
      top: center.dy - _avatar / 2,
      width: _avatar,
      height: _avatar,
      child: Center(child: child),
    );
  }
}

class _Person {
  const _Person(this.initials, this.at, this.color);

  final String initials;
  final Offset at;
  final Color color;
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials, required this.color});

  final String initials;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: OnboardingArtNetwork._avatar,
      height: OnboardingArtNetwork._avatar,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(color: Colors.white, fontSize: 18),
      ),
    );
  }
}

// O espaço vazio da rede: círculo branco com borda tracejada e um "+".
class _EmptySlot extends StatelessWidget {
  const _EmptySlot({required this.diameter});

  final double diameter;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _DashedCirclePainter(),
      child: SizedBox(
        width: diameter,
        height: diameter,
        child: const Icon(Icons.add, size: 28, color: AppColors.textSecondary),
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  const _DashedCirclePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawCircle(
      rect.center,
      size.width / 2,
      Paint()..color = Colors.white,
    );

    final stroke = Paint()
      ..color = AppColors.iconMuted
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()..addOval(rect.deflate(0.5));
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 4), stroke);
        distance += 7;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter old) => false;
}

class _LinesPainter extends CustomPainter {
  const _LinesPainter({required this.center, required this.targets});

  final Offset center;
  final List<Offset> targets;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    for (final target in targets) {
      canvas.drawLine(center, target, paint);
    }
  }

  @override
  bool shouldRepaint(_LinesPainter old) =>
      old.center != center || old.targets != targets;
}

// Tela 3: a pessoa com o celular e o pino de localização (imagem do Figma).
class OnboardingArtControl extends StatelessWidget {
  const OnboardingArtControl({super.key});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: kOnboardingArtSize,
        height: kOnboardingArtSize,
        child: Stack(
          children: [
            const _SoftCircle(),
            Positioned(
              left: 51,
              top: 23,
              width: 228,
              height: 289,
              child: Image.asset(
                'assets/images/onboarding_controle.png',
                excludeFromSemantics: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
