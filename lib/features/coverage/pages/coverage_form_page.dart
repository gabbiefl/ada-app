// Tela "Nova faixa" / "Editar faixa": liga um CONTATO a um horário.
//
// O mesmo formulário serve para criar e para editar (como o de contato): com um
// `ruleId`, a tela edita essa faixa; sem ele, cria uma nova. Ao salvar, entrega
// os dados ao CoverageController, que valida (início diferente do fim, contato
// que existe, sem cruzar com outra faixa ligada). A tela só mostra o resultado.
//
// Para passar da meia-noite, basta um fim menor que o início (23:00 às 4:00).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import 'package:ada_app/core/theme/app_colors.dart';
import 'package:ada_app/core/widgets/confirm_dialog.dart';
import 'package:ada_app/features/contacts/state/contacts_controller.dart';
import 'package:ada_app/features/coverage/models/coverage_rule.dart';
import 'package:ada_app/features/coverage/state/coverage_controller.dart';
import 'package:ada_app/features/coverage/utils/coverage_logic.dart';

// Como a tela pede um horário. No app abre o seletor de horas do Material; nos
// testes entra uma função que devolve o horário combinado (o seletor de relógio
// é difícil de operar num teste).
typedef TimePickerFn = Future<TimeOfDay?> Function(
  BuildContext context,
  TimeOfDay initial,
);

// O seletor de horas padrão, em formato de 24 horas (23:00, e não 11 PM).
Future<TimeOfDay?> showCoverageTimePicker(
  BuildContext context,
  TimeOfDay initial,
) {
  return showTimePicker(
    context: context,
    initialTime: initial,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
      child: child!,
    ),
  );
}

class CoverageFormPage extends StatefulWidget {
  const CoverageFormPage({
    super.key,
    this.ruleId,
    this.pickTime = showCoverageTimePicker,
  });

  // Se vier preenchido, a tela EDITA esta faixa. Se for null, cria uma nova.
  final String? ruleId;
  final TimePickerFn pickTime;

  @override
  State<CoverageFormPage> createState() => _CoverageFormPageState();
}

class _CoverageFormPageState extends State<CoverageFormPage> {
  // A faixa que está sendo editada (null = criando uma nova).
  CoverageRule? _editing;

  // O que a usuária escolheu até agora. Horas em minutos desde a meia-noite.
  String? _contactId;
  int? _start;
  int? _end;

  // Mensagens de erro de cada parte e uma geral (cruzamento).
  String? _contactError;
  String? _startError;
  String? _endError;
  String? _formError;

  bool get _isEditing => widget.ruleId != null;

  @override
  void initState() {
    super.initState();
    final id = widget.ruleId;
    if (id != null) {
      _editing = context.read<CoverageController>().byId(id);
      _contactId = _editing?.contactId;
      _start = _editing?.start;
      _end = _editing?.end;
    }
  }

  // Abre o seletor de horas para o início ou o fim.
  Future<void> _pick({required bool isStart}) async {
    final current = isStart ? _start : _end;
    final TimeOfDay initial;
    if (current != null) {
      initial = _toTimeOfDay(current);
    } else if (isStart) {
      initial = const TimeOfDay(hour: 8, minute: 0);
    } else {
      // Sugere uma hora depois do início.
      final base = _start ?? 8 * 60;
      initial = _toTimeOfDay((base + 60) % minutesPerDay);
    }

    final picked = await widget.pickTime(context, initial);
    // Depois de um await, a tela pode já ter saído.
    if (picked == null || !mounted) return;

    setState(() {
      final minutes = picked.hour * 60 + picked.minute;
      if (isStart) {
        _start = minutes;
        _startError = null;
      } else {
        _end = minutes;
        _endError = null;
      }
      _formError = null;
    });
  }

