# 01 — Rotas e go_router

Uma **rota** é o "endereço" de uma tela, como numa página web (`/home`, `/contacts`). O **go_router** (pacote oficial do time do Flutter) lê o endereço e decide qual tela mostrar.

## Como `main.dart`, `app.dart` e o router se encaixam
```
main()                      → runApp(const AdaApp())
 └─ AdaApp (app.dart)       → MaterialApp.router(theme, routerConfig: appRouter)
     └─ appRouter           → lê o endereço e escolhe a tela
         └─ HomePage, ContactsPage, ...
```
- `main.dart` só liga o app. `app.dart` configura tema e de onde vêm as telas.
- Com `MaterialApp.router`, a tela inicial não vem mais de `home:`, e sim do `routerConfig`.

## Uma rota (mínimo)
```dart
final router = GoRouter(
  initialLocation: '/home',
  routes: [
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomePage(),
    ),
  ],
);
```

## `go` x `push` x `pop`
| Chamada | O que faz |
|---|---|
| `context.go('/contacts')` | **Troca** a tela pelo endereço (vai direto lá) |
| `context.push('/contacts/new')` | **Empilha** a tela por cima; dá para voltar |
| `context.pop()` | Fecha a tela do topo e volta |

Regra prática: para abrir um detalhe ou formulário e depois voltar, use `push`. Para saltar entre áreas, use `go`.

## Rotas aninhadas
Uma rota pode ter filhas. O caminho da filha é relativo ao da mãe:
```dart
GoRoute(
  path: '/settings',
  builder: (context, state) => const SettingsPage(),
  routes: [
    GoRoute(path: 'messages', builder: (_, __) => const MessagesPage()), // /settings/messages
  ],
),
```

## Barra inferior com `StatefulShellRoute`
`StatefulShellRoute.indexedStack` cria **uma moldura** (o `Scaffold` com a barra) e várias **abas** (`branches`), cada uma com a sua pilha de telas.
- Ao trocar de aba, a anterior **guarda o estado** (a rolagem não volta ao topo).
- `shell.goBranch(index)` muda de aba; tocar na aba atual volta ao início dela.
- Uma tela com `parentNavigatorKey: _rootKey` abre **por cima da barra** (como "Novo contato").

## Dica: caminhos em um lugar só
Guardar os textos das rotas em constantes evita erro de digitação:
```dart
class AppRoutes {
  AppRoutes._();
  static const home = '/home';
}
```

## No ADA
- Mapa de telas: [`app_router.dart`](../../../lib/core/routes/app_router.dart)
- Raiz do app: [`app.dart`](../../../lib/app.dart) e [`main.dart`](../../../lib/main.dart)
- Barra inferior: [`ada_bottom_nav.dart`](../../../lib/core/widgets/ada_bottom_nav.dart)
- Botões ligados com `push`/`pop`: [`settings_page.dart`](../../../lib/features/settings/pages/settings_page.dart), [`messages_page.dart`](../../../lib/features/messages/pages/messages_page.dart)
