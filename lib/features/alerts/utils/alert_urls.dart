// Monta os endereços (URLs) que abrem o WhatsApp, o discador e o app de SMS.
//
// Funções puras: só recebem telefone e texto e devolvem um endereço, sem abrir
// nada. Assim toda a formatação (código do país, codificação do texto) fica em
// um lugar só e é testada sem celular.
//
// Os contatos guardam só os dígitos, com DDD (ex.: 51999990001). Fora do Brasil
// o número precisa do código do país, então acrescentamos o 55.

// '51999990001' -> '5551999990001' (sem o +, como o wa.me pede).
// Se já vier com o 55 na frente (12 ou 13 dígitos), não repete.
String internationalDigits(String phone) {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  final alreadyHasCountry =
      digits.startsWith('55') && (digits.length == 12 || digits.length == 13);
  return alreadyHasCountry ? digits : '55$digits';
}

// '51999990001' -> '+5551999990001' (formato usado por ligação e SMS).
String internationalPhone(String phone) => '+${internationalDigits(phone)}';

// Conversa do WhatsApp com a mensagem já escrita. A usuária toca em enviar.
// Uri.encodeComponent troca espaços e acentos por %XX; quebras de linha viram
// %0A, que o WhatsApp entende.
Uri whatsAppUri(String phone, String text) => Uri.parse(
  'https://wa.me/${internationalDigits(phone)}?text=${Uri.encodeComponent(text)}',
);

// Discador com o número já digitado (plano B da ligação direta).
Uri dialerUri(String phone) =>
    Uri(scheme: 'tel', path: internationalPhone(phone));

// App de mensagens com o texto pronto (plano B do SMS direto).
Uri smsComposerUri(String phone, String text) => Uri.parse(
  'sms:${internationalPhone(phone)}?body=${Uri.encodeComponent(text)}',
);
