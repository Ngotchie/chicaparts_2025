// lib/screens/forgot_password_page.dart
import 'package:chicaparts_partner/api/login/login.dart';
import 'package:flutter/material.dart';

class ForgotPasswordPage extends StatefulWidget {
  final bool isEnglish;
  final AuthService auth;

  const ForgotPasswordPage({
    super.key,
    required this.isEnglish,
    required this.auth,
  });

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final msg =
          await widget.auth.requestPasswordReset(_emailCtrl.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
      Navigator.of(context).pop(); // Retour à l'écran Login
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEnglish
                ? (e.toString().replaceFirst('Exception: ', '').isEmpty
                    ? 'An error occurred.'
                    : e.toString().replaceFirst('Exception: ', ''))
                : (e.toString().replaceFirst('Exception: ', '').isEmpty
                    ? 'Une erreur est survenue.'
                    : e.toString().replaceFirst('Exception: ', '')),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    var isEnglish = widget.isEnglish;
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 101, 98, 98),
      appBar: AppBar(
        // titleTextStyle: const TextStyle(color: Colors.white, fontSize: 24),
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(isEnglish ? 'Forgot Password' : 'Mot de passe oublié'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Text(
                  isEnglish
                      ? 'Reset your password'
                      : 'Réinitialiser votre mot de passe',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  isEnglish
                      ? "Enter your email address. We'll send you a reset link."
                      : "Saisissez votre adresse email. Nous vous enverrons un lien de réinitialisation.",
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Email',
                    hintStyle: const TextStyle(color: Colors.white54),
                    prefixIcon: const Icon(Icons.email, color: Colors.white70),
                    filled: true,
                    fillColor: const Color(0xFF1A1A1A),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    final v = value?.trim() ?? '';
                    if (v.isEmpty) {
                      return isEnglish
                          ? 'Please enter your email'
                          : 'Veuillez entrer votre email';
                    }
                    final emailReg = RegExp(
                        r'^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$');
                    if (!emailReg.hasMatch(v)) {
                      return isEnglish
                          ? 'Enter a valid email'
                          : 'Entrez un email valide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC107),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.black)
                        : Text(
                            isEnglish ? 'Send reset link' : 'Envoyer le lien',
                            style: const TextStyle(
                                color: Colors.black, fontSize: 16),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
