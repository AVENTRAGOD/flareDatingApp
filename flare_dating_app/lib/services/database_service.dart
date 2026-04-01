import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  DatabaseService._init();

  /// Inserts a new user document into the 'users' collection using their email as the Document ID.
  Future<void> insertUser(Map<String, dynamic> userDetails) async {
    try {
      final email = userDetails['email'] as String;
      // Merge adds or updates without overwriting existing unrelated fields
      await _firestore.collection('users').doc(email).set(
        userDetails,
        SetOptions(merge: true),
      );
    } catch (e) {
      print('Error inserting user to Firestore: $e');
      rethrow;
    }
  }

  /// Updates an existing user's profile with additional details
  Future<void> updateUserProfile(String email, Map<String, dynamic> profileData) async {
    try {
      await _firestore.collection('users').doc(email).update(profileData);
    } catch (e) {
      print('Error updating user profile in Firestore: $e');
      rethrow;
    }
  }

  /// Retrieves all users from the database 
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error getting users from Firestore: $e');
      return [];
    }
  }

  /// Retrieves a specific user by their email
  Future<Map<String, dynamic>?> getUserProfile(String email) async {
    try {
      final doc = await _firestore.collection('users').doc(email).get();
      if (doc.exists) return doc.data();
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  /// Deletes a user account from the database
  Future<void> deleteUser(String email) async {
    try {
      await _firestore.collection('users').doc(email).delete();
    } catch (e) {
      print('Error deleting user profile: $e');
      rethrow;
    }
  }

  /// Uploads a profile picture to Firebase Storage and returns the public download URL.
  Future<String?> uploadProfilePicture(String email, {File? file, Uint8List? bytes}) async {
    try {
      final ref = _storage.ref().child('profile_pictures').child('$email.jpg');
      
      if (bytes != null) {
        await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      } else if (file != null) {
        await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
      } else {
        return null;
      }
      
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading profile picture: $e');
      return null;
    }
  }

  /// Records a swipe interaction (like or dislike)
  Future<void> recordInteraction(String myEmail, String targetEmail, bool isLike) async {
    try {
      final interactionId = '${myEmail}_$targetEmail';
      await _firestore.collection('interactions').doc(interactionId).set({
        'from': myEmail,
        'to': targetEmail,
        'isLike': isLike,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error recording interaction: $e');
    }
  }

  /// Removes a like interaction (for the "X" button on matches page)
  Future<void> removeInteraction(String myEmail, String targetEmail) async {
    try {
      final interactionId = '${myEmail}_$targetEmail';
      await _firestore.collection('interactions').doc(interactionId).delete();
    } catch (e) {
      print('Error removing interaction: $e');
    }
  }

  /// Gets a list of emails that the current user has already swiped on (to prevent showing them again)
  Future<List<String>> getSwipedUsers(String myEmail) async {
    try {
      final snapshot = await _firestore
          .collection('interactions')
          .where('from', isEqualTo: myEmail)
          .get();
      return snapshot.docs.map((doc) => doc.data()['to'] as String).toList();
    } catch (e) {
      print('Error getting swiped users: $e');
      return [];
    }
  }

  /// Fetches a list of emails of users who swiped right on the currentUser
  Future<List<String>> getUsersWhoLikedMe(String currentUserEmail) async {
    try {
      final snapshot = await _firestore
          .collection('interactions')
          .where('to', isEqualTo: currentUserEmail)
          .where('isLike', isEqualTo: true)
          .get();
          
      return snapshot.docs.map((doc) => doc['from'] as String).toList();
    } catch (e) {
      print('Error getting users who liked me: $e');
      return [];
    }
  }

  /// Gets the full profiles of users that the current user swiped right on
  Future<List<Map<String, dynamic>>> getLikedUsers(String myEmail) async {
    try {
      final snapshot = await _firestore
          .collection('interactions')
          .where('from', isEqualTo: myEmail)
          .where('isLike', isEqualTo: true)
          .get();
          
      List<String> likedEmails = snapshot.docs.map((doc) => doc.data()['to'] as String).toList();
      
      if (likedEmails.isEmpty) return [];

      List<Map<String, dynamic>> likedProfiles = [];
      for (String email in likedEmails) {
        final userDoc = await _firestore.collection('users').doc(email).get();
        if (userDoc.exists) {
          likedProfiles.add(userDoc.data()!);
        }
      }
      return likedProfiles;
    } catch (e) {
      print('Error getting liked users: $e');
      return [];
    }
  }

  // ==========================================
  // CHAT & MESSAGING SYSTEM
  // ==========================================

  /// Generate a unique, consistent chat ID between two users
  String getChatId(String user1, String user2) {
    if (user1.compareTo(user2) > 0) {
      return '${user1}_$user2';
    } else {
      return '${user2}_$user1';
    }
  }

  /// Send a message (Text or Image) to a specific Chat ID
  Future<void> sendMessage(String senderEmail, String receiverEmail, String text, {String? imageUrl}) async {
    try {
      final chatId = getChatId(senderEmail, receiverEmail);
      
      // 1. Update the parent chat document with the latest info
      await _firestore.collection('chats').doc(chatId).set({
        'participants': [senderEmail, receiverEmail],
        'lastMessage': imageUrl != null ? '📷 Image' : text,
        'lastMessageTime': FieldValue.serverTimestamp(),
        // Setting up simple unread counter (can expand later)
        'lastSender': senderEmail,
      }, SetOptions(merge: true));

      // 2. Add the individual message to the messages subcollection
      await _firestore.collection('chats').doc(chatId).collection('messages').add({
        'senderId': senderEmail,
        'receiverId': receiverEmail,
        'text': text,
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  /// Get a real-time stream of all conversations a user is involved in
  Stream<QuerySnapshot> getUserChatsStream(String email) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: email)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  /// Get a real-time stream of messages inside a specific Chat Room
  Stream<QuerySnapshot> getChatStream(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // ==========================================
  // DUMMY SEEDER
  // ==========================================
  
  /// Injects 10 fake users into the database for testing Matchmaking algorithms
  Future<void> seedDummyUsers() async {
    try {
      final checkDoc = await _firestore.collection('users').doc('tester1@example.com').get();
      if (checkDoc.exists) return; // Already seeded

      final List<String> availableInterests = ['Music', 'Art', 'Sports', 'Cooking', 'Travel', 'Photography', 'Gaming', 'Fitness'];
      final List<String> genders = ['Male', 'Female'];
      
      // Some safe Unsplash images
      final List<String> photos = [
        'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?auto=format&fit=crop&q=80&w=600',
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=600',
        'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&q=80&w=600',
        'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&q=80&w=600',
        'https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?auto=format&fit=crop&q=80&w=600',
        'https://images.unsplash.com/photo-1488161628813-04466f872507?auto=format&fit=crop&q=80&w=600',
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&q=80&w=600',
        'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&q=80&w=600',
        'https://images.unsplash.com/photo-1513956589380-bad6acb9b9d4?auto=format&fit=crop&q=80&w=600',
        'https://images.unsplash.com/photo-1520813792240-56fc4a3765a7?auto=format&fit=crop&q=80&w=600',
      ];

      for (int i = 0; i < 10; i++) {
        final email = 'tester${i + 1}@example.com';
        
        // Randomly pick 3-4 interests
        availableInterests.shuffle();
        final selectedInterests = availableInterests.take(4).toList();
        
        // Generate a random valid DOB (approx 20-30 years old)
        final age = 20 + (i % 10);
        final dob = DateTime.now().subtract(Duration(days: age * 365));

        await _firestore.collection('users').doc(email).set({
          'email': email,
          'first_name': 'Tester',
          'last_name': '${i + 1}',
          'gender': genders[i % 2],
          'dob': dob.toIso8601String(),
          'avatar_path': photos[i],
          'interests': selectedInterests,
        });
      }
      print('✅ 10 Dummy Tester Profiles successfully seeded to Firestore!');
    } catch (e) {
      print('Error seeding dummy users: $e');
    }
  }
}
