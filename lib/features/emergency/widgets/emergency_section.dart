// Seção "Segurança pública" da Home: ligar direto para a Polícia Militar (190) e
// para a Central de Atendimento à Mulher (180).
//
// Regras:
//   - sempre CONFIRMA antes de ligar (um toque sem querer no 190 seria um trote);
//   - liga SÓ para o serviço tocado: não ativa modo nenhum e não avisa a rede;
//   - se a ligação direta não for possível (sem permissão ou sem chip), abre o
//     discador com o número já digitado (plano B). Se nem isso der, avisa.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ada_app/core/widgets/confirm_dialog.dart';
import 'package:ada_app/features/alerts/data/alert_actions.dart';
import 'package:ada_app/features/emergency/models/emergency_service.dart';
import 'package:ada_app/features/emergency/widgets/service_card.dart';

class EmergencySection extends StatelessWidget {
  const EmergencySection({super.key});

  Future<void> _call(BuildContext context, EmergencyService service) async {
    // Pega o que precisa ANTES dos await: depois deles o context pode não valer.
    final actions = context.read<AlertActions>();
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showConfirmDialog(
      context,
      title: 'Ligar para o ${service.number}?',
      message: service.confirmMessage,
      confirmLabel: 'Ligar',
    );
    if (!confirmed) return;

    var result = await actions.call(service.number);
    if (!result.isSuccess) {
      result = await actions.openDialer(service.number);
    }
    if (!result.isSuccess) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Não foi possível ligar. Disque ${service.number} pelo telefone.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text('Segurança pública', style: textTheme.titleMedium),
        ),
        const SizedBox(height: 4),
        Text(
          'Ligue direto para a polícia ou para a central da mulher. A sua rede '
          'não é avisada.',
          style: textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        for (final service in emergencyServices) ...[
          ServiceCard(
            service: service,
            icon: serviceIcon(service),
            onTap: () => _call(context, service),
          ),
          if (service != emergencyServices.last) const SizedBox(height: 16),
        ],
      ],
    );
  }
}
