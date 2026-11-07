// Caixa vermelha que explica por que a localização não veio, em linguagem
// simples. O texto de cada motivo fica aqui; o serviço só devolve o motivo.

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:ada_app/core/theme/app_colors.dart';
import 'package:ada_app/features/map/data/location_service.dart';

// O que dizer para cada motivo de falha.
String locationFailureMessage(LocationFailure failure) {
  switch (failure) {
    case LocationFailure.serviceDisabled:
      return 'A localização do celular está desligada. Ligue-a para o ADA '
          'encontrar onde você está.';
    case LocationFailure.permissionDenied:
      return 'Sem a permissão de localização, o ADA não consegue mostrar onde '
          'você está. Você pode tentar de novo.';
    case LocationFailure.permissionDeniedForever:
      return 'A permissão de localização está bloqueada. Libere-a nas '
          'configurações do aplicativo.';
    case LocationFailure.timeout:
      return 'Não foi possível encontrar a sua localização a tempo. Vá para '
          'um lugar aberto e tente de novo.';
    case LocationFailure.unknown:
      return 'Não foi possível obter a localização agora. Tente de novo.';
  }
}

class LocationErrorBox extends StatelessWidget {
  const LocationErrorBox({super.key, required this.failure});

  final LocationFailure failure;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: AppColors.modeDangerText);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
      decoration: BoxDecoration(
        color: AppColors.modeDanger.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(
            LucideIcons.triangleAlert,
            size: 22,
            color: AppColors.modeDangerText,
          ),
          const SizedBox(width: 19),
          Expanded(child: Text(locationFailureMessage(failure), style: style)),
        ],
      ),
    );
  }
}
