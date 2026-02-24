import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:test/home_screen.dart';
import 'package:test/login_screen.dart';

class AuthController extends GetxController {
  static AuthController instance = Get.find();
  FirebaseAuth auth = FirebaseAuth.instance;

  // Helper: validate email format
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  // Signup
  void register(String email, String password, String name) async {
    email = email.trim();
    password = password.trim();
    name = name.trim();

    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      Get.snackbar("Error", "All fields are required");
      return;
    }

    if (!_isValidEmail(email)) {
      Get.snackbar("Error", "Invalid email format");
      return;
    }

    if (password.length < 6) {
      Get.snackbar("Error", "Password must be at least 6 characters");
      return;
    }

    try {
      UserCredential userCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await userCredential.user?.updateDisplayName(name);
      await userCredential.user?.reload();

      Get.snackbar("Success", "Registration successful!");
      Get.to(() => LoginScreen());
    } on FirebaseAuthException catch (e) {
      Get.snackbar("Error", e.message ?? "Something went wrong");
    } catch (e) {
      Get.snackbar("Error", "Unexpected error: $e");
    }
  }

  // Login
  void login(String email, String password) async {
    email = email.trim();
    password = password.trim();

    if (email.isEmpty || password.isEmpty) {
      Get.snackbar("Error", "Email and password are required");
      return;
    }

    if (!_isValidEmail(email)) {
      Get.snackbar("Error", "Invalid email format");
      return;
    }

    try {
      await auth.signInWithEmailAndPassword(email: email, password: password);
      Get.snackbar("Success", "Login successful!");
      Get.offAll(() => HomeScreen());
    } on FirebaseAuthException catch (e) {
      Get.snackbar("Error", e.message ?? "Something went wrong");
    } catch (e) {
      Get.snackbar("Error", "Unexpected error: $e");
    }
  }
}
