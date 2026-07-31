import 'dart:convert';

import 'package:chicaparts_partner/api/traveler/api_user_traveler.dart';
import 'package:chicaparts_partner/models/user/user.dart';
import 'package:chicaparts_partner/providers/language_provider.dart';
import 'package:chicaparts_partner/services/api.dart';
import 'package:chicaparts_partner/widgets/traveler/book/PhoneAndCountryPicker.dart';
import 'package:chicaparts_partner/widgets/traveler/book/book_app_bar.dart';
import 'package:chicaparts_partner/widgets/traveler/book/booking_step_indicator.dart';
import 'package:chicaparts_partner/widgets/traveler/book/paymentPage.dart';
import 'package:chicaparts_partner/widgets/traveler/book/selectBookingDetails.dart';
import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BillingInfoPage extends StatefulWidget {
  final BookingDetails bookingDetails;

  const BillingInfoPage({super.key, required this.bookingDetails});

  @override
  _BillingInfoPageState createState() => _BillingInfoPageState();
}

class _BillingInfoPageState extends State<BillingInfoPage> {
  static const _guestInitialPassword = '000000';

  final _formKey = GlobalKey<FormState>();
  final ApiUserTraveler _apiUser = ApiUserTraveler();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  bool _creatingGuestAccount = false;

  String? _selectedCivility;
  Country? _selectedCountry;
  PhoneNumber? _phoneNumber;
  String _fullPhoneNumber = '';

  final List<String> civilities = ['Mr', 'Mrs', 'Miss'];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _firstNameController.text = prefs.getString('billing_first_name') ?? '';
      _lastNameController.text = prefs.getString('billing_last_name') ?? '';
      _emailController.text = prefs.getString('billing_email') ?? '';
      _addressController.text = prefs.getString('billing_address') ?? '';
      _cityController.text = prefs.getString('billing_city') ?? '';

      final savedCivility = prefs.getString('billing_civility');
      _selectedCivility =
          civilities.contains(savedCivility) ? savedCivility : null;

      final countryIso = prefs.getString('billing_country_iso');
      final phone = prefs.getString('billing_phone');

      if (countryIso != null && countryIso.isNotEmpty) {
        final allCountries = CountryService().getAll();
        try {
          _selectedCountry = allCountries.firstWhere(
            (country) => country.countryCode == countryIso,
          );
        } catch (e) {
          _selectedCountry = null;
        }
      }

