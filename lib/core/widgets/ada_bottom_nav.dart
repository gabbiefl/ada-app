// Barra de navegação inferior do ADA (Início, Rede, Mapa e Ajustes).
//
// Fica em core/widgets/ porque aparece em várias telas. Por enquanto é só visual:
// quem usa informa qual item está ativo e o que fazer ao tocar. A navegação de
// verdade (go_router) entra na Fase 4.

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AdaBottomNav extends StatelessWidget {
  const AdaBottomNav({super.key, this.currentIndex = 0, this.onTap});

  final int currentIndex; // 0 início, 1 rede, 2 mapa, 3 ajustes
  final ValueChanged<int>? onTap; // recebe o índice do item tocado

  // Os ícones, na ordem da barra. `static const`: a lista é fixa.
  static const _icons = [
    LucideIcons.house,
    LucideIcons.users,
    LucideIcons.mapPin,
    LucideIcons.settings,
  ];

  // O nome de cada item, na mesma ordem. A barra só tem ícones, então o leitor de
  // tela precisa deste texto para dizer o que cada um é.
  static const _labels = ['Início', 'Rede', 'Mapa', 'Configurações'];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.outline)),
      ),
      // SafeArea: não deixa a barra ficar sob os botões do sistema do celular.
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 73,
          child: Row(
            // spaceEvenly: divide o espaço igualmente entre os 4 itens.
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (var i = 0; i < _icons.length; i++)
                _NavItem(
                  icon: _icons[i],
                  label: _labels[i],
                  active: i == currentIndex,
                  onTap: () => onTap?.call(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // Semantics: dá o nome ao item e diz se é o selecionado ("Início, selecionado").
    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          width: 56,
          height: 50,
          decoration: BoxDecoration(
            // Item ativo: fundo rosa a 15% (cor primária do tema).
            color: active ? colors.tertiary.withValues(alpha: 0.15) : null,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(
            icon,
            size: 24,
            color: active ? colors.tertiary : colors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
