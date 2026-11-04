// Tela "Configurações": menu que leva a Horário de cobertura, Histórico de
// alertas e Mensagens personalizadas. Por enquanto é estática: os itens ainda
// não abrem as outras telas (a navegação entra na Fase 4).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:ada_app/core/routes/app_router.dart';
import 'package:ada_app/features/settings/widgets/settings_tile.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

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
                onTap: () => context.push(AppRoutes.history),
                icon: LucideIcons.clock,
                title: 'Histórico de alertas',
                description:
                    'Eventos anteriores, com data, horário e localização.',
              ),
              const SizedBox(height: 11),
              SettingsTile(
                onTap: () => context.push(AppRoutes.messages),
                icon: LucideIcons.messageCircle,
                title: 'Mensagens personalizadas',
                description: 'Personalize as mensagens enviadas em alertas.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
