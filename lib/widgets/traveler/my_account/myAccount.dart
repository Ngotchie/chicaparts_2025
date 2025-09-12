import 'dart:convert';

import 'package:chicaparts_partner/providers/language_provider.dart';
import 'package:chicaparts_partner/widgets/login/welcome.dart';
import 'package:chicaparts_partner/widgets/traveler/my_account/myBooking.dart';
import 'package:chicaparts_partner/widgets/traveler/my_account/profile.dart';
import 'package:chicaparts_partner/widgets/traveler/my_account/setting.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyAccountPage extends StatefulWidget {
  const MyAccountPage({super.key});

  @override
  State<MyAccountPage> createState() => _MyAccountPageState();
}

class _MyAccountPageState extends State<MyAccountPage> {
  bool isGuest = true;
  String? userName;
  String? email;

  @override
  void initState() {
    super.initState();
    _loadUserSession();
  }

  Future<Map<String, dynamic>> getUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user');

    if (userData != null) {
      final json = jsonDecode(userData);
      final name = json['name'] ?? json['first_name'] ?? "Utilisateur";
      final email = json['email'] ?? "";
      return {
        'isGuest': false,
        'name': name,
        'email': email,
      };
    }

    return {
      'isGuest': true,
      'name': null,
      'email': null,
    };
  }

  Future<void> _loadUserSession() async {
    final session = await getUserSession();
    setState(() {
      isGuest = session['isGuest'];
      userName = session['name'];
      email = session['email'];
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              /// 🔝 AppBar "Mon compte"
              Padding(
                padding: const EdgeInsets.only(top: 12.0, bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "👤 ${lang.t('my_account')}",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF244B6B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          lang.t('my_account_txt'),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings_outlined,
                          size: 26, color: Color(0xFF244B6B)),
                      onPressed: () {
                        // Navigation vers Paramètres
                      },
                      tooltip: "Paramètres",
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),

              /// 👤 Avatar + nom ou invité
              Center(
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 40,
                      backgroundColor: Color(0xFF244B6B),
                      child: Icon(Icons.person, size: 40, color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isGuest ? "Invité" : userName ?? lang.t('user'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF244B6B),
                      ),
                    ),
                    if (!isGuest && email != null)
                      Text(email!,
                          style:
                              TextStyle(fontSize: 14, color: Colors.grey[600])),
                  ],
                ),
              ),

              const SizedBox(height: 15),

              /// 📦 Menu des options
              _buildOptionTile(Icons.settings, lang.t('settings'), () {
                // TODO: Naviguer vers page Paramètres
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
                );
              }),

              _buildOptionTile(Icons.lock, lang.t('privacy'), () {
                // TODO: Page RGPD ou préférences
              }),

              _buildOptionTile(Icons.history, lang.t('my_bookings'), () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyReservationsPage()),
                );
              }),

              if (!isGuest)
                _buildOptionTile(Icons.edit, lang.t('my_profile'), () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfilePage()),
                  );
                }),

              const Divider(height: 25),

              isGuest
                  ? _buildOptionTile(Icons.login, lang.t('login'), () {
                      // TODO: Naviguer vers page de login
                      Navigator.of(context).pushReplacementNamed('/login');
                    })
                  : _buildOptionTile(Icons.logout, lang.t('logout'), () {
                      // TODO: Déconnexion logic
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text("Déconnexion"),
                          content: Text(lang.t('text_logout')),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          actions: [
                            TextButton(
                              child: Text(lang.t('cancel')),
                              onPressed: () => Navigator.pop(context),
                            ),
                            TextButton(
                              child: Text(
                                lang.t('logout'),
                                style: const TextStyle(color: Colors.redAccent),
                              ),
                              onPressed: () {
                                Navigator.pop(
                                    context); // ferme la boîte de dialogue
                                logoutUser(context); // 🔥 déconnexion
                              },
                            ),
                          ],
                        ),
                      );
                    }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      leading: Icon(icon, color: const Color(0xFF244B6B)),
      title: Text(label, style: const TextStyle(fontSize: 16)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  void logoutUser(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // 🔐 Supprime toute la session

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => WelcomePage()),
      (route) => false,
    );
  }
}
