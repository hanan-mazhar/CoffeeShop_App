import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Models/user_model.dart';
import 'notification_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // ── Sign Up ────────────────────────────────────────────────────────────────
  Future<String?> signUp({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String address,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = UserModel(
        uid: result.user!.uid,
        name: name,
        email: email,
        phone: phone,
        address: address,
        role: 'user',
      );

      await _db.collection('users').doc(result.user!.uid).set(user.toMap());

      // Start Firestore notification listener after signup
      NotificationService().startListening(result.user!.uid);

      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return 'This email is already registered.';
      } else if (e.code == 'weak-password') {
        return 'Password must be at least 6 characters.';
      }
      return e.message;
    }
  }

  // ── Login ─────────────────────────────────────────────────────────────────
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);

      // Start Firestore notification listener after login
      NotificationService().startListening(result.user!.uid);

      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        return 'Invalid email or password.';
      }
      return e.message;
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    await _auth.signOut();
  }

  // ── Get user data ─────────────────────────────────────────────────────────
  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ── Update profile ────────────────────────────────────────────────────────
  Future<bool> updateProfile({
    required String uid,
    required String name,
    required String phone,
    required String address,
  }) async {
    try {
      await _db.collection('users').doc(uid).update({
        'name': name,
        'phone': phone,
        'address': address,
      });
      return true;
    } catch (e) {
      return false;
    }
  }
}