// Uma faixa de horário de cobertura: "das 23:00 às 4:00, ligar para Tainá".
//
// A hora é guardada como MINUTOS DESDE A MEIA-NOITE (0 a 1439): 8:00 vira 480 e
// 23:00 vira 1380. Um número simples é fácil de comparar, de gravar em JSON e de
// testar. A tela converte de e para o seletor de horas (TimeOfDay).
//
// A faixa vale de [start] até [end], contando o início e NÃO contando o fim:
// 8:00 às 13:00 inclui as 8:00 e não inclui as 13:00 (que são da faixa seguinte).
// Se o fim é MENOR que o início (23:00 às 4:00), a faixa atravessa a meia-noite.
//
// Privacidade: a faixa guarda só o id do contato e as horas, nunca o telefone, e
// o toString também não mostra nada disso.

// Um trecho dentro de UM mesmo dia: de [start] (incluído) até [end] (excluído),
// em minutos, entre 0 e 1440. Uma faixa que atravessa a meia-noite vira dois.
typedef Span = ({int start, int end});

const minutesPerDay = 1440;

class CoverageRule {
  const CoverageRule({
    required this.id,
    required this.contactId,
    required this.start,
    required this.end,
    this.enabled = true,
  });

  final String id; // identifica a faixa
  final String contactId; // quem será ligado nesta faixa
  final int start; // minutos desde a meia-noite (0 a 1439)
  final int end; // idem; menor que o início = atravessa a meia-noite
  final bool enabled; // desligada, a faixa fica salva mas não vale

  // Os trechos do dia que a faixa cobre.
  //   8:00 às 13:00  -> [8:00, 13:00)
  //   23:00 às 4:00  -> [23:00, 24:00) e [0:00, 4:00)
  //   18:00 às 0:00  -> [18:00, 24:00)   (o fim 0:00 é a própria meia-noite)
  List<Span> get spans {
    if (start < end) return [(start: start, end: end)];
    return [
      (start: start, end: minutesPerDay),
      if (end > 0) (start: 0, end: end),
    ];
  }

  CoverageRule copyWith({
    String? contactId,
    int? start,
    int? end,
    bool? enabled,
  }) {
    return CoverageRule(
      id: id,
      contactId: contactId ?? this.contactId,
      start: start ?? this.start,
      end: end ?? this.end,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'contactId': contactId,
    'start': start,
    'end': end,
    'enabled': enabled,
  };

  factory CoverageRule.fromJson(Map<String, dynamic> json) {
    return CoverageRule(
      id: json['id'] as String,
      contactId: json['contactId'] as String,
      start: json['start'] as int,
      end: json['end'] as int,
      // Faixas gravadas sem o campo valem como ligadas.
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CoverageRule &&
      other.id == id &&
      other.contactId == contactId &&
      other.start == start &&
      other.end == end &&
      other.enabled == enabled;

  @override
  int get hashCode => Object.hash(id, contactId, start, end, enabled);

  @override
  String toString() => 'CoverageRule($id)';
}
