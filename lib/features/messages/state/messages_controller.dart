// Guarda o texto das três mensagens de emergência e aplica as regras delas.
//
// Mesmo padrão do ContactsController (Fase 5): um ChangeNotifier que as telas
// assinam. Só guardamos os textos EDITADOS pela usuária; enquanto uma mensagem
// não for editada, vale o texto padrão do MessageKind. Por isso "resetar" é
// apenas esquecer a edição.
//
// O texto é um MODELO: o link de localização será acrescentado na hora de
// enviar (Fases 8 e 9), porque ele muda a cada alerta.

import 'package:flutter/foundation.dart';

import 'package:ada_app/features/messages/models/message_kind.dart';

// Motivos pelos quais um texto pode ser recusado.
enum MessagesError { empty, tooLong }

class MessagesController extends ChangeNotifier {
  // Map: um valor para cada chave. Aqui, o texto editado de cada MessageKind.
  final Map<MessageKind, String> _custom = {};

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
    notifyListeners();
    return null;
  }

  // Volta ao texto padrão, apagando a edição.
  void reset(MessageKind kind) {
    if (_custom.remove(kind) != null) notifyListeners();
  }
}
