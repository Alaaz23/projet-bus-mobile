import 'package:flutter/material.dart';
import 'package:bus_tracking/utils/constants.dart';

/// Page d'accueil pour les administrateurs
/// Accessible après connexion avec un compte admin (matricule: admin, mot de passe: admin123)
class AdminHomePage extends StatelessWidget {
  final String matricule;
  final String displayName;
  final String token;

  const AdminHomePage({
    Key? key,
    required this.matricule,
    required this.displayName,
    required this.token,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Panneau Administrateur',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: kPrimaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Déconnexion',
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/');
            },
          ),
        ],
      ),
      backgroundColor: kBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Carte de bienvenue
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              color: kPrimaryColor,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.admin_panel_settings,
                          size: 36, color: kPrimaryColor),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Bienvenue,',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 14),
                          ),
                          Text(
                            displayName,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Matricule : $matricule',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Actions disponibles',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryColor),
            ),
            const SizedBox(height: 12),

            // Grille d'actions admin
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _adminCard(
                  context,
                  icon: Icons.people,
                  label: 'Salariés',
                  subtitle: 'Gérer les employés',
                  color: kSecondaryColor,
                  onTap: () => _showInfo(context,
                      'Gestion des salariés disponible via le portail web'),
                ),
                _adminCard(
                  context,
                  icon: Icons.directions_bus,
                  label: 'Bus',
                  subtitle: 'Gérer les bus',
                  color: kPrimaryColor,
                  onTap: () => _showInfo(context,
                      'Gestion des bus disponible via le portail web'),
                ),
                _adminCard(
                  context,
                  icon: Icons.route,
                  label: 'Trajets',
                  subtitle: 'Voir les trajets',
                  color: Colors.teal,
                  onTap: () => _showInfo(context,
                      'Gestion des trajets disponible via le portail web'),
                ),
                _adminCard(
                  context,
                  icon: Icons.feedback,
                  label: 'Feedbacks',
                  subtitle: 'Voir les retours',
                  color: Colors.orange,
                  onTap: () => _showInfo(context,
                      'Gestion des feedbacks disponible via le portail web'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Info token
            Card(
              color: Colors.grey[100],
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.security, color: kSecondaryColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Connecté en tant qu\'ADMIN',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: kPrimaryColor)),
                          Text(
                            'Utilisez le portail web pour la gestion complète',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _adminCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 4,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 8),
              Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: color)),
              Text(subtitle,
                  style:
                      TextStyle(fontSize: 11, color: Colors.grey[600]),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  void _showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: kPrimaryColor,
      duration: const Duration(seconds: 3),
    ));
  }
}

