import 'package:chicaparts_partner/providers/currency_provider.dart';
import 'package:chicaparts_partner/providers/language_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool darkMode = false;
  bool notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final langProvider = context.watch<LanguageProvider>();
    final currencyProvider = context.watch<CurrencyProvider>();
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              /// 🔝 AppBar style comme la page compte/favoris
              Padding(
                padding: const EdgeInsets.only(top: 16.0, bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new,
                              color: Color(0xFF244B6B)),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lang.t('settings'),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF244B6B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              lang.t('settings_text'),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Icon(Icons.settings,
                        size: 28, color: Color(0xFF244B6B)),
                  ],
                ),
              ),

              /// 🌍 Langue
              ListTile(
                leading: const Icon(Icons.language, color: Color(0xFF244B6B)),
                title: Text(lang.t('language')),
                trailing: DropdownButton<String>(
                  value: langProvider.currentLang,
                  items: const [
                    DropdownMenuItem(value: "fr", child: Text("Français")),
                    DropdownMenuItem(value: "en", child: Text("English")),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      langProvider.loadLanguage(value);

                      /// ✅ Option : Changer devise automatiquement selon langue
                      // final newCurrency = value == "fr" ? "€" : "\$";
                      // currencyProvider.setCurrency(newCurrency);
                    }
                  },
                ),
              ),

              const Divider(),

              /// 💱 Devise
              ListTile(
                leading:
                    const Icon(Icons.attach_money, color: Color(0xFF244B6B)),
                title: Text(lang.t('currency')),
                trailing: DropdownButton<String>(
                  value: currencyProvider.currency,
                  items: ["EUR", "USD", "XAF", "GBP", "CAD"]
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      currencyProvider.setCurrency(value);
                    }
                  },
                ),
              ),

              const Divider(),

              /// 🌙 Mode sombre
              SwitchListTile(
                activeThumbColor: const Color(0xFF244B6B),
                title: Text(
                  lang.t('mode'),
                  style: TextStyle(
                    color: darkMode ? Colors.black : Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                secondary: Icon(
                  Icons.dark_mode,
                  color: darkMode ? const Color(0xFF244B6B) : Colors.grey,
                ),
                value: darkMode,
                onChanged: (val) {
                  setState(() => darkMode = val);
                  // TODO: Activer/désactiver un vrai ThemeProvider
                },
                subtitle: Text(
                  darkMode ? lang.t('black_mode') : lang.t('light_mode'),
                  style: TextStyle(
                    color: darkMode ? Colors.grey[700] : Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ),

              /// 🔔 Notifications
              SwitchListTile(
                activeThumbColor: const Color(0xFF244B6B),
                title: Text(
                  lang.t('notifications'),
                  style: TextStyle(
                    color:
                        notificationsEnabled ? Colors.black : Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                secondary: Icon(
                  Icons.notifications,
                  color: notificationsEnabled
                      ? const Color(0xFF244B6B)
                      : Colors.grey,
                ),
                value: notificationsEnabled,
                onChanged: (val) {
                  setState(() => notificationsEnabled = val);
                  // TODO: Persister localement
                },
                subtitle: Text(
                  notificationsEnabled
                      ? lang.t('notif_on')
                      : lang.t('notif_off'),
                  style: TextStyle(
                    color: notificationsEnabled
                        ? Colors.grey[700]
                        : Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
