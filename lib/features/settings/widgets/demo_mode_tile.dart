// Item de Configurações com uma chave liga/desliga: "Modo de demonstração".
//
// Com ele ligado, o alerta faz todo o percurso na tela (cartões de progresso),
// mas NÃO envia SMS nem liga de verdade. Serve para ensaiar a apresentação sem
// avisar a rede por engano. Fica desligado ao abrir o app (não é gravado): um
// esquecimento nunca deixa um alerta de verdade "de mentirinha".

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import 'package:ada_app/core/theme/app_colors.dart';
import 'package:ada_app/features/alerts/state/alert_controller.dart';

class DemoModeTile extends StatelessWidget {
  const DemoModeTile({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.tertiary; // rosa da marca
    // watch: a chave reflete o valor atual; read nas ações (abaixo, no onChanged).
    final alert = context.watch<AlertController>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 21, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.placeholder.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 44,
            decoration: ShapeDecoration(
              color: accent.withValues(alpha: 0.15),
              shape: const StadiumBorder(),
            ),
            child: Icon(LucideIcons.flaskConical, size: 24, color: accent),
          ),
          const SizedBox(width: 19),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Modo de demonstração',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Simula o alerta sem enviar SMS nem ligar. Use para ensaiar.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Semantics: dá o nome à chave. Sem ele, o leitor de tela diria só
          // "chave", sem dizer para que serve.
          Semantics(
            label: 'Modo de demonstração',
            child: Switch(
              value: alert.demoMode,
              onChanged: (value) =>
                  context.read<AlertController>().demoMode = value,
            ),
          ),
        ],
      ),
    );
  }
}
