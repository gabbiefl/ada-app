# 05 — Reusar o padrão e não confiar no dado guardado

Na Fase 6 guardamos as mensagens com o **mesmo desenho** dos contatos. Reusar um padrão que já funciona é mais rápido e mais seguro do que inventar outro.

## O padrão (controlador + repositório + provider)
| Peça | Papel |
|---|---|
| Model / enum | O que é o dado (`Contact`, `MessageKind`) |
| Repositório (contrato) | `load()` e `save()`, sem dizer onde |
| Repositório seguro | Guarda no aparelho (`flutter_secure_storage`) |
| Repositório em memória | Usado nos testes |
| Controlador (`ChangeNotifier`) | Regras + avisa as telas + manda gravar |
| `provider` | Entrega o controlador às telas |

Um dado novo repete as mesmas peças. Nenhum pacote novo foi preciso.

## Guardar só o que mudou
As mensagens têm um texto **padrão** no código. Só os textos **editados** vão para o armazenamento, num `Map<MessageKind, String>`:
```dart
String textOf(MessageKind kind) => _custom[kind] ?? kind.defaultText;
```
`??` usa o padrão quando não há edição. "Resetar" vira apenas apagar a edição, e mudar o padrão numa versão nova do app vale para quem nunca editou.

## Mapa para JSON e de volta
```dart
// gravar: chave do enum vira texto
jsonEncode({for (final e in custom.entries) e.key.name: e.value});
// ler: texto vira enum; nome desconhecido é ignorado
final byName = MessageKind.values.asNameMap();
```

## Nunca confie no dado guardado
O que está no disco pode ter vindo de outra versão do app, ficar corrompido ou ser editado. Por isso o `load()` **aplica as regras de novo** (texto vazio, mais de 200 letras, igual ao padrão) em vez de assumir que o `save()` já validou. Se a leitura falhar, o app usa os padrões e não quebra.

## Modelo de texto (template)
A mensagem guardada é um **modelo**. O link de localização muda a cada alerta, então não fica gravado no texto: será acrescentado na hora de enviar (Fases 8 e 9).

## Privacidade
O texto pode ter dado pessoal ("estou na casa da…"). Fica no armazenamento seguro e **nunca** vai para `print` ou `debugPrint`.

## No ADA
- Repositório: [`messages_repository.dart`](../../../lib/features/messages/data/messages_repository.dart)
- Controlador: [`messages_controller.dart`](../../../lib/features/messages/state/messages_controller.dart)
- Testes: [`messages_controller_test.dart`](../../../test/features/messages_controller_test.dart), [`messages_repository_test.dart`](../../../test/features/messages_repository_test.dart)
- Padrão original: [Persistência local](03-persistencia-local.md)
