// Cartão com a localização encontrada: coordenadas e o link de mapa que irá na
// mensagem de alerta.

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
              Text('Sua localização atual', style: textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          // 5 casas decimais (cerca de 1 metro) bastam para ler na tela.
          Text(
            'Latitude ${point.latitude.toStringAsFixed(5)}\n'
            'Longitude ${point.longitude.toStringAsFixed(5)}',
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
