import 'package:flutter/material.dart';
import 'package:bus_tracking/services/api_service.dart';
import 'package:bus_tracking/utils/constants.dart';

class BusesPage extends StatefulWidget {
  const BusesPage({Key? key}) : super(key: key);

  @override
  State<BusesPage> createState() => _BusesPageState();
}

class _BusesPageState extends State<BusesPage> {
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService.getBuses();
  }

  Color _statutColor(String? statut) {
    switch (statut) {
      case 'EN_ROUTE':
        return Colors.green;
      case 'A_LARRET':
        return Colors.orange;
      case 'HORS_SERVICE':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _statutLabel(String? statut) {
    switch (statut) {
      case 'EN_ROUTE':
        return 'En route';
      case 'A_LARRET':
        return 'À l\'arrêt';
      case 'HORS_SERVICE':
        return 'Hors service';
      default:
        return statut ?? '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Bus',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: kPrimaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: kBackgroundColor,
      body: FutureBuilder<List<dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    Text(
                      'Erreur : ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () =>
                          setState(() => _future = ApiService.getBuses()),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Réessayer'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryColor),
                    ),
                  ],
                ),
              ),
            );
          }

          final buses = snapshot.data ?? [];
          if (buses.isEmpty) {
            return const Center(child: Text('Aucun bus trouvé.'));
          }

          return RefreshIndicator(
            onRefresh: () async =>
                setState(() => _future = ApiService.getBuses()),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: buses.length,
              itemBuilder: (context, index) {
                final b = buses[index] as Map<String, dynamic>;
                final designation = b['designation'] ?? '—';
                final capacite = b['capacite']?.toString() ?? '—';
                final statut = b['statut'] as String?;
                final traget = b['traget'];
                final trajetLabel = traget != null
                    ? (traget['libelle'] ?? '—')
                    : '—';

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: kPrimaryColor.withOpacity(0.1),
                          child: const Icon(Icons.directions_bus,
                              color: kPrimaryColor, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                designation,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: kPrimaryColor),
                              ),
                              const SizedBox(height: 4),
                              Text('Trajet : $trajetLabel',
                                  style: TextStyle(color: Colors.grey[700])),
                              Text('Capacité : $capacite places',
                                  style: TextStyle(color: Colors.grey[600])),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _statutColor(statut).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: _statutColor(statut), width: 1.2),
                          ),
                          child: Text(
                            _statutLabel(statut),
                            style: TextStyle(
                                color: _statutColor(statut),
                                fontWeight: FontWeight.w600,
                                fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
