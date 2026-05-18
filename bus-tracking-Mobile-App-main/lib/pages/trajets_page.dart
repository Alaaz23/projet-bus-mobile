import 'package:flutter/material.dart';
import 'package:bus_tracking/services/api_service.dart';
import 'package:bus_tracking/utils/constants.dart';

class TrajetsPage extends StatefulWidget {
  const TrajetsPage({Key? key}) : super(key: key);

  @override
  State<TrajetsPage> createState() => _TrajetsPageState();
}

class _TrajetsPageState extends State<TrajetsPage> {
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService.getTrajets();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Trajets',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
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
                          setState(() => _future = ApiService.getTrajets()),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Réessayer'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal),
                    ),
                  ],
                ),
              ),
            );
          }

          final trajets = snapshot.data ?? [];
          if (trajets.isEmpty) {
            return const Center(child: Text('Aucun trajet trouvé.'));
          }

          return RefreshIndicator(
            onRefresh: () async =>
                setState(() => _future = ApiService.getTrajets()),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: trajets.length,
              itemBuilder: (context, index) {
                final t = trajets[index] as Map<String, dynamic>;
                final libelle = t['libelle'] ?? '—';
                final id = t['id']?.toString() ?? '—';

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.teal.withOpacity(0.15),
                      child: const Icon(Icons.route, color: Colors.teal),
                    ),
                    title: Text(
                      libelle,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: kPrimaryColor),
                    ),
                    subtitle: Text('ID : $id'),
                    trailing: const Icon(Icons.chevron_right, color: Colors.teal),
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
