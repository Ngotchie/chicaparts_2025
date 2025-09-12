import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

// Définition des langues prises en charge
class AppLocalizations {
  static final _localizedValues = {
    'en': {
      'welcome':
          'Find and book the best places to stay in France and Cameroon.',
      'login': 'Login With Account Details',
      'continue_guest': 'Continue as Guest',
      'or': 'OR',
      'signup_text': "Don't have an account?",
      'signup': 'Sign Up',
      'language': 'Français',
    },
    'fr': {
      'welcome':
          'Trouvez et réservez les meilleurs hébergements en France et au Cameroun.',
      'login': 'Se connecter à mon compte',
      'continue_guest': 'Continuer en tant qu\'invité',
      'or': 'OU',
      'signup_text': "Vous n'avez pas de compte?",
      'signup': 'S\'inscrire',
      'language': 'English',
    }
  };

  final String locale;
  AppLocalizations(this.locale);

  String get(String key) => _localizedValues[locale]?[key] ?? key;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }
}

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  _WelcomePageState createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  int _currentIndex = 0;
  String _currentLocale = 'en'; // Langue par défaut

  final List<String> imageList = [
    "assets/images/background-signup.jpg",
    "assets/images/terrasse.png",
    "assets/images/cuisine.png",
    "assets/images/chambre.png",
  ];

  @override
  Widget build(BuildContext context) {
    var localization = AppLocalizations(_currentLocale);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  // Carrousel avec indicateur
                  Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      CarouselSlider(
                        options: CarouselOptions(
                          height: MediaQuery.of(context).size.height * 0.45,
                          autoPlay: true,
                          viewportFraction: 1.0,
                          enlargeCenterPage: false,
                          onPageChanged: (index, reason) {
                            setState(() {
                              _currentIndex = index;
                            });
                          },
                        ),
                        items: imageList.map((imagePath) {
                          return Container(
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage(imagePath),
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      // Indicateur de page (points)
                      Positioned(
                        bottom: 10,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(imageList.length, (index) {
                            return Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentIndex == index
                                    ? Colors.blueAccent
                                    : Colors.grey,
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Texte d’accroche (mis à jour)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      localization.get('welcome'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Bouton "Login With Phone Number"
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, "/login");
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(
                          0xFF244B6B), // Bleu de la charte graphique
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    // icon: Icon(Icons.phone, color: Colors.white),
                    label: Text(
                      localization.get('login'),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Texte "OR"
                  Text(
                    localization.get('or'),
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),

                  const SizedBox(height: 15),

                  // Bouton "Continue as Guest"
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, "/home");
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade400),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 50, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      localization.get('continue_guest'),
                      style: const TextStyle(color: Colors.black, fontSize: 14),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Lien "Sign Up"
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(localization.get('signup_text'),
                          style: const TextStyle(fontSize: 14)),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, "/account");
                        },
                        child: Text(
                          localization.get('signup'),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF244B6B), // Bleu de la charte
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  const Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 10.0),
                      child: Text(
                        "Powered by Mayem Solutions",
                        style: TextStyle(color: Colors.black, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bouton de changement de langue
            Positioned(
              top: 40,
              right: 20,
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _currentLocale = (_currentLocale == 'en') ? 'fr' : 'en';
                  });
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white, // Couleur du texte et icône
                ),
                icon: const Icon(Icons.language), // Icône de langue
                label: Text(
                  _currentLocale == 'en' ? "Français" : "English",
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
