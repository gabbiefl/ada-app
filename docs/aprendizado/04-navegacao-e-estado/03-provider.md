# 03 — Provider

O **Provider** entrega um objeto (como o `ModeController`) a qualquer tela da árvore de widgets, **sem passar parâmetro de mão em mão**.

## A analogia: o quadro de avisos
Imagine o controlador como um **quadro de avisos** com a informação "o modo atual é Normal".
- **Sem Provider**, cada tela receberia o quadro das mãos de quem a abriu (`HomePage(controller: c)`), e ele passaria por vários widgets que nem o usam.
- **Com Provider**, o quadro é **pendurado na parede do prédio**. Qualquer sala (tela) dentro do prédio olha para a parede e vê o aviso.

## "Acima" na árvore
O Provider só vale para quem está **abaixo** dele:
```
ChangeNotifierProvider        ← o quadro é pendurado aqui
 └─ MaterialApp.router
     └─ Scaffold + barra
         ├─ HomePage          ← enxerga
         ├─ ContactsPage      ← enxerga
         └─ SettingsPage      ← enxerga
```
- Acima do `MaterialApp`, ele cobre **todas as telas**, inclusive as que o `go_router` abre depois.
- Dentro da `HomePage`, só a Home e seus filhos enxergariam.

## Como fornecer
```dart
ChangeNotifierProvider(
  create: (_) => ModeController(),   // roda uma vez; o dispose é automático
  child: MaterialApp.router(...),
)
```

## Como usar: `watch` x `read`
O `context` é o "endereço" do widget na árvore. O Provider sobe a partir dele até achar o objeto.

| | O que faz | Quando usar |
|---|---|---|
| `context.watch<ModeController>()` | **Assina**: o `build` roda de novo quando o controlador avisa | Para **mostrar** o dado no `build` |
| `context.read<ModeController>()` | Só **pega** o objeto, sem assinar | Para **dar ordens**, como em `onPressed` |

```dart
// no build: a tela acompanha o modo
final mode = context.watch<ModeController>().mode;

// num clique: só executa a ação
onPressed: () => context.read<ModeController>().activate(SecurityMode.danger),
```
Erro comum: usar `watch` dentro de um `onPressed`. Em cliques, use `read`.

## Em testes
Para controlar o objeto no teste, forneça um já criado com `.value`:
```dart
ChangeNotifierProvider.value(value: controller, child: MaterialApp(...))
```
Assim o teste guarda a referência e muda o modo para ver a tela reagir.

## Alternativa
**Riverpod** não depende do `BuildContext` e é mais fácil de testar, mas traz mais conceitos novos. Para um estado pequeno como o modo atual, o Provider bastou.

## No ADA
- Fornecido em [`app.dart`](../../../lib/app.dart)
- Lido em [`home_page.dart`](../../../lib/features/home/pages/home_page.dart) com `context.watch`
- Teste da Home reagindo ao modo: [`widget_test.dart`](../../../test/widget_test.dart)
