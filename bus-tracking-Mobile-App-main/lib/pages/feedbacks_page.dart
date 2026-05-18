import 'package:flutter/material.dart';
import 'package:bus_tracking/services/api_service.dart';
import 'package:bus_tracking/utils/constants.dart';

class FeedbacksPage extends StatefulWidget {
  const FeedbacksPage({Key? key}) : super(key: key);

  @override
  State<FeedbacksPage> createState() => _FeedbacksPageState();
}

class _FeedbacksPageState extends State<FeedbacksPage> {
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService.getFeedbacks();
  }

  Color _ratingColor(int? rating) {
    if (rating == null) return Colors.grey;
    if (rating >= 4) return Colors.green;
    if (rating >= 2) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Feedbacks',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange,
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
                          setState(() => _future = ApiService.getFeedbacks()),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Réessayer'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange),
                    ),
                  ],
                ),
              ),
            );
          }

          final feedbacks = snapshot.data ?? [];
          if (feedbacks.isEmpty) {
            return const Center(child: Text('Aucun feedback trouvé.'));
          }

          return RefreshIndicator(
            onRefresh: () async =>
                setState(() => _future = ApiService.getFeedbacks()),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: feedbacks.length,
              itemBuilder: (context, index) {
                final f = feedbacks[index] as Map<String, dynamic>;
                final nom = f['nom'] ?? '—';
                final prenom = f['prenom'] ?? '—';
                final commentaire = f['commentaire'] ?? '';
                final rating = f['rating'] as int?;
                final checked = f['checked'] as bool? ?? false;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor:
                                  Colors.orange.withOpacity(0.15),
                              child: const Icon(Icons.person,
                                  color: Colors.orange),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '$prenom $nom',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: kPrimaryColor),
                              ),
                            ),
                            if (rating != null)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(
                                  5,
                                  (i) => Icon(
                                    i < rating
                                        ? Icons.star
                                        : Icons.star_border,
                                    size: 16,
                                    color: _ratingColor(rating),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (commentaire.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            commentaire,
                            style: TextStyle(
                                color: Colors.grey[700], fontSize: 13),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              checked
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              size: 16,
                              color: checked ? Colors.green : Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              checked ? 'Lu' : 'Non lu',
                              style: TextStyle(
                                  fontSize: 11,
                                  color:
                                      checked ? Colors.green : Colors.grey),
                            ),
                          ],
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
