import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:test/auth_controller.dart';
import 'package:test/home_screen.dart';
import 'package:test/login_screen.dart';

class GoogleAuthController extends GetxController {
  static AuthController instance = Get.find();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Correct initialization for version 6.2.1
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  var user = Rxn<User>();
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    user.bindStream(_auth.authStateChanges());
    ever(user, _initialScreen);
  }

  void _initialScreen(User? user) {
    if (user == null) {
      Get.offAll(() => LoginScreen());
    } else {
      Get.offAll(() => HomeScreen());
    }
  }

  // Google Sign In Method
  Future<void> signInWithGoogle() async {
    try {
      isLoading.value = true;

      // Google Sign In
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        isLoading.value = false;
        return;
      }

      // Authentication details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      await _auth.signInWithCredential(credential);

      Get.snackbar(
        "Success",
        "Login Successful!",
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Login Failed: ${e.toString()}",
        snackPosition: SnackPosition.TOP,
      );
      if (kDebugMode) {
        print("Google Sign In Error: $e");
      }
    } finally {
      isLoading.value = false;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();

      Get.snackbar(
        "Success",
        "Logout Successful",
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Logout Failed: ${e.toString()}",
        snackPosition: SnackPosition.TOP,
      );
    }
  }
}
