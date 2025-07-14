import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../services/auth_service.dart';
import 'login_screen.dart';

// same imports...
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _profileImageUrl;
  File? _pickedImageFile;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      _nameController.text = data['name'] ?? '';
      _emailController.text = data['email'] ?? '';
      _phoneController.text = data['phone'] ?? '';
      _dobController.text = data['dob'] ?? '';
      _profileImageUrl = data['profileImage'];
    }
    setState(() => _isLoading = false);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) {
      setState(() => _pickedImageFile = File(picked.path));
    }
  }

  Future<String?> _uploadProfileImage(String uid) async {
    if (_pickedImageFile == null) return _profileImageUrl;
    final ref = FirebaseStorage.instance.ref().child('profile_images/$uid.jpg');
    await ref.putFile(_pickedImageFile!);
    return await ref.getDownloadURL();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final imageUrl = await _uploadProfileImage(uid);
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'dob': _dobController.text.trim(),
        'profileImage': imageUrl,
      });
      setState(() {
        _profileImageUrl = imageUrl;
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Profile updated")),
      );
    }
  }

  void _logout() async {
    await _authService.logout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90),
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF512DA8), Color(0xFF9575CD)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black45,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      "Your Profile",
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF2C2C3E),
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF9575CD), Color(0xFF512DA8)],
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 55,
                          backgroundColor: Colors.grey[100],
                          backgroundImage: _pickedImageFile != null
                              ? FileImage(_pickedImageFile!)
                              : (_profileImageUrl != null
                              ? NetworkImage(_profileImageUrl!)
                              : const AssetImage('assets/images/user.png')) as ImageProvider,
                        ),
                      ),
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.edit, size: 18, color: Colors.deepPurple[700]),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "Edit Profile",
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                _buildField(_nameController, "Full Name"),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  enabled: false,
                  style: const TextStyle(color: Colors.white70),
                  decoration: _inputDecoration("Email"),
                ),
                const SizedBox(height: 12),
                _buildField(_phoneController, "Phone"),
                const SizedBox(height: 12),
                _buildField(_dobController, "Date of Birth"),
                const SizedBox(height: 28),
                _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple[700],
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      "Save Changes",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
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

  Widget _buildField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(label),
      validator: (val) => val == null || val.isEmpty ? "Enter $label" : null,
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: Colors.white.withOpacity(0.08),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }
}
