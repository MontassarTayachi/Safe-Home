import 'package:flutter/material.dart';
import 'package:safehome/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  String? imageUrl;
  String? time;
  bool _isLoading = false;
  bool _isRefreshing = false;
  late TabController _tabController;
  List<Map<String, dynamic>> _notificationHistory = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchLastImage();
    _loadNotificationHistory();
  }

  Future<void> fetchLastImage() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      final data = await ApiService.fetchLastImage();
      setState(() {
        // D'après le backend, la réponse contient directement l'objet image
        imageUrl = data['imageUrl'];

        // Convertir la date au format lisible en utilisant le champ 'time'
        final timeString = data['time'];
        if (timeString != null) {
          // Si time est un timestamp ISO format
          try {
            final dateTime = DateTime.parse(timeString);
            time =
                '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
          } catch (e) {
            // Si le format n'est pas ISO
            time = timeString.toString();
          }
        } else {
          time = 'Date inconnue';
        }

        _isRefreshing = false;
      });
    } catch (e) {
      print('Error fetching image: $e');
      setState(() {
        _isRefreshing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Erreur de chargement: ${e.toString().replaceAll("Exception: ", "")}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadNotificationHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Récupérer toutes les images pour l'historique
      final images = await ApiService.fetchAllImages();

      setState(() {
        _notificationHistory = [];

        // Transformer les images en notifications
        for (var image in images) {
          String formattedTime = 'Date inconnue';

          // Utiliser le champ 'time' fourni par l'API
          final timeString = image['time'];
          if (timeString != null) {
            try {
              final dateTime = DateTime.parse(timeString);
              formattedTime =
                  '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
            } catch (e) {
              formattedTime = timeString.toString();
            }
          }

          // Déterminer le type d'image en fonction de l'extension
          String type = 'motion';
          final imageUrl = image['imageUrl']?.toString() ?? '';
          if (imageUrl.contains('webp')) {
            type =
                'alert'; // On considère les webp comme des alertes importantes
          }

          // Extraire le nom du fichier depuis l'URL
          String fileName = 'Image';
          try {
            final uri = Uri.parse(imageUrl);
            final path = uri.path;
            final segments = path.split('/');
            if (segments.isNotEmpty) {
              fileName = segments.last;
            }
          } catch (e) {
            // En cas d'erreur, on garde la valeur par défaut
          }

          _notificationHistory.add({
            'id': image['_id'] ?? 'unknown',
            'title': 'Détection: $fileName',
            'body': 'Une détection a été enregistrée',
            'time': formattedTime,
            'type': type,
            'imageUrl': imageUrl,
          });
        }

        // Trier les notifications par date (plus récentes en premier)
        _notificationHistory.sort((a, b) {
          try {
            final timeA = a['time']?.toString() ?? '';
            final timeB = b['time']?.toString() ?? '';
            return timeB.compareTo(timeA);
          } catch (e) {
            return 0;
          }
        });

        _isLoading = false;
      });
    } catch (e) {
      print('Error loading history: $e');
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Erreur de chargement de l\'historique: ${e.toString().replaceAll("Exception: ", "")}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SafeHome'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('isConnected', false);
              if (mounted) {
                Navigator.pushReplacementNamed(context, 'AddUser');
              }
            },
            tooltip: 'Déconnexion',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, 'Settings');
            },
            tooltip: 'Paramètres',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.home), text: 'Accueil'),
            Tab(icon: Icon(Icons.notifications), text: 'Alertes'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Home with Last Image
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white,
                  const Color(0xFFE0F2F7),
                ],
              ),
            ),
            child: _isRefreshing && imageUrl == null
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: fetchLastImage,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          // Statut du système
                          Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 16),
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.green),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'Système actif et opérationnel',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Dernière image détectée
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  const Text(
                                    'Dernière Détection',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF19717B),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  _isRefreshing && imageUrl != null
                                      ? const Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(50.0),
                                            child: CircularProgressIndicator(),
                                          ),
                                        )
                                      : ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          child: imageUrl != null
                                              ? Image.network(
                                                  imageUrl!,
                                                  loadingBuilder: (context,
                                                      child, loadingProgress) {
                                                    if (loadingProgress == null)
                                                      return child;
                                                    return Center(
                                                      child:
                                                          CircularProgressIndicator(
                                                        value: loadingProgress
                                                                    .expectedTotalBytes !=
                                                                null
                                                            ? loadingProgress
                                                                    .cumulativeBytesLoaded /
                                                                loadingProgress
                                                                    .expectedTotalBytes!
                                                            : null,
                                                      ),
                                                    );
                                                  },
                                                  errorBuilder: (context, error,
                                                      stackTrace) {
                                                    return Container(
                                                      width: double.infinity,
                                                      height: 200,
                                                      color: Colors.grey[300],
                                                      child: const Center(
                                                        child: Icon(
                                                          Icons.error_outline,
                                                          color: Colors.red,
                                                          size: 50,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                )
                                              : Container(
                                                  width: double.infinity,
                                                  height: 200,
                                                  color: Colors.grey[200],
                                                  child: const Center(
                                                    child: Text(
                                                      'Aucune image disponible',
                                                      style: TextStyle(
                                                          color: Colors.grey),
                                                    ),
                                                  ),
                                                ),
                                        ),
                                  const SizedBox(height: 15),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE0F2F7),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.access_time,
                                          color: Color(0xFF19717B),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          time != null
                                              ? 'Détecté à: $time'
                                              : 'Aucune détection',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Color(0xFF19717B),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Panneau de contrôle
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Panneau de contrôle',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF19717B),
                                    ),
                                  ),
                                  const SizedBox(height: 15),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: [
                                      _buildControlButton(Icons.refresh,
                                          'Actualiser', fetchLastImage),
                                      _buildControlButton(
                                          Icons.notifications, 'Alertes', () {
                                        _tabController.animateTo(1);
                                      }),
                                      _buildControlButton(
                                          Icons.camera_alt, 'Capture', () {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Capture manuelle en cours...'),
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),

          // Tab 2: Notification History
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white,
                  const Color(0xFFE0F2F7),
                ],
              ),
            ),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _notificationHistory.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_off_outlined,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucune alerte pour le moment',
                              style: TextStyle(
                                  fontSize: 18, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadNotificationHistory,
                        child: ListView.builder(
                          itemCount: _notificationHistory.length,
                          itemBuilder: (context, index) {
                            final notification = _notificationHistory[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      notification['type'] == 'alert'
                                          ? Colors.red[100]
                                          : Colors.orange[100],
                                  child: Icon(
                                    notification['type'] == 'alert'
                                        ? Icons.warning_amber
                                        : Icons.motion_photos_on,
                                    color: notification['type'] == 'alert'
                                        ? Colors.red
                                        : Colors.orange,
                                  ),
                                ),
                                title: Text(
                                  notification['title'],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(notification['body']),
                                    const SizedBox(height: 4),
                                    Text(
                                      notification['time'],
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                isThreeLine: true,
                                trailing: Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: Colors.grey[400],
                                ),
                                onTap: () {
                                  // Afficher l'image de la notification dans une dialogue
                                  if (notification['imageUrl'] != null) {
                                    showDialog(
                                      context: context,
                                      builder: (context) => Dialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  const BorderRadius.vertical(
                                                top: Radius.circular(16),
                                              ),
                                              child: Image.network(
                                                notification['imageUrl'],
                                                fit: BoxFit.cover,
                                                loadingBuilder: (context, child,
                                                    loadingProgress) {
                                                  if (loadingProgress == null)
                                                    return child;
                                                  return SizedBox(
                                                    height: 300,
                                                    child: Center(
                                                      child:
                                                          CircularProgressIndicator(
                                                        value: loadingProgress
                                                                    .expectedTotalBytes !=
                                                                null
                                                            ? loadingProgress
                                                                    .cumulativeBytesLoaded /
                                                                loadingProgress
                                                                    .expectedTotalBytes!
                                                            : null,
                                                      ),
                                                    ),
                                                  );
                                                },
                                                errorBuilder: (context, error,
                                                    stackTrace) {
                                                  return Container(
                                                    height: 200,
                                                    color: Colors.grey[300],
                                                    child: const Center(
                                                      child: Icon(
                                                        Icons.error_outline,
                                                        color: Colors.red,
                                                        size: 50,
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(16.0),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    notification['title'],
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(notification['body']),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Détecté le: ${notification['time']}',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.grey[600],
                                                      fontStyle:
                                                          FontStyle.italic,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 16),
                                                  SizedBox(
                                                    width: double.infinity,
                                                    child: ElevatedButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context),
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: const Color(0xFF19717B),
                                                      ),
                                                      child: const Row(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          Icon(Icons.close, color: Colors.white),
                                                          SizedBox(width: 8),
                                                          Text('Fermer', style: TextStyle(color: Colors.white)),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Aucune image disponible pour cette alerte'),
                                      ),
                                    );
                                  }
                                },
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton(
      IconData icon, String label, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFE0F2F7),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF19717B)),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF19717B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
