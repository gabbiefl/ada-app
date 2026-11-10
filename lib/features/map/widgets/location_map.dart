// Mapa interativo com a posição da usuária (OpenStreetMap, pelo flutter_map).
//
// Dá para arrastar e dar zoom. O botão do canto volta a centralizar no ponto
// dela. Só aparece depois de a posição ser encontrada, então os pedaços do mapa
// (tiles) só são baixados quando a usuária pede para ver a localização.
//
// Privacidade: o que vai para a internet é só o pedido dos pedaços do mapa da
// região (o servidor do OpenStreetMap vê a área, não a posição exata). A posição
// em si NÃO é enviada, nem guardada.
//
// Sem internet, o fundo do mapa fica vazio e o marcador continua no lugar; o
// cartão de baixo (link do mapa) segue valendo como plano B.

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:ada_app/core/theme/app_colors.dart';
import 'package:ada_app/features/map/models/geo_point.dart';

class LocationMap extends StatefulWidget {
  const LocationMap({super.key, required this.point, this.tileProvider});

  final GeoPoint point;

  // Quem entrega os pedaços do mapa. No app é a internet (padrão); nos testes é
  // uma versão que não acessa a rede.
  final TileProvider? tileProvider;

  // Altura do mapa na tela.
  static const double height = 320;
  static const double _zoom = 16;

  @override
  State<LocationMap> createState() => _LocationMapState();
}

class _LocationMapState extends State<LocationMap> {
  final _controller = MapController();

  LatLng get _center => LatLng(widget.point.latitude, widget.point.longitude);

  // Quando "Atualizar localização" traz um ponto novo, o mapa vai até ele.
  @override
  void didUpdateWidget(LocationMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.point != widget.point) {
      _controller.move(_center, LocationMap._zoom);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Mapa com a sua localização atual',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: LocationMap.height,
          child: Stack(
            children: [
              FlutterMap(
                mapController: _controller,
                options: MapOptions(
                  initialCenter: _center,
                  initialZoom: LocationMap._zoom,
                  minZoom: 3,
                  maxZoom: 19,
                  // Sem girar o mapa com dois dedos: confunde quem está com
                  // pressa. Arrastar e dar zoom continuam.
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    // Identifica o app para o servidor, como a política de uso
                    // do OpenStreetMap pede.
                    userAgentPackageName: 'br.academico.cesuca.ada',
                    tileProvider: widget.tileProvider,
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _center,
                        width: 64,
                        height: 64,
                        child: const _YouAreHere(),
                      ),
                    ],
                  ),
                  // A licença dos dados do mapa exige este crédito. Sem aumentar com a
                  // fonte do sistema: é um selo no canto, e crescido ele estouraria
                  // o mapa.
                  MediaQuery.withNoTextScaling(
                    child: const SimpleAttributionWidget(
                      source: Text('© OpenStreetMap'),
                      backgroundColor: Colors.white70,
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 12,
                right: 12,
                child: _RecenterButton(
                  onPressed: () => _controller.move(_center, LocationMap._zoom),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// O marcador "você está aqui": um ponto rosa com borda branca e um halo.
class _YouAreHere extends StatelessWidget {
  const _YouAreHere();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.brand.withValues(alpha: 0.2),
            ),
          ),
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.brand,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Botão redondo de 48 que volta a centralizar o mapa na usuária.
class _RecenterButton extends StatelessWidget {
  const _RecenterButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 3,
      shape: const CircleBorder(),
      child: IconButton(
        onPressed: onPressed,
        tooltip: 'Centralizar na minha localização',
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        icon: const Icon(
          LucideIcons.locateFixed,
          size: 22,
          color: AppColors.modeNormal,
        ),
      ),
    );
  }
}
