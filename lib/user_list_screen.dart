import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:test/chat_screen.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  // TextEditingController তৈরি করা
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    // Listener যোগ করা
    _searchController.addListener(() {
      setState(() {
        searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    // Controller dispose করা - এটি খুবই জরুরি
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Chats",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: 24,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          CircleAvatar(
            backgroundColor: Colors.grey.shade100,
            child: const Icon(Icons.camera_alt, color: Colors.black, size: 20),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            backgroundColor: Colors.grey.shade100,
            child: const Icon(Icons.edit, color: Colors.black, size: 20),
          ),
          const SizedBox(width: 15),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No users found."));
          }

          // সব ইউজার ফিল্টার করা (current user বাদে)
          var allUsers = snapshot.data!.docs.where((doc) {
            return doc.id != currentUserId;
          }).toList();

          // সার্চ অনুযায়ী ফিল্টার করা
          var filteredUsers = allUsers.where((doc) {
            var userData = doc.data() as Map<String, dynamic>;
            String name = (userData['name'] ?? "User").toString().toLowerCase();
            return name.contains(searchQuery.toLowerCase());
          }).toList();

          return Column(
            children: [
              // ১. সার্চ ফিল্ড
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 10,
                ),
                child: TextField(
                  controller: _searchController, // Controller যুক্ত করা
                  decoration: InputDecoration(
                    hintText: "Search",
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear(); // Clear করার button
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              // ২. অনলাইন রো (Horizontal) - শুধু যখন search নেই
              if (searchQuery.isEmpty)
                SizedBox(
                  height: 110,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemCount: allUsers.length,
                    itemBuilder: (context, index) {
                      var userData =
                          allUsers[index].data() as Map<String, dynamic>;
                      return _buildOnlineUserItem(userData, allUsers[index].id);
                    },
                  ),
                ),

              // ৩. মেইন চ্যাট লিস্ট (Vertical) - filtered users দেখানো
              Expanded(
                child: filteredUsers.isEmpty
                    ? const Center(child: Text("No users found"))
                    : ListView.builder(
                        itemCount: filteredUsers.length,
                        itemBuilder: (context, index) {
                          var userData =
                              filteredUsers[index].data()
                                  as Map<String, dynamic>;
                          return _buildChatTile(
                            currentUserId,
                            filteredUsers[index].id,
                            userData,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  // অনলাইন আইটেম (ওপরের রো)
  Widget _buildOnlineUserItem(Map<String, dynamic> userData, String userId) {
    bool isOnline = userData['isOnline'] ?? true;
    String? photoUrl = userData['photoUrl'];
    String name = userData['name'] ?? "User";

    return GestureDetector(
      onTap: () => _goToChat(userId, name, photoUrl),
      child: Container(
        width: 75,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        child: Column(
          children: [
            _buildAvatarWithBadge(photoUrl, isOnline, radius: 30),
            const SizedBox(height: 5),
            Text(
              name.split(" ")[0],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // চ্যাট টাইল (নিচের লিস্ট)
  Widget _buildChatTile(
    String currentUserId,
    String userId,
    Map<String, dynamic> userData,
  ) {
    bool isOnline = userData['isOnline'] ?? true;
    String name = userData['name'] ?? "User";

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(_getChatRoomId(currentUserId, userId))
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, msgSnapshot) {
        String lastMsg = "Start a conversation";
        String time = "";

        if (msgSnapshot.hasData && msgSnapshot.data!.docs.isNotEmpty) {
          var lastMsgData =
              msgSnapshot.data!.docs.first.data() as Map<String, dynamic>;
          lastMsg = lastMsgData['message'] ?? "";
          if (lastMsgData['timestamp'] != null) {
            time = DateFormat(
              'hh:mm a',
            ).format((lastMsgData['timestamp'] as Timestamp).toDate());
          }
        }

        return ListTile(
          onTap: () => _goToChat(userId, name, userData['photoUrl']),
          leading: _buildAvatarWithBadge(
            userData['photoUrl'],
            isOnline,
            radius: 28,
          ),
          title: Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(lastMsg, maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: Text(
            time,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        );
      },
    );
  }

  Widget _buildAvatarWithBadge(
    String? photoUrl,
    bool isOnline, {
    required double radius,
  }) {
    return Stack(
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: Colors.grey.shade200,
          backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
              ? NetworkImage(photoUrl)
              : null,
          child: (photoUrl == null || photoUrl.isEmpty)
              ? Icon(Icons.person, size: radius, color: Colors.grey)
              : null,
        ),
        Positioned(
          bottom: 1,
          right: 1,
          child: Container(
            height: radius * 0.4,
            width: radius * 0.4,
            decoration: BoxDecoration(
              color: isOnline ? Colors.green : Colors.grey.shade400,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  void _goToChat(String id, String name, String? photo) {
    Get.to(
      () =>
          ChatScreen(receiverId: id, receiverName: name, receiverPhoto: photo),
    );
  }

  String _getChatRoomId(String a, String b) {
    List<String> ids = [a, b];
    ids.sort();
    return ids.join("_");
  }
}
