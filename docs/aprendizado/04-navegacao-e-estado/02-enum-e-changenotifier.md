# 02 — enum e ChangeNotifier

Dois conceitos que formam a base do estado do ADA: o **`enum`**, que define quais valores existem, e o **`ChangeNotifier`**, que guarda o valor atual e avisa quando ele muda.

## enum: um conjunto fechado de valores
```dart
enum SecurityMode { normal, attention, danger }
```
O compilador garante que só existem estes três. Com texto (`'perigo'`), um erro de digitação (`'perrigo'`) só aparece com o app rodando; com `enum`, o erro aparece antes de rodar.

```dart
if (mode == SecurityMode.danger) { ... }
```

## ChangeNotifier: guarda o dado e avisa
```dart
class Contador extends ChangeNotifier {
  int _valor = 0;
  int get valor => _valor;       // só leitura por fora

  void somar() {
    _valor++;
    notifyListeners();           // "mudou!": quem ouve é avisado
  }
}
```
- O atributo com `_` é **privado**: só a própria classe altera. Quem está de fora lê pelo `get` e muda chamando os métodos.
- `notifyListeners()` avisa todos que "assinaram". Sem ele, o valor muda, mas a tela não sabe.
- Evite avisar à toa: se o valor novo é igual ao atual, retorne antes.

## Por que separar UI e lógica
A regra "qual é o modo atual e como ele muda" fica no controlador, e a tela só **mostra** o resultado. Vantagens:
- dá para **testar a lógica sem desenhar tela** (rápido e simples);
- várias telas podem usar o mesmo dado;
- mudar o visual não quebra a regra.

## Testando um controlador (sem tela)
```dart
test('avisa só quando o modo muda', () {
  final c = ModeController();
  var avisos = 0;
  c.addListener(() => avisos++);

  c.activate(SecurityMode.attention);
  c.activate(SecurityMode.attention); // igual: não avisa

  expect(avisos, 1);
});
```

## No ADA
- Os três modos: [`security_mode.dart`](../../../lib/core/state/security_mode.dart)
- O controlador, com `activate` e `deactivate`: [`mode_controller.dart`](../../../lib/core/state/mode_controller.dart)
- Testes: [`mode_controller_test.dart`](../../../test/core/state/mode_controller_test.dart)
