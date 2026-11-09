// Um serviço público de ajuda que a usuária pode ligar direto da Home.
//
// Os números são fixos (190 e 180): não são dados da usuária, então não ficam
// guardados em lugar nenhum. Ligar para eles NÃO aciona a rede de contatos.

class EmergencyService {
  const EmergencyService({
    required this.number,
    required this.name,
    required this.summary,
    required this.confirmMessage,
  });

  final String number; // "190"
  final String name; // "Polícia Militar"

  // Quando usar, em poucas palavras (aparece no cartão).
  final String summary;

  // O que o diálogo de confirmação diz antes de ligar.
  final String confirmMessage;

  // "Ligue 190": o título do cartão.
  String get title => 'Ligue $number';
}

const policiaMilitar = EmergencyService(
  number: '190',
  name: 'Polícia Militar',
  summary:
      'Emergência da Polícia Militar. Use quando a violência estiver '
      'acontecendo ou se o agressor descumprir a medida protetiva e se '
      'aproximar.',
  confirmMessage:
      'Polícia Militar. Ligue só se a violência estiver acontecendo agora ou '
      'se o agressor descumprir a medida protetiva e se aproximar. O ADA não '
      'avisa a sua rede.',
);

const centralDaMulher = EmergencyService(
  number: '180',
  name: 'Central de Atendimento à Mulher',
  summary:
      'Canal gratuito do governo federal, 24 horas por dia. Escuta, '
      'orientação, denúncia e encaminhamento para a rede de apoio.',
  confirmMessage:
      'Central de Atendimento à Mulher: gratuita, 24 horas, todos os dias. '
      'Oferece escuta, orientação, denúncia e encaminhamento. O ADA não avisa '
      'a sua rede.',
);

const emergencyServices = [policiaMilitar, centralDaMulher];
