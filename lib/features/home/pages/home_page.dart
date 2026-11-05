// Tela inicial do ADA (modo Normal), montada a partir do Figma.
//
// Fica em lib/features/home/pages/: cada funcionalidade tem sua pasta
// (features/<nome>/) e, dentro dela, as telas ficam em pages/.
// Por enquanto é estática: os cards dos modos e a barra de navegação entram
// nos próximos passos da Fase 3.

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import 'package:ada_app/core/state/mode_controller.dart';
import 'package:ada_app/core/state/security_mode.dart';
import 'package:ada_app/core/theme/mode_colors.dart';
import 'package:ada_app/features/home/widgets/mode_card.dart';
import 'package:ada_app/features/home/widgets/mode_rings.dart';
import 'package:ada_app/features/home/widgets/status_chip.dart';

// StatefulWidget: agora a tela guarda algo que vive e muda, o controlador da
// animação dos anéis. (Ver o resumo 04 de aprendizado sobre Stateless x Stateful.)
class HomePage extends StatefulWidget {
  // O modo atual não é mais parâmetro: a Home o lê do ModeController, que vive
  // no app inteiro (ver app.dart).
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

// SingleTickerProviderStateMixin: fornece o "relógio" (ticker) que faz a animação
// avançar a cada quadro. Todo AnimationController precisa de um.
class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 1500),
          )
          // repeat(reverse: true): vai de 0 a 1 e volta, sem parar (efeito de pulsar).
          ..repeat(reverse: true);
  }

  // dispose: libera o controlador quando a tela sai, para não gastar bateria.
  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  // Toque no card Atenção: pede ao controlador e, se ele recusar (estando no
  // Perigo), explica o motivo. A tela não conhece a regra, só mostra o resultado.
  void _activateAttention() {
    final error = context.read<ModeController>().activate(
      SecurityMode.attention,
    );
    if (error == ModeError.deactivateFirst) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Desative o Modo perigo antes de mudar para Atenção.'),
        ),
      );
    }
  }

  // Diálogo de confirmação em dois botões. Devolve true só se a usuária confirmar
  // (Cancelar, ou tocar fora do diálogo, devolve false/null).
  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
    Color? confirmColor,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: confirmColor),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  // Perigo dispara o fluxo de emergência, então o primeiro toque só PERGUNTA;
  // o segundo (em "Ativar") é que ativa. Total: 2 toques (meta do RNF01).
  Future<void> _activateDanger() async {
    // Pega o controlador ANTES do await: depois dele o context pode não valer.
    final controller = context.read<ModeController>();
    if (controller.mode == SecurityMode.danger) return; // já está ativo

    final confirmed = await _confirm(
      title: 'Ativar o Modo perigo?',
      message: 'Use apenas em caso de emergência.',
      confirmLabel: 'Ativar',
      confirmColor: ModeColors.of(context).danger,
    );
    if (confirmed) controller.activate(SecurityMode.danger);
  }

  // Encerrar um alerta por engano é o pior erro deste app: também confirma.
  Future<void> _deactivate() async {
    final controller = context.read<ModeController>();
    if (controller.mode == SecurityMode.normal) return;

    final confirmed = await _confirm(
      title: 'Desativar o alerta?',
      message: 'O ADA voltará ao modo normal.',
      confirmLabel: 'Desativar',
    );
    if (confirmed) controller.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    // Cores e estilos vêm do tema, e não de valores fixos aqui.
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final modeColors = ModeColors.of(context);

    // context.watch: "assina" o controlador. Quando o modo muda e ele chama
    // notifyListeners(), este build roda de novo e a tela se atualiza.
    // O visual do Modo Atenção ainda não foi lido no Figma, então por ora só o
    // Perigo muda a tela.
    final mode = context.watch<ModeController>().mode;

    // Cores do símbolo central, conforme o estado.
    final active = mode == SecurityMode.danger;
    final ringColor = active ? modeColors.danger : modeColors.normal;
    final circleColor = active
        ? theme.colorScheme.onPrimary
        : modeColors.normal;
    final symbol = active
        ? 'assets/images/simbolo_perigo.png'
        : 'assets/images/simbolo_ada.png';

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Cabeçalho: logo à esquerda, sino à direita.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 35),
              child: SizedBox(
                height: 85,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset(
                      'assets/images/logo_horizontal_azul.png',
                      height: 42,
                    ),
                    // Stack: o sino com uma bolinha de aviso por cima, no canto.
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          LucideIcons.bell,
                          color: theme.colorScheme.onSurface,
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: theme.colorScheme.tertiary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Expanded + SingleChildScrollView: o resto da tela rola se não couber
            // (telas baixas), em vez de dar erro de "overflow".
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    const SizedBox(height: 32),
                    // Alignment.centerLeft: o texto encosta na esquerda.
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Olá, Gabriela', style: textTheme.headlineSmall),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Estamos com você!',
                                style: textTheme.bodyLarge,
                              ),
                              const SizedBox(width: 6),
                              // colorScheme.tertiary é o rosa da marca.
                              Icon(
                                LucideIcons.heart,
                                size: 15,
                                color: theme.colorScheme.tertiary,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Stack: um widget SOBRE o outro (anéis atrás, círculo na frente).
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        ModeRings(color: ringColor, pulse: _pulse),
                        // Tocar no símbolo desativa (com confirmação). No modo
                        // Normal ele não faz nada, e o leitor de tela não o
                        // anuncia como botão.
                        Semantics(
                          button: mode != SecurityMode.normal,
                          label: mode != SecurityMode.normal
                              ? 'Desativar alerta'
                              : null,
                          child: GestureDetector(
                            onTap: _deactivate,
                            child: Container(
                              width: 134,
                              height: 134,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: circleColor,
                              ),
                              padding: const EdgeInsets.all(30),
                              child: Image.asset(symbol),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Estado ativo: chip e instrução. Normal: frase de apoio.
                    if (active) ...[
                      StatusChip(
                        label: 'Modo perigo ativo',
                        color: modeColors.danger,
                        textColor: modeColors.dangerText,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Toque no ícone para desativar.',
                        style: textTheme.labelMedium,
                      ),
                    ] else
                      Text(
                        'Nenhum alerta ativo no momento.',
                        style: textTheme.bodyMedium,
                      ),
                    const SizedBox(height: 40),
                    ModeCard(
                      title: 'MODO PERIGO',
                      caption: 'Clique em caso de emergências.',
                      icon: LucideIcons.triangleAlert,
                      color: modeColors.danger,
                      textColor: modeColors.dangerText,
                      onTap: _activateDanger,
                    ),
                    const SizedBox(height: 16),
                    ModeCard(
                      title: 'MODO ATENÇÃO',
                      caption: 'Clique em caso de atenção.',
                      icon: LucideIcons.eye,
                      color: modeColors.attention,
                      textColor: modeColors.attentionText,
                      onTap: _activateAttention,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
