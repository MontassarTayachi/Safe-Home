import 'package:flutter/material.dart';
import 'package:safehome/services/config_service.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  final _ipController = TextEditingController();
  final _portController = TextEditingController();
  final _baseUrlController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _showAdvancedOptions = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final baseUrl = await ConfigService.getBaseUrl();
    final ip = await ConfigService.getIpAddress();
    final port = await ConfigService.getPort();

    setState(() {
      _baseUrlController.text = baseUrl;
      _ipController.text = ip;
      _portController.text = port;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Si on utilise l'URL directe, on l'enregistre directement
      if (_showAdvancedOptions) {
        await ConfigService.setBaseUrl(_baseUrlController.text);
      } else {
        // Sinon on utilise les champs IP et port
        await ConfigService.setIpAddress(_ipController.text);
        await ConfigService.setPort(_portController.text);
      }

      // Recharger les paramètres pour s'assurer que tout est cohérent
      await _loadSettings();

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configuration enregistrée avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    _baseUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres serveur'),
        backgroundColor: const Color(0xFF19717B),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Configuration du Serveur',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF19717B),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Configurez les paramètres réseau pour vous connecter au serveur SafeHome.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 15),
                    // Switch pour basculer entre configuration simple et avancée
                    SwitchListTile(
                      title: const Text('Mode avancé'),
                      subtitle: const Text('Configurer directement l\'URL complète'),
                      value: _showAdvancedOptions,
                      activeColor: const Color(0xFF19717B),
                      onChanged: (bool value) {
                        setState(() {
                          _showAdvancedOptions = value;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    
                    // Affichage conditionnel en fonction du mode choisi
                    _showAdvancedOptions
                    ? TextFormField(
                        controller: _baseUrlController,
                        decoration: InputDecoration(
                          labelText: 'URL complète du serveur',
                          hintText: 'https://backend-safehome.onrender.com',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(Icons.link),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer une URL valide';
                          }
                          try {
                            final uri = Uri.parse(value);
                            if (!uri.hasScheme || !uri.hasAuthority) {
                              return 'L\'URL doit inclure le protocole (http/https) et le domaine';
                            }
                          } catch (e) {
                            return 'Format d\'URL invalide';
                          }
                          return null;
                        },
                      )
                    : Column(
                        children: [

                    TextFormField(
                      controller: _ipController,
                      decoration: InputDecoration(
                        labelText: 'Adresse ou nom de domaine',
                        hintText: 'backend-safehome.onrender.com',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: const Icon(Icons.computer),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer une adresse ou un nom de domaine';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _portController,
                      decoration: InputDecoration(
                        labelText: 'Port (optionnel)',
                        hintText: 'Laisser vide pour le port par défaut',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: const Icon(Icons.settings_ethernet),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return null; // Le port est optionnel
                        }
                        final port = int.tryParse(value);
                        if (port == null || port <= 0 || port > 65535) {
                          return 'Veuillez entrer un port valide (1-65535)';
                        }
                        return null;
                      },
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 10),
                    // Message d'information sur le protocole
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.grey[600]),
                          const SizedBox(width: 10),
                          Expanded(
                            child: const Text(
                              'HTTPS sera utilisé pour backend-safehome.onrender.com, HTTP pour les autres serveurs',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saveSettings,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF19717B),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Enregistrer la configuration',
                              style: TextStyle(fontSize: 16, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () {
                          _loadSettings();
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF19717B)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.refresh, color: Color(0xFF19717B)),
                            SizedBox(width: 8),
                            Text(
                              'Réinitialiser les valeurs',
                              style: TextStyle(
                                color: Color(0xFF19717B),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
