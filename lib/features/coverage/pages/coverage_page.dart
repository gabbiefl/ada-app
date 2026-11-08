// Tela "Horário de cobertura": quem o ADA liga em cada faixa de horário.
//
// Segue o Figma: o cartão "Cobertura das 24 horas" e a lista de faixas, cada uma
// com ícone do período, horário, "Ligar para <contato>" e uma chave liga/desliga.
// Além do Figma, diz QUEM SERIA LIGADO AGORA, para a usuária conferir a regra.
//
// A tela só DESENHA o estado dos controladores; as regras ficam neles.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import 'package:ada_app/core/theme/app_colors.dart';
import 'package:ada_app/core/widgets/page_header.dart';
import 'package:ada_app/features/alerts/state/alert_controller.dart';
import 'package:ada_app/features/contacts/state/contacts_controller.dart';
import 'package:ada_app/features/coverage/state/coverage_controller.dart';
import 'package:ada_app/features/coverage/utils/coverage_logic.dart';
import 'package:ada_app/features/coverage/widgets/coverage_rule_tile.dart';
import 'package:ada_app/features/coverage/widgets/coverage_summary_card.dart';

// StatefulWidget: guarda um temporizador que atualiza "quem seria ligado agora"
// quando a hora vira.
class CoveragePage extends StatefulWidget {
  const CoveragePage({super.key});

  @override
  State<CoveragePage> createState() => _CoveragePageState();
}

class _CoveragePageState extends State<CoveragePage> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    // A cada 30 segundos redesenha, para a frase "agora" acompanhar o relógio.
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  // dispose: cancela o temporizador quando a tela sai.
  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  // Mexeu na chave. Desligar sempre pode; ligar só se não cruzar com outra faixa
  // ligada, e então a tela explica com qual.
  void _toggle(String ruleId, bool value, Map<String, String> names) {
    final coverage = context.read<CoverageController>();
    final rule = coverage.byId(ruleId);
    if (rule == null) return;

    final error = coverage.setEnabled(ruleId, value);
    if (error != CoverageError.overlaps) return;

    final conflict = coverage.findConflict(
      ignoreId: ruleId,
      start: rule.start,
      end: rule.end,
    );
    final other = conflict == null
        ? 'outra faixa'
        : '${formatRange(conflict)} (${names[conflict.contactId] ?? 'contato removido'})';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Essa faixa cruza com $other. Desligue a outra antes de ligar esta.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // watch: a tela se redesenha quando as faixas ou os contatos mudam.
    final coverage = context.watch<CoverageController>();
    final network = context.watch<ContactsController>();

    final contacts = network.contacts.toList();
    final names = {for (final c in contacts) c.id: c.name};
    // Faixas de contatos que não existem mais não aparecem (e são apagadas pelo
    // app quando a rede muda).
    final rules = [
      for (final r in coverage.rules)
        if (names.containsKey(r.contactId)) r,
    ];

    // Quem o alerta ligaria AGORA: a mesma política que o Perigo usa.
    final now = context.read<AlertController>().callTarget.pick(contacts);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(40, 30, 40, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHeader(
                title: 'Horário de cobertura',
                subtitle: 'Priorize para quem ligar de acordo com o horário.',
                trailing: IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(LucideIcons.arrowLeft),
                  color: AppColors.placeholder,
                  tooltip: 'Voltar',
                ),
              ),
              const SizedBox(height: 24),
              if (contacts.isEmpty)
                const _Notice(
                  icon: LucideIcons.users,
                  text:
                      'Você ainda não tem contatos. Cadastre alguém de '
                      'confiança na aba Rede para criar faixas de horário.',
                )
              else ...[
                CoverageSummaryCard(
                  rules: rules,
                  fallbackName: contacts.first.name,
                ),
                const SizedBox(height: 12),
                if (now != null)
                  _Notice(
                    icon: LucideIcons.phoneCall,
                    text: 'Agora, o ADA ligaria para ${now.name}.',
                  ),
                const SizedBox(height: 12),
                for (final rule in rules) ...[
                  CoverageRuleTile(
                    rule: rule,
                    contactName: names[rule.contactId]!,
                    onToggle: (value) => _toggle(rule.id, value, names),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Caixa azul com ícone e texto, no mesmo estilo das outras telas.
class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppColors.info),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppColors.info),
            ),
          ),
        ],
      ),
    );
  }
}
