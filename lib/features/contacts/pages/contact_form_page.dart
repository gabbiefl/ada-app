// Tela "Novo contato": cadastro de uma pessoa da rede de confiança.
//
// Formulário de verdade: valida nome e telefone, e ao salvar entrega o contato
// ao ContactsController. As regras (limite de 5, telefone repetido) ficam no
// controlador; a tela só mostra o resultado.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import 'package:ada_app/core/theme/app_colors.dart';
import 'package:ada_app/features/contacts/formatters/phone_input_formatter.dart';
import 'package:ada_app/features/contacts/models/contact.dart';
import 'package:ada_app/features/contacts/state/contacts_controller.dart';
import 'package:ada_app/features/contacts/validators/contact_validators.dart';
import 'package:ada_app/features/contacts/widgets/info_box.dart';

// StatefulWidget: a tela guarda coisas que vivem enquanto ela está aberta (os
// controladores dos campos e o telefone que o controlador recusou).
class ContactFormPage extends StatefulWidget {
  // contactId: se vier preenchido, a tela EDITA esse contato (o mesmo
  // formulário serve para cadastrar e editar). Se for null, cadastra um novo.
  const ContactFormPage({super.key, this.contactId});

  final String? contactId;

  @override
  State<ContactFormPage> createState() => _ContactFormPageState();
}

class _ContactFormPageState extends State<ContactFormPage> {
  // GlobalKey<FormState>: a "chave" que dá acesso ao Form de fora, para chamar
  // validate() quando a usuária tocar em Salvar.
  final _formKey = GlobalKey<FormState>();

  // TextEditingController: lê (e controla) o texto digitado em um campo.
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  // Telefone (só dígitos) que o ContactsController recusou por já existir.
  String? _duplicatePhone;

  // O contato que está sendo editado (null = cadastro novo).
  Contact? _editing;

  bool get _isEditing => _editing != null;

  // initState roda uma vez, quando a tela nasce: ideal para preencher os campos.
  @override
  void initState() {
    super.initState();
    final id = widget.contactId;
    if (id != null) {
      _editing = context.read<ContactsController>().byId(id);
      _nameController.text = _editing?.name ?? '';
      _phoneController.text = _editing?.formattedPhone ?? '';
    }
  }

  // Como todo controller, precisa ser liberado quando a tela sai.
  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // Regras do telefone: as do ContactValidators + "já existe na rede".
  String? _validatePhone(String? value) {
    if (ContactValidators.digitsOnly(value ?? '') == _duplicatePhone) {
      return 'Este telefone já está na sua rede.';
    }
    return ContactValidators.phone(value);
  }

  void _save() {
    // validate() roda o validator de TODOS os campos e mostra os erros.
    if (!_formKey.currentState!.validate()) return;

    // read, e não watch: estamos num clique, só damos uma ordem.
    final controller = context.read<ContactsController>();
    final name = _nameController.text;
    final phone = _phoneController.text;
    final error = _isEditing
        ? controller.update(_editing!.id, name: name, phone: phone)
        : controller.add(name: name, phone: phone);

    switch (error) {
      case null:
        context.pop(); // deu certo: volta para a Rede
      case ContactsError.duplicatePhone:
        // Guarda o telefone recusado e valida de novo para o erro aparecer.
        setState(() {
          _duplicatePhone = ContactValidators.digitsOnly(_phoneController.text);
        });
        _formKey.currentState!.validate();
      case ContactsError.limitReached:
        _showMessage(
          'Sua rede já tem ${ContactsController.maxContacts} contatos.',
        );
      case ContactsError.invalidData || ContactsError.notFound:
        _showMessage('Não foi possível salvar o contato. Tente novamente.');
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    // Cadastro: número que o novo contato vai ocupar (nunca passa de 5).
    // Edição: quantos contatos a rede tem.
    final network = context.watch<ContactsController>();
    final position = _isEditing
        ? network.count
        : math.min(network.count + 1, ContactsController.maxContacts);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Expanded + rolagem: o formulário rola; os botões ficam fixos embaixo.
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(40, 30, 40, 16),
                child: Form(
                  key: _formKey,
                  // Depois do primeiro erro, os campos revalidam enquanto a
                  // usuária digita (some o erro assim que ela corrige).
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _isEditing ? 'Editar contato' : 'Novo contato',
                            style: textTheme.headlineSmall,
                          ),
                          Text(
                            '$position/${ContactsController.maxContacts}',
                            style: textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      // Ao editar, o contato já existe: sem "Escolher da agenda".
                      if (!_isEditing) ...[
                        // Botão de borda azul-marinho: muda só a aparência do
                        // OutlinedButton do tema (cantos 20, altura 71, texto preto).
                        OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(LucideIcons.bookUser, size: 24),
                          label: const Text('Escolher da agenda'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 71),
                            foregroundColor: theme.colorScheme.onSurface,
                            side: BorderSide(color: theme.colorScheme.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            iconSize: 24,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const _OrDivider(),
                        const SizedBox(height: 28),
                      ],
                      const _FieldLabel('Nome'),
                      const SizedBox(height: 8),
                      // TextFormField = TextField + validator, para usar no Form.
                      TextFormField(
                        controller: _nameController,
                        style: textTheme.labelLarge,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        validator: ContactValidators.name,
                        decoration: const InputDecoration(
                          hintText: 'Nome do contato',
                          prefixIcon: Icon(LucideIcons.user, size: 18),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const _FieldLabel('Telefone'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _phoneController,
                        style: textTheme.labelLarge,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _save(),
                        validator: _validatePhone,
                        // Ignora letras, limita a 11 dígitos e aplica a máscara
                        // (51) 99999-9999 enquanto a usuária digita.
                        inputFormatters: [PhoneInputFormatter()],
                        decoration: const InputDecoration(
                          hintText: '(51) 99999-0000',
                          prefixIcon: Icon(LucideIcons.phone, size: 18),
                        ),
                      ),
                      const SizedBox(height: 32),
                      const InfoBox(),
                    ],
                  ),
                ),
              ),
            ),
            // Botões fixos no rodapé: Cancelar (secundário) e Salvar (principal).
            Padding(
              padding: const EdgeInsets.fromLTRB(40, 0, 40, 24),
              child: Column(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => context.pop(),
                    icon: const Icon(LucideIcons.x, size: 24),
                    label: const Text('Cancelar'),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _save,
                    child: const Text('Salvar contato'),
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

// Rótulo acima de cada campo (Bold 15, azul-marinho).
class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: AppColors.modeNormal,
        fontWeight: FontWeight.w700,
        fontVariations: const [FontVariation('wght', 700)],
      ),
    );
  }
}

// Linha com "ou preencha" no meio.
class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(child: Divider(color: theme.colorScheme.outline)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            'ou preencha',
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              fontVariations: const [FontVariation('wght', 600)],
            ),
          ),
        ),
        Expanded(child: Divider(color: theme.colorScheme.outline)),
      ],
    );
  }
}
