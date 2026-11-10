// Cartão abaixo do mapa: explica que é essa a posição do alerta e mostra o link
// que vai na mensagem. As coordenadas não aparecem (o mapa já mostra o lugar); elas
// continuam dentro do link, que serve de plano B quando o mapa não carrega.

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:ada_app/core/theme/app_colors.dart';
import 'package:ada_app/features/map/models/geo_point.dart';
import 'package:ada_app/features/map/utils/map_link.dart';

class LocationSuccessCard extends StatelessWidget {
  const LocationSuccessCard({super.key, required this.point});

  final GeoPoint point;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 21, 20, 21),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.placeholder.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.mapPin,
                size: 20,
                color: Theme.of(context).colorScheme.tertiary,
              ),
              const SizedBox(width: 8),
              // Expanded: com texto grande, o título quebra de linha em vez de
              // estourar a largura.
              Expanded(
                child: Text(
                  'Sua localização atual',
                  style: textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'É esta a posição que vai junto do seu alerta.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Text('Link enviado nos alertas', style: textTheme.labelMedium),
          const SizedBox(height: 4),
          // SelectableText: dá para segurar e copiar o link.
          SelectableText(mapLink(point), style: textTheme.bodySmall),
        ],
      ),
    );
  }
}
