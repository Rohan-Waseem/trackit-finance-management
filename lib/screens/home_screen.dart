import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui'; // for ImageFilter
import 'login_screen.dart';
import 'profile_screen.dart';
import 'transaction_screen.dart';
import 'upload_receipts_screen.dart';
import 'notes_screen.dart';
import 'stats_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String name = 'User';
  String? profileImageUrl;
  int balance = 0;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          name = data['name'] ?? 'User';
          profileImageUrl = data['profileImage'];
          balance = data['balance'] ?? 0;
        });
      }
    }
  }

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 90,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              ),
              child: CircleAvatar(
                radius: 26,
                backgroundImage: profileImageUrl != null
                    ? NetworkImage(profileImageUrl!)
                    : const AssetImage('assets/images/user.png') as ImageProvider,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                "Hi, $name",
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => _logout(context),
          )
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF5D3FD3), Color(0xFF8E44AD)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepPurple.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                      border: Border.all(color: Colors.white.withOpacity(0.15)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Available Balance",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.white70,
                            )),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Rs. $balance",
                                style: GoogleFonts.poppins(
                                  fontSize: 30,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                )),
                            IconButton(
                              icon: const Icon(Icons.refresh, color: Colors.white),
                              onPressed: () {
                                _loadUserInfo();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("🔄 Balance refreshed")),
                                );
                              },
                            )
                          ],
                        ),
                      ],
                    ),
                  ),

                ),
              ),

              const SizedBox(height: 32),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  children: [
                    _dashboardCard(
                        label: "Transactions",
                        icon: Icons.history,
                        destination: const TransactionScreen()),
                    _dashboardCard(
                        label: "Upload Receipts",
                        icon: Icons.receipt_long,
                        destination: const UploadReceiptsScreen()),
                    _dashboardCard(
                        label: "Notes",
                        icon: Icons.note_add,
                        destination: const NotesScreen()),
                    _dashboardCard(
                        label: "Stats",
                        icon: Icons.bar_chart,
                        destination: const StatsScreen()),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _dashboardCard({
    required String label,
    required IconData icon,
    required Widget destination,
  }) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => destination),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFF2A2D40), Color(0xFF1E1F2F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 6)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.deepPurpleAccent, size: 36),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            )
          ],
        ),
      ),
    );
  }
}
