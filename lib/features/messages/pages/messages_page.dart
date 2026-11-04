// Tela "Mensagens": as três mensagens enviadas nos alertas (Perigo, Atenção e
// "Cheguei bem"). Os textos vêm do MessagesController; "Editar" abre a edição
// da mensagem tocada.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import 'package:ada_app/core/routes/app_router.dart';
import 'package:ada_app/core/theme/app_colors.dart';
import 'package:ada_app/core/theme/mode_colors.dart';
import 'package:ada_app/core/widgets/page_header.dart';
import 'package:ada_app/features/messages/models/message_kind.dart';
import 'package:ada_app/features/messages/state/messages_controller.dart';
import 'package:ada_app/features/messages/widgets/message_card.dart';

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  // Cor do pontinho de cada mensagem (a mesma do modo a que ela pertence).
  Color _colorOf(MessageKind kind, ModeColors modeColors) {
    switch (kind) {
      case MessageKind.danger:
        return modeColors.danger;
      case MessageKind.attention:
        return modeColors.attention;
      case MessageKind.arrived:
        return AppColors.avatarGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    final modeColors = ModeColors.of(context);
    // watch: a tela se redesenha quando um texto muda.
    final messages = context.watch<MessagesController>();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(40, 30, 40, 24),
          child: Column(
            children: [
              PageHeader(
                title: 'Mensagens',
                subtitle: 'Personalize as mensagens enviadas em alertas.',
                trailing: IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(LucideIcons.arrowLeft),
                  color: AppColors.placeholder,
                ),
              ),
              const SizedBox(height: 32),
              // Uma lista de cards gerada a partir do enum: um por mensagem.
              for (final kind in MessageKind.values) ...[
                MessageCard(
                  title: kind.title,
                  text: messages.textOf(kind),
                  color: _colorOf(kind, modeColors),
                  onEdit: () => context.push(AppRoutes.editMessage(kind)),
                ),
                if (kind != MessageKind.values.last) const SizedBox(height: 15),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
