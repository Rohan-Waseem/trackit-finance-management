import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔐 Login with email and password
  Future<User?> loginWithEmail(String email, String password) async {
    try {
      UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return cred.user;
    } catch (e) {
      print("Login error: $e");
      return null;
    }
  }

  // 📝 Sign up and save extra user data
  Future<User?> signUpWithEmail({
    required String name,
    required String email,
    required String phone,
    required String dob,
    required String password,
  }) async {
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore.collection('users').doc(cred.user!.uid).set({
        'name': name,
        'email': email,
        'phone': phone,
        'dob': dob,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return cred.user;
    } catch (e) {
      print("Signup error: $e");
      return null;
    }
  }
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        return null; // User canceled
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      // Optional: Save user to Firestore if new
      final user = userCredential.user;
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
          'name': user.displayName,
          'email': user.email,
          'phone': user.phoneNumber ?? '',
          'dob': '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return user;
    } catch (e) {
      print("Google sign-in error: $e");
      return null;
    }
  }
  // 🚪 Logout user
  Future<void> logout() async {
    await _auth.signOut();
  }
}
