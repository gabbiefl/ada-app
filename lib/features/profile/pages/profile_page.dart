// Tela "Como podemos te chamar?": a usuária diz o nome (ou apelido) que o ADA usa
// para cumprimentá-la na Home. É opcional, e o nome fica só neste celular.
//
// Aparece uma vez, depois do onboarding: Continuar grava o nome e Pular segue sem
// nome. Nos dois casos vai para a Home. Para trocar o nome depois, a usuária usa
// "Apagar meus dados" (Configurações), e a pergunta volta.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import 'package:ada_app/core/routes/app_router.dart';
import 'package:ada_app/features/profile/state/profile_controller.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String? _validate(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Digite um nome ou toque em Pular.';
    if (text.length > ProfileController.maxNameLength) {
      return 'Use até ${ProfileController.maxNameLength} letras.';
    }
    return null;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    context.read<ProfileController>().save(_nameController.text);
    context.go(AppRoutes.home);
  }

  void _skip() {
    context.read<ProfileController>().skip();
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(39, 56, 39, 16),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          'Como podemos te chamar?',
                          style: textTheme.headlineSmall?.copyWith(
                            fontSize: 28,
                          ),
                        ),
                      ),
                      const SizedBox(height: 17),
                      Text(
                        'Só para te cumprimentar. O nome fica só neste '
                        'celular.',
                        style: textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _nameController,
                        style: textTheme.labelLarge,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _save(),
                        validator: _validate,
                        decoration: const InputDecoration(
                          hintText: 'Seu nome ou apelido',
                          prefixIcon: Icon(LucideIcons.user, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(42, 0, 42, 32),
              child: Column(
                children: [
                  FilledButton(
                    onPressed: _save,
                    child: const Text('Continuar'),
                  ),
                  const SizedBox(height: 8),
                  // Alvo de toque de 48, como as outras ações de texto.
                  TextButton(
                    onPressed: _skip,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text('Pular'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
