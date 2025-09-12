import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  String _currentLang = "fr";
  Map<String, String> _translations = {};

  String get currentLang => _currentLang;
  String t(String key) => _translations[key] ?? key;

  Future<void> loadLanguage(String langCode) async {
    _currentLang = langCode;
    final jsonString =
        await rootBundle.loadString('assets/lang/$langCode.json');
    final jsonMap = jsonDecode(jsonString);
    _translations = Map<String, String>.from(jsonMap);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_lang', langCode);
    notifyListeners();
  }

  Future<void> initLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLang = prefs.getString('app_lang') ?? 'fr';
    await loadLanguage(savedLang);
  }
}
