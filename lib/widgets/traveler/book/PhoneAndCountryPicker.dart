import 'package:flutter/material.dart';
import 'package:country_picker/country_picker.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:chicaparts_partner/providers/language_provider.dart';
import 'package:provider/provider.dart';

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
    _selectedCountry = _countryFromIso(widget.initialPhoneNumber?.isoCode);
  }

  @override
  void didUpdateWidget(covariant PhoneAndCountryPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialPhoneNumber?.isoCode !=
        oldWidget.initialPhoneNumber?.isoCode) {
      _selectedCountry = _countryFromIso(widget.initialPhoneNumber?.isoCode);
    }
  }

  Country? _countryFromIso(String? isoCode) {
    if (isoCode == null || isoCode.isEmpty) return null;
    try {
      return CountryService().getAll().firstWhere(
            (country) => country.countryCode == isoCode,
          );
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final colors = Theme.of(context).colorScheme;

    return TextFormField(
      controller: widget.controller,
      keyboardType: TextInputType.phone,
      style: TextStyle(color: colors.onSurface),
      decoration: InputDecoration(
        labelText: lang.t('phone'),
        filled: true,
        fillColor: colors.surfaceContainerHighest.withOpacity(0.55),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        prefixIconConstraints: const BoxConstraints(minWidth: 58, minHeight: 48),
        prefixIcon: InkWell(
          borderRadius: const BorderRadius.horizontal(
            left: Radius.circular(8),
          ),
          onTap: () {
            showCountryPicker(
              context: context,
              showPhoneCode: true,
              onSelect: (country) {
                setState(() => _selectedCountry = country);
                widget.onCountrySelected(country);
                _notifyPhoneChanged(widget.controller.text);
              },
            );
          },
          child: Padding(
            padding: const EdgeInsets.only(left: 12, right: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_selectedCountry == null)
                  Icon(Icons.public, size: 20, color: colors.primary)
                else ...[
                  Text(
                    _selectedCountry!.flagEmoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '+${_selectedCountry!.phoneCode}',
                    style: TextStyle(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                Icon(Icons.arrow_drop_down, color: colors.primary),
                const SizedBox(width: 4),
                Container(
                  width: 1,
                  height: 24,
                  color: colors.outlineVariant,
                ),
              ],
            ),
          ),
        ),
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
      ),
      onChanged: (value) {
        _notifyPhoneChanged(value);
      },
      validator: (value) {
        if (_selectedCountry == null) {
          return lang.t('phone_country_code_required');
        }
        if (value == null || value.trim().isEmpty) {
          return lang.t('required');
        }
        return null;
      },
    );
  }

  void _notifyPhoneChanged(String rawNumber) {
    final country = _selectedCountry;
    final dialCode = country == null ? '' : '+${country.phoneCode}';
    var localNumber = rawNumber.replaceAll(RegExp(r'[\s().-]'), '');

    if (dialCode.isNotEmpty && localNumber.startsWith(dialCode)) {
      localNumber = localNumber.substring(dialCode.length);
    } else if (country != null &&
        localNumber.startsWith('00${country.phoneCode}')) {
      localNumber = localNumber.substring(country.phoneCode.length + 2);
    }

    final fullNumber = dialCode.isEmpty ? localNumber : '$dialCode$localNumber';
    _phoneNumber = PhoneNumber(
      isoCode: country?.countryCode ?? '',
      phoneNumber: fullNumber,
      dialCode: dialCode,
    );
    widget.onPhoneChanged(_phoneNumber!);
  }
}
