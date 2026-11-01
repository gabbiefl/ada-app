// Regras de validação do contato, como funções puras.
//
// "Pura" = só recebe um texto e devolve um resultado, sem tela nem estado. Por
// isso é fácil de testar e pode ser usada pelo formulário e pelo controlador.
//
// Padrão de retorno do Flutter para validators: devolve a MENSAGEM de erro, ou
// null quando está tudo certo. É exatamente o que o TextFormField espera.

class ContactValidators {
  ContactValidators._(); // só agrupa funções; não se cria objeto

  static const maxNameLength = 50;

  // Deixa só os dígitos: '(51) 99999-0001' vira '51999990001'.
  // RegExp(r'\D') casa com qualquer caractere que NÃO seja dígito.
  static String digitsOnly(String text) => text.replaceAll(RegExp(r'\D'), '');

  static String? name(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Informe o nome.';
    if (text.length < 2) return 'O nome precisa ter pelo menos 2 letras.';
    if (text.length > maxNameLength) {
      return 'O nome pode ter no máximo $maxNameLength letras.';
    }
    return null;
  }

  // Telefone brasileiro: DDD (2 dígitos) + número de 8 ou 9 dígitos.
  // Celular tem 11 dígitos e o número começa com 9.
  static String? phone(String? value) {
    final digits = digitsOnly(value ?? '');
    if (digits.isEmpty) return 'Informe o telefone.';
    if (digits.length != 10 && digits.length != 11) {
      return 'Digite o DDD e o número. Ex.: (51) 99999-0001.';
    }
    // O DDD não começa com 0 (e 00 a 10 não existem).
    if (digits.startsWith('0') || digits[1] == '0') {
      return 'O DDD informado não é válido.';
    }
    if (digits.length == 11 && digits[2] != '9') {
      return 'Celular com 11 dígitos deve começar com 9 depois do DDD.';
    }
    return null;
  }
}
