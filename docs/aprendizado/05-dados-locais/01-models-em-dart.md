# 01 — Models em Dart

Um **model** é uma classe que representa um "dado do mundo real" no app (um contato, uma mensagem). Ele agrupa os campos em um objeto só, em vez de espalhar `String nome, String telefone` por todo o código.

## Classe imutável
Depois de criado, o objeto **não muda**. Todos os campos são `final`.
```dart
class Contact {
  const Contact({required this.id, required this.name, required this.phone});

  final String id;
  final String name;
  final String phone;
}
```
- `required`: o parâmetro é obrigatório quando se cria o objeto.
- `const` no construtor permite criar objetos constantes (úteis em testes).
- Imutável evita alterações escondidas: quem tem o objeto sabe que ele não vai mudar por baixo.

## `copyWith`: "editar" criando uma cópia
Como o objeto não muda, para editar criamos **outro** com o campo trocado:
```dart
Contact copyWith({String? name, String? phone}) {
  return Contact(id: id, name: name ?? this.name, phone: phone ?? this.phone);
}

final editado = contato.copyWith(name: 'Maria Souza');
```
- `String?` aceita `null`; `??` significa "se for nulo, use o valor atual".
- Um `ChangeNotifier` percebe melhor a mudança quando o objeto na lista é **outro**.

## JSON: guardar e ler
Para gravar no aparelho, o objeto vira um `Map` (e depois texto JSON); para ler, o caminho inverso.
```dart
Map<String, dynamic> toJson() => {'id': id, 'name': name, 'phone': phone};

factory Contact.fromJson(Map<String, dynamic> json) {
  return Contact(
    id: json['id'] as String,
    name: json['name'] as String,
    phone: json['phone'] as String,
  );
}
```
- `factory` é um construtor que monta o objeto a partir de dados.
- `as String` diz ao Dart o tipo do valor que veio do JSON.

## Igualdade: `==` e `hashCode`
Por padrão, o Dart compara objetos pelo **endereço na memória**: dois contatos com os mesmos dados seriam "diferentes". Sobrescrevemos `==` e `hashCode` para compará-los pelo conteúdo:
```dart
@override
bool operator ==(Object other) =>
    other is Contact && other.id == id && other.name == name && other.phone == phone;

@override
int get hashCode => Object.hash(id, name, phone);
```
Regra: quando se muda o `==`, muda-se o `hashCode` junto.

## Privacidade no `toString`
O `toString` aparece em logs e mensagens de erro. No ADA ele mostra só o `id`, porque nome e telefone são dado pessoal.

## Guardar pouco
O model do ADA tem só nome e telefone: **minimização de dados** (guardar só o necessário).

## No ADA
- Model: [`contact.dart`](../../../lib/features/contacts/models/contact.dart)
- Testes: [`contact_test.dart`](../../../test/features/contact_test.dart)
