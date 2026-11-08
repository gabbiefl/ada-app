// Carrega a fonte do ADA (Nunito) nos testes de widget.
//
// Por padrão, os testes de widget desenham todo o texto com a fonte "Ahem", em que
// cada letra é um quadrado largo. Isso INFLA os textos e cria overflows que não
// existem no celular. Testes que medem tamanhos (alvos de toque, texto grande,
// quebra de linha) chamam esta função em `setUpAll` para medir o texto de verdade.

import 'package:flutter/services.dart';

Future<void> loadAppFont() async {
  final loader = FontLoader('Nunito')
    ..addFont(rootBundle.load('assets/fonts/Nunito-VariableFont_wght.ttf'));
  await loader.load();
}
