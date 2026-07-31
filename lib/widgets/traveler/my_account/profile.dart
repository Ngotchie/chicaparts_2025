import 'dart:convert';
import 'package:chicaparts_partner/api/login/login.dart';
import 'package:chicaparts_partner/api/traveler/api_booking_traveler.dart';
import 'package:chicaparts_partner/api/traveler/api_user_traveler.dart';
import 'package:chicaparts_partner/models/traveler/modele_booking_traveler.dart';
import 'package:chicaparts_partner/providers/language_provider.dart';
import 'package:chicaparts_partner/widgets/login/forgot_password.dart';
import 'package:chicaparts_partner/widgets/traveler/my_account/editProfile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chicaparts_partner/models/user/user.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:chicaparts_partner/widgets/login/welcome.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<UserProfile> _futureProfile;
  final ApiBooking api = ApiBooking();
  final ApiUserTraveler apiUser = ApiUserTraveler();
  bool _profileUpdated = false;

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

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _profileUpdated);
        return false;
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // 🔵 HEADER UNIFORME
                _buildHeader(context, "👤 ${lang.t('my_profile')}"),

                Container(height: 1, color: Colors.grey[300]),

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
                            "${lang.t('error')} : ${lang.t('error_network')}",
                          ),
                        );
                      }

                      final u = snap.data!;

                      return ListView(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
                        children: [
                          _ProfileHeroCard(
                            name: '${u.firstName.trim()} ${u.lastName.trim()}',
                            email: u.email,
                            city: u.city,
                            gender: (u.gender == 'm')
                                ? lang.t('male')
                                : lang.t('female'),
                            subtitle: lang.t('update_profile_text'),
                          ),
                          const SizedBox(height: 18),
                          _InfoSectionCard(
                            title: lang.t('personal_infos'),
                            icon: Icons.perm_identity_rounded,
                            children: [
                              _InfoRow(
                                icon: Icons.badge_outlined,
                                label: lang.t('first_name'),
                                value: u.firstName,
                              ),
                              _InfoRow(
                                icon: Icons.badge_rounded,
                                label: lang.t('last_name'),
                                value: u.lastName,
                              ),
                              _InfoRow(
                                icon: Icons.wc_outlined,
                                label: lang.t('gender'),
                                value: (u.gender == 'm')
                                    ? lang.t('male')
                                    : lang.t('female'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _InfoSectionCard(
                            title: lang.t('contact'),
                            icon: Icons.alternate_email_rounded,
                            children: [
                              _ActionRow(
                                icon: Icons.email_outlined,
                                label: "Email",
                                value: u.email,
                                onTap: () =>
                                    _open(Uri.parse('mailto:${u.email}')),
                                trailingIcon: Icons.open_in_new_rounded,
                              ),
                              _ActionRow(
                                icon: Icons.call_outlined,
                                label: lang.t('phone'),
                                value: u.phone,
                                onTap: () => _open(Uri.parse('tel:${u.phone}')),
                                trailingIcon: Icons.phone_forwarded_rounded,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _SectionTitle(lang.t('address')),
                          _InfoRow(
                            icon: Icons.location_city_outlined,
                            label: lang.t('city'),
                            value: u.city,
                          ),
                          _InfoRow(
                            icon: Icons.local_activity_outlined,
                            label: lang.t('state'),
                            value: u.state ?? '—',
                          ),
                          _InfoRow(
                            icon: Icons.map_outlined,
                            label: lang.t('zip'),
                            value: u.zipCode ?? '—',
                          ),
                          const SizedBox(height: 24),
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFF4F8FC),
                                  Color(0xFFE8F1F8),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color:
                                    const Color(0xFF244B6B).withOpacity(0.10),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFF244B6B).withOpacity(0.08),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(18),
                                onTap: () => _openForgotPassword(context),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF244B6B)
                                              .withOpacity(0.10),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                        child: const Icon(
                                          Icons.lock_reset_rounded,
                                          color: Color(0xFF244B6B),
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              lang.t('reset_password'),
                                              style: const TextStyle(
                                                color: Color(0xFF244B6B),
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              lang.t('reset_password_subtitle'),
                                              style: TextStyle(
                                                color: Colors.grey[700],
                                                fontSize: 12.5,
                                                height: 1.3,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.70),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          size: 14,
                                          color: Color(0xFF244B6B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(top: 20),
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                              border: Border.all(
                                color: Colors.grey.shade200,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF244B6B)
                                            .withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.manage_accounts_outlined,
                                        color: Color(0xFF244B6B),
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            lang.t('account_actions'),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF244B6B),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            lang.t('account_actions_subtitle'),
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[600],
                                              height: 1.35,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () => _confirmLogout(context),
                                    icon: const Icon(Icons.logout_rounded),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF244B6B),
                                      side: const BorderSide(
                                          color: Color(0xFF244B6B)),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    label: Text(
                                      lang.t('logout'),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () =>
                                        _confirmDeleteAccount(context),
                                    icon: const Icon(
                                        Icons.delete_forever_rounded),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      side: const BorderSide(color: Colors.red),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    label: Text(
                                      lang.t('delete_my_account'),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),

            // Bouton flottant en haut à droite
            Positioned(
              top: 75,
              right: 16,
              child: FutureBuilder<UserProfile>(
                future: _futureProfile,
                builder: (context, snap) {
                  if (!snap.hasData) return const SizedBox.shrink();

                  return Material(
                    elevation: 6,
                    borderRadius: BorderRadius.circular(30),
                    color: const Color(0xFF244B6B),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: () async {
                        final updated = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditProfilePage(user: snap.data!),
                          ),
                        );
                        if (updated is UserProfile) {
                          _profileUpdated = true;
                          setState(
                            () => _futureProfile = Future.value(updated),
                          );
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.edit,
                                color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              lang.t('edit_profile'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  void _openForgotPassword(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, __, ___) => ForgotPasswordPage(
          isEnglish: lang.currentLang == 'en',
          auth: AuthService(
            baseUrl: 'https://intranet.chic-aparts.com/chicaparts',
          ),
        ),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user');
      final currentUser = User.fromJson(jsonDecode(userJson!));

      final response = await apiUser.deleteAccount(currentUser);

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      await prefs.clear();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const WelcomePage()),
        (route) => false,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(lang.t('account_deleted_success'))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${lang.t('account_deleted_error')}: $e'),
        ),
      );
    }
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(lang.t('delete_account_title')),
        content: Text(lang.t('delete_account_confirmation')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(lang.t('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(lang.t('delete_my_account')),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _deleteAccount(context);
    }
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(lang.t('logout')),
          content: Text(lang.t('confirm_logout')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                lang.t('cancel'),
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              icon: const Icon(Icons.logout),
              label: Text(lang.t('logout')),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      logoutUser(context);
    }
  }

  void logoutUser(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // 🔐 Supprime toute la session
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const WelcomePage()),
      (route) => false,
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
            onPressed: () => Navigator.pop(context, _profileUpdated),
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

class _ProfileHeroCard extends StatelessWidget {
  final String name;
  final String email;
  final String city;
  final String gender;
  final String subtitle;

  const _ProfileHeroCard({
    required this.name,
    required this.email,
    required this.city,
    required this.gender,
    required this.subtitle,
  });

  String _initialsFrom(String fullName) {
    final parts = fullName
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .take(2)
        .toList();
    if (parts.isEmpty) return 'U';
    return parts.map((part) => part[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF244B6B),
            Color(0xFF35698F),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF244B6B).withOpacity(0.22),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.16),
                  ),
                ),
                child: Text(
                  _initialsFrom(name),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      email,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.88),
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.86),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ProfileTag(
                icon: Icons.location_on_outlined,
                label: city,
              ),
              _ProfileTag(
                icon: Icons.wc_outlined,
                label: gender,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileTag extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ProfileTag({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 15),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _InfoSectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF244B6B).withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF244B6B).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF244B6B),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1D3550),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1D3550),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFE),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF244B6B).withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFF244B6B), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1D3550),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: const Color(0xFFF8FBFE),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFF244B6B).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF244B6B),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1D3550),
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailingIcon != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      trailingIcon,
                      size: 17,
                      color: const Color(0xFF244B6B),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

