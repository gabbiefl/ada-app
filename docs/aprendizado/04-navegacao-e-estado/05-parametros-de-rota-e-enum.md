# 05 — Parâmetros de rota e enum com propriedades

Uma rota pode **carregar um dado** no próprio endereço (`/edit/danger`). E um `enum` pode **carregar dados** além do nome.

## Parâmetro de rota
No `go_router`, `:nome` no caminho vira um parâmetro:
```dart
GoRoute(
  path: 'edit/:kind',
  builder: (context, state) {
    final nome = state.pathParameters['kind']; // 'danger'
    ...
  },
)
```
Para navegar, monte o endereço com o valor:
```dart
context.push('/settings/messages/edit/${kind.name}');
```
No ADA o mesmo mecanismo aparece duas vezes: `:id` (contato) e `:kind` (mensagem). Deixe a montagem do endereço numa função (`AppRoutes.editMessage(kind)`) para o texto não se espalhar pelo código.

## Texto de volta para enum
O endereço é sempre texto. Para voltar ao enum:
```dart
final kind = MessageKind.values.asNameMap()['danger']; // MessageKind.danger
```
`asNameMap()` devolve um `Map<String, MessageKind>`. Um nome que não existe dá `null`, então **trate esse caso** (no ADA, aparece "Mensagem não encontrada"). Quem digita ou cola um endereço errado não pode derrubar o app.

## Enum com propriedades
Cada valor pode carregar seus próprios dados:
```dart
enum MessageKind {
  danger(title: 'Modo perigo', defaultText: 'Preciso de ajuda...'),
  arrived(title: 'Cheguei bem', defaultText: 'Cheguei em segurança...');

  const MessageKind({required this.title, required this.defaultText});
  final String title;
  final String defaultText;
}
```
O título e o padrão ficam junto do tipo, e não espalhados pelas telas. Para percorrer todos: `MessageKind.values`.

## `switch` sobre enum
O Dart exige tratar **todos** os valores, então não precisa de `default`. Se entrar um valor novo no enum, o compilador aponta cada `switch` que ficou incompleto.
```dart
final cor = switch (kind) {
  MessageKind.danger => vermelho,
  MessageKind.attention => amarelo,
  MessageKind.arrived => verde,
};
```

## No ADA
- Enum: [`message_kind.dart`](../../../lib/features/messages/models/message_kind.dart)
- Rota com `:kind`: [`app_router.dart`](../../../lib/core/routes/app_router.dart)
- `switch` das cores e lista gerada do enum: [`messages_page.dart`](../../../lib/features/messages/pages/messages_page.dart)
- Teste do fluxo: [`messages_pages_test.dart`](../../../test/features/messages_pages_test.dart)
