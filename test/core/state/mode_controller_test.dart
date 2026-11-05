// Testa a lógica do modo atual, sem desenhar nenhuma tela.

import 'package:flutter_test/flutter_test.dart';

import 'package:ada_app/core/feedback/haptics.dart';
import 'package:ada_app/core/state/mode_controller.dart';
import 'package:ada_app/core/state/security_mode.dart';

void main() {
  test('começa no modo normal', () {
    expect(ModeController().mode, SecurityMode.normal);
  });

  test('activate troca o modo e deactivate volta ao normal', () {
    final controller = ModeController();

    expect(controller.activate(SecurityMode.danger), isNull);
    expect(controller.mode, SecurityMode.danger);

    controller.deactivate();
    expect(controller.mode, SecurityMode.normal);
  });

  test('avisa quem está ouvindo só quando o modo muda', () {
    final controller = ModeController();
    var avisos = 0;
    controller.addListener(() => avisos++);

    controller.activate(SecurityMode.attention);
    controller.activate(SecurityMode.attention); // igual: não avisa
    controller.deactivate();

    expect(avisos, 2);
  });

  group('transições', () {
    test('do Normal vai para Atenção ou Perigo', () {
      for (final target in [SecurityMode.attention, SecurityMode.danger]) {
        final controller = ModeController();
        expect(controller.activate(target), isNull);
        expect(controller.mode, target);
      }
    });

    test('da Atenção sobe direto para o Perigo', () {
      final controller = ModeController()..activate(SecurityMode.attention);

      expect(controller.activate(SecurityMode.danger), isNull);
      expect(controller.mode, SecurityMode.danger);
    });

    test('do Perigo não desce direto para Atenção', () {
      final controller = ModeController()..activate(SecurityMode.danger);
      var avisos = 0;
      controller.addListener(() => avisos++);

      final error = controller.activate(SecurityMode.attention);

      expect(error, ModeError.deactivateFirst);
      expect(controller.mode, SecurityMode.danger);
      expect(avisos, 0); // recusa não avisa ninguém
    });

    test('do Perigo, desativar primeiro permite chegar à Atenção', () {
      final controller = ModeController()..activate(SecurityMode.danger);

      controller.deactivate();

      expect(controller.activate(SecurityMode.attention), isNull);
      expect(controller.mode, SecurityMode.attention);
    });

    test('de qualquer modo se volta ao Normal', () {
      for (final from in SecurityMode.values) {
        final controller = ModeController()..activate(from);

        controller.deactivate();

        expect(controller.mode, SecurityMode.normal);
      }
    });

    test('canGoTo: ficar no mesmo modo não é mudança', () {
      for (final mode in SecurityMode.values) {
        expect(mode.canGoTo(mode), isFalse);
      }
    });
  });

  group('vibração', () {
    test('vibra ao ativar o Perigo', () {
      final haptics = _FakeHaptics();
      final controller = ModeController(haptics: haptics);

      controller.activate(SecurityMode.danger);

      expect(haptics.vibrations, 1);
    });

    test('não vibra de novo se o Perigo já estava ativo', () {
      final haptics = _FakeHaptics();
      final controller = ModeController(haptics: haptics)
        ..activate(SecurityMode.danger);

      controller.activate(SecurityMode.danger);

      expect(haptics.vibrations, 1);
    });

    test('Atenção e desativar não vibram', () {
      final haptics = _FakeHaptics();
      final controller = ModeController(haptics: haptics);

      controller.activate(SecurityMode.attention);
      controller.deactivate();

      expect(haptics.vibrations, 0);
    });

    test('subir da Atenção para o Perigo vibra', () {
      final haptics = _FakeHaptics();
      final controller = ModeController(haptics: haptics)
        ..activate(SecurityMode.attention);

      controller.activate(SecurityMode.danger);

      expect(haptics.vibrations, 1);
    });

    test('mudança recusada não vibra', () {
      final haptics = _FakeHaptics();
      final controller = ModeController(haptics: haptics)
        ..activate(SecurityMode.danger);

      controller.activate(SecurityMode.attention); // recusado

      expect(haptics.vibrations, 1); // só a do primeiro activate
    });

    test('sem vibrador, tudo funciona normalmente', () {
      final controller = ModeController();

      expect(controller.activate(SecurityMode.danger), isNull);
      expect(controller.mode, SecurityMode.danger);
    });
  });
}

// Vibrador falso: só conta quantas vezes "vibrou".
class _FakeHaptics implements Haptics {
  int vibrations = 0;

  @override
  Future<void> alert() async => vibrations++;
}
