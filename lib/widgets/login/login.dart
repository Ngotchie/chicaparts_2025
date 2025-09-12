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
  bool isTraveler = false;
  // Controllers pour les champs de texte
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  bool isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: Stack(
          children: [
            // Arrière-plan avec image en diagonale
            Positioned.fill(
              child: Transform.rotate(
                angle:
                    -0.6, // En radians, -0.4 ≈ -23 degrés (ajuste selon ton besoin)
                child: Opacity(
                  opacity:
                      0.5, // ✅ Faible opacité pour éviter que ce soit trop agressif
                  child: Image.asset(
                    "assets/images/logo-chic.png",
                    // fit: BoxFit.cover, // ✅ Prend toute la page
                    alignment: Alignment.center,
                  ),
                ),
              ),
            ),
            // Overlay sombre pour améliorer la lisibilité
            Positioned.fill(
              child: IgnorePointer(
                  child: Container(color: Colors.black.withOpacity(0.5))),
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
                      // Titre
                      Text(
                        isEnglish ? "Welcome Back!" : "Bon retour !",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Champ Email avec validation
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

                      // Champ Mot de passe avec affichage/masquage
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

                      // Bouton Se connecter
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
                              await _authentification(emailController.text,
                                  passwordController.text, context);
                              setState(() => isLoading = false);
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

                      // Lien vers "Mot de passe oublié"
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

                      // Lien vers inscription avec animation
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              PageRouteBuilder(
                                transitionDuration:
                                    const Duration(milliseconds: 500),
                                pageBuilder: (_, __, ___) => AccountPage(),
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

            Positioned(
              top: 40,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Bouton retour
                  IconButton(
                    icon: const Icon(Icons.arrow_back,
                        color: Colors.white, size: 28),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => WelcomePage()),
                      );
                    },
                  ),

                  // Bouton changement de langue
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

  // Widget pour un champ de texte avec validation
  Widget buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    String? errorText;

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
                obscureText: isPassword,
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  if (validator != null) {
                    final validation = validator(value);
                    setFieldState(() {
                      errorText = validation;
                    });
                  }
                },
                decoration: InputDecoration(
                  prefixIcon: Icon(icon, color: Colors.white),
                  hintText: hintText,
                  hintStyle: const TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
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

  Future<User> _getUserData(email, pass) async {
    ApiUrl url = ApiUrl();
    String apiUrl = url.getApiUrl();
    String apiKey = url.getKey();
    var client = RetryClient(http.Client());
    User user = User(0, "", "", []);

    try {
      var data = await client.post(Uri.parse('${apiUrl}auth/login'),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'X-Authorization': apiKey,
          },
          body: jsonEncode(<String, String>{'email': email, 'password': pass}));
      if (data.statusCode == 200) {
        isTraveler = false;
        var jsonData = jsonDecode(data.body);
        user = User(jsonData["id"], jsonData["name"], jsonData["email"],
            jsonData["third_party"]);
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('user', data.body);
        prefs.setString('email', jsonData["email"]);

        // await FavoriteRepository.syncLocalFavoritesToServer(user);

        return user;
      } else {
        return user;
      }
    } catch (e) {
      client.close();
      print(e);
      return throw Exception(e);
    }
  }

  Future<User> _getTravelerData(email, pass) async {
    ApiUrl url = ApiUrl();
    String apiUrl = url.getChicapartsUrl();
    String apiKey = url.getKey();
    var client = RetryClient(http.Client());
    User user = User(0, "", "", []);

    try {
      var data = await client.post(Uri.parse('${apiUrl}auth/login'),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'X-Authorization': apiKey,
          },
          body: jsonEncode(<String, String>{'login': email, 'password': pass}));
      if (data.statusCode == 200) {
        isTraveler = true;
        var jsonData = jsonDecode(data.body);
        user = User(jsonData["user"]["id"], jsonData["user"]["first_name"],
            jsonData["user"]["email"], "traveler");
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('user', jsonEncode(user.toJson()));
        prefs.setString('email', jsonData["user"]["email"]);
        return user;
      } else {
        return user;
      }
    } catch (e) {
      client.close();
      print(e);
      return throw Exception(e);
    }
  }

  _authentification(String email, String pass, context) async {
    try {
      // Appel API pour récupérer les données utilisateur
      var response = await _getUserData(email, pass);
      var response2 = await _getTravelerData(email, pass);

      // Vérifier si l'email est vide ou null (éviter le crash)
      if (response.email.isEmpty && response2.email.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 10),
                Text(
                  isEnglish
                      ? "Email or password incorrect!"
                      : "Email ou mot de passe erroné",
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        // Redirection vers la page principale après connexion
        !isTraveler
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
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isEnglish
                      ? "An error occurred: ${e.toString()}"
                      : "Une erreur est survenue : ${e.toString()}",
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
}
