// Tela "Como podemos te chamar?": a usuária diz o nome (ou apelido) que o ADA usa
// para cumprimentá-la na Home. É opcional, e o nome fica só neste celular.
//
// A mesma tela serve para dois momentos:
//   - primeira vez (editing = false): depois do onboarding. Botões Continuar e
//     Pular; ao terminar, vai para a Home;
//   - editar (editing = true): aberta por Configurações. Botões Salvar e Cancelar;
//     o campo vem preenchido, e deixá-lo em branco REMOVE o nome.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import 'package:ada_app/core/routes/app_router.dart';
import 'package:ada_app/features/profile/state/profile_controller.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, this.editing = false});

  final bool editing;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.editing) {
      _nameController.text = context.read<ProfileController>().name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // Terminou: a primeira vez segue para a Home; a edição volta a Configurações.
  void _done() {
    if (widget.editing) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  String? _validate(String? value) {
    final text = (value ?? '').trim();
    // Ao editar, em branco é permitido: remove o nome.
    if (text.isEmpty) {
      return widget.editing ? null : 'Digite um nome ou toque em Pular.';
    }
    if (text.length > ProfileController.maxNameLength) {
      return 'Use até ${ProfileController.maxNameLength} letras.';
    }
    return null;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final controller = context.read<ProfileController>();
    final text = _nameController.text;
    if (text.trim().isEmpty) {
      controller.skip(); // só chega aqui ao editar: remove o nome
    } else {
      controller.save(text);
    }
    _done();
  }

  void _skip() {
    context.read<ProfileController>().skip();
    _done();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final editing = widget.editing;

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
                          editing ? 'Seu nome' : 'Como podemos te chamar?',
                          style: textTheme.headlineSmall?.copyWith(
                            fontSize: 28,
                          ),
                        ),
                      ),
                      const SizedBox(height: 17),
                      Text(
                        editing
                            ? 'Deixe em branco para remover. O nome fica só '
                                  'neste celular.'
                            : 'Só para te cumprimentar. O nome fica só neste '
                                  'celular.',
                        style: textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _nameController,
                        style: textTheme.labelLarge,
                        autofocus: false,
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
                    child: Text(editing ? 'Salvar' : 'Continuar'),
                  ),
                  const SizedBox(height: 8),
                  // Pular (primeira vez) ou Cancelar (editar): ambos saem sem
                  // mudar o nome, com alvo de toque de 48.
                  TextButton(
                    onPressed: editing ? () => context.pop() : _skip,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: Text(editing ? 'Cancelar' : 'Pular'),
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
