// Guarda o texto das três mensagens de emergência e aplica as regras delas.
//
// Mesmo padrão do ContactsController (Fase 5): um ChangeNotifier que as telas
// assinam. Só guardamos os textos EDITADOS pela usuária; enquanto uma mensagem
// não for editada, vale o texto padrão do MessageKind. Por isso "resetar" é
// apenas esquecer a edição.
//
// Os textos editados são carregados de um MessagesRepository ao abrir o app
// (load) e gravados de novo a cada mudança. Sem repositório, vivem só na memória.
//
// O texto é um MODELO: o link de localização será acrescentado na hora de
// enviar (Fases 8 e 9), porque ele muda a cada alerta.

import 'package:flutter/foundation.dart';

import 'package:ada_app/features/messages/data/messages_repository.dart';
import 'package:ada_app/features/messages/models/message_kind.dart';

// Motivos pelos quais um texto pode ser recusado.
enum MessagesError { empty, tooLong }

class MessagesController extends ChangeNotifier {
  MessagesController({this.repository});

  final MessagesRepository? repository;

  // Map: um valor para cada chave. Aqui, o texto editado de cada MessageKind.
  final Map<MessageKind, String> _custom = {};

  // Fila de gravações: cada uma só começa quando a anterior termina.
  Future<void> _pendingSave = Future.value();
  bool _disposed = false;

  // O carregamento em andamento (ou já feito). Quem precisa dos dados prontos,
  // como o alerta, espera por `ready` em vez de ler uma lista ainda vazia.
  Future<void>? _loading;

  // Completa quando os textos guardados já foram lidos. Sem repositório, ou
  // antes de load() ser chamado, já está pronto.
  Future<void> get ready => _loading ?? Future.value();

  // Lê os textos guardados. Chamado uma vez, ao abrir o app.
  Future<void> load() => _loading = _load();

  Future<void> _load() async {
    final repository = this.repository;
    if (repository == null) return;

    try {
      final saved = await repository.load();
      if (_disposed) return;
      _custom.clear();
      // Confere de novo as regras: dado guardado não é garantido válido.
      for (final entry in saved.entries) {
        final text = entry.value.trim();
        if (text.isNotEmpty &&
            text.length <= MessageKind.maxLength &&
            text != entry.key.defaultText) {
          _custom[entry.key] = text;
        }
      }
      notifyListeners();
    } catch (_) {
      // Dado ilegível ou armazenamento indisponível: valem os textos padrão.
      // Nada é impresso: o texto pode conter dado pessoal.
    }
  }

  // Avisa as telas e grava os textos editados. Chamado depois de toda mudança.
  void _changed() {
    notifyListeners();

    final repository = this.repository;
    if (repository == null) return;

    // Cópia neste instante: se mudar de novo antes de gravar, esta gravação
    // continua com os dados certos.
    final snapshot = Map<MessageKind, String>.of(_custom);
    _pendingSave = _pendingSave
        .then((_) => repository.save(snapshot))
        .catchError((_) {}); // falha ao gravar não derruba o app
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  // Texto em uso: o editado ou, se não houver, o padrão.
  String textOf(MessageKind kind) => _custom[kind] ?? kind.defaultText;

  // A mensagem foi editada pela usuária? (útil para mostrar "Resetar").
  bool isCustomized(MessageKind kind) => _custom.containsKey(kind);

  // Padrão de retorno: null = deu certo; senão, o motivo da recusa.
  MessagesError? save(MessageKind kind, String text) {
    final clean = text.trim();
    if (clean.isEmpty) return MessagesError.empty;
    if (clean.length > MessageKind.maxLength) return MessagesError.tooLong;

    // Igual ao padrão: não precisa guardar nada.
    if (clean == kind.defaultText) {
      reset(kind);
      return null;
    }
    if (_custom[kind] == clean) return null; // nada mudou: não avisa à toa

    _custom[kind] = clean;
    _changed();
    return null;
  }

  // Volta ao texto padrão, apagando a edição.
  void reset(MessageKind kind) {
    if (_custom.remove(kind) != null) _changed();
  }
}
