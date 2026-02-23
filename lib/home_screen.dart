import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test/google_auth_controller.dart';
import 'package:test/notification_screen.dart';
import 'package:test/user_list_screen.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({super.key});
  final googleauth = Get.put(GoogleAuthController());
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  User? user;
  Map<String, dynamic> userData = {}; // always non-null
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    if (user == null) {
      if (kDebugMode) print("User is null. Please login first.");
      setState(() => isLoading = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      final data = doc.data();
      if (data != null) {
        setState(() {
          userData = data;
          isLoading = false;
        });
      } else {
        if (kDebugMode) print("No valid user data for uid: ${user!.uid}");
        setState(() {
          userData = {}; // empty map fallback
          isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) print("Error fetching user data: $e");
      Get.snackbar('Error', 'Unable to fetch user data');
      setState(() {
        userData = {}; // fallback
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = userData['name']?.toString() ?? 'User';
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Gradient header full top
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(24, topPadding + 24, 24, 40),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade700, Colors.blue.shade400],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Greeting
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Hello,',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            userName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          widget.googleauth.signOut();
                        },
                        child: Icon(Icons.logout_outlined, color: Colors.white),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Dashboard body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back, $userName!',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _featureCard('Profile', Icons.person, Colors.blue),
                            _featureCard(
                              'Messages',
                              Icons.message,
                              Colors.green,
                            ),
                            GestureDetector(
                              onTap: () {
                                Get.to(() => const UserListScreen());
                              },
                              child: _featureCard(
                                'Chat',
                                Icons.settings,
                                Colors.orange,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Get.to(() => NotificationsScreen());
                              },
                              child: _featureCard(
                                'Notifications',
                                Icons.notifications,
                                Colors.purple,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // Feature card widget
  Widget _featureCard(String title, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1), // Flutter 3.27+ compatible
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: color),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