      if (phone != null && phone.trim().isNotEmpty) {
        _fullPhoneNumber = _normalizeStoredPhone(phone, _selectedCountry);
        _phoneController.text =
            _nationalPhoneNumber(_fullPhoneNumber, _selectedCountry);
        _phoneNumber = PhoneNumber(
          isoCode: _selectedCountry?.countryCode ?? '',
          dialCode:
              _selectedCountry == null ? '' : '+${_selectedCountry!.phoneCode}',
          phoneNumber: _fullPhoneNumber,
        );
      }
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: buildBookAppBar(lang.t('billing_infos')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 112),
            children: [
              const BookingStepIndicator(currentStep: 2),
              const SizedBox(height: 14),
              _sectionCard(
                title: lang.t('personal_infos'),
                icon: Icons.badge_outlined,
                children: [
                  _buildDropdownField(
                    lang.t('civility'),
                    civilities,
                    _selectedCivility,
                    (value) => setState(() => _selectedCivility = value),
                    Icons.person_outline,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    lang.t('first_name'),
                    _firstNameController,
                    Icons.person_outline,
                    validator: (value) => _validateName(
                      value,
                      _lastNameController.text,
                      lang,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    lang.t('last_name'),
                    _lastNameController,
                    Icons.person_outline,
                    validator: (value) => _validateName(
                      value,
                      _firstNameController.text,
                      lang,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _sectionCard(
                title: lang.t('contact'),
                icon: Icons.contact_mail_outlined,
                children: [
                  _buildTextField(
                    lang.t('email'),
                    _emailController,
                    Icons.email_outlined,
                    required: true,
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 12),
                  PhoneAndCountryPicker(
                    initialPhoneNumber: _phoneNumber,
                    controller: _phoneController,
                    onPhoneChanged: (number) {
                      setState(() {
                        _phoneNumber = number;
                        _fullPhoneNumber = number.phoneNumber?.trim() ?? '';
                      });
                    },
                    onCountrySelected: (country) {
                      setState(() => _selectedCountry = country);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _sectionCard(
                title: lang.t('address'),
                icon: Icons.location_on_outlined,
                children: [
                  _buildTextField(
                    lang.t('billing_address'),
                    _addressController,
                    Icons.location_on_outlined,
                    required: true,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    lang.t('city'),
                    _cityController,
                    Icons.location_city_outlined,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(lang),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: colors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDropdownField(
    String label,
    List<String> items,
    String? value,
    Function(String?) onChanged,
    IconData icon,
  ) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    return DropdownButtonFormField<String>(
      decoration: _inputDecoration(label, icon),
      initialValue: value,
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
      validator: (value) => value == null ? lang.t('required') : null,
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool required = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: _inputDecoration(label, icon),
      validator: (value) {
        if (required && (value == null || value.trim().isEmpty)) {
          return lang.t('required');
        }
        return validator?.call(value);
      },
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    final colors = Theme.of(context).colorScheme;

    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: colors.primary, size: 20),
      filled: true,
      fillColor: colors.surfaceContainerHighest.withOpacity(0.55),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colors.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colors.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colors.primary, width: 1.4),
      ),
    );
  }

  Widget _buildBottomBar(LanguageProvider lang) {
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        decoration: BoxDecoration(
          color: colors.surfaceContainer,
          border: Border(top: BorderSide(color: colors.outlineVariant)),
        ),
        child: SizedBox(
          height: 48,
          width: double.infinity,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: _creatingGuestAccount ? null : _saveBillingInfo,
            icon: _creatingGuestAccount
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.arrow_forward, size: 18),
            label: Text(
              _creatingGuestAccount
                  ? lang.t('creating_account')
                  : lang.t('proceed_pay'),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return null;
    final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    return valid ? null : 'Email invalide';
  }

  String? _validateName(
    String? value,
    String otherName,
    LanguageProvider lang,
  ) {
    if ((value ?? '').trim().isEmpty && otherName.trim().isEmpty) {
      return lang.t('first_or_last_name_required');
    }
    return null;
  }

  Future<void> _saveBillingInfo() async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    if (!_formKey.currentState!.validate()) return;

    if (_selectedCountry == null || _fullPhoneNumber.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(lang.t('phone_country_code_required'))),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('billing_civility', _selectedCivility ?? '');
    await prefs.setString('billing_first_name', _firstNameController.text);
    await prefs.setString('billing_last_name', _lastNameController.text);
    await prefs.setString('billing_email', _emailController.text);
    await prefs.setString('billing_phone', _fullPhoneNumber);
    await prefs.setString('billing_address', _addressController.text);
    await prefs.setString('billing_country', _selectedCountry?.name ?? '');
    await prefs.setString('billing_city', _cityController.text);
    await prefs.setString(
      'billing_country_iso',
      _selectedCountry?.countryCode ?? '',
    );

    final billingInfo = BillingInfo(
      civility: _selectedCivility ?? '',
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      email: _emailController.text,
      phone: _fullPhoneNumber,
      address: _addressController.text,
      country: _selectedCountry?.name ?? '',
      city: _cityController.text,
    );

    final hasSession = (prefs.getString('user') ?? '').isNotEmpty;
    if (!hasSession) {
      setState(() => _creatingGuestAccount = true);
      try {
        await _createAndLoginGuestAccount(billingInfo, prefs, lang);
        if (!mounted) return;
        await _showGuestAccountCreatedDialog(billingInfo.email, lang);
      } catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_guestAccountErrorMessage(error, lang)),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      } finally {
        if (mounted) setState(() => _creatingGuestAccount = false);
      }
    }

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentPage(
          bookingDetails: widget.bookingDetails,
          billingInfo: billingInfo,
        ),
      ),
    );
  }

  String _normalizeStoredPhone(String phone, Country? country) {
    final compact = phone.trim().replaceAll(RegExp(r'[\s().-]'), '');
    if (country == null) return compact;

    final dialCode = '+${country.phoneCode}';
    if (compact.startsWith(dialCode)) return compact;
    if (compact.startsWith('00${country.phoneCode}')) {
      return '+${compact.substring(2)}';
    }
    return '$dialCode$compact';
  }

  String _nationalPhoneNumber(String fullPhone, Country? country) {
    if (country == null) return fullPhone;
    final dialCode = '+${country.phoneCode}';
    return fullPhone.startsWith(dialCode)
        ? fullPhone.substring(dialCode.length)
        : fullPhone;
  }

  Future<void> _createAndLoginGuestAccount(
    BillingInfo billing,
    SharedPreferences prefs,
    LanguageProvider lang,
  ) async {
    final response = await _apiUser.UserRegister({
      'first_name': billing.firstName.trim().isNotEmpty
          ? billing.firstName.trim()
          : billing.lastName.trim(),
      'last_name': billing.lastName.trim(),
      'email': billing.email.trim().toLowerCase(),
      'mobile_phone_number': billing.phone.trim(),
      'password': _guestInitialPassword,
      'local': lang.currentLang,
    });

    if (response == null) {
      throw Exception('NETWORK_ERROR');
    }

    if (response.statusCode != 200 && response.statusCode != 201) {
      if (response.statusCode != 409 && response.statusCode != 422) {
        throw Exception('REGISTER_ERROR');
      }
      // L'adresse peut appartenir à un compte invité créé précédemment.
      // La tentative de connexion ci-dessous permettra de le récupérer.
    }

    final loginResponse = await _loginGuestAccount(billing.email);
    if (loginResponse.statusCode != 200) {
      if (response.statusCode == 409 || response.statusCode == 422) {
        throw Exception('ACCOUNT_ALREADY_EXISTS');
      }
      throw Exception('LOGIN_ERROR');
    }

    final body = jsonDecode(loginResponse.body);
    if (body is! Map) throw Exception('LOGIN_ERROR');

    final rawUser = body['user'] ??
        (body['data'] is Map ? (body['data'] as Map)['user'] : null);
    if (rawUser is! Map) throw Exception('LOGIN_ERROR');

    final id = int.tryParse('${rawUser['id']}') ?? 0;
    final name = (rawUser['first_name'] ??
            rawUser['name'] ??
            (billing.firstName.trim().isNotEmpty
                ? billing.firstName
                : billing.lastName))
        .toString();
    final email =
        (rawUser['email'] ?? billing.email).toString().trim().toLowerCase();
    if (id <= 0 || email.isEmpty) throw Exception('LOGIN_ERROR');

    final user = User(id, name, email, 'traveler');
    await prefs.setString('user', jsonEncode(user.toJson()));
    await prefs.setString('email', email);
    await prefs.setString('user_raw_traveler', loginResponse.body);
    await prefs.setString('app_lang', lang.currentLang);

    final token = body['token'] ??
        body['access_token'] ??
        (body['data'] is Map
            ? ((body['data'] as Map)['token'] ??
                (body['data'] as Map)['access_token'])
            : null);
    if (token != null && token.toString().isNotEmpty) {
      await prefs.setString('auth_token', token.toString());
    }
  }

  Future<http.Response> _loginGuestAccount(String email) {
    final api = ApiUrl();
    return http.post(
      Uri.parse('${api.getChicapartsUrl()}auth/login'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'X-Authorization': api.getKey(),
      },
      body: jsonEncode({
        'login': email.trim().toLowerCase(),
        'password': _guestInitialPassword,
      }),
    );
  }

  String _guestAccountErrorMessage(Object error, LanguageProvider lang) {
    final value = error.toString();
    if (value.contains('ACCOUNT_ALREADY_EXISTS')) {
      return lang.t('guest_account_exists');
    }
    if (value.contains('NETWORK_ERROR')) {
      return lang.t('error_network');
    }
    return lang.t('guest_account_creation_error');
  }

  Future<void> _showGuestAccountCreatedDialog(
    String email,
    LanguageProvider lang,
  ) {
    final colors = Theme.of(context).colorScheme;
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: colors.surfaceContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          title: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_add_alt_1_rounded,
                  color: colors.onPrimaryContainer,
                  size: 32,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                lang.t('guest_account_created'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                lang.t('guest_account_created_text'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: Column(
                  children: [
                    _AccountCredentialRow(
                      icon: Icons.alternate_email,
                      label: lang.t('email'),
                      value: email.trim().toLowerCase(),
                    ),
                    const SizedBox(height: 10),
                    _AccountCredentialRow(
                      icon: Icons.lock_outline,
                      label: lang.t('temporary_password'),
                      value: _guestInitialPassword,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 19,
                    color: colors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      lang.t('guest_change_password_hint'),
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.pop(dialogContext),
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text(lang.t('continue')),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AccountCredentialRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _AccountCredentialRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 19, color: colors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              SelectableText(
                value,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class BillingInfo {
  final String civility;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String address;
  final String country;
  final String city;

  BillingInfo({
    required this.civility,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.address,
    required this.country,
    required this.city,
  });

  Map<String, dynamic> toJson() => {
        'guestTitle': civility,
        'guestFirstName': firstName,
        'guestName': lastName,
        'guestEmail': email,
        'guestPhone': phone,
        'guestAddress': address,
        'guestCountry': country,
        'guestCity': city,
      };
}
