import 'dart:convert';

import 'package:chicaparts_partner/models/traveler/modele_booking_traveler.dart';
import 'package:chicaparts_partner/models/user/user.dart';
import 'package:chicaparts_partner/providers/language_provider.dart';
import 'package:chicaparts_partner/services/api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditProfilePage extends StatefulWidget {
  final UserProfile user;

  const EditProfilePage({super.key, required this.user});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController cityController;
  late TextEditingController phoneController;
  late TextEditingController zipCodeController;
  late TextEditingController stateController;

  String? selectedGender;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    firstNameController = TextEditingController(text: widget.user.firstName);
    lastNameController = TextEditingController(text: widget.user.lastName);
    cityController = TextEditingController(text: widget.user.city);
    phoneController = TextEditingController(text: widget.user.phone);
    zipCodeController = TextEditingController(text: widget.user.zipCode ?? '');
    stateController = TextEditingController(text: widget.user.state ?? '');
    selectedGender = widget.user.gender;
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    cityController.dispose();
    phoneController.dispose();
    zipCodeController.dispose();
    stateController.dispose();
    super.dispose();
  }

  Future<void> _submitChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      ApiUrl url = ApiUrl();
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user');
      final currentUser = User.fromJson(jsonDecode(userJson!));

      final response = await http.post(
        Uri.parse('${url.getChicapartsUrl()}auth/me?user_id=${currentUser.id}'),
        headers: {
          'Accept': 'application/json',
          'X-Authorization': url.getKey(),
        },
        body: {
          'first_name': firstNameController.text,
          'last_name': lastNameController.text,
          'gender': selectedGender,
          'city': cityController.text,
          'mobile_phone_number': phoneController.text,
          'postcode': zipCodeController.text,
          'state': stateController.text,
          'status': widget.user.status == 'pendig' ? 'inactive' : 'active',
          'country_id': widget.user.countryId.toString(),
          'entity_type': widget.user.entityType
        },
      );

      if (response.statusCode == 200) {
        final user = User(currentUser.id, firstNameController.text,
            currentUser.email, "traveler");
        await prefs.setString('user', jsonEncode(user.toJson()));
        Navigator.pop(context, true);
      } else {
        _showError(context, "Unknow error");
      }
    } catch (e) {
      _showError(context, "Network error");
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

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("✏️ ${lang.t('edit_profile')}"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF244B6B),
      ),

      // ✅ bouton enregistré collé en bas, comme sur la page profil
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white)),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(
                _isSaving ? lang.t('saving') : "💾 ${lang.t('save')}",
                style: const TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF244B6B),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isSaving ? null : _submitChanges,
            ),
          ),
        ),
      ),

      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          children: [
            // === Header compact (aligné avec la page Profil)
            // Card(
            //   elevation: 0,
            //   color: Colors.white,
            //   shape: RoundedRectangleBorder(
            //       borderRadius: BorderRadius.circular(14)),
            //   child: Padding(
            //     padding: const EdgeInsets.all(16),
            //     child: Row(
            //       children: [
            //         const CircleAvatar(
            //           radius: 28,
            //           backgroundColor: Color(0xFF244B6B),
            //           child: Icon(Icons.person, color: Colors.white, size: 28),
            //         ),
            //         const SizedBox(width: 12),
            //         Expanded(
            //           child: Column(
            //             crossAxisAlignment: CrossAxisAlignment.start,
            //             children: [
            //               Text(
            //                 "${widget.user.firstName} ${widget.user.lastName}"
            //                         .trim()
            //                         .isEmpty
            //                     ? lang.t('user')
            //                     : "${widget.user.firstName} ${widget.user.lastName}",
            //                 style: const TextStyle(
            //                     fontSize: 18, fontWeight: FontWeight.w700),
            //                 maxLines: 1,
            //                 overflow: TextOverflow.ellipsis,
            //               ),
            //               const SizedBox(height: 2),
            //               Text(
            //                 widget.user.email,
            //                 style: TextStyle(
            //                     fontSize: 13, color: Colors.grey[600]),
            //                 maxLines: 1,
            //                 overflow: TextOverflow.ellipsis,
            //               ),
            //             ],
            //           ),
            //         ),
            //         TextButton.icon(
            //           onPressed: () {}, // (optionnel) changer la photo
            //           icon: const Icon(Icons.edit, size: 18),
            //           label: Text(lang.t('edit')),
            //         )
            //       ],
            //     ),
            //   ),
            // ),

            // const SizedBox(height: 12),

            // === Section : Informations personnelles
            _SectionCard(
              title: lang.t('personal_infos'),
              children: [
                _buildTextField(
                  lang.t('first_name'),
                  firstNameController,
                  prefix: Icons.badge,
                ),
                _buildTextField(
                  lang.t('last_name'),
                  lastNameController,
                  isRequired: false,
                  prefix: Icons.badge_outlined,
                ),
                _buildGenderFieldStyled(),
              ],
            ),

            // === Section : Coordonnées
            _SectionCard(
              title: lang.t('contact'),
              children: [
                _buildTextField(
                  lang.t('phone'),
                  phoneController,
                  keyboard: TextInputType.phone,
                  prefix: Icons.phone_outlined,
                ),
                // email affiché en lecture seule pour cohérence avec la page profil
                _DisplayTile(
                  icon: Icons.email_outlined,
                  label: "Email",
                  value: widget.user.email,
                ),
              ],
            ),

            // === Section : Adresse
            _SectionCard(
              title: lang.t('address'),
              children: [
                _buildTextField(
                  lang.t('city'),
                  cityController,
                  isRequired: false,
                  prefix: Icons.location_city_outlined,
                ),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        lang.t('zip'),
                        zipCodeController,
                        isRequired: false,
                        keyboard: TextInputType.number,
                        prefix: Icons.local_post_office_outlined,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildTextField(
                        lang.t('state'),
                        stateController,
                        isRequired: false,
                        prefix: Icons.map_outlined,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

// ======= Genre avec style cohérent
  Widget _buildGenderFieldStyled() {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300),
    );

    return DropdownButtonFormField<String>(
      value: (selectedGender ?? '').isEmpty ? null : selectedGender,
      decoration: InputDecoration(
        labelText: lang.t('gender'),
        prefixIcon: const Icon(Icons.transgender),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: Color(0xFF244B6B), width: 1.2),
        ),
      ),
      items: [
        DropdownMenuItem(value: 'm', child: Text(lang.t('male'))),
        DropdownMenuItem(value: 'f', child: Text(lang.t('female'))),
      ],
      onChanged: (v) => setState(() => selectedGender = v),
    );
  }
}

/// ====== Helpers UI (légers) ======

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF244B6B))),
            const SizedBox(height: 8),
            ..._withDividers(children),
          ],
        ),
      ),
    );
  }

  List<Widget> _withDividers(List<Widget> items) {
    final out = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      out.add(items[i]);
      if (i != items.length - 1) {
        out.add(const SizedBox(height: 10));
      }
    }
    return out;
  }
}

/// Affichage lecture seule (email)
class _DisplayTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DisplayTile(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
      ),
    );
  }
}

// ======= Remplace ta version par celle-ci pour garder ton nullable + icônes
Widget _buildTextField(
  String label,
  TextEditingController controller, {
  bool isRequired = true,
  TextInputType keyboard = TextInputType.text,
  IconData? prefix,
}) {
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: Colors.grey.shade300),
  );

  return TextFormField(
    controller: controller,
    keyboardType: keyboard,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: prefix != null ? Icon(prefix) : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: Color(0xFF244B6B), width: 1.2),
      ),
    ),
    validator: (value) {
      if (!isRequired) return null;
      if (value == null || value.trim().isEmpty) return 'Champ requis';
      return null;
    },
  );
}
