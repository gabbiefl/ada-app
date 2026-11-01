// Tela "Rede de contatos": as pessoas de confiança que recebem o alerta.
//
// A lista vem do ContactsController (provider). Cadastrar, editar e remover
// contatos de verdade entram nos próximos passos da Fase 5.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:ada_app/core/routes/app_router.dart';
import 'package:ada_app/core/theme/app_colors.dart';
import 'package:ada_app/features/contacts/state/contacts_controller.dart';
import 'package:ada_app/features/contacts/widgets/add_contact_card.dart';
import 'package:ada_app/features/contacts/widgets/contact_card.dart';

class ContactsPage extends StatelessWidget {
  const ContactsPage({super.key});

  // Cores dos avatares, na ordem em que aparecem no design.
  static const _avatarColors = [
    AppColors.brand,
    AppColors.avatarGreen,
    AppColors.modeAttention,
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // watch: a tela se redesenha sempre que a rede de contatos muda.
    final network = context.watch<ContactsController>();
    final contacts = network.contacts;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(39, 30, 39, 24),
          child: Column(
            children: [
              // Título à esquerda e contador à direita.
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rede de contatos',
                          style: textTheme.headlineSmall,
                        ),
                        Text(
                          'Cadastre a sua rede de confiança.',
                          style: textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${network.count}/${ContactsController.maxContacts}',
                    style: textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              for (var i = 0; i < contacts.length; i++) ...[
                ContactCard(
                  name: contacts[i].name,
                  phone: contacts[i].formattedPhone,
                  color: _avatarColors[i % _avatarColors.length],
                ),
                const SizedBox(height: 9),
              ],
              // Lista vazia = 5 espaços "Adicionar contato": já é o estado vazio.
              for (var i = 0; i < network.freeSlots; i++) ...[
                AddContactCard(onTap: () => context.push(AppRoutes.newContact)),
                const SizedBox(height: 9),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
