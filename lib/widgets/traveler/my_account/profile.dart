import 'dart:convert';

import 'package:chicaparts_partner/api/traveler/api_booking_traveler.dart';
import 'package:chicaparts_partner/models/traveler/modele_booking_traveler.dart';
import 'package:chicaparts_partner/providers/language_provider.dart';
import 'package:chicaparts_partner/services/api.dart';
import 'package:chicaparts_partner/widgets/traveler/my_account/editProfile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chicaparts_partner/models/user/user.dart';
import 'package:http/http.dart' as http;

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<UserProfile> _futureProfile;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _futureProfile = fetchUserProfile();
  }

  ApiBooking apiBooking = ApiBooking();
  Future<UserProfile> fetchUserProfile() async {
    final prefs = await SharedPreferences.getInstance();

    final userJson = prefs.getString('user');
    final currentUser = User.fromJson(jsonDecode(userJson!));

    User user = currentUser;
    return await apiBooking.fetchUserProfile(user);
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: Text("👤 ${lang.t('my_profile')}"),
        backgroundColor: Colors.white,
      ),
      body: FutureBuilder<UserProfile>(
          future: _futureProfile,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                  child:
                      Text("${lang.t('error')} : ${lang.t('error_network')}"));
            } else {
              final user = snapshot.data!;
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundImage: AssetImage('assets/images/avatar.png'),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "${user.firstName} ${user.lastName}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 30),
                  _buildProfileItem(
                      Icons.book, lang.t('bookings'), "${user.bookingCount}"),
                  _buildProfileItem(
                      Icons.reviews, lang.t('review'), "${user.reviewCount}"),

                  _buildProfileItem(
                      Icons.badge, lang.t('first_name'), user.firstName),
                  _buildProfileItem(
                      Icons.badge_outlined, lang.t('last_name'), user.lastName),
                  _buildProfileItem(Icons.female, lang.t('gender'),
                      user.gender == 'm' ? lang.t('male') : lang.t('female')),
                  _buildProfileItem(
                      Icons.location_city, lang.t('city'), user.city),
                  _buildProfileItem(
                      Icons.location_pin, lang.t('zip'), user.zipCode ?? '-'),
                  _buildProfileItem(
                      Icons.map, lang.t('state'), user.state ?? '-'),
                  _buildProfileItem(Icons.email, "Email", user.email),
                  _buildProfileItem(Icons.phone, lang.t('phone'), user.phone),

                  const SizedBox(height: 20),

                  /// ✏️ Modifier
                  ElevatedButton.icon(
                    onPressed: () async {
                      final updated = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditProfilePage(user: snapshot.data!),
                        ),
                      );

                      if (updated == true) {
                        setState(() {
                          _futureProfile = fetchUserProfile(); // 🔁 rafraîchir
                        });
                      }
                    },
                    icon: const Icon(
                      Icons.edit,
                      color: Colors.white,
                    ),
                    label: Text(
                      lang.t('edit_profile'),
                      style: const TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF244B6B),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// ❌ Supprimer
                  OutlinedButton.icon(
                    onPressed: () {
                      _confirmDelete(context);
                    },
                    icon: const Icon(Icons.delete_forever, color: Colors.red),
                    label: Text(
                      lang.t('delete_profile'),
                      style: const TextStyle(color: Colors.red),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ],
              );
            }
          }),
    );
  }

  Widget _buildProfileItem(IconData icon, String label, String value) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 6),
      leading: Icon(icon, color: Colors.blueAccent),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(value),
    );
  }

  void _confirmDelete(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("❗️${lang.t('confirm')}"),
        content: Text(lang.t('delete_account_message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(lang.t('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAccount();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(lang.t('profile_deleted'))),
              );
              // Rediriger ou fermer la session
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(lang.t('delete')),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    setState(() => _isSaving = true);

    try {
      ApiUrl url = ApiUrl();
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user');
      final currentUser = User.fromJson(jsonDecode(userJson!));

      final response = await http.delete(
        Uri.parse('${url.getChicapartsUrl()}auth/me?user_id=${currentUser.id}'),
        headers: {
          'Accept': 'application/json',
          'X-Authorization': url.getKey(),
        },
      );

      if (response.statusCode == 200) {
        await prefs.clear(); // 🔐 Déconnecte l'utilisateur
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, "/login", (route) => false);
      } else {
        final msg = jsonDecode(response.body)['error'] ?? 'Unknow Error';
        _showError(context, msg.toString());
      }
    } catch (e) {
      _showError(context, "Network error : $e");
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showError(BuildContext context, String message) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(lang.t('error')),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(lang.t('close')))
        ],
      ),
    );
  }
}
