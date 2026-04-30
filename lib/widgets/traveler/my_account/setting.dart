import 'package:chicaparts_partner/providers/currency_provider.dart';
import 'package:chicaparts_partner/providers/language_provider.dart';
import 'package:chicaparts_partner/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool notificationsEnabled = true;
  bool _hasChanged = false;

  @override
  Widget build(BuildContext context) {
    final langProvider = context.watch<LanguageProvider>();
    final currencyProvider = context.watch<CurrencyProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = themeProvider.isDarkMode;
    final titleColor = theme.textTheme.bodyLarge?.color ??
        (isDarkMode ? Colors.white : Colors.black);
    final mutedColor = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
    final inactiveColor = isDarkMode ? Colors.grey[300]! : Colors.grey[700]!;
    final tileColor = isDarkMode ? const Color(0xFF111827) : Colors.white;

    // ignore: deprecated_member_use
    return WillPopScope(
        onWillPop: () async {
          Navigator.pop(context, _hasChanged);
          return false;
        },
        child: Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
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
                              icon: Icon(
                                Icons.arrow_back_ios_new,
                                color: colorScheme.primary,
                              ),
                              onPressed: () => Navigator.pop(context, true),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lang.t('settings'),
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  lang.t('settings_text'),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: mutedColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Icon(Icons.settings,
                            size: 28, color: colorScheme.primary),
                      ],
                    ),
                  ),

                  /// 🌍 Langue
                  ListTile(
                    tileColor: tileColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    leading: Icon(Icons.language, color: colorScheme.primary),
                    title: Text(lang.t('language')),
                    trailing: DropdownButton<String>(
                      dropdownColor: tileColor,
                      value: langProvider.currentLang,
                      items: const [
                        DropdownMenuItem(value: "fr", child: Text("Français")),
                        DropdownMenuItem(value: "en", child: Text("English")),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          langProvider.loadLanguage(value);
                          setState(() {
                            _hasChanged = true;
                          });

                          /// ✅ Option : Changer devise automatiquement selon langue
                          // final newCurrency = value == "fr" ? "€" : "\$";
                          // currencyProvider.setCurrency(newCurrency);
                        }
                      },
                    ),
                  ),

                  Divider(color: theme.dividerColor),

                  /// 💱 Devise
                  ListTile(
                    tileColor: tileColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    leading: Icon(Icons.attach_money, color: colorScheme.primary),
                    title: Text(lang.t('currency')),
                    trailing: DropdownButton<String>(
                      dropdownColor: tileColor,
                      value: currencyProvider.currency,
                      items: ["EUR", "USD", "XAF", "GBP", "CAD"]
                          .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          currencyProvider.setCurrency(value);
                        }
                        setState(() {
                          _hasChanged = true;
                        });
                      },
                    ),
                  ),

                  Divider(color: theme.dividerColor),

                  /// 🌙 Mode sombre
                  // SwitchListTile(
                  //   activeThumbColor: const Color(0xFF244B6B),
                  //   title: Text(
                  //     lang.t('mode'),
                  //     style: TextStyle(
                  //       color: darkMode ? Colors.black : Colors.grey[700],
                  //       fontWeight: FontWeight.w500,
                  //     ),
                  //   ),
                  //   secondary: Icon(
                  //     Icons.dark_mode,
                  //     color: darkMode ? const Color(0xFF244B6B) : Colors.grey,
                  //   ),
                  //   value: darkMode,
                  //   onChanged: (val) {
                  //     setState(() => darkMode = val);
                  //     // TODO: Activer/désactiver un vrai ThemeProvider
                  //   },
                  //   subtitle: Text(
                  //     darkMode ? lang.t('black_mode') : lang.t('light_mode'),
                  //     style: TextStyle(
                  //       color: darkMode ? Colors.grey[700] : Colors.grey[500],
                  //       fontSize: 12,
                  //     ),
                  //   ),
                  // ),

                  /// 🔔 Notifications
                  SwitchListTile(
                    tileColor: tileColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: Text(
                      lang.t('mode'),
                      style: TextStyle(
                        color: titleColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    secondary: Icon(
                      isDarkMode ? Icons.dark_mode : Icons.light_mode,
                      color: isDarkMode ? colorScheme.primary : inactiveColor,
                    ),
                    value: isDarkMode,
                    onChanged: (value) async {
                      await themeProvider.setDarkMode(value);
                      setState(() {
                        _hasChanged = true;
                      });
                    },
                    subtitle: Text(
                      isDarkMode ? lang.t('black_mode') : lang.t('light_mode'),
                      style: TextStyle(
                        color: mutedColor,
                        fontSize: 12,
                      ),
                    ),
                  ),

                  Divider(color: theme.dividerColor),

                  SwitchListTile(
                    tileColor: tileColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: Text(
                      lang.t('notifications'),
                      style: TextStyle(
                        color:
                            notificationsEnabled ? titleColor : inactiveColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    secondary: Icon(
                      Icons.notifications,
                      color: notificationsEnabled
                          ? colorScheme.primary
                          : inactiveColor,
                    ),
                    value: notificationsEnabled,
                    onChanged: (value) {
                      setState(() => notificationsEnabled = value);
                    },
                    subtitle: Text(
                      notificationsEnabled
                          ? lang.t('notif_on')
                          : lang.t('notif_off'),
                      style: TextStyle(
                        color: mutedColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ));
  }
}
