# 04 — Testando navegação e estado

Testar o **fluxo** (tocar, navegar, ver a tela mudar) é diferente de testar uma tela isolada. Alguns cuidados aparecem.

## Três níveis de teste
| Nível | O que testa | Exemplo no ADA |
|---|---|---|
| Unitário | A lógica, sem tela | `ModeController` troca e avisa |
| Widget | Uma tela reagindo ao estado | Home mostra "Modo perigo ativo" |
| Fluxo | Navegar entre telas pelo app | Configurações → Mensagens → Editar → Cancelar |

## `pump(Duration)` x `pumpAndSettle`
- `pumpAndSettle` avança o relógio **até não haver mais animação**.
- Na Home, os anéis pulsam para sempre, então ele esperaria para sempre e o teste travaria.
- `pump(Duration(milliseconds: 600))` avança um tempo fixo, o suficiente para a transição de tela.

```dart
await tester.tap(find.byIcon(LucideIcons.users));
await tester.pump(const Duration(milliseconds: 600));
expect(find.text('Rede de contatos'), findsOneWidget);
```

## O router é um só
No ADA, `appRouter` é uma variável global: ele **lembra onde parou** no teste anterior. Para cada teste começar de um lugar conhecido, vá direto a uma tela:
```dart
appRouter.go(AppRoutes.settings);
await tester.pumpWidget(const AdaApp());
```
Esta é a vantagem das rotas por caminho: ir a qualquer tela sem tocar na barra.

## Testando que o estado chegou
`context.read` em um widget do app mostra se o Provider foi pendurado no lugar certo:
```dart
final context = tester.element(find.byType(HomePage));
expect(context.read<ModeController>().mode, SecurityMode.normal);
```

## Testando que a tela reage
```dart
controller.activate(SecurityMode.danger);
await tester.pump(const Duration(milliseconds: 100));
expect(find.text('Modo perigo ativo'), findsOneWidget);
```
Se a tela não mudar, suspeite de um `notifyListeners()` ausente ou de um `read` onde devia ser `watch`.

## Dicas
- Em testes de tela, passe `theme: AppTheme.light` para ter as cores e fontes do ADA.
- `find.text`, `find.byIcon` e `find.byType` localizam widgets; `tester.tap` toca neles.

## No ADA
- Fluxos: [`app_router_test.dart`](../../../test/core/routes/app_router_test.dart)
- Home reagindo ao modo: [`widget_test.dart`](../../../test/widget_test.dart)
- Lógica pura: [`mode_controller_test.dart`](../../../test/core/state/mode_controller_test.dart)
