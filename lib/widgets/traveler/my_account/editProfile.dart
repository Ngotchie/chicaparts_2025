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
        Navigator.pop(context, true);
      } else {
        final msg = jsonDecode(response.body)['error'] ?? 'Unknow error';
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

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    return Scaffold(
      appBar: AppBar(title: Text("✏️ ${lang.t('edit_profile')}")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField(lang.t('first_name'), firstNameController),
              _buildTextField(lang.t('last_name'), lastNameController),
              _buildGenderField(),
              _buildTextField(lang.t('city'), cityController),
              _buildTextField(lang.t('phone'), phoneController),
              _buildTextField(lang.t('zip'), zipCodeController),
              _buildTextField(lang.t('state'), stateController),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF244B6B),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _isSaving ? null : _submitChanges,
                child: _isSaving
                    ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                    : Text(
                        "💾 ${lang.t('save')}",
                        style: const TextStyle(color: Colors.white),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade300)),
        ),
        validator: (value) =>
            value == null || value.isEmpty ? lang.t('required') : null,
      ),
    );
  }

  Widget _buildGenderField() {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        value: selectedGender,
        decoration: InputDecoration(
          labelText: lang.t('gender'),
          border: const OutlineInputBorder(),
        ),
        items: [
          DropdownMenuItem(value: '', child: Text(lang.t('select_gender'))),
          DropdownMenuItem(value: "m", child: Text(lang.t('male'))),
          DropdownMenuItem(value: "f", child: Text(lang.t('fmale'))),
        ],
        onChanged: (value) => setState(() => selectedGender = value),
        validator: (value) =>
            value == null || value.isEmpty ? lang.t('required') : null,
      ),
    );
  }
}
