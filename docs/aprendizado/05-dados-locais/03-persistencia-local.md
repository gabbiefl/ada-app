# 03 — Persistência local

**Persistir** é guardar os dados para que continuem lá quando o app fechar e abrir de novo. Sem isso, a lista de contatos sumiria a cada abertura.

## Armazenamento: qual escolher
| Opção | Quando usar |
|---|---|
| `shared_preferences` | Preferências simples (tema, um número). Sem criptografia |
| `flutter_secure_storage` | Dados **sensíveis**. No Android, a chave de criptografia fica no Keystore |
| Banco local (`sqflite`, `drift`) | Muitos dados, buscas e relações |

O ADA usa o `flutter_secure_storage`: são só 5 contatos, mas são **telefones de outras pessoas** (dado pessoal, LGPD). No Chrome o navegador não oferece essa proteção, então lá serve só para testar o fluxo.

## `Future`, `async` e `await`
Ler e gravar levam tempo. Em vez de travar a tela, a função devolve um `Future`: "o resultado chega depois".
```dart
Future<String?> ler() async {
  final texto = await storage.read(key: 'chave'); // espera, sem travar a tela
  return texto;
}
```
- `async` marca a função que usa `await`.
- `await` pausa **aquela função** até o `Future` terminar; o resto do app segue desenhando.

## Repositório: o contrato
Uma classe abstrata diz **o que** fazer, sem dizer **como**:
```dart
abstract class ContactsRepository {
  Future<List<Contact>> load();
  Future<void> save(List<Contact> contacts);
}
```
Cada implementação resolve de um jeito:
- `SecureContactsRepository`: grava no armazenamento seguro, a lista inteira como JSON em uma entrada;
- `InMemoryContactsRepository`: guarda na memória, usado nos testes.

## Injeção de dependência
O controlador **recebe** o repositório pelo construtor, em vez de criá-lo sozinho:
```dart
ContactsController(repository: SecureContactsRepository())
```
Assim as regras da rede (limite, duplicado) não dependem de onde os dados ficam. Trocar o armazenamento, ou usar um falso nos testes, não mexe nelas.

## Carregar e gravar
- Ao abrir o app: `controller.load()` lê o que estava guardado.
- A cada mudança (`add`, `update`, `remove`): o controlador avisa as telas **e** grava uma cópia da lista (`snapshot`).
- As gravações entram numa fila, para a última gravada ser sempre a mais nova.

## Quando algo falha
Dado ilegível ou armazenamento indisponível não pode fechar o app: a leitura falha → rede vazia; a gravação falha → a tela continua certa. E **nada é impresso em log**, porque telefone é dado pessoal.

## No ADA
- Repositório: [`contacts_repository.dart`](../../../lib/features/contacts/data/contacts_repository.dart)
- Controlador: [`contacts_controller.dart`](../../../lib/features/contacts/state/contacts_controller.dart)
- Ligação no app: [`app.dart`](../../../lib/app.dart)
- Testes: [`contacts_repository_test.dart`](../../../test/features/contacts_repository_test.dart)
