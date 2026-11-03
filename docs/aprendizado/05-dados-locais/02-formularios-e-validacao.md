# 02 — Formulários e validação

Um formulário junta **campos**, **validação** (o texto está certo?) e uma **ação** ao salvar.

## As peças
| Peça | Para que serve |
|---|---|
| `Form` | Agrupa os campos e valida todos de uma vez |
| `GlobalKey<FormState>` | A "chave" que dá acesso ao `Form` de fora (para chamar `validate()`) |
| `TextFormField` | Um `TextField` que se encaixa no `Form` e aceita `validator` |
| `TextEditingController` | Lê (e define) o texto de um campo |

## Exemplo mínimo
```dart
final _formKey = GlobalKey<FormState>();
final _nome = TextEditingController();

Form(
  key: _formKey,
  child: Column(
    children: [
      TextFormField(
        controller: _nome,
        validator: (valor) => (valor ?? '').trim().isEmpty ? 'Informe o nome.' : null,
      ),
      FilledButton(
        onPressed: () {
          if (_formKey.currentState!.validate()) {
            // tudo certo: salvar
          }
        },
        child: const Text('Salvar'),
      ),
    ],
  ),
)
```

## Regra do `validator`
Devolve a **mensagem de erro**, ou `null` quando está tudo certo. É um padrão do Flutter: `null` significa "sem problema". Escrevendo o validador como função pura (só recebe texto e devolve resultado), ele é fácil de testar e serve ao formulário e ao controlador.

## Validar enquanto digita
`autovalidateMode: AutovalidateMode.onUserInteraction` revalida a cada alteração depois que a usuária mexeu no campo: o erro some assim que ela corrige.

## Ciclo de vida: `initState` e `dispose`
Telas com campos são `StatefulWidget`.
- `initState` roda **uma vez**, quando a tela nasce: bom para preencher os campos (edição).
- `dispose` roda quando a tela sai: libere os `TextEditingController`, senão sobra memória ocupada.

## Mesmo formulário para cadastrar e editar
Um parâmetro opcional (`contactId`) muda o comportamento: com ele, a tela preenche os campos e chama `update`; sem ele, chama `add`.

## Máscara com `TextInputFormatter`
Um formatter recebe o texto **antes** e **depois** de cada tecla e devolve o que fica no campo:
```dart
inputFormatters: [PhoneInputFormatter()], // (51) 99999-9999 enquanto digita
```
Cuidados: manter o cursor no lugar certo e tratar o backspace sobre símbolos da máscara (senão o campo trava).

## Guardar sem máscara
O campo mostra `(51) 99999-0001`, mas guardamos só os dígitos (`51999990001`). Fica mais fácil validar, comparar números repetidos e usar em `tel:` e `wa.me`.

## No ADA
- Formulário: [`contact_form_page.dart`](../../../lib/features/contacts/pages/contact_form_page.dart)
- Validação: [`contact_validators.dart`](../../../lib/features/contacts/validators/contact_validators.dart)
- Máscara: [`phone_input_formatter.dart`](../../../lib/features/contacts/formatters/phone_input_formatter.dart)
- Testes: [`contact_form_page_test.dart`](../../../test/features/contact_form_page_test.dart), [`contact_validators_test.dart`](../../../test/features/contact_validators_test.dart), [`phone_input_formatter_test.dart`](../../../test/features/phone_input_formatter_test.dart)
