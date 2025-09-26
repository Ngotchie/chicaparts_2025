import 'dart:convert';

import 'package:chicaparts_partner/api/traveler/api_user_traveler.dart';
import 'package:chicaparts_partner/models/user/user.dart';
import 'package:chicaparts_partner/widgets/login/welcome.dart';
import 'package:chicaparts_partner/widgets/menu/bottomMenuTraveler.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  bool isTraveler = true; // Voyageur actif par défaut
  bool isEnglish = true; // Anglais par défaut
  String language = "en"; // Variable pour gérer la langue
  bool isLoading = false;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();

  bool firstNameError = false;
  bool emailError = false;
  bool passwordError = false;

  PhoneNumber? _phoneNumber;

  final apiUser = ApiUserTraveler();

  @override
  void initState() {
    super.initState();
    _phoneNumber = PhoneNumber(isoCode: 'FR');
  }

  Future<void> registerUser(context) async {
    setState(() {
      firstNameError = firstNameController.text.trim().isEmpty;
      emailError = emailController.text.trim().isEmpty;
      passwordError = passwordController.text.trim().isEmpty;
    });

    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    final email = emailController.text.trim();
    final phone = _phoneNumber?.phoneNumber ?? phoneController.text.trim();
    final password = passwordController.text.trim();

    if (firstNameError || emailError || passwordError) {
      // Affiche une snackbar ou juste return
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEnglish
              ? "Please fill all required fields"
              : "Veuillez remplir tous les champs obligatoires"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final Map<String, dynamic> body = {
      "first_name": firstName,
      "last_name": lastName,
      "email": email,
      "mobile_phone_number": phone,
      "password": password,
      "local": isEnglish ? "en" : "fr",
    };

    try {
      dynamic response = await apiUser.UserRegister(body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print(data);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(isEnglish
                  ? "Compte créé avec succès 🎉"
                  : "Account created succefully 🎉")),
        );

        // Naviguer vers la page suivante ou de login
        _authenticateFromRegister(data["data"]["user"], context);
      } else {
        final error = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  "Erreur: ${error['message'] ?? isEnglish ? 'Inscription échouée' : 'Registration failed'}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Une erreur est survenue.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Image d'arrière-plan
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
          Container(
            color: Colors.black.withOpacity(0.5), // Ajout d'une couche sombre
          ),

          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 100),
                    // Titre
                    Text(
                      isEnglish ? "Create an account" : "Créer un compte",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Toggle Voyageur / Partenaire
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(isEnglish ? "Partner" : "Partenaire",
                            style: const TextStyle(color: Colors.white)),
                        Switch(
                          value: isTraveler,
                          onChanged: (value) {
                            setState(() {
                              isTraveler = value;
                            });

                            if (!value) {
                              // Rediriger vers la page de connexion si "Partenaire"
                              Navigator.pushReplacementNamed(context, "/login");
                            }
                          },
                          activeColor:
                              const Color(0xFFFFC107), // Jaune charte graphique
                        ),
                        Text(isEnglish ? "Traveler" : "Voyageur",
                            style: const TextStyle(color: Colors.white)),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Champ Nom
                    buildTextField(
                      isEnglish ? "First Name" : "Prénom",
                      Icons.person,
                      firstNameController,
                      hasError: firstNameError,
                    ),
                    const SizedBox(height: 10),

                    buildTextField(
                      isEnglish ? "Last Name" : "Nom",
                      Icons.person,
                      lastNameController,
                    ),
                    const SizedBox(height: 10),

                    // Champ Email
                    buildTextField(
                      "Email",
                      Icons.email,
                      emailController,
                      hasError: emailError,
                    ),
                    const SizedBox(height: 10),

                    // Champ Téléphone
                    buildTextField(
                      isEnglish ? "Phone Number" : "Numéro de téléphone",
                      Icons.phone,
                      phoneController,
                      isPhoneField: true,
                    ),
                    const SizedBox(height: 10),

                    // Champ Mot de passe
                    buildTextField(isEnglish ? "Password" : "Mot de passe",
                        Icons.lock, passwordController,
                        isPassword: true, hasError: passwordError),
                    const SizedBox(height: 20),

                    // Bouton S'inscrire
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
                          // Logique d'inscription + OTP ici
                          setState(() => isLoading = true);
                          // Logique inscription ici
                          await registerUser(context);
                          // await Future.delayed(
                          //     Duration(seconds: 2)); // Simule un appel API
                          setState(() => isLoading = false);
                        },
                        child: isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.black)
                            : Text(
                                isEnglish ? "Sign Up" : "S'inscrire",
                                style: const TextStyle(
                                    color: Colors.black, fontSize: 18),
                              ),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Lien vers connexion
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, "/login");
                        },
                        child: Text(
                          isEnglish
                              ? "Already have an account? Log in"
                              : "Vous avez déjà un compte ? Connectez-vous",
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
    );
  }

  // Widget pour un champ de texte personnalisé
  Widget buildTextField(
    String hintText,
    IconData icon,
    TextEditingController controller, {
    bool isPassword = false,
    bool isPhoneField = false,
    bool hasError = false,
    String? errorText,
  }) {
    if (isPhoneField) {
      return _buildPhoneNumberField(hintText);
    }

    String? _error = errorText;
    bool _obscure = isPassword; // état local (visible/masqué)

    return StatefulBuilder(
      builder: (context, setFieldState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: hasError ? Colors.red : Colors.transparent,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 8,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: controller,
                obscureText: _obscure,
                obscuringCharacter: '•',
                enableSuggestions: !isPassword,
                autocorrect: !isPassword,
                keyboardType:
                    isPassword ? TextInputType.text : TextInputType.text,
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  // si tu veux mettre une validation live plus tard,
                  // mets-la ici et affecte _error via setFieldState(...)
                },
                decoration: InputDecoration(
                  prefixIcon: Icon(icon, color: Colors.white),
                  hintText: hintText,
                  hintStyle: const TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 15, horizontal: 0),

                  // 👇 Bouton afficher/masquer (avec "peek" en appui long)
                  suffixIcon: isPassword
                      ? GestureDetector(
                          onTap: () =>
                              setFieldState(() => _obscure = !_obscure),
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
            if ((hasError && errorText != null) || _error != null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0, left: 8),
                child: Text(
                  _error ?? errorText!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildPhoneNumberField(String hintText) {
    return Container(
        padding: const EdgeInsets.only(left: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 8,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: InternationalPhoneNumberInput(
          onInputChanged: (PhoneNumber number) {
            setState(() => _phoneNumber = number);
          },
          selectorConfig: const SelectorConfig(
            selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
            showFlags: true,
          ),
          textFieldController: phoneController,
          initialValue: _phoneNumber,
          formatInput: false,
          keyboardType: TextInputType.phone,
          textStyle: const TextStyle(color: Colors.white),
          inputDecoration: InputDecoration(
            hintText: isEnglish ? "Phone Number" : "Numéro de téléphone",
            hintStyle: const TextStyle(color: Colors.white70),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
          ),
          spaceBetweenSelectorAndTextField: 0,
          selectorTextStyle: const TextStyle(color: Colors.white),
        ));
  }

  Future<void> _authenticateFromRegister(data, context) async {
    try {
      // 🎯 Enregistrer si nécessaire (ex: SharedPreferences ou token)
      // await saveSession(userData);
      final user = User(
        data["id"],
        data["first_name"],
        data["email"],
        "traveler",
      );
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString(
          'user', jsonEncode(user.toJson())); // tout le JSON si besoin
      prefs.setString('email', data["email"]);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const BottomMenuTraveler(
            index: 0,
            results: [], // À charger si besoin
          ),
        ),
      );
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
