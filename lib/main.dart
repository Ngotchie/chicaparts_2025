import 'dart:convert';
import 'package:chicaparts_partner/widgets/booking/myBookings.dart';
import 'package:chicaparts_partner/widgets/traveler/accommodation/accommodationDetails.dart';
import 'package:chicaparts_partner/widgets/traveler/favorites/favorites.dart';
import 'package:chicaparts_partner/widgets/traveler/my_account/bookingDetails.dart';
import 'package:chicaparts_partner/widgets/traveler/my_account/myBooking.dart';
import 'package:chicaparts_partner/widgets/traveler/my_account/my_reviews_page.dart';
import 'package:chicaparts_partner/widgets/traveler/my_account/profile.dart';
import 'package:chicaparts_partner/widgets/traveler/my_account/setting.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

// MODELS & PROVIDERS
import 'package:chicaparts_partner/models/user/user.dart';
import 'package:chicaparts_partner/providers/currency_provider.dart';
import 'package:chicaparts_partner/providers/exchange_rate_provider.dart';
import 'package:chicaparts_partner/providers/favorite_provider.dart';
import 'package:chicaparts_partner/providers/language_provider.dart';

// WIDGETS / ROUTES
import 'package:chicaparts_partner/widgets/login/login.dart';
import 'package:chicaparts_partner/widgets/login/account.dart';
import 'package:chicaparts_partner/widgets/login/welcome.dart';
import 'package:chicaparts_partner/widgets/menu/bottomMenu.dart';
import 'package:chicaparts_partner/widgets/menu/bottomMenuTraveler.dart';
import 'package:chicaparts_partner/widgets/traveler/book/resumeReservation.dart';

// ---------- CONFIG ----------
const _kSplashDelay = Duration(milliseconds: 700); // délai très court
const _kPrimary = Color(0xFF244B6B);
const _kSecondary = Color(0xFFFBD107); // #FBD107

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) Charger l'utilisateur une seule fois
  final prefs = await SharedPreferences.getInstance();
  prefs.setString('app_lang', prefs.getString('app_lang') ?? 'en');

  User? user;
  final userJson = prefs.getString('user');
  if (userJson != null) {
    try {
      user = User.fromJson(jsonDecode(userJson));
    } catch (_) {
      user = null;
    }
  }

  // 2) Stripe (mobile only)
  if (!kIsWeb) {
    Stripe.publishableKey =
        "pk_live_51PL2lGRqkPd0DuljQ67EL63SVdBOGJNtIu3n7sZSz7SMvBywISzzMDwdTqnSnsSe1EpH5MCmK2VNS8uc5V3jjZ0H00NmThjT5f";

    await Stripe.instance.applySettings();
  }

  // 3) Providers (créés maintenant, initialisation lourde après 1er frame)
  final langProvider = LanguageProvider();
  final currencyProvider = CurrencyProvider();
  final exchangeProvider = ExchangeRateProvider();
  final favoriteProvider = FavoriteProvider();

  // 4) Style barre système
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: _kPrimary,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
  ));

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => langProvider),
        ChangeNotifierProvider(create: (_) => currencyProvider),
        ChangeNotifierProvider(create: (_) => exchangeProvider),
        ChangeNotifierProvider(create: (_) => favoriteProvider),
      ],
      child: MyApp(initialUser: user),
    ),
  );

  // 5) Warm-up asynchrone (ne bloque pas l’ouverture)
  //if (user?.thirdParty == 'traveler') {
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    try {
      await langProvider.initLanguage();
      await currencyProvider.initCurrency();
      await exchangeProvider.loadRates();
      await favoriteProvider.loadFavorites(isGuest: false, user: user!);
    } catch (_) {
      // silencieux pour ne pas bloquer l'UX ; journaliser si besoin
    }
  });
  //}
}

class MyApp extends StatelessWidget {
  final User? initialUser;
  const MyApp({super.key, this.initialUser});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chicaparts',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: _kPrimary,
          secondary: _kSecondary,
        ),
        fontFamily: 'Montserrat',
      ),
      // On garde le système de routes + Splash en route initiale
      initialRoute: '/',
      routes: {
        '/': (_) => SplashScreen(initialUser: initialUser),
        '/login': (_) => const LoginPage(),
        '/account': (_) => const AccountPage(),
        '/welcome': (_) => const WelcomePage(),
        '/booking': (_) => const BottomMenu(index: 1),
        '/accommodation': (_) => const BottomMenu(index: 0),
        '/finance': (_) => const BottomMenu(index: 2),
        '/operation': (_) => const BottomMenu(index: 3),
        '/home': (_) => const BottomMenuTraveler(index: 0, results: []),
        '/resume-reservation': (_) => const ResumeReservationPage(),
        '/account/settings': (_) => const SettingsPage(),
        '/account/profile': (_) => const ProfilePage(),
        '/reservations': (_) => const MyReservationsPage(),
        '/favorites': (_) => const BottomMenuTraveler(index: 2, results: []),
      },
      onGenerateRoute: (settings) {
        final name = settings.name ?? '';
        final uri = Uri.parse(name);

        // /reservations/<id>
        if (uri.pathSegments.length == 2 &&
            uri.pathSegments[0] == 'reservations') {
          final id = uri.pathSegments[1];
          return MaterialPageRoute(
            builder: (_) => BookingDetailsPage(bookingId: id),
            settings: settings,
          );
        }

        //accommodation/<id>
        if (uri.pathSegments.length == 2 &&
            uri.pathSegments[0] == 'accommodation') {
          final id = uri.pathSegments[1];
          final currency = uri.pathSegments[2];
          final price = uri.pathSegments[1];
          return MaterialPageRoute(
            builder: (_) => AccommodationDetails(
              accommodationId: id as int,
              currency: currency,
              dayPrice: price as double,
            ),
            settings: settings,
          );
        }

        if (name == '/avis') {
          return MaterialPageRoute(
            builder: (_) => const MyReviewsPage(),
            settings: settings,
          );
        }
        return null; // laisser Flutter gérer les autres
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  final User? initialUser;
  const SplashScreen({super.key, this.initialUser});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();

    // Petit effet visuel rapide
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..forward();
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    // Délai court puis navigation en fonction du user
    Future.delayed(_kSplashDelay, _goNext);
  }

  void _goNext() {
    final user = widget.initialUser;

    // Choix de la page selon le type d'utilisateur
    if (user != null && user.thirdParty == 'traveler') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const BottomMenuTraveler(index: 0, results: []),
        ),
      );
      return;
    }

    if (user != null && user.thirdParty == 'partner') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const BottomMenu(index: 0)),
      );
      return;
    }

    // Non connecté → welcome
    Navigator.of(context).pushReplacementNamed('/welcome');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Splash simple (image + fond) avec un petit fade-in
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: Image.asset(
            'assets/images/new-logo.png',
            width: 200,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
