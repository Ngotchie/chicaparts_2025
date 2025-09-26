import 'dart:convert';

import 'package:chicaparts_partner/models/user/user.dart';
import 'package:chicaparts_partner/services/api.dart';
import 'package:chicaparts_partner/services/favorite_repository.dart';
import 'package:chicaparts_partner/widgets/login/welcome.dart';
import 'package:chicaparts_partner/widgets/menu/bottomMenu.dart';
import 'package:chicaparts_partner/widgets/menu/bottomMenuTraveler.dart';
import 'package:flutter/material.dart';
import 'package:http/retry.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'account.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  bool isEnglish = true;
  bool isLoading = false;
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: Stack(
          children: [
            // BG image diagonale
            Positioned.fill(
              child: Transform.rotate(
                angle: -0.6,
                child: Opacity(
                  opacity: 0.5,
                  child: Image.asset(
                    "assets/images/logo-chic.png",
                    alignment: Alignment.center,
                  ),
                ),
              ),
            ),
            // Overlay sombre
            Positioned.fill(
              child: IgnorePointer(
                child: Container(color: Colors.black.withOpacity(0.5)),
              ),
            ),

            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 120),
                      Text(
                        isEnglish ? "Welcome Back!" : "Bon retour !",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Email
                      buildTextField(
                        controller: emailController,
                        hintText: "Email",
                        icon: Icons.email,
                        isPassword: false,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return isEnglish
                                ? "Please enter your email"
                                : "Veuillez entrer votre email";
                          }
                          if (!RegExp(
                                  r"^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$")
                              .hasMatch(value)) {
                            return isEnglish
                                ? "Enter a valid email"
                                : "Entrez un email valide";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),

                      // Password
                      buildTextField(
                        controller: passwordController,
                        hintText: isEnglish ? "Password" : "Mot de passe",
                        icon: Icons.lock,
                        isPassword: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return isEnglish
                                ? "Please enter your password"
                                : "Veuillez entrer votre mot de passe";
                          }
                          if (value.length < 6) {
                            return isEnglish
                                ? "Password must be at least 6 characters"
                                : "Le mot de passe doit contenir au moins 6 caractères";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Bouton Login
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFC107),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              setState(() => isLoading = true);
                              await _authenticate(
                                emailController.text.trim(),
                                passwordController.text,
                                context,
                              );
                              if (mounted) setState(() => isLoading = false);
                            }
                          },
                          child: isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.black)
                              : Text(
                                  isEnglish ? "Login" : "Se connecter",
                                  style: const TextStyle(
                                      color: Colors.black, fontSize: 18),
                                ),
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Forgot password
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isEnglish
                                      ? "Reset password functionality coming soon"
                                      : "La fonctionnalité de réinitialisation arrive bientôt",
                                ),
                              ),
                            );
                          },
                          child: Text(
                            isEnglish
                                ? "Forgot password?"
                                : "Mot de passe oublié ?",
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Sign up
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              PageRouteBuilder(
                                transitionDuration:
                                    const Duration(milliseconds: 500),
                                pageBuilder: (_, __, ___) =>
                                    const AccountPage(),
                                transitionsBuilder: (_, animation, __, child) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  );
                                },
                              ),
                            );
                          },
                          child: Text(
                            isEnglish
                                ? "Don't have an account? Sign Up"
                                : "Pas encore de compte ? S'inscrire",
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),

            // AppBar custom
            Positioned(
              top: 40,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back,
                        color: Colors.white, size: 28),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const WelcomePage()),
                      );
                    },
                  ),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        isEnglish = !isEnglish;
                      });
                    },
                    icon: const Icon(Icons.language, color: Colors.white),
                    label: Text(
                      isEnglish ? "Français" : "English",
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // TextField avec validation live + toggle "voir/cacher" pour les mots de passe
  Widget buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    String? errorText;
    bool _obscure = isPassword; // état local du champ (visible/masqué)

    return StatefulBuilder(
      builder: (context, setFieldState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 6,
                    offset: const Offset(1, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: controller,
                obscureText: _obscure,
                obscuringCharacter: '•',
                keyboardType: isPassword
                    ? TextInputType.text
                    : TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  if (validator != null) {
                    final validation = validator(value);
                    setFieldState(() => errorText = validation);
                  }
                },
                decoration: InputDecoration(
                  prefixIcon: Icon(icon, color: Colors.white),
                  hintText: hintText,
                  hintStyle: const TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 15, horizontal: 0),

                  // 👇 Bouton afficher/masquer pour les champs password
                  suffixIcon: isPassword
                      ? GestureDetector(
                          onTap: () =>
                              setFieldState(() => _obscure = !_obscure),
                          // Appui long = "peek": montre tant que pressé
                          onLongPressStart: (_) =>
                              setFieldState(() => _obscure = false),
                          onLongPressEnd: (_) =>
                              setFieldState(() => _obscure = true),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Icon(
                              _obscure
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : null,
                ),
              ),
            ),
            if (errorText != null)
              Padding(
                padding: const EdgeInsets.only(top: 5, left: 8),
                child: Text(
                  errorText!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                ),
              ),
          ],
        );
      },
    );
  }

  /// ---------------------------
  ///  API CALLS + NORMALISATION
  /// ---------------------------

  /// Login PARTENAIRE (Season)
  Future<User?> _loginPartner(String email, String pass) async {
    final url = ApiUrl();
    final apiUrl = url.getApiUrl(); // ex: https://season.api/...
    final apiKey = url.getKey();

    final client = RetryClient(http.Client());
    try {
      final resp = await client.post(
        Uri.parse('${apiUrl}auth/login'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'X-Authorization': apiKey,
        },
        body: jsonEncode(<String, String>{
          'email': email,
          'password': pass,
        }),
      );

      if (resp.statusCode != 200) return null;

      // Réponse Season (partner) — très verbeuse
      final Map<String, dynamic> jsonData = jsonDecode(resp.body);

      // 🔵 Normalisation → User léger de l’app
      final user = User(
        jsonData["id"] ?? 0,
        (jsonData["name"] ?? '').toString(),
        (jsonData["email"] ?? '').toString(),
        "partner", // ✅ clé unifiée
      );

      final prefs = await SharedPreferences.getInstance();
      // Sauvegarde NORMALISÉE
      await prefs.setString('user', jsonEncode(user.toJson()));
      await prefs.setString('email', user.email);

      // (Optionnel) Historiser le RAW si besoin de permissions/roles plus tard
      await prefs.setString('user_raw_partner', resp.body);

      await prefs.setString('app_lang', isEnglish ? 'en' : 'fr');
      // await FavoriteRepository.syncLocalFavoritesToServer(user);
      return user;
    } catch (e) {
      debugPrint('Partner login error: $e');
      return null;
    } finally {
      client.close();
    }
  }

  /// Login VOYAGEUR (Chicaparts)
  Future<User?> _loginTraveler(String email, String pass) async {
    final url = ApiUrl();
    final apiUrl = url.getChicapartsUrl(); // ex: https://chicaparts.api/...
    final apiKey = url.getKey();

    final client = RetryClient(http.Client());
    try {
      final resp = await client.post(
        Uri.parse('${apiUrl}auth/login'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'X-Authorization': apiKey,
        },
        body: jsonEncode(<String, String>{
          'login': email,
          'password': pass,
        }),
      );

      if (resp.statusCode != 200) return null;

      // Réponse Chicaparts (traveler)
      final Map<String, dynamic> jsonData = jsonDecode(resp.body);
      final u = jsonData["user"] as Map<String, dynamic>?;

      final user = User(
        (u?["id"] ?? 0) as int,
        (u?["first_name"] ?? u?["name"] ?? '').toString(),
        (u?["email"] ?? '').toString(),
        "traveler", // ✅ clé unifiée
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(user.toJson())); // normalisé
      await prefs.setString('email', user.email);

      await prefs.setString('user_raw_traveler', resp.body); // optionnel

      await prefs.setString('app_lang', isEnglish ? 'en' : 'fr');

      return user;
    } catch (e) {
      debugPrint('Traveler login error: $e');
      return null;
    } finally {
      client.close();
    }
  }

  /// Auth globale : d’abord PARTNER, sinon TRAVELER.
  Future<void> _authenticate(
      String email, String pass, BuildContext context) async {
    try {
      // 1) Partner (Season)
      User? user = await _loginPartner(email, pass);

      // 2) Si partner KO → Traveler (Chicaparts)
      user ??= await _loginTraveler(email, pass);

      if (user == null || user.email.isEmpty) {
        _showErrorSnack(
          context,
          isEnglish
              ? "Email or password incorrect!"
              : "Email ou mot de passe erroné",
        );
        return;
      }

      // Routing selon thirdParty normalisé
      if (user.thirdParty == "partner") {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const BottomMenu(index: 0)),
        );
      } else {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const BottomMenuTraveler(index: 0, results: []),
          ),
        );
      }
    } catch (e) {
      _showErrorSnack(
        context,
        (isEnglish ? "An error occurred: " : "Une erreur est survenue : ") +
            e.toString(),
      );
    }
  }

  void _showErrorSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
