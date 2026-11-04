// Rotas do ADA, com o go_router.
//
// Cada tela tem um "endereço" (caminho), como num site: /home, /contacts...
// O go_router lê o endereço e decide qual tela mostrar. Vantagem sobre empilhar
// telas na mão: o app sabe "onde está" e dá para ir direto a qualquer tela.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:ada_app/core/widgets/ada_bottom_nav.dart';
import 'package:ada_app/core/widgets/coming_soon_page.dart';
import 'package:ada_app/features/contacts/pages/contact_form_page.dart';
import 'package:ada_app/features/contacts/pages/contacts_page.dart';
import 'package:ada_app/features/home/pages/home_page.dart';
import 'package:ada_app/features/messages/models/message_kind.dart';
import 'package:ada_app/features/messages/pages/message_edit_page.dart';
import 'package:ada_app/features/messages/pages/messages_page.dart';
import 'package:ada_app/features/settings/pages/settings_page.dart';

// Os caminhos ficam em um lugar só, para não repetir texto pelo código.
class AppRoutes {
  AppRoutes._();

  static const home = '/home';
  static const contacts = '/contacts';
  static const newContact = '/contacts/new';
  // Função (e não constante): o endereço leva o id do contato, ex.: /contacts/edit/123.
  static String editContact(String id) => '/contacts/edit/$id';
  static const map = '/map';
  static const settings = '/settings';
  static const messages = '/settings/messages';
  // Função: o endereço leva qual mensagem editar, ex.: /settings/messages/edit/danger.
  static String editMessage(MessageKind kind) =>
      '/settings/messages/edit/${kind.name}';
  static const coverage = '/settings/coverage';
  static const history = '/settings/history';
}

// Navegador "raiz": telas abertas nele cobrem a barra inferior (ex.: Novo contato).
final _rootKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootKey,
  initialLocation: AppRoutes.home,
  routes: [
    // StatefulShellRoute: a "moldura" com a barra inferior. Cada aba (branch)
    // guarda a sua própria pilha de telas e o seu estado ao trocar de aba.
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => Scaffold(
        body: shell,
        bottomNavigationBar: AdaBottomNav(
          currentIndex: shell.currentIndex,
          // goBranch: vai para a aba tocada. Tocar na aba atual volta ao início dela.
          onTap: (index) => shell.goBranch(
            index,
            initialLocation: index == shell.currentIndex,
          ),
        ),
      ),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.home,
              builder: (context, state) => const HomePage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.contacts,
              builder: (context, state) => const ContactsPage(),
              routes: [
                // Sem barra inferior: abre no navegador raiz, por cima de tudo.
                GoRoute(
                  path: 'new',
                  parentNavigatorKey: _rootKey,
                  builder: (context, state) => const ContactFormPage(),
                ),
                // ':id' é um parâmetro do caminho: o go_router o entrega em
                // state.pathParameters['id'].
                GoRoute(
                  path: 'edit/:id',
                  parentNavigatorKey: _rootKey,
                  builder: (context, state) =>
                      ContactFormPage(contactId: state.pathParameters['id']),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.map,
              builder: (context, state) => const ComingSoonPage(title: 'Mapa'),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.settings,
              builder: (context, state) => const SettingsPage(),
              routes: [
                GoRoute(
                  path: 'messages',
                  builder: (context, state) => const MessagesPage(),
                  routes: [
                    GoRoute(
                      path: 'edit/:kind',
                      builder: (context, state) {
                        // Texto da rota -> enum. asNameMap()['danger'] acha
                        // MessageKind.danger; nome desconhecido dá null.
                        final kind = MessageKind.values
                            .asNameMap()[state.pathParameters['kind']];
                        if (kind == null) {
                          return const ComingSoonPage(
                            title: 'Mensagem não encontrada',
                          );
                        }
                        return MessageEditPage(kind: kind);
                      },
                    ),
                  ],
                ),
                GoRoute(
                  path: 'coverage',
                  builder: (context, state) =>
                      const ComingSoonPage(title: 'Horário de cobertura'),
                ),
                GoRoute(
                  path: 'history',
                  builder: (context, state) =>
                      const ComingSoonPage(title: 'Histórico de alertas'),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);
