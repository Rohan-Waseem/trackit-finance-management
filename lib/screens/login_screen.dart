import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'signup_screen.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  final _authService = AuthService();

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final user = await _authService.loginWithEmail(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );
    setState(() => _isLoading = false);
    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login failed. Check credentials.")),
      );
    }
  }

  Future<void> _googleLogin() async {
    final user = await _authService.signInWithGoogle();
    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Google login failed")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C2B),
      body: Stack(
        children: [
          Positioned(
            top: -60,
            left: -60,
            child: Container(
              width: 160,
              height: 160,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Colors.blue, Colors.deepPurple],
                ),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Colors.blueAccent, Colors.purpleAccent],
                      ).createShader(bounds),
                      child: Text(
                        "📊 TrackIt Login",
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildNeumorphicField(
                      controller: _emailController,
                      label: "Email",
                      keyboardType: TextInputType.emailAddress,
                      validator: (val) =>
                      val == null || !val.contains("@") ? "Enter valid email" : null,
                    ),
                    const SizedBox(height: 16),
                    _buildNeumorphicField(
                      controller: _passwordController,
                      label: "Password",
                      obscure: true,
                      validator: (val) =>
                      val == null || val.length < 6 ? "Min 6 characters" : null,
                    ),
                    const SizedBox(height: 32),
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Column(
                      children: [
                        _buildMainButton("Login", _login),
                        const SizedBox(height: 16),
                        _buildGoogleButton(),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Divider(color: Colors.white30),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SignupScreen()),
                      ),
                      child: RichText(
                        text: TextSpan(
                          text: "Don't have an account? ",
                          style: const TextStyle(color: Colors.white70),
                          children: [
                            TextSpan(
                              text: "Sign up",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: Colors.lightBlueAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNeumorphicField({
    required TextEditingController controller,
    required String label,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3D),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black54, offset: Offset(2, 2), blurRadius: 5),
          BoxShadow(color: Colors.black26, offset: Offset(-2, -2), blurRadius: 5),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscure,
        validator: validator,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildMainButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6C63FF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: _googleLogin,
        icon: Image.asset(
          'assets/images/google.png',
          height: 22,
          width: 22,
        ),
        label: const Text(
          "Sign in with Google",
          style: TextStyle(fontSize: 15, color: Colors.white),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFF1C1C2B),
          side: const BorderSide(color: Colors.white30),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
