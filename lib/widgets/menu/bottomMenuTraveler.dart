import 'package:chicaparts_partner/models/traveler/model_accommodation_traveler.dart';
import 'package:chicaparts_partner/widgets/traveler/favorites/favorites.dart';
import 'package:chicaparts_partner/widgets/traveler/home.dart';
import 'package:chicaparts_partner/widgets/traveler/my_account/myAccount.dart';
import 'package:chicaparts_partner/widgets/traveler/search/searchPage.dart';
import 'package:flutter/material.dart';
import 'package:chicaparts_partner/providers/language_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class BottomMenuTraveler extends StatefulWidget {
  final List<Stay> results;
  final int index;
  const BottomMenuTraveler(
      {super.key, required this.index, required this.results});

  @override
  _BottomMenuTravelerState createState() => _BottomMenuTravelerState();
}

class _BottomMenuTravelerState extends State<BottomMenuTraveler> {
  int _selectedIndex = 0;
  late List<Stay> search_result;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    search_result = widget.results; // ✅ ICI c'est bon
    _selectedIndex = widget.index;
    // Liste des pages associées aux onglets
    _pages = [
      const HomePage(),
      SearchPage(results: search_result),
      const FavoritesPages(),
      const MyAccountPage()
    ];
  }

  final String phoneNumber =
      "+33612781715"; // Numéro WhatsApp au format international

  void _openWhatsApp() async {
    final Uri whatsappUrl = Uri.parse("https://wa.me/$phoneNumber");

    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    } else {
      debugPrint("❌ Impossible d’ouvrir WhatsApp");
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    return Stack(children: [
      Scaffold(
        body: _pages[_selectedIndex], // Afficher la page sélectionnée
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          backgroundColor:
              const Color(0xFF244B6B), // Bleu de la charte graphique
          selectedItemColor:
              const Color(0xFFFFC107), // Icône sélectionnée en blanc
          unselectedItemColor: Colors.white,
          // Icône non sélectionnée en jaune
          showUnselectedLabels:
              true, // Afficher les labels des icônes non sélectionnées
          type: BottomNavigationBarType
              .fixed, // Évite l'effet de zoom sur l'icône active
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home),
              label: lang.t('home'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.search),
              label: lang.t('search'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.favorite),
              label: lang.t('favorite'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person),
              label: lang.t('account'),
            ),
          ],
        ),
      ),
      // ✅ Bouton WhatsApp flottant
      Positioned(
        bottom: 80, // légèrement au-dessus du bottom nav
        right: 16,
        child: FloatingActionButton(
          onPressed: _openWhatsApp,
          backgroundColor: Colors.green,
          mini: true,
          child: const Icon(FontAwesomeIcons.whatsapp, color: Colors.white),
        ),
      ),
    ]);
  }
}
