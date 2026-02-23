import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class ChatController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Receiver এর তথ্য
  late String receiverId;
  late String receiverName;
  String? receiverPhoto;

  // Chat room ID
  late String chatRoomId;

  // Online status observable
  var isReceiverOnline = false.obs;

  // Constructor দিয়ে receiver info নেওয়া
  void initializeChat(String recId, String recName, String? recPhoto) {
    receiverId = recId;
    receiverName = recName;
    receiverPhoto = recPhoto;
    chatRoomId = _getChatRoomId(_auth.currentUser!.uid, receiverId);
    
    // Online status listen করা শুরু
    _listenToReceiverStatus();
    
    // নিজেকে online করা
    _setMyStatus(true);
  }

  @override
  void onClose() {
    // Controller close হলে offline করা
    _setMyStatus(false);
    super.onClose();
  }

  // Chat Room ID তৈরি করা (দুজনের মধ্যে unique)
  String _getChatRoomId(String userId1, String userId2) {
    List<String> ids = [userId1, userId2];
    ids.sort();
    return ids.join("_");
  }

  // Receiver এর online status listen করা
  void _listenToReceiverStatus() {
    _firestore
        .collection('users')
        .doc(receiverId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        var data = snapshot.data() as Map<String, dynamic>;
        isReceiverOnline.value = data['isOnline'] ?? false;
      }
    });
  }

  // নিজের online/offline status set করা
  Future<void> _setMyStatus(bool isOnline) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return;

      await _firestore.collection('users').doc(currentUser.uid).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Set status error: $e");
    }
  }

  // App lifecycle এর জন্য status update
  void updateMyStatus(bool isOnline) {
    _setMyStatus(isOnline);
  }

  // মেসেজ পাঠানোর ফাংশন
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) {
      Get.snackbar(
        "Warning",
        "Message cannot be empty!",
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Message data তৈরি করা
      Map<String, dynamic> messageData = {
        'message': text.trim(),
        'senderId': currentUser.uid,
        'receiverId': receiverId,
        'senderName': currentUser.displayName ?? "Unknown",
        'senderImage': currentUser.photoURL ?? "",
        'timestamp': FieldValue.serverTimestamp(),
        'isSeen': false, // isSeen এ পরিবর্তন করা (ChatScreen এর সাথে match করার জন্য)
      };

      // Chat room এ message save করা
      await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .add(messageData);

      // Chat room এর last message update করা
      await _firestore.collection('chat_rooms').doc(chatRoomId).set({
        'lastMessage': text.trim(),
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': currentUser.uid,
        'participants': [currentUser.uid, receiverId],
        'participantsInfo': {
          currentUser.uid: {
            'name': currentUser.displayName ?? "Unknown",
            'photoUrl': currentUser.photoURL ?? "",
          },
          receiverId: {
            'name': receiverName,
            'photoUrl': receiverPhoto ?? "",
          },
        },
      }, SetOptions(merge: true));

    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to send message: $e",
        snackPosition: SnackPosition.BOTTOM,
      );
      print("Send message error: $e");
    }
  }

  // রিয়েল-টাইম মেসেজ পাওয়ার স্ট্রিম
  Stream<QuerySnapshot> getMessages() {
    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Message seen করা
  Future<void> markMessagesAsSeen() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // যে messages আমি পাঠাইনি এবং এখনো unseen
      var unseenMessages = await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .where('receiverId', isEqualTo: currentUser.uid)
          .where('isSeen', isEqualTo: false)
          .get();

      // Batch update করা (efficient)
      WriteBatch batch = _firestore.batch();
      for (var doc in unseenMessages.docs) {
        batch.update(doc.reference, {'isSeen': true});
      }
      await batch.commit();
      
    } catch (e) {
      print("Mark as seen error: $e");
    }
  }

  // Unseen message count
  Stream<int> getUnseenCount() {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value(0);

    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .where('receiverId', isEqualTo: currentUser.uid)
        .where('isSeen', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Receiver এর online status পাওয়া
  Stream<bool> getReceiverOnlineStatus() {
    return _firestore
        .collection('users')
        .doc(receiverId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        var data = snapshot.data() as Map<String, dynamic>;
        return data['isOnline'] ?? false;
      }
      return false;
    });
  }

  // User typing indicator
  Future<void> setTyping(bool isTyping) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return;

      await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .update({
        'typing_${currentUser.uid}': isTyping,
        'typingTimestamp_${currentUser.uid}': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Typing indicator error: $e");
    }
  }

  // Receiver typing status পাওয়া
  Stream<bool> getReceiverTypingStatus() {
    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        var data = snapshot.data() as Map<String, dynamic>;
        return data['typing_$receiverId'] ?? false;
      }
      return false;
    });
  }

  // Message delete করা
  Future<void> deleteMessage(String messageId) async {
    try {
      await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .doc(messageId)
          .delete();

      Get.snackbar(
        "Success",
        "Message deleted",
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to delete message: $e",
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Last seen time পাওয়া
  Future<String> getReceiverLastSeen() async {
    try {
      var doc = await _firestore.collection('users').doc(receiverId).get();
      
      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;
        
        if (data['isOnline'] == true) {
          return "Online";
        }
        
        if (data['lastSeen'] != null) {
          Timestamp lastSeenTimestamp = data['lastSeen'];
          DateTime lastSeenDate = lastSeenTimestamp.toDate();
          DateTime now = DateTime.now();
          
          Duration difference = now.difference(lastSeenDate);
          
          if (difference.inMinutes < 1) {
            return "Just now";
          } else if (difference.inHours < 1) {
            return "${difference.inMinutes} min ago";
          } else if (difference.inDays < 1) {
            return "${difference.inHours} hours ago";
          } else {
            return "${difference.inDays} days ago";
          }
        }
      }
      
      return "Offline";
    } catch (e) {
      print("Get last seen error: $e");
      return "Offline";
    }
  }
}