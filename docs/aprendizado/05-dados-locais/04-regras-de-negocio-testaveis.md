# 04 — Regras de negócio testáveis

**Regra de negócio** é o que o app *decide* (não o que ele *desenha*): "no máximo 5 contatos", "o mesmo telefone não entra duas vezes". Colocada em uma classe própria, ela pode ser testada **sem tela**.

## Onde ficam as regras
No `ContactsController` (um `ChangeNotifier`), não nos widgets. A tela só pede ("cadastre isto") e mostra o resultado.

## Resultado: `null` ou o motivo da recusa
Cada operação devolve `null` se deu certo, ou um `enum` com o motivo:
```dart
enum ContactsError { limitReached, duplicatePhone, invalidData, notFound }

ContactsError? add({required String name, required String phone}) {
  if (isFull) return ContactsError.limitReached;
  ...
  return null; // deu certo
}
```
A tela decide a mensagem de cada caso com um `switch`, e o compilador avisa se esquecermos algum.

## Estado derivado
`isFull`, `freeSlots` e `count` são **calculados** da lista, não guardados em variáveis à parte:
```dart
bool get isFull => count >= maxContacts;
```
Assim nunca ficam desatualizados em relação à lista. A tela "rede cheia" só pergunta `isFull`.

## Lista só de leitura
Para ninguém de fora dar `.add()` direto (pulando as regras e o `notifyListeners`), o controlador expõe uma visão protegida:
```dart
UnmodifiableListView<Contact> get contacts => UnmodifiableListView(_contacts);
```

## Não confiar só na tela
O formulário já valida, mas o controlador **valida de novo**. Quem protege a regra é quem a guarda.

## Avisar só quando algo mudou
Recusas não chamam `notifyListeners()`: a tela não se redesenha à toa.

## Testando sem tela
```dart
test('recusa o sexto contato', () {
  final controller = ContactsController();
  // ... cadastra 5 ...
  expect(controller.add(name: 'Sexta', phone: '51988880000'), ContactsError.limitReached);
});
```
Rápido, sem emulador, sem `pumpWidget`. Quando uma regra muda, o teste mostra na hora o que quebrou.

## Pirâmide de testes no ADA
| Nível | Exemplo |
|---|---|
| Unitário | Controlador, validadores, máscara, model |
| Widget | Rede mostra o aviso de 5/5; formulário mostra os erros |
| Fluxo | Adicionar → preencher → salvar → o contato aparece; tocar no card → editar |

## No ADA
- Regras: [`contacts_controller.dart`](../../../lib/features/contacts/state/contacts_controller.dart)
- Testes: [`contacts_controller_test.dart`](../../../test/features/contacts_controller_test.dart), [`contacts_page_test.dart`](../../../test/features/contacts_page_test.dart)
