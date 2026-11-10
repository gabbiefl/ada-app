// Aba "Mapa": mostra a localização atual da usuária num mapa interativo
// (OpenStreetMap), com o link que vai nos alertas logo abaixo. O acompanhamento
// em tempo real (F8-04) fica para depois. A tela só desenha o estado do LocationController e escolhe o texto
// de cada caso; quem busca a posição é o serviço.

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import 'package:ada_app/core/widgets/page_header.dart';
import 'package:ada_app/features/map/data/location_service.dart';
import 'package:ada_app/features/map/state/location_controller.dart';
import 'package:ada_app/features/map/widgets/location_error_box.dart';
import 'package:ada_app/features/map/widgets/location_map.dart';
import 'package:ada_app/features/map/widgets/location_notice.dart';
import 'package:ada_app/features/map/widgets/location_success_card.dart';

class MapPage extends StatelessWidget {
  // tileProvider: de onde vêm os pedaços do mapa. Só os testes trocam (por uma
  // versão sem internet); no app vale o padrão.
  const MapPage({super.key, this.tileProvider});

  final TileProvider? tileProvider;

  @override
  Widget build(BuildContext context) {
    // watch: a tela se redesenha a cada mudança de estado da busca.
    final location = context.watch<LocationController>();
    final isLoading = location.status == LocationStatus.loading;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(40, 30, 40, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PageHeader(
                title: 'Mapa',
                subtitle: 'Veja a sua localização atual.',
              ),
              const SizedBox(height: 24),
              const LocationNotice(),
              const SizedBox(height: 24),
              FilledButton.icon(
                // onPressed null = botão desligado (enquanto busca).
                onPressed: isLoading ? null : location.refresh,
                icon: const Icon(LucideIcons.locateFixed, size: 22),
                label: Text(_buttonLabel(location.status)),
              ),
              const SizedBox(height: 24),
              _Result(location: location, tileProvider: tileProvider),
            ],
          ),
        ),
      ),
    );
  }

  String _buttonLabel(LocationStatus status) {
    switch (status) {
      case LocationStatus.idle:
        return 'Ver minha localização';
      case LocationStatus.loading:
        return 'Buscando…';
      case LocationStatus.success:
        return 'Atualizar localização';
      case LocationStatus.failure:
        return 'Tentar de novo';
    }
  }
}

// A parte de baixo da tela: muda conforme o estado da busca.
class _Result extends StatelessWidget {
  const _Result({required this.location, this.tileProvider});

  final LocationController location;
  final TileProvider? tileProvider;

  @override
  Widget build(BuildContext context) {
    switch (location.status) {
      case LocationStatus.idle:
        return const SizedBox.shrink(); // nada a mostrar ainda
      case LocationStatus.loading:
        return const Center(
          child: CircularProgressIndicator(
            semanticsLabel: 'Buscando a sua localização',
          ),
        );
      case LocationStatus.success:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LocationMap(point: location.point!, tileProvider: tileProvider),
            const SizedBox(height: 16),
            LocationSuccessCard(point: location.point!),
          ],
        );
      case LocationStatus.failure:
        final failure = location.failure!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LocationErrorBox(failure: failure),
            // Quando só a usuária resolve, oferecemos o atalho para o lugar certo.
            if (failure == LocationFailure.permissionDeniedForever) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: location.openAppSettings,
                child: const Text('Abrir configurações do app'),
              ),
            ],
            if (failure == LocationFailure.serviceDisabled) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: location.openLocationSettings,
                child: const Text('Ligar a localização'),
              ),
            ],
          ],
        );
    }
  }
}
