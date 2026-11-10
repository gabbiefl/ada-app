// Tela "Configurações": menu que leva a Horário de cobertura e Mensagens
// personalizadas, com a chave do Modo de demonstração e o "Apagar meus dados".
// Não há histórico de alertas, de propósito: o ADA não guarda que um alerta foi
// enviado (ver docs/privacidade-e-dados.md).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import 'package:ada_app/core/routes/app_router.dart';
import 'package:ada_app/core/state/mode_controller.dart';
import 'package:ada_app/core/theme/app_colors.dart';
import 'package:ada_app/core/widgets/confirm_dialog.dart';
import 'package:ada_app/features/alerts/state/alert_controller.dart';
import 'package:ada_app/features/contacts/state/contacts_controller.dart';
import 'package:ada_app/features/coverage/state/coverage_controller.dart';
import 'package:ada_app/features/map/state/location_controller.dart';
import 'package:ada_app/features/messages/state/messages_controller.dart';
import 'package:ada_app/features/onboarding/data/onboarding_repository.dart';
import 'package:ada_app/features/profile/state/profile_controller.dart';
import 'package:ada_app/features/settings/utils/erase_all_data.dart';
import 'package:ada_app/features/settings/widgets/demo_mode_tile.dart';
import 'package:ada_app/features/settings/widgets/settings_tile.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  // "Apagar meus dados": pergunta com um texto claro e, confirmado, apaga tudo e
  // avisa. Pega os controladores ANTES do await: depois dele o context pode não
  // valer mais.
  Future<void> _eraseData(BuildContext context) async {
    final mode = context.read<ModeController>();
    final alert = context.read<AlertController>();
    final contacts = context.read<ContactsController>();
    final messages = context.read<MessagesController>();
    final coverage = context.read<CoverageController>();
    final location = context.read<LocationController>();
    final onboarding = context.read<OnboardingRepository>();
    final profile = context.read<ProfileController>();
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showConfirmDialog(
      context,
      title: 'Apagar todos os dados?',
      message:
          'Isso apaga os seus contatos, as faixas de horário e as mensagens que '
          'você editou (elas voltam ao texto padrão), e desfaz qualquer alerta '
          'em andamento. Não dá para desfazer.',
      confirmLabel: 'Apagar tudo',
      confirmColor: Theme.of(context).colorScheme.error,
    );
    if (!confirmed) return;

    await eraseAllData(
      mode: mode,
      alert: alert,
      contacts: contacts,
      messages: messages,
      coverage: coverage,
      location: location,
      onboarding: onboarding,
      profile: profile,
    );
    messenger.showSnackBar(
      const SnackBar(content: Text('Seus dados foram apagados.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(39, 30, 39, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Configurações', style: textTheme.headlineSmall),
              // Esta frase vem do Figma, mas parece cópia da tela Rede. Confirmar.
              Text('Ajuste o app do seu jeito.', style: textTheme.bodyLarge),
              const SizedBox(height: 48),
              SettingsTile(
                onTap: () => context.push(AppRoutes.coverage),
                icon: LucideIcons.moonStar,
                title: 'Horário de cobertura',
                description:
                    'Priorize para quem ligar de acordo com o horário.',
              ),
              const SizedBox(height: 11),
              SettingsTile(
                onTap: () => context.push(AppRoutes.messages),
                icon: LucideIcons.messageCircle,
                title: 'Mensagens personalizadas',
                description: 'Personalize as mensagens enviadas em alertas.',
              ),
              const SizedBox(height: 11),
              const DemoModeTile(),
              const SizedBox(height: 11),
              SettingsTile(
                onTap: () => _eraseData(context),
                icon: LucideIcons.trash2,
                accent: AppColors.modeDanger,
                title: 'Apagar meus dados',
                description:
                    'Remove contatos, faixas de horário e mensagens editadas '
                    'deste celular.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
