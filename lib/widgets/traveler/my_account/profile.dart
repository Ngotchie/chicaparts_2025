import 'dart:convert';
import 'package:chicaparts_partner/api/traveler/api_booking_traveler.dart';
import 'package:chicaparts_partner/models/traveler/modele_booking_traveler.dart';
import 'package:chicaparts_partner/providers/language_provider.dart';
import 'package:chicaparts_partner/widgets/traveler/my_account/editProfile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chicaparts_partner/models/user/user.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<UserProfile> _futureProfile;
  final ApiBooking api = ApiBooking();

  @override
  void initState() {
    super.initState();
    _futureProfile = _fetch();
  }

  Future<UserProfile> _fetch() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('user');
    final currentUser = User.fromJson(jsonDecode(raw!));
    return api.fetchUserProfile(currentUser);
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 🔵 HEADER UNIFORME
            _buildHeader(context, "👤 ${lang.t('my_profile')}"),

            // ligne séparatrice
            Container(height: 1, color: Colors.grey[300]),

            // -------------------------------
            //        CONTENU SCROLLABLE
            // -------------------------------
            Expanded(
              child: FutureBuilder<UserProfile>(
                future: _futureProfile,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError || !snap.hasData) {
                    return Center(
                      child: Text(
                          "${lang.t('error')} : ${lang.t('error_network')}"),
                    );
                  }

                  final u = snap.data!;

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      _SectionTitle(lang.t('personal_infos')),
                      _InfoRow(
                          icon: Icons.badge_outlined,
                          label: lang.t('first_name'),
                          value: u.firstName),
                      _InfoRow(
                          icon: Icons.badge,
                          label: lang.t('last_name'),
                          value: u.lastName),
                      _InfoRow(
                        icon: Icons.wc_outlined,
                        label: lang.t('gender'),
                        value: (u.gender == 'm')
                            ? lang.t('male')
                            : lang.t('female'),
                      ),
                      const _DividerThin(),
                      _SectionTitle(lang.t('contact')),
                      _ActionRow(
                        icon: Icons.email_outlined,
                        label: "Email",
                        value: u.email,
                        onTap: () => _open(Uri.parse('mailto:${u.email}')),
                        trailingIcon: Icons.open_in_new,
                      ),
                      _ActionRow(
                        icon: Icons.call_outlined,
                        label: lang.t('phone'),
                        value: u.phone,
                        onTap: () => _open(Uri.parse('tel:${u.phone}')),
                        trailingIcon: Icons.phone_forwarded,
                      ),
                      const _DividerThin(),
                      _SectionTitle(lang.t('address')),
                      _InfoRow(
                          icon: Icons.location_city_outlined,
                          label: lang.t('city'),
                          value: u.city),
                      _InfoRow(
                          icon: Icons.local_activity_outlined,
                          label: lang.t('state'),
                          value: u.state ?? '—'),
                      _InfoRow(
                          icon: Icons.map_outlined,
                          label: lang.t('zip'),
                          value: u.zipCode ?? '—'),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // ---------------------------------------------------------
      //                BOUTON "Éditer le profil"
      // ---------------------------------------------------------
      floatingActionButton: FutureBuilder<UserProfile>(
        future: _futureProfile,
        builder: (context, snap) {
          if (!snap.hasData) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            backgroundColor: const Color(0xFF244B6B),
            icon: const Icon(Icons.edit, color: Colors.white),
            label: Text(lang.t('edit_profile'),
                style: const TextStyle(color: Colors.white)),
            onPressed: () async {
              final updated = await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => EditProfilePage(user: snap.data!)),
              );
              if (updated == true) setState(() => _futureProfile = _fetch());
            },
          );
        },
      ),
    );
  }

  /// 🔵 HEADER UNIFORME (comme les autres pages)
  Widget _buildHeader(BuildContext context, String title) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 20, color: Color(0xFF244B6B)),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF244B6B),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _open(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

/// ====== UI Helpers ======

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 6),
      child: Text(text,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
    );
  }
}

class _DividerThin extends StatelessWidget {
  const _DividerThin();
  @override
  Widget build(BuildContext context) {
    return Divider(height: 20, thickness: 0.6, color: Colors.grey.shade300);
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
      leading: Icon(icon, color: const Color(0xFF244B6B)),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(value, maxLines: 2, overflow: TextOverflow.ellipsis),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final IconData? trailingIcon;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
      leading: Icon(icon, color: const Color(0xFF244B6B)),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(value),
      trailing: trailingIcon != null
          ? Icon(trailingIcon, size: 18, color: Colors.grey[600])
          : null,
      onTap: onTap,
    );
  }
}
