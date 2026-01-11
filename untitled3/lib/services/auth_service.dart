import 'package:firebase_auth/firebase_auth.dart';

/// Service class for handling Firebase Authentication operations.
/// Provides methods for email/password login, registration, phone OTP, and logout.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Stream of authentication state changes.
  /// Listen to this to react to user sign-in/sign-out.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Get the current user, if any.
  User? get currentUser => _auth.currentUser;

  /// Sign in with email and password.
  /// Throws FirebaseAuthException on failure.
  Future<UserCredential> loginWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Register a new user with email and password.
  /// Throws FirebaseAuthException on failure.
  Future<UserCredential> registerWithEmail(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Send OTP to the given phone number.
  /// Returns the verification ID needed for sign-in.
  /// Throws FirebaseAuthException on failure.
  Future<String> sendOTP(String phoneNumber) async {
    String verificationId = '';
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Auto-sign in on Android (not always called)
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        throw e;
      },
      codeSent: (String verId, int? resendToken) {
        verificationId = verId;
      },
      codeAutoRetrievalTimeout: (String verId) {
        verificationId = verId;
      },
    );
    return verificationId;
  }

  /// Verify the OTP and sign in with phone.
  /// Throws FirebaseAuthException on failure.
  Future<UserCredential> verifyOTP(String verificationId, String smsCode) async {
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return await _auth.signInWithCredential(credential);
  }

  /// Sign out the current user.
  Future<void> logout() async {
    await _auth.signOut();
  }
}