// Widget raiz do ADA: configura o MaterialApp (título, tema e rotas).
//
// As telas e a navegação ficam em core/routes/app_router.dart.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ada_app/core/feedback/haptics.dart';
import 'package:ada_app/core/routes/app_router.dart';
import 'package:ada_app/core/state/mode_controller.dart';
import 'package:ada_app/features/alerts/data/alert_actions.dart';
import 'package:ada_app/features/alerts/data/platform_alert_actions.dart';
import 'package:ada_app/features/alerts/state/alert_controller.dart';
import 'package:ada_app/core/theme/app_theme.dart';
import 'package:ada_app/features/contacts/data/contacts_repository.dart';
import 'package:ada_app/features/contacts/state/contacts_controller.dart';
import 'package:ada_app/features/map/data/geolocator_location_service.dart';
import 'package:ada_app/features/map/data/location_service.dart';
import 'package:ada_app/features/map/state/location_controller.dart';
import 'package:ada_app/features/messages/data/messages_repository.dart';
import 'package:ada_app/features/messages/state/messages_controller.dart';

// StatelessWidget: um widget que NÃO guarda dados que mudam.
// A configuração do app é fixa, então não precisamos de StatefulWidget.
class AdaApp extends StatelessWidget {
  // `super.key` repassa a `key` (identificador do widget) para a classe-mãe.
  // `const` no construtor permite criar o widget com `const AdaApp()`.
  //
  // Os dois serviços abaixo existem para os TESTES trocarem o GPS e o envio de
  // SMS por versões falsas (nenhum teste manda mensagem ou liga de verdade). No
  // app de verdade ficam vazios e valem os serviços reais.
  const AdaApp({super.key, this.locationService, this.alertActions});

  final LocationService? locationService;
  final AlertActions? alertActions;

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
        ChangeNotifierProvider(
          create: (_) => ModeController(haptics: const SystemHaptics()),
        ),
        // `..load()` (cascata): cria o controlador e, em seguida, já manda
        // carregar os contatos guardados no aparelho.
        ChangeNotifierProvider(
          create: (_) =>
              ContactsController(repository: SecureContactsRepository())
                ..load(),
        ),
        // Mensagens de emergência: carrega e grava os textos editados no
        // armazenamento seguro, igual aos contatos.
        ChangeNotifierProvider(
          create: (_) =>
              MessagesController(repository: SecureMessagesRepository())
                ..load(),
        ),
        // Localização atual: só busca quando a usuária pede (aba Mapa), e nunca
        // guarda a posição.
        ChangeNotifierProvider(
          create: (_) => LocationController(
            service: locationService ?? GeolocatorLocationService(),
          ),
        ),
        // Alerta: junta localização, SMS e ligação. Só dispara quando o Perigo ou
        // a Atenção são ativados (a ligação a esses toques vem no passo 5).
        ChangeNotifierProvider(
          create: (_) => AlertController(
            locationService: locationService ?? GeolocatorLocationService(),
            actions: alertActions ?? PlatformAlertActions(),
          ),
        ),
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
