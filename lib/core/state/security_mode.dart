// Os três modos de segurança do ADA.
//
// Um enum garante que só existem estes três valores: o compilador avisa se
// alguém tentar usar um modo que não existe (o que não acontece com texto).
//
// Além dos valores, o enum guarda uma REGRA: de qual modo se pode ir para qual
// (uma "máquina de estados" simples). Assim a regra fica junto do modo, e não
// espalhada pelas telas.
//
//   Normal   ->  Atenção, Perigo
//   Atenção  ->  Perigo, Normal
//   Perigo   ->  Normal        (não "rebaixa" direto para Atenção)
//
// Subir o alerta é sempre permitido (a situação piorou). Baixar de Perigo para
// Atenção sem querer seria arriscado, então é preciso desativar antes.

enum SecurityMode {
  normal,
  attention,
  danger;

  // Pode mudar deste modo para [next]? (Ficar no mesmo modo não é mudança.)
  bool canGoTo(SecurityMode next) {
    if (next == this) return false;
    // Do Perigo só se sai desativando (indo para o Normal).
    if (this == SecurityMode.danger) return next == SecurityMode.normal;
    return true;
  }
}
