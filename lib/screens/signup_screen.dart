import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  Future<void> _pickDOB() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1970),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final user = await _authService.signUpWithEmail(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      dob: _dobController.text.trim(),
      password: _passwordController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Signup failed. Try again.")),
      );
    }
  }

  Future<void> _googleSignup() async {
    final user = await _authService.signInWithGoogle();
    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Google sign-up failed")),
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
            right: -60,
            child: Container(
              width: 160,
              height: 160,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Colors.purple, Colors.deepPurple],
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
                        colors: [Colors.pinkAccent, Colors.deepPurpleAccent],
                      ).createShader(bounds),
                      child: Text(
                        "📝 Create Account",
                        style: GoogleFonts.poppins(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildNeumorphicField(_nameController, "Full Name"),
                    const SizedBox(height: 12),
                    _buildNeumorphicField(
                      _emailController,
                      "Email",
                      keyboardType: TextInputType.emailAddress,
                      validator: (val) =>
                      val == null || !val.contains("@") ? "Enter valid email" : null,
                    ),
                    const SizedBox(height: 12),
                    _buildNeumorphicField(
                      _phoneController,
                      "Phone Number",
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _pickDOB,
                      child: AbsorbPointer(
                        child: _buildNeumorphicField(_dobController, "Date of Birth"),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildNeumorphicField(
                      _passwordController,
                      "Password",
                      obscureText: true,
                    ),
                    const SizedBox(height: 12),
                    _buildNeumorphicField(
                      _confirmPasswordController,
                      "Confirm Password",
                      obscureText: true,
                      validator: (val) {
                        if (val == null || val != _passwordController.text) {
                          return "Passwords do not match";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Column(
                      children: [
                        _buildMainButton("Sign Up", _signup),
                        const SizedBox(height: 16),
                        _buildGoogleButton(),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Divider(color: Colors.white24),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                      child: RichText(
                        text: TextSpan(
                          text: "Already have an account? ",
                          style: const TextStyle(color: Colors.white70),
                          children: [
                            TextSpan(
                              text: "Login",
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

  Widget _buildNeumorphicField(
      TextEditingController controller,
      String label, {
        bool obscureText = false,
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
        obscureText: obscureText,
        validator: validator ??
                (val) => val == null || val.isEmpty ? "Enter $label" : null,
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
        onPressed: _googleSignup,
        icon: Image.asset('assets/images/google.png', height: 22, width: 22),
        label: const Text(
          "Sign up with Google",
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
