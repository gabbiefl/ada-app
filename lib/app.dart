// Widget raiz do ADA: configura o MaterialApp (título, tema e rotas).
//
// As telas e a navegação ficam em core/routes/app_router.dart.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ada_app/core/routes/app_router.dart';
import 'package:ada_app/core/state/mode_controller.dart';
import 'package:ada_app/core/theme/app_theme.dart';
import 'package:ada_app/features/contacts/state/contacts_controller.dart';

// StatelessWidget: um widget que NÃO guarda dados que mudam.
// A configuração do app é fixa, então não precisamos de StatefulWidget.
class AdaApp extends StatelessWidget {
  // `super.key` repassa a `key` (identificador do widget) para a classe-mãe.
  // `const` no construtor permite criar o widget com `const AdaApp()`.
  const AdaApp({super.key});

  // `build` descreve COMO este widget aparece: ele devolve outros widgets.
  // O Flutter chama `build` sempre que precisa desenhar (ou redesenhar) a tela.
  @override
  Widget build(BuildContext context) {
    // MaterialApp: a "casca" que dá ao app o visual e o comportamento do
    // Material Design (navegação, tema, textos do sistema).
    // MultiProvider: junta vários providers em um só, sem aninhar um dentro do
    // outro. Cada ChangeNotifierProvider cria UM controlador e o deixa
    // disponível para todas as telas abaixo dele. `create` roda uma vez só, e o
    // provider chama dispose() do controlador quando o app fecha.
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ModeController()),
        ChangeNotifierProvider(create: (_) => ContactsController()),
      ],
      child: MaterialApp.router(
        // Nome que o sistema usa, por exemplo na lista de apps recentes.
        title: 'ADA',
        // Tema do ADA (cores e fonte do Figma), definido em core/theme/.
        theme: AppTheme.light,
        // As telas e a navegação vêm do go_router (core/routes/app_router.dart).
        routerConfig: appRouter,
      ),
    );
  }
}
