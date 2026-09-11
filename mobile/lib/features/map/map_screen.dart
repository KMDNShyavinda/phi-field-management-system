import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../domain/models.dart';
import '../../providers.dart';

class OfflineMapScreen extends ConsumerStatefulWidget {
  const OfflineMapScreen({super.key});

  @override
  ConsumerState<OfflineMapScreen> createState() => _OfflineMapScreenState();
}

class _OfflineMapScreenState extends ConsumerState<OfflineMapScreen> {
  List<Premise> _premises = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPremises();
  }

  Future<void> _loadPremises() async {
    final maps = await ref.read(dbProvider).all('premises');
    final premises = maps.map((e) => Premise.fromMap(e)).toList();
    
    setState(() {
      _premises = premises;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Default center to Colombo if no premises exist, or center to the first premise.
    final centerPos = _premises.isNotEmpty 
        ? LatLng(_premises.first.latitude, _premises.first.longitude)
        : const LatLng(6.9271, 79.8612);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Maps - Locations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPremises,
          )
        ],
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: centerPos,
          initialZoom: 13.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.phi.app',
            // Ideally, we'd use a caching tile provider here for true offline.
            // For MVP, standard TileLayer caches per session.
          ),
          MarkerLayer(
            markers: _premises.map((p) {
              return Marker(
                width: 40.0,
                height: 40.0,
                point: LatLng(p.latitude, p.longitude),
                child: GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text(p.name),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Owner: ${p.ownerName}'),
                            Text('Risk Level: ${p.risk.toUpperCase()}'),
                            Text('Compliance: ${p.complianceScore}%'),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          )
                        ],
                      ),
                    );
                  },
                  child: Icon(
                    Icons.location_on,
                    color: p.risk == 'high' || p.risk == 'critical' ? Colors.red : Colors.blue,
                    size: 40.0,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
