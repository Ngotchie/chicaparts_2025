import 'dart:convert';
import 'package:chicaparts_partner/widgets/booking/myBookings.dart';
import 'package:chicaparts_partner/widgets/traveler/accommodation/accommodationDetails.dart';
import 'package:chicaparts_partner/widgets/traveler/favorites/favorites.dart';
import 'package:chicaparts_partner/widgets/traveler/my_account/bookingDetails.dart';
import 'package:chicaparts_partner/widgets/traveler/my_account/claims.dart';
import 'package:chicaparts_partner/widgets/traveler/my_account/invoices.dart';
import 'package:chicaparts_partner/widgets/traveler/my_account/myBooking.dart';
import 'package:chicaparts_partner/widgets/traveler/my_account/my_reviews_page.dart';
import 'package:chicaparts_partner/widgets/traveler/my_account/profile.dart';
import 'package:chicaparts_partner/widgets/traveler/my_account/setting.dart';
import 'package:chicaparts_partner/widgets/traveler/my_account/transaction.dart';
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
import 'package:chicaparts_partner/providers/theme_provider.dart';

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
  final themeProvider = ThemeProvider();

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
        ChangeNotifierProvider(create: (_) => themeProvider),
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
      await themeProvider.initTheme();
      if (user != null) {
        await favoriteProvider.loadFavorites(
          isGuest: false,
          user: user,
        );
      }
    } catch (e, s) {
      // silencieux pour ne pas bloquer l'UX ; journaliser si besoin
      debugPrint('Startup error: $e');
      debugPrint('$s');
    }
  });
  //}
}

class MyApp extends StatelessWidget {
  final User? initialUser;
  const MyApp({super.key, this.initialUser});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            isDarkMode ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDarkMode ? Brightness.dark : Brightness.light,
        systemNavigationBarColor:
            isDarkMode ? const Color(0xFF111827) : Colors.white,
        systemNavigationBarIconBrightness:
            isDarkMode ? Brightness.light : Brightness.dark,
      ),
    );

    return MaterialApp(
      title: 'Chicaparts',
      debugShowCheckedModeBanner: false,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: themeProvider.themeMode,
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
        '/my-account': (_) => const BottomMenuTraveler(index: 3, results: []),
        '/resume-reservation': (_) => const ResumeReservationPage(),
        '/account/settings': (_) => const SettingsPage(),
        '/account/profile': (_) => const ProfilePage(),
        '/reservations': (_) => const MyReservationsPage(),
        '/favorites': (_) => const BottomMenuTraveler(index: 2, results: []),
        '/account/transactions': (_) => const TransactionPage(),
        '/account/payments': (_) => const TransactionPage(
              paymentType: 'booking',
              titleKey: 'payments',
              fallbackTitleFr: 'Paiements',
              fallbackTitleEn: 'Payments',
            ),
        '/account/invoices': (_) => const InvoicesPage(),
        '/account/tips': (_) => const TransactionPage(
              paymentType: 'tip',
              titleKey: 'tips',
              fallbackTitleFr: 'Pourboires',
              fallbackTitleEn: 'Tips',
            ),
        '/account/claims': (_) => const ClaimsPage()
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

        // /acc/<id>/<currency>/<price>
        if (uri.pathSegments.length == 4 && uri.pathSegments[0] == 'acc') {
          final int? id = int.tryParse(uri.pathSegments[1]);
          final String currency = Uri.decodeComponent(uri.pathSegments[2]);
          final double? price = double.tryParse(uri.pathSegments[3]);

          if (id != null && price != null) {
            return MaterialPageRoute(
              builder: (_) => AccommodationDetails(
                accommodationId: id,
                currency: currency,
                dayPrice: price,
              ),
              settings: settings,
            );
          }
        }

        if (name == '/avis') {
          return MaterialPageRoute(
            builder: (_) => const MyReviewsPage(),
            settings: settings,
          );
        }

        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Route non trouvée')),
          ),
          settings: settings,
        );
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
    if (!mounted) return;

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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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

ThemeData _buildLightTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: _kPrimary,
    primary: _kPrimary,
    secondary: _kSecondary,
    brightness: Brightness.light,
  );

  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Montserrat',
    colorScheme: colorScheme,
    scaffoldBackgroundColor: const Color(0xFFF6F8FB),
    canvasColor: Colors.white,
    dividerColor: const Color(0xFFE2E8F0),
    cardColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: _kPrimary,
      elevation: 0,
      centerTitle: false,
    ),
    listTileTheme: const ListTileThemeData(iconColor: _kPrimary),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? _kPrimary : Colors.white,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? _kPrimary.withValues(alpha: 0.45)
            : const Color(0xFFCBD5E1),
      ),
    ),
  );
}

ThemeData _buildDarkTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: _kPrimary,
    primary: const Color(0xFF8AB4D6),
    secondary: _kSecondary,
    brightness: Brightness.dark,
    surface: const Color(0xFF111827),
  );

  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Montserrat',
    colorScheme: colorScheme,
    scaffoldBackgroundColor: const Color(0xFF0B1220),
    canvasColor: const Color(0xFF111827),
    dividerColor: const Color(0xFF243041),
    cardColor: const Color(0xFF111827),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: Color(0xFF8AB4D6),
      textColor: Colors.white,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? const Color(0xFF8AB4D6)
            : const Color(0xFFE5E7EB),
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? const Color(0xFF8AB4D6).withValues(alpha: 0.45)
            : const Color(0xFF334155),
      ),
    ),
  );
}
