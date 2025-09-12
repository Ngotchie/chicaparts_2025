import 'package:chicaparts_partner/providers/language_provider.dart';
import 'package:chicaparts_partner/widgets/traveler/book/PhoneAndCountryPicker.dart';
import 'package:chicaparts_partner/widgets/traveler/book/paymentPage.dart';
import 'package:chicaparts_partner/widgets/traveler/book/selectBookingDetails.dart';
import 'package:chicaparts_partner/widgets/traveler/book/viewBookingDetails.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:country_picker/country_picker.dart';

class BillingInfoPage extends StatefulWidget {
  final BookingDetails bookingDetails;

  const BillingInfoPage({super.key, required this.bookingDetails});

  @override
  _BillingInfoPageState createState() => _BillingInfoPageState();
}

class _BillingInfoPageState extends State<BillingInfoPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();

  String? _selectedCivility;
  Country? _selectedCountry;
  PhoneNumber? _phoneNumber;
  // Liste statique des pays
  final List<Country> _countries = CountryService().getAll();

  String _fullPhoneNumber = '';

  List<String> civilities = ["Mr", "Mrs", "Miss"];

  @override
  void initState() {
    super.initState();
    _phoneNumber = PhoneNumber(isoCode: 'FR');
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _firstNameController.text = prefs.getString('billing_first_name') ?? '';
      _lastNameController.text = prefs.getString('billing_last_name') ?? '';
      _emailController.text = prefs.getString('billing_email') ?? '';
      _addressController.text = prefs.getString('billing_address') ?? '';
      _cityController.text = prefs.getString('billing_city') ?? '';
      String? savedCivility = prefs.getString("billing_civility");
      if (civilities.contains(savedCivility)) {
        _selectedCivility = savedCivility;
      } else {
        _selectedCivility = null;
      }
      String? countryIso = prefs.getString('billing_country_iso');
      String? phone = prefs.getString('billing_phone');

      // 📱 Charger numéro de téléphone
      if (phone != null) {
        _phoneController.text = phone;
        _fullPhoneNumber = phone;
      }

      // 🌍 Charger pays
      if (countryIso != null && countryIso.isNotEmpty) {
        final allCountries = CountryService().getAll();
        try {
          _selectedCountry = allCountries.firstWhere(
            (c) => c.countryCode == countryIso,
          );
        } catch (e) {
          _selectedCountry = null; // ❌ Si pas trouvé, on met null
        }
      }
    });
  }

  Widget _buildDropdownField(String label, List<String> items, String? value,
      Function(String?) onChanged, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: DropdownButtonFormField(
        decoration: _inputDecoration(label, icon),
        value: value,
        items: items
            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
            .toList(),
        onChanged: onChanged,
        validator: (value) => value == null ? "Required field" : null,
      ),
    );
  }

  Widget _buildTextField(
      String label, TextEditingController controller, IconData icon,
      {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: TextFormField(
        controller: controller,
        decoration: _inputDecoration(label, icon),
        validator: (value) {
          if (required && (value == null || value.trim().isEmpty)) {
            return "Required field";
          }
          return null;
        },
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.blueAccent, width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      prefixIcon: Icon(icon, color: Colors.blueAccent),
      filled: true,
      fillColor: Colors.grey[100],
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
    );
  }

  Future<void> _saveBillingInfo() async {
    if (_formKey.currentState!.validate()) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('billing_civility', _selectedCivility ?? '');
      await prefs.setString('billing_first_name', _firstNameController.text);
      await prefs.setString('billing_last_name', _lastNameController.text);
      await prefs.setString('billing_email', _emailController.text);
      await prefs.setString('billing_phone', _fullPhoneNumber);
      await prefs.setString('billing_address', _addressController.text);
      await prefs.setString('billing_country', _selectedCountry?.name ?? '');
      await prefs.setString('billing_city', _cityController.text);
      await prefs.setString('billing_phone', _fullPhoneNumber);
      await prefs.setString(
          'billing_country_iso', _selectedCountry?.countryCode ?? '');

      BillingInfo billingInfo = BillingInfo(
        civility: _selectedCivility ?? '',
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        email: _emailController.text,
        phone: _fullPhoneNumber,
        address: _addressController.text,
        country: _selectedCountry?.name ?? '',
        city: _cityController.text,
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentPage(
              bookingDetails: widget.bookingDetails, billingInfo: billingInfo),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: Text("🏠 ${lang.t('billing_infos')}",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Sélection de la civilité
                _buildDropdownField(
                    lang.t('civility'), civilities, _selectedCivility, (value) {
                  setState(() => _selectedCivility = value);
                }, Icons.person_outline),

                _buildTextField(lang.t('first_name'), _firstNameController,
                    Icons.person_outline,
                    required: true),
                _buildTextField(lang.t('last_name'), _lastNameController,
                    Icons.person_outline,
                    required: true),
                _buildTextField("Email", _emailController, Icons.email_outlined,
                    required: true),

                // Sélection du numéro de téléphone
                // Padding(
                //   padding: const EdgeInsets.symmetric(vertical: 6.0),
                //   child: InternationalPhoneNumberInput(
                //     onInputChanged: (PhoneNumber number) {
                //       setState(() {
                //         _phoneNumber = number;
                //         _fullPhoneNumber =
                //             '${number.dialCode}${_phoneController.text}';
                //         // ✅ Ajoute l'indicatif + le numéro saisi
                //       });
                //     },
                //     selectorConfig: const SelectorConfig(
                //       selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
                //     ),
                //     textFieldController: _phoneController,
                //     inputDecoration:
                //         _inputDecoration("Phone", Icons.phone_outlined),
                //     initialValue: _phoneNumber,
                //     formatInput: false,
                //     keyboardType: TextInputType.phone,
                //     validator: (value) {
                //       if (_phoneController.text.isEmpty) {
                //         return "Required field";
                //       }
                //       return null;
                //     },
                //   ),
                // ),
                const SizedBox(height: 8),

                PhoneAndCountryPicker(
                  initialPhoneNumber: _phoneNumber,
                  controller: _phoneController,
                  onPhoneChanged: (number) {
                    setState(() {
                      _phoneNumber = number;
                      _fullPhoneNumber =
                          '${number.dialCode}${_phoneController.text}';
                    });
                  },
                  onCountrySelected: (country) {
                    setState(() {
                      _selectedCountry = country;
                    });
                  },
                ),

                const SizedBox(height: 8),

                _buildTextField(lang.t('billing_address'), _addressController,
                    Icons.location_on_outlined,
                    required: true),

                // // Sélection du pays avec drapeau
                // Padding(
                //   padding: const EdgeInsets.symmetric(vertical: 6.0),
                //   child: InkWell(
                //     onTap: () {
                //       showCountryPicker(
                //         context: context,
                //         showPhoneCode: false,
                //         onSelect: (Country country) {
                //           setState(() => _selectedCountry = country);
                //         },
                //       );
                //     },
                //     child: Container(
                //       padding: const EdgeInsets.symmetric(
                //           vertical: 16, horizontal: 12),
                //       decoration: BoxDecoration(
                //         border: Border.all(color: Colors.grey.shade300),
                //         borderRadius: BorderRadius.circular(10),
                //         color: Colors.grey[100],
                //       ),
                //       child: Row(
                //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //         children: [
                //           if (_selectedCountry != null)
                //             Row(
                //               children: [
                //                 Text(_selectedCountry!.flagEmoji,
                //                     style: const TextStyle(fontSize: 20)),
                //                 const SizedBox(width: 10),
                //                 Text(_selectedCountry!.name,
                //                     style: const TextStyle(fontSize: 16)),
                //               ],
                //             )
                //           else
                //             const Text("Select Country",
                //                 style: TextStyle(
                //                     fontSize: 16, color: Colors.grey)),
                //           const Icon(Icons.arrow_drop_down,
                //               color: Colors.blueAccent),
                //         ],
                //       ),
                //     ),
                //   ),
                // ),

                _buildTextField(lang.t('city'), _cityController,
                    Icons.location_city_outlined),

                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: _saveBillingInfo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF244B6B),
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 30),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(lang.t('proceed_pay'),
                      style:
                          const TextStyle(color: Colors.white, fontSize: 18)),
                ),
              ],
            ),
          ),
        ),
      ),
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
        "guestTitle": civility,
        "guestFirstName": firstName,
        "guestName": lastName,
        "guestEmail": email,
        "guestPhone": phone,
        "guestAddress": address,
        "guestCity": city,
        "guestState": "",
        "guestPostcode": "",
        "guestCountry": country,
      };
}
