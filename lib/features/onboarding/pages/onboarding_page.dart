// Onboarding: 3 telas que explicam o ADA na primeira abertura.
//
// PageView: as telas ficam lado a lado e a usuária desliza (ou toca em
// "Continuar"). O PageController diz em qual está e leva à próxima.
//
// Ao terminar (ou ao tocar em "Pular"), grava que já viu e vai para a tela de permissões. Se a
// gravação falhar, vai para a Home do mesmo jeito: o onboarding nunca pode
// impedir o uso do app.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:ada_app/core/routes/app_router.dart';
import 'package:ada_app/core/theme/app_colors.dart';
import 'package:ada_app/features/onboarding/data/onboarding_repository.dart';
import 'package:ada_app/features/onboarding/widgets/onboarding_art.dart';

class _Slide {
  const _Slide({required this.art, required this.title, required this.body});

  final Widget art;
  final String title;
  final String body;
}

// O texto da tela 3 diz o que o app faz de verdade: a localização vai uma vez,
// junto do alerta, e não há acompanhamento em tempo real.
const _slides = [
  _Slide(
    art: OnboardingArtSecurity(),
    title: 'Sua segurança em um toque.',
    body: 'Ative o alerta em segundos e avise quem você confia.',
  ),
  _Slide(
    art: OnboardingArtNetwork(),
    title: 'Sua rede sempre por perto.',
    body:
        'Cadastre até 5 pessoas de confiança. Elas recebem seu alerta e sua '
        'localização ao mesmo tempo.',
  ),
  _Slide(
    art: OnboardingArtControl(),
    title: 'Você no controle.',
    body:
        'Sua localização só é enviada quando você ativa um alerta. Seus dados '
        'ficam só no seu celular.',
  ),
];

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, this.onFinished});

  // O que fazer ao terminar. Se null, vai para a Home. Existe para os testes.
  final VoidCallback? onFinished;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _index = 0;

  bool get _isLast => _index == _slides.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_isLast) return _finish();
    await _controller.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _finish() async {
    // Pega o repositório ANTES do await: depois dele o context pode não valer.
    final repository = context.read<OnboardingRepository>();
    try {
      await repository.markSeen();
    } catch (_) {
      // Sem gravar, o onboarding só aparece de novo na próxima abertura.
    }
    if (!mounted) return;
    final onFinished = widget.onFinished;
    if (onFinished != null) {
      onFinished();
    } else {
      // Depois da apresentação, explica e pede as permissões.
      context.go(AppRoutes.permissions);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // "Pular" some na última tela, mas o espaço fica reservado para a
            // tela não "pular" de lugar.
            SizedBox(
              height: 56,
              child: Align(
                alignment: Alignment.centerRight,
                child: _isLast
                    ? null
                    : Padding(
                        padding: const EdgeInsets.only(right: 24),
                        child: TextButton(
                          onPressed: _finish,
                          style: TextButton.styleFrom(
                            minimumSize: const Size(64, 48),
                            foregroundColor: AppColors.textSecondary,
                          ),
                          child: const Text('Pular'),
                        ),
                      ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final slide = _slides[i];
                  // Rolagem: com a fonte do sistema grande, o texto cresce e a
                  // tela rola em vez de estourar.
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 39),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(child: slide.art),
                        const SizedBox(height: 40),
                        Semantics(
                          header: true,
                          child: Text(
                            slide.title,
                            style: textTheme.headlineSmall?.copyWith(
                              fontSize: 28,
                            ),
                          ),
                        ),
                        const SizedBox(height: 17),
                        Text(slide.body, style: textTheme.bodyLarge),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            _Dots(count: _slides.length, index: _index),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.fromLTRB(42, 0, 42, 40),
              child: FilledButton(
                onPressed: _next,
                child: Text(_isLast ? 'Começar' : 'Continuar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Bolinhas que mostram em qual das telas a usuária está.
class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Tela ${index + 1} de $count',
      child: ExcludeSemantics(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < count; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: i == index ? 22 : 8,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: i == index
                      ? AppColors.modeNormal
                      : AppColors.placeholder,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
