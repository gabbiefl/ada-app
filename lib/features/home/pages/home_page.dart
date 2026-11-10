// Tela inicial do ADA (modo Normal), montada a partir do Figma.
//
// Fica em lib/features/home/pages/: cada funcionalidade tem sua pasta
// (features/<nome>/) e, dentro dela, as telas ficam em pages/.
// Por enquanto é estática: os cards dos modos e a barra de navegação entram
// nos próximos passos da Fase 3.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import 'package:ada_app/core/routes/app_router.dart';
import 'package:ada_app/core/state/mode_controller.dart';
import 'package:ada_app/core/state/security_mode.dart';
import 'package:ada_app/core/theme/mode_colors.dart';
import 'package:ada_app/core/widgets/confirm_dialog.dart';
import 'package:ada_app/features/alerts/state/alert_controller.dart';
import 'package:ada_app/features/contacts/state/contacts_controller.dart';
import 'package:ada_app/features/coverage/state/coverage_controller.dart';
import 'package:ada_app/features/emergency/widgets/emergency_section.dart';
import 'package:ada_app/features/home/widgets/mode_card.dart';
import 'package:ada_app/features/home/widgets/mode_rings.dart';
import 'package:ada_app/features/home/widgets/status_chip.dart';
import 'package:ada_app/features/messages/models/message_kind.dart';
import 'package:ada_app/features/messages/state/messages_controller.dart';

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
  // Quanto o alerta espera, no máximo, a rede e as mensagens carregarem.
  static const _loadTimeout = Duration(seconds: 2);

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

  // Diálogo de confirmação (compartilhado com a tela Alerta, ver
  // core/widgets/confirm_dialog.dart).
  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
    Color? confirmColor,
  }) => showConfirmDialog(
    context,
    title: title,
    message: message,
    confirmLabel: confirmLabel,
    confirmColor: confirmColor,
  );

  // Dispara o alerta e abre a tela de progresso. Chamado logo depois de o modo
  // ser ativado. Junta os dados de outros controladores: a rede e a mensagem.
  Future<void> _startAlert(MessageKind kind) async {
    final alert = context.read<AlertController>();
    final network = context.read<ContactsController>();
    final messages = context.read<MessagesController>();
    final coverage = context.read<CoverageController>();

    // Espera a rede, as mensagens e as faixas de cobertura guardadas terminarem
    // de carregar: ler antes disso daria uma lista vazia, o texto padrão no lugar
    // do editado ou o contato errado para ligar. Quando já carregaram (o normal),
    // não espera nada.
    // Com prazo: se a leitura travar, o alerta NÃO pode ficar esperando para
    // sempre. Passado o limite, sai com o que já estiver carregado.
    try {
      await Future.wait([network.ready, messages.ready, coverage.ready])
          .timeout(_loadTimeout);
    } on TimeoutException {
      // segue com o que houver
    }
    if (!mounted) return;

    // Um alerta anterior (ex.: a Atenção, ao subir para o Perigo) é encerrado
    // antes de começar o novo.
    alert.reset();
    // Sem await: a tela de progresso acompanha enquanto o alerta anda.
    unawaited(
      alert.start(
        kind: kind,
        contacts: network.contacts.toList(),
        message: messages.textOf(kind),
      ),
    );
    context.push(AppRoutes.alert);
  }

  // Atenção: a rede recebe um SMS com a localização, então também confirma.
  Future<void> _activateAttention() async {
    final controller = context.read<ModeController>();
    if (controller.mode == SecurityMode.attention) return; // já está ativo

    // Do Perigo não se desce direto para a Atenção: explica antes de perguntar.
    if (!controller.mode.canGoTo(SecurityMode.attention)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Desative o Modo perigo antes de mudar para Atenção.'),
        ),
      );
      return;
    }

    final confirmed = await _confirm(
      title: 'Ativar o Modo atenção?',
      message: 'A sua rede receberá uma mensagem com a sua localização.',
      confirmLabel: 'Ativar',
      confirmColor: ModeColors.of(context).attentionText,
    );
    // Depois de um await, a tela pode já ter saído: confere antes de usar o context.
    if (!confirmed || !mounted) return;

    if (controller.activate(SecurityMode.attention) == null) {
      await _startAlert(MessageKind.attention);
    }
  }

  // Perigo dispara o fluxo de emergência, então o primeiro toque só PERGUNTA;
  // o segundo (em "Ativar") é que ativa e já dispara o alerta, sem outra
  // confirmação. Total: 2 toques (meta do RNF01).
  Future<void> _activateDanger() async {
    // Pega o controlador ANTES do await: depois dele o context pode não valer.
    final controller = context.read<ModeController>();
    if (controller.mode == SecurityMode.danger) return; // já está ativo

    final confirmed = await _confirm(
      title: 'Ativar o Modo perigo?',
      message:
          'O ADA vai avisar a sua rede por SMS com a sua localização e ligar '
          'para o contato de plantão. Use apenas em caso de emergência.',
      confirmLabel: 'Ativar',
      confirmColor: ModeColors.of(context).danger,
    );
    if (!confirmed || !mounted) return;

    if (controller.activate(SecurityMode.danger) == null) {
      await _startAlert(MessageKind.danger);
    }
  }

  // Encerrar um alerta por engano é o pior erro deste app: também confirma.
  // Ao desativar, o alerta em andamento é cancelado (nenhum envio novo sai).
  Future<void> _deactivate() async {
    final controller = context.read<ModeController>();
    final alert = context.read<AlertController>();
    if (controller.mode == SecurityMode.normal) return;

    final confirmed = await _confirm(
      title: 'Desativar o alerta?',
      message: 'O ADA voltará ao modo normal.',
      confirmLabel: 'Desativar',
    );
    if (!confirmed) return;

    controller.deactivate();
    alert.reset();
  }

  @override
  Widget build(BuildContext context) {
    // Cores e estilos vêm do tema, e não de valores fixos aqui.
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final modeColors = ModeColors.of(context);

    // context.watch: "assina" o controlador. Quando o modo muda e ele chama
    // notifyListeners(), este build roda de novo e a tela se atualiza.
    final mode = context.watch<ModeController>().mode;

    // Estado derivado: tudo o que a tela mostra sai do modo atual, sem guardar
    // nada a mais. No Normal o círculo é azul-marinho; nos alertas, branco com o
    // símbolo colorido (o mesmo desenho, só mudam cor, símbolo e textos).
    final active = mode != SecurityMode.normal;
    final ringColor = switch (mode) {
      SecurityMode.normal => modeColors.normal,
      SecurityMode.attention => modeColors.attention,
      SecurityMode.danger => modeColors.danger,
    };
    final circleColor = active
        ? theme.colorScheme.onPrimary
        : modeColors.normal;
    final symbol = switch (mode) {
      SecurityMode.normal => 'assets/images/simbolo_ada.png',
      SecurityMode.attention => 'assets/images/simbolo_atencao.png',
      SecurityMode.danger => 'assets/images/simbolo_perigo.png',
    };
    final chipLabel = mode == SecurityMode.attention
        ? 'Modo atenção ativo'
        : 'Modo perigo ativo';
    final chipTextColor = mode == SecurityMode.attention
        ? modeColors.attentionText
        : modeColors.dangerText;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Cabeçalho: só a logo. O sino do Figma foi removido
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
                          Text('Olá!', style: textTheme.headlineSmall),
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
                            // Sem alerta ativo não há o que desativar: sem gesto, o
                            // leitor de tela não anuncia um botão sem ação.
                            onTap: mode == SecurityMode.normal
                                ? null
                                : _deactivate,
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
                        label: chipLabel,
                        color: ringColor,
                        textColor: chipTextColor,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Toque no ícone para desativar.',
                        style: textTheme.labelMedium,
                      ),
                      const SizedBox(height: 4),
                      // Reabre a tela de progresso do alerta em andamento.
                      TextButton(
                        onPressed: () => context.push(AppRoutes.alert),
                        child: const Text('Ver alerta'),
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
                    const SizedBox(height: 32),
                    // Ligar direto para o 190 ou o 180 (não aciona a rede).
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: EmergencySection(),
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