  TimeOfDay _toTimeOfDay(int minutes) =>
      TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);

  void _save() {
    final coverage = context.read<CoverageController>();
    final network = context.read<ContactsController>();

    // Primeiro, o que a tela consegue conferir sozinha: faltou escolher algo?
    setState(() {
      _contactError = _contactId == null ? 'Escolha quem será ligado.' : null;
      _startError = _start == null ? 'Escolha o horário de início.' : null;
      _endError = _end == null ? 'Escolha o horário de fim.' : null;
      _formError = null;
    });
    if (_contactId == null || _start == null || _end == null) return;

    final id = _editing?.id;
    final error = id == null
        ? coverage.add(contactId: _contactId!, start: _start!, end: _end!)
        : coverage.update(
            id,
            contactId: _contactId!,
            start: _start!,
            end: _end!,
          );

    if (error == null) {
      context.pop();
      return;
    }

    // O controlador recusou: explica o motivo no lugar certo.
    setState(() {
      switch (error) {
        case CoverageError.sameStartEnd:
          _endError = 'O fim precisa ser diferente do início.';
        case CoverageError.invalidTime:
          _formError = 'Escolha um horário válido.';
        case CoverageError.contactMissing:
          _contactError = 'Esse contato não existe mais.';
        case CoverageError.notFound:
          _formError = 'Essa faixa não existe mais.';
        case CoverageError.overlaps:
          final conflict = coverage.findConflict(
            ignoreId: id,
            start: _start!,
            end: _end!,
          );
          final who = conflict == null
              ? ''
              : ' (${network.byId(conflict.contactId)?.name ?? 'contato removido'})';
          final range = conflict == null
              ? 'outra faixa'
              : formatRange(conflict);
          _formError =
              'Esse horário cruza com $range$who. Ajuste o horário ou desligue '
              'a outra faixa antes.';
      }
    });
  }

  Future<void> _remove() async {
    final coverage = context.read<CoverageController>();
    final rule = _editing;
    if (rule == null) return;

    final confirmed = await showConfirmDialog(
      context,
      title: 'Remover a faixa?',
      message:
          'A faixa ${formatRange(rule)} deixa de existir e esse horário fica '
          'sem cobertura.',
      confirmLabel: 'Remover',
      confirmColor: Theme.of(context).colorScheme.error,
    );
    if (!confirmed || !mounted) return;

    coverage.remove(rule.id);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final network = context.watch<ContactsController>();

    // Editar uma faixa que não existe mais (ex.: foi apagada): avisa e volta.
    if (_isEditing && _editing == null) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(40, 30, 40, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Faixa não encontrada', style: textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text('Essa faixa não existe mais.', style: textTheme.bodyLarge),
                const Spacer(),
                OutlinedButton(
                  onPressed: () => context.pop(),
                  child: const Text('Voltar'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final crossesMidnight = _start != null && _end != null && _end! < _start!;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Expanded + rolagem: o formulário rola; os botões ficam fixos embaixo.
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(40, 30, 40, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEditing ? 'Editar faixa' : 'Nova faixa',
                      style: textTheme.headlineSmall,
                    ),
                    Text(
                      'Escolha quem será ligado e em que horário.',
                      style: textTheme.bodySmall,
                    ),
                    const SizedBox(height: 28),
                    const _Label('Quem será ligado'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _contactId,
                      isExpanded: true,
                      hint: const Text('Escolha o contato'),
                      decoration: InputDecoration(errorText: _contactError),
                      items: [
                        for (final c in network.contacts)
                          DropdownMenuItem(value: c.id, child: Text(c.name)),
                      ],
                      onChanged: (value) => setState(() {
                        _contactId = value;
                        _contactError = null;
                        _formError = null;
                      }),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _TimeField(
                            label: 'Início',
                            minutes: _start,
                            error: _startError,
                            onTap: () => _pick(isStart: true),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _TimeField(
                            label: 'Fim',
                            minutes: _end,
                            error: _endError,
                            onTap: () => _pick(isStart: false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      crossesMidnight
                          ? 'Essa faixa passa da meia-noite: vale das '
                                '${formatMinutes(_start!)} até as '
                                '${formatMinutes(_end!)} do dia seguinte.'
                          : 'A faixa vale todos os dias. O horário de início '
                                'conta; o de fim já não conta. Para passar da '
                                'meia-noite, escolha um fim menor que o '
                                'início (ex.: 23:00 às 4:00).',
                      style: textTheme.bodySmall,
                    ),
                    if (_formError != null) ...[
                      const SizedBox(height: 16),
                      _ErrorBox(text: _formError!),
                    ],
                    if (_isEditing) ...[
                      const SizedBox(height: 24),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _remove,
                          icon: const Icon(LucideIcons.trash2, size: 20),
                          label: const Text('Remover faixa'),
                          style: TextButton.styleFrom(
                            foregroundColor: theme.colorScheme.error,
                          ),
                        ),
                      ),
                    ],
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
                    child: const Text('Salvar faixa'),
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

// Rótulo de um campo, no mesmo estilo do formulário de contato.
class _Label extends StatelessWidget {
  const _Label(this.text);

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

// Campo que mostra um horário e abre o seletor ao tocar. O InputDecorator dá o
// mesmo visual dos outros campos (borda, erro) a algo que não é digitado.
class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.minutes,
    required this.error,
    required this.onTap,
  });

  final String label;
  final int? minutes;
  final String? error;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(label),
        const SizedBox(height: 8),
        InkWell(
          // A chave permite aos testes tocar no CAMPO (e não no rótulo).
          key: Key('time-field-$label'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: InputDecorator(
            decoration: InputDecoration(
              errorText: error,
              errorMaxLines: 3,
              suffixIcon: const Icon(LucideIcons.clock, size: 20),
            ),
            child: Text(
              minutes == null ? 'Escolher' : formatMinutes(minutes!),
              style: minutes == null
                  ? theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    )
                  : theme.textTheme.bodyMedium,
            ),
          ),
        ),
      ],
    );
  }
}

// Caixa vermelha com o motivo de a faixa ter sido recusada.
class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.modeDanger.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(
            LucideIcons.triangleAlert,
            size: 22,
            color: AppColors.modeDangerText,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppColors.modeDangerText),
            ),
          ),
        ],
      ),
    );
  }
}
