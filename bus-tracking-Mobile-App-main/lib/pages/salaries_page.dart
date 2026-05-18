import 'package:flutter/material.dart';
import 'package:bus_tracking/services/api_service.dart';
import 'package:bus_tracking/utils/constants.dart';

class SalariesPage extends StatefulWidget {
  const SalariesPage({Key? key}) : super(key: key);

  @override
  State<SalariesPage> createState() => _SalariesPageState();
}

class _SalariesPageState extends State<SalariesPage> {
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService.getSalaries();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Salariés',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: kSecondaryColor,
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
                      onPressed: () => setState(() {
                        _future = ApiService.getSalaries();
                      }),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Réessayer'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: kSecondaryColor),
                    ),
                  ],
                ),
              ),
            );
          }

          final salaries = snapshot.data ?? [];
          if (salaries.isEmpty) {
            return const Center(child: Text('Aucun salarié trouvé.'));
          }

          return RefreshIndicator(
            onRefresh: () async =>
                setState(() => _future = ApiService.getSalaries()),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: salaries.length,
              itemBuilder: (context, index) {
                final s = salaries[index] as Map<String, dynamic>;
                final nom = s['nom'] ?? '—';
                final prenom = s['prenom'] ?? '—';
                final matricule = s['matricule'] ?? '—';
                final bus = s['bus'];
                final station = s['station'];
                final busLabel = bus != null
                    ? (bus['designation'] ?? 'Bus inconnu')
                    : 'Non assigné';
                final stationLabel = station != null
                    ? (station['libelle'] ?? 'Station inconnue')
                    : 'Non assignée';

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: kSecondaryColor,
                      child: Text(
                        nom.isNotEmpty ? nom[0].toUpperCase() : '?',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(
                      '$prenom $nom',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: kPrimaryColor),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Matricule : $matricule'),
                        Text('Bus : $busLabel',
                            style: TextStyle(color: Colors.grey[600])),
                        Text('Station : $stationLabel',
                            style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                    isThreeLine: true,
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
