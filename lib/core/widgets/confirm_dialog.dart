// Diálogo de confirmação com dois botões, usado onde um toque errado custa caro
// (ativar o Perigo, desativar ou cancelar um alerta).
//
// Devolve true só se a usuária confirmar. Cancelar, tocar fora do diálogo ou
// voltar devolve false.

import 'package:flutter/material.dart';

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Cancelar',
  Color? confirmColor,
}) async {
  // showDialog devolve um Future: ele "espera" a usuária escolher e entrega o
  // valor passado ao Navigator.pop (true = confirmar, false ou null = desistir).
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(cancelLabel),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: TextButton.styleFrom(foregroundColor: confirmColor),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return confirmed == true;
}
