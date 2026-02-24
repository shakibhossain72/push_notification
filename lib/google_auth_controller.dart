// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/foundation.dart';
// import 'package:get/get.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:test/auth_controller.dart';
// import 'package:test/home_screen.dart';
// import 'package:test/login_screen.dart';

// class GoogleAuthController extends GetxController {
//   static AuthController instance = Get.find();
//   final FirebaseAuth _auth = FirebaseAuth.instance;

//   // Correct initialization for version 6.2.1
//   final GoogleSignIn _googleSignIn = GoogleSignIn();

//   var user = Rxn<User>();
//   var isLoading = false.obs;

//   @override
//   void onInit() {
//     super.onInit();
//     user.bindStream(_auth.authStateChanges());
//     ever(user, _initialScreen);
//   }

//   void _initialScreen(User? user) {
//     if (user == null) {
//       Get.offAll(() => LoginScreen());
//     } else {
//       Get.offAll(() => HomeScreen());
//     }
//   }

//   // Google Sign In Method
//   Future<void> signInWithGoogle() async {
//     try {
//       isLoading.value = true;

//       // Google Sign In
//       final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

//       if (googleUser == null) {
//         isLoading.value = false;
//         return;
//       }

//       // Authentication details
//       final GoogleSignInAuthentication googleAuth =
//           await googleUser.authentication;

//       // Create credential
//       final credential = GoogleAuthProvider.credential(
//         accessToken: googleAuth.accessToken,
//         idToken: googleAuth.idToken,
//       );

//       // Sign in to Firebase
//       await _auth.signInWithCredential(credential);

//       Get.snackbar(
//         "Success",
//         "Login Successful!",
//         snackPosition: SnackPosition.TOP,      );
//     } catch (e) {
//       Get.snackbar(
//         "Error",
//         "Login Failed: ${e.toString()}",
//         snackPosition: SnackPosition.TOP,
//       );
//       if (kDebugMode) {
//         print("Google Sign In Error: $e");
//       }
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   // Sign Out
//   Future<void> signOut() async {
//     try {
//       await _googleSignIn.signOut();
//       await _auth.signOut();

//       Get.snackbar(
//         "Success",
//         "Logout Successful",
//         snackPosition: SnackPosition.TOP,
//       );
//     } catch (e) {
//       Get.snackbar(
//         "Error",
//         "Logout Failed: ${e.toString()}",
//         snackPosition: SnackPosition.TOP,
//       );
//     }
//   }
// }
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore ইম্পোর্ট করুন
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:test/home_screen.dart';
import 'package:test/login_screen.dart';
import 'package:test/user_list_screen.dart';

class GoogleAuthController extends GetxController {
  // static GoogleAuthController instance = Get.find(); // আপনার ক্লাস নাম অনুযায়ী আপডেট
  final FirebaseAuth _auth = FirebaseAuth.instance;
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
      Get.offAll(() => UserListScreen());
    }
  }

  // Google Sign In Method
  Future<void> signInWithGoogle() async {
    try {
      isLoading.value = true;

      // ১. গুগল সাইন ইন প্রসেস
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        isLoading.value = false;
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // ২. ফায়ারবেসে সাইন ইন
      UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      User? firebaseUser = userCredential.user;

      // ৩. সবচেয়ে জরুরি ধাপ: Firestore-এ ইউজার ডাটা সেভ করা (এটিই আপনার চ্যাট লিস্ট তৈরি করবে)
      if (firebaseUser != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUser.uid)
            .set({
              'uid': firebaseUser.uid,
              'name': firebaseUser.displayName ?? "No Name",
              'email': firebaseUser.email ?? "No Email",
              'photoUrl': firebaseUser.photoURL ?? "",
              'lastSeen':
                  FieldValue.serverTimestamp(), // রিয়েলটাইম স্ট্যাটাসের জন্য
            }, SetOptions(merge: true)); // merge: true দিলে আগের ডাটা হারাবে না
      }

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
