import 'package:flutter/material.dart';
import 'package:country_picker/country_picker.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';

class PhoneAndCountryPicker extends StatefulWidget {
  final PhoneNumber? initialPhoneNumber;
  final TextEditingController controller;
  final ValueChanged<PhoneNumber> onPhoneChanged;
  final ValueChanged<Country> onCountrySelected;

  const PhoneAndCountryPicker({
    super.key,
    this.initialPhoneNumber,
    required this.controller,
    required this.onPhoneChanged,
    required this.onCountrySelected,
  });

  @override
  _PhoneAndCountryPickerState createState() => _PhoneAndCountryPickerState();
}

class _PhoneAndCountryPickerState extends State<PhoneAndCountryPicker> {
  Country? _selectedCountry;
  PhoneNumber? _phoneNumber;

  @override
  void initState() {
    super.initState();
    _phoneNumber = widget.initialPhoneNumber;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border.all(color: Colors.grey.shade300, width: 1.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          // 📍 Bouton pays (drapeau + code)
          InkWell(
            onTap: () {
              showCountryPicker(
                context: context,
                showPhoneCode: true,
                onSelect: (country) {
                  setState(() {
                    _selectedCountry = country;
                  });
                  widget.onCountrySelected(country);
                },
              );
            },
            child: Row(
              children: [
                if (_selectedCountry != null)
                  Row(
                    children: [
                      Text(
                        _selectedCountry!.flagEmoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "+${_selectedCountry!.phoneCode}",
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  )
                else
                  const Text(
                    "🌍 +..",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                const Icon(Icons.arrow_drop_down, color: Colors.blueAccent),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // 📞 Champ numéro de téléphone
          Expanded(
            child: TextFormField(
              controller: widget.controller,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: "Phone Number",
                border: InputBorder.none,
              ),
              onChanged: (value) {
                final fullPhone = '+${_selectedCountry?.phoneCode ?? ''}$value';
                final phone = PhoneNumber(
                    isoCode: _selectedCountry?.countryCode ?? '',
                    phoneNumber: value,
                    dialCode: '+${_selectedCountry?.phoneCode ?? ''}');
                widget.onPhoneChanged(phone);
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Required field";
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }
}
