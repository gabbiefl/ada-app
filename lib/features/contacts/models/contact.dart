// Um contato da rede de confiança: só o necessário (nome e telefone).
//
// Guardar pouco é uma escolha de privacidade (minimização de dados): não temos
// e-mail, foto nem endereço de ninguém.
//
// A classe é IMUTÁVEL: depois de criada, não muda. Para "editar", criamos uma
// cópia com o campo trocado (copyWith). Isso evita alterações escondidas e faz
// o ChangeNotifier perceber a mudança, porque o objeto na lista é outro.

import 'package:ada_app/features/contacts/formatters/phone_input_formatter.dart';

class Contact {
  // `const` no construtor: permite criar contatos constantes nos testes.
  const Contact({required this.id, required this.name, required this.phone});

  final String id; // identifica o contato (o nome pode se repetir)
  final String name;
  final String phone; // só dígitos, com DDD: '51999990001'

  // copyWith: devolve um contato novo, trocando só o que for informado.
  // `String?` aceita null, que significa "mantenha o valor atual".
  Contact copyWith({String? name, String? phone}) {
    return Contact(id: id, name: name ?? this.name, phone: phone ?? this.phone);
  }

  // Telefone para exibir: '51999990001' vira '(51) 99999-0001'.
  // Guardamos só dígitos e formatamos apenas na hora de mostrar.
  // A máscara é a mesma do campo de digitação (formatPhone).
  String get formattedPhone =>
      phone.length == 10 || phone.length == 11 ? formatPhone(phone) : phone;

  // Vira um Map para ser gravado como JSON (usado na persistência, passo 8).
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'phone': phone};

  // `factory`: construtor que pode devolver o objeto montado a partir de dados.
  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
    );
  }

  // Por padrão o Dart compara objetos pelo ENDEREÇO na memória. Aqui dois
  // contatos com os mesmos dados são iguais, o que facilita os testes.
  @override
  bool operator ==(Object other) =>
      other is Contact &&
      other.id == id &&
      other.name == name &&
      other.phone == phone;

  @override
  int get hashCode => Object.hash(id, name, phone);

  // Sem telefone no texto de depuração: dado pessoal não vai para logs.
  @override
  String toString() => 'Contact(id: $id)';
}
