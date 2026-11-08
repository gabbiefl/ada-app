// Tela "Mensagens - Editar": edição do texto de uma mensagem.
//
// Recebe QUAL mensagem editar (MessageKind). StatefulWidget porque guarda o
// controlador do campo de texto e a mensagem de erro. Salvar passa pelo
// MessagesController, que aplica as regras (vazio / mais de 200 letras).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import 'package:ada_app/core/theme/app_colors.dart';
import 'package:ada_app/core/widgets/page_header.dart';
import 'package:ada_app/features/messages/models/message_kind.dart';
import 'package:ada_app/features/messages/state/messages_controller.dart';

class MessageEditPage extends StatefulWidget {
  const MessageEditPage({super.key, required this.kind});

  final MessageKind kind;

  @override
  State<MessageEditPage> createState() => _MessageEditPageState();
}

class _MessageEditPageState extends State<MessageEditPage> {
  // TextEditingController: guarda e controla o texto do campo.
  late final TextEditingController _controller;

  // Motivo da recusa ao salvar (null = sem erro para mostrar).
  String? _error;

  @override
  void initState() {
    super.initState();
    // read (e não watch): só queremos o texto atual, uma vez, ao abrir.
    final current = context.read<MessagesController>().textOf(widget.kind);
    _controller = TextEditingController(text: current);
  }

  void _save() {
    final error = context.read<MessagesController>().save(
      widget.kind,
      _controller.text,
    );
    if (error == null) {
      context.pop();
      return;
    }
    setState(() {
      _error = switch (error) {
        MessagesError.empty => 'Escreva uma mensagem antes de salvar.',
        MessagesError.tooLong =>
          'A mensagem pode ter no máximo ${MessageKind.maxLength} letras.',
      };
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(40, 30, 40, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PageHeader(
                      title: 'Mensagens',
                      subtitle: 'Editando: ${widget.kind.title}',
                      trailing: IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(LucideIcons.arrowLeft),
                        color: AppColors.iconMuted,
                        tooltip: 'Voltar',
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Texto da mensagem',
                      style: textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontVariations: const [FontVariation('wght', 600)],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Stack: o contador fica SOBRE o campo, no canto inferior.
                    Stack(
                      children: [
                        SizedBox(
                          height: 172,
                          child: TextField(
                            controller: _controller,
                            maxLength: MessageKind.maxLength,
                            // expands + maxLines null: o texto ocupa a caixa toda.
                            expands: true,
                            maxLines: null,
                            textAlignVertical: TextAlignVertical.top,
                            style: textTheme.bodyMedium,
                            // counterText vazio: o contador padrão do Flutter
                            // fica fora da caixa; desenhamos o nosso dentro.
                            decoration: const InputDecoration(
                              counterText: '',
                              contentPadding: EdgeInsets.fromLTRB(
                                26,
                                26,
                                26,
                                36,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 20,
                          bottom: 14,
                          // ListenableBuilder: refaz só o contador a cada letra.
                          child: ListenableBuilder(
                            listenable: _controller,
                            builder: (context, _) => Text(
                              '${_controller.text.length}/${MessageKind.maxLength}',
                              style: textTheme.bodySmall?.copyWith(
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.modeDanger,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: InkWell(
                        onTap: () => setState(() {
                          _controller.text = widget.kind.defaultText;
                          _error = null;
                        }),
                        // Altura mínima de 48: o texto sozinho é pequeno demais para
                        // tocar. O Row fica centralizado dentro dela.
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 48),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.rotateCcw,
                                size: 16,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Resetar para padrão',
                                style: textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontVariations: const [
                                    FontVariation('wght', 600),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(40, 0, 40, 24),
              child: Column(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => context.pop(),
                    icon: const Icon(LucideIcons.x, size: 24),
                    label: const Text('Cancelar'),
                  ),
                  const SizedBox(height: 11),
                  FilledButton(
                    onPressed: _save,
                    child: const Text('Salvar mensagem'),
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
