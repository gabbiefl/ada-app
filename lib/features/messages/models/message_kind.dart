// Os três tipos de mensagem de emergência do ADA.
//
// É um "enum com propriedades": além de listar os valores possíveis, cada um
// carrega seus próprios dados (título e texto padrão). Assim o título e o
// padrão ficam junto do tipo, e não espalhados pelas telas.

enum MessageKind {
  // Cada valor chama o construtor abaixo, passando seus dados.
  danger(
    title: 'Modo perigo',
    defaultText: 'Preciso de ajuda. Estou em situação de perigo. Minha localização está sendo compartilhada.',
  ),
  attention(
    title: 'Modo atenção',
    defaultText: 'Estou me sentindo insegura. Acompanhe minha localização e fique atento ao meu contato.',
  ),
  arrived(
    title: 'Cheguei bem',
    defaultText: 'Cheguei em segurança. Pode ficar tranquilo(a). Obrigada por acompanhar!',
  );

  const MessageKind({required this.title, required this.defaultText});

  final String title;
  final String defaultText;

  // Número máximo de letras (o design mostra o contador "x/200").
  static const maxLength = 200;
}
