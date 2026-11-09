// Monta os endereços (URLs) que abrem o WhatsApp, o discador e o app de SMS.
//
// Funções puras: só recebem telefone e texto e devolvem um endereço, sem abrir
// nada. Assim toda a formatação (código do país, codificação do texto) fica em
// um lugar só e é testada sem celular.
//
// Os contatos guardam só os dígitos, com DDD (ex.: 51999990001). Fora do Brasil
// o número precisa do código do país, então acrescentamos o 55.

// Números de serviço (190, 180, 192...) têm até 3 dígitos e NÃO levam código do
// país nem DDD: '+55190' não existe, só o '190' completa a ligação.
bool isServiceNumber(String phone) =>
    phone.replaceAll(RegExp(r'\D'), '').length <= 3;

// '51999990001' -> '5551999990001' (sem o +, como o wa.me pede).
// Se já vier com o 55 na frente (12 ou 13 dígitos), não repete.
// Número de serviço (190) volta como está.
String internationalDigits(String phone) {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  if (isServiceNumber(digits)) return digits;
  final alreadyHasCountry =
      digits.startsWith('55') && (digits.length == 12 || digits.length == 13);
  return alreadyHasCountry ? digits : '55$digits';
}

// '51999990001' -> '+5551999990001' (formato usado por ligação e SMS).
// Número de serviço: '190' -> '190' (sem o +).
String internationalPhone(String phone) => isServiceNumber(phone)
    ? internationalDigits(phone)
    : '+${internationalDigits(phone)}';

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
