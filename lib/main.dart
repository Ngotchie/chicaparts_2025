import 'dart:async';
import 'dart:convert';

import 'package:chicaparts_partner/models/user/user.dart';
import 'package:chicaparts_partner/providers/currency_provider.dart';
import 'package:chicaparts_partner/providers/exchange_rate_provider.dart';
import 'package:chicaparts_partner/providers/favorite_provider.dart';
import 'package:chicaparts_partner/providers/language_provider.dart';
import 'package:chicaparts_partner/services/user.dart';
import 'package:chicaparts_partner/widgets/login/account.dart';
import 'package:chicaparts_partner/widgets/login/welcome.dart';
import 'package:chicaparts_partner/widgets/menu/bottomMenuTraveler.dart';
import 'package:chicaparts_partner/widgets/traveler/book/resumeReservation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chicaparts_partner/widgets/login/login.dart';
import 'package:chicaparts_partner/widgets/menu/bottomMenu.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
// import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Stripe.publishableKey =
      "pk_live_51PL2lGRqkPd0DuljQ67EL63SVdBOGJNtIu3n7sZSz7SMvBywISzzMDwdTqnSnsSe1EpH5MCmK2VNS8uc5V3jjZ0H00NmThjT5f";
  Stripe.instance.applySettings();

  final langProvider = LanguageProvider();
  final currencyProvider = CurrencyProvider();
  final exchangeProvider = ExchangeRateProvider();
  final favoriteProvider = FavoriteProvider();

  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isGuest = true;
  dynamic user;
  final userJson = prefs.getString('user');
  if (userJson != null) {
    final decoded = jsonDecode(userJson);
    user = User.fromJson(decoded);
    isGuest = false;
  }

  await langProvider.initLanguage();
  await currencyProvider.initCurrency();
  await exchangeProvider.loadRates();
  await favoriteProvider.loadFavorites(isGuest: isGuest, user: user);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Color(0xFF244B6B), // même couleur
      statusBarIconBrightness: Brightness.light, // ou dark selon ton fond
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => langProvider),
        ChangeNotifierProvider(create: (_) => currencyProvider),
        ChangeNotifierProvider(create: (_) => exchangeProvider),
        ChangeNotifierProvider(create: (_) => favoriteProvider),
      ],
      child: MyApp(),
    ),
  );
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent, // navigation bar color
      statusBarColor:
          Color(0xff04994b6) //Colors.orange[900] // status bar color
      ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Chic Partner',
      theme: ThemeData(
          colorScheme: ColorScheme.fromSwatch().copyWith(
            primary: const Color(0xFF244B6B), //Color(0xFFF37540),
            secondary: const Color(0xffffbd107),
          ),
          fontFamily: 'Montserrat'),
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/login': (context) => LoginPage(),
        '/account': (context) => AccountPage(),
        '/welcome': (context) => WelcomePage(),
        '/booking': (context) => const BottomMenu(index: 1),
        '/accommodation': (context) => const BottomMenu(index: 0),
        '/finance': (context) => const BottomMenu(index: 2),
        '/operation': (context) => const BottomMenu(index: 3),
        '/home': (context) => const BottomMenuTraveler(
              index: 0,
              results: [],
            ),
        '/resume-reservation': (context) => const ResumeReservationPage(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String currentEmail = "";
  late User user;

  startTime() async {
    var duration = const Duration(seconds: 4);
    return Timer(duration, navigationPage);
  }

  getData() async {}

  void navigationPage() async {
    WidgetsFlutterBinding.ensureInitialized(); // ✅ Assure l'initialisation

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() {
        currentEmail = prefs.getString('email') ?? "";
        final userJson = prefs.getString('user');
        if (userJson != null) {
          final decoded = jsonDecode(userJson);
          user = User.fromJson(decoded);
        }
      });
    } catch (e) {
      Navigator.of(context).pushReplacementNamed('/welcome');
      print("Erreur lors du chargement des données: $e");
    }
    if (currentEmail != "") {
      user.thirdParty != "traveler"
          ? Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const BottomMenu(index: 0),
              ),
            )
          : Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const BottomMenuTraveler(
                  index: 0,
                  results: [],
                ),
              ),
            );
    } else {
      // Navigator.of(context).pushReplacementNamed('/login');
      Navigator.of(context).pushReplacementNamed('/welcome');
    }
  }

  @override
  void initState() {
    super.initState();
    startTime();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset(
          "assets/images/new-logo.png",
          width: 200,
        ),
      ),
    );
  }
}
