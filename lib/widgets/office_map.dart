import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../app_theme.dart';

class OfficeMap extends StatelessWidget {
  const OfficeMap({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    this.height = 190,
    this.userLatitude,
    this.userLongitude,
    this.zoom = 15.5,
  });

  final double latitude;
  final double longitude;
  final int radiusMeters;
  final double height;
  final double? userLatitude;
  final double? userLongitude;
  final double zoom;

  @override
  Widget build(BuildContext context) {
    final office = LatLng(latitude, longitude);
    final hasUser = userLatitude != null && userLongitude != null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: hasUser
                    ? LatLng(
                        (office.latitude + userLatitude!) / 2,
                        (office.longitude + userLongitude!) / 2,
                      )
                    : office,
                initialZoom: zoom,
                minZoom: 3,
                maxZoom: 19,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.bmtcindebarokah.absensi_mobile',
                  maxZoom: 19,
                ),
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: office,
                      radius: radiusMeters.toDouble(),
                      useRadiusInMeter: true,
                      color: brandPrimary.withValues(alpha: 0.14),
                      borderColor: brandPrimary.withValues(alpha: 0.75),
                      borderStrokeWidth: 1.6,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: office,
                      width: 38,
                      height: 38,
                      child: const Icon(
                        Icons.location_pin,
                        color: brandPrimary,
                        size: 34,
                        semanticLabel: 'Kantor',
                      ),
                    ),
                    if (hasUser)
                      Marker(
                        point: LatLng(userLatitude!, userLongitude!),
                        width: 30,
                        height: 30,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: infoMain.withValues(alpha: 0.25),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.my_location, size: 14, color: infoMain),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            Positioned(
              left: 8,
              bottom: 6,
              child: Text(
                '© OpenStreetMap',
                style: TextStyle(
                  fontSize: 10,
                  color: textMuted.withValues(alpha: 0.8),
                  backgroundColor: Colors.white70,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
