// Tela de abertura (splash): fundo azul-marinho, a logo do ADA no centro e uma
// barrinha de progresso. Quando a barra enche, o app segue para a Home.
//
// A barra é uma animação: um AnimationController vai de 0 a 1 no tempo dado, e o
// AnimatedBuilder redesenha a barra a cada "quadro". Ao terminar, ele avisa
// (status completed) e a tela navega: ao onboarding na primeira vez, ao nome se
// ainda não foi perguntado, ou à Home. O controlador é descartado no dispose, então
// sair da tela antes do fim não deixa nada pendente.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:ada_app/core/routes/app_router.dart';
import 'package:ada_app/core/theme/app_colors.dart';
import 'package:ada_app/features/onboarding/data/onboarding_repository.dart';
import 'package:ada_app/features/profile/state/profile_controller.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({
    super.key,
    this.duration = const Duration(milliseconds: 2200),
    this.onFinished,
  });

  final Duration duration;

  // O que fazer quando a barra enche. Se null, vai ao onboarding ou à Home. Existe para os
  // testes poderem conferir o fim sem depender do roteador.
  final VoidCallback? onFinished;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..addStatusListener((status) {
        if (status != AnimationStatus.completed || !mounted) return;
        final onFinished = widget.onFinished;
        if (onFinished != null) {
          onFinished();
        } else {
          _goNext();
        }
      })
      ..forward();
  }

  // Para onde ir depois da splash:
  //   - nunca viu o onboarding: onboarding (e dele segue ao nome);
  //   - viu, mas o nome nunca foi perguntado: tela do nome;
  //   - senão: Home.
  // Se não der para ler (falha no armazenamento), vai para a Home: a
  // apresentação nunca pode travar o app.
  Future<void> _goNext() async {
    final onboarding = context.read<OnboardingRepository>();
    final profile = context.read<ProfileController>();
    var seen = true;
    var asked = true;
    try {
      seen = await onboarding.hasSeen();
    } catch (_) {}
    try {
      await profile.ready;
      asked = profile.asked;
    } catch (_) {}
    if (!mounted) return;
    context.go(
      !seen
          ? AppRoutes.onboarding
          : !asked
          ? AppRoutes.profileSetup
          : AppRoutes.home,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.modeNormal,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logo_ada_branca.png',
              width: 150,
              semanticLabel: 'ADA — Alerta, Defesa e Apoio',
            ),
            const SizedBox(height: 48),
            // Um único nome para a barra: o leitor de tela diz "Carregando".
            Semantics(
              label: 'Carregando o ADA',
              child: ExcludeSemantics(
                child: SizedBox(
                  width: 160,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) => LinearProgressIndicator(
                        value: _controller.value,
                        minHeight: 4,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        color: AppColors.brand,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
