import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:async';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  
  // Local fallback cache for development/offline scenarios
  final Map<String, Map<String, dynamic>> _localUserCache = {};
  final List<Map<String, dynamic>> _interactions = [];
  final List<Map<String, dynamic>> _chats = [];
  final List<Map<String, dynamic>> _messages = [];
  
  // Streams controllers
  final StreamController<List<Map<String, dynamic>>> _chatStreamController = StreamController.broadcast();
  final StreamController<List<Map<String, dynamic>>> _messagesStreamController = StreamController.broadcast();

  DatabaseService._init();

  /// Inserts a new user document
  Future<void> insertUser(Map<String, dynamic> userDetails) async {
    final email = userDetails['email'] as String;
    if (_localUserCache.containsKey(email)) {
      _localUserCache[email]!.addAll(userDetails);
    } else {
      _localUserCache[email] = Map<String, dynamic>.from(userDetails);
    }
  }

  /// Updates an existing user's profile
  Future<void> updateUserProfile(String email, Map<String, dynamic> profileData) async {
    if (_localUserCache.containsKey(email)) {
      _localUserCache[email]!.addAll(profileData);
    } else {
      _localUserCache[email] = Map<String, dynamic>.from(profileData);
    }
  }

  /// Retrieves all users
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    return _localUserCache.values.toList();
  }

  /// Retrieves a specific user
  Future<Map<String, dynamic>?> getUserProfile(String email) async {
    return _localUserCache[email];
  }

  /// Calculates real-time stats
  Future<Map<String, int>> getUserStats(String email) async {
    int likesSent = _interactions.where((i) => i['from'] == email && i['isLike'] == true).length;
    int passesSent = _interactions.where((i) => i['from'] == email && i['isLike'] == false).length;
    int messagesSent = _messages.where((m) => m['senderId'] == email).length;
    final userDoc = await getUserProfile(email);
    int snakeScore = userDoc?['snake_high_score'] ?? 0;

    return {
      'likes_sent': likesSent,
      'passes_sent': passesSent,
      'messages_sent': messagesSent,
      'snake_score': snakeScore,
    };
  }

  /// Deletes a user account
  Future<void> deleteUser(String email) async {
    _localUserCache.remove(email);
  }

  /// Updates snake score
  Future<void> updateSnakeHighScore(String email, int newScore) async {
    final userProfile = await getUserProfile(email);
    final int currentHigh = userProfile?['snake_high_score'] ?? 0;
    if (newScore > currentHigh) {
      if (_localUserCache.containsKey(email)) {
        _localUserCache[email]!['snake_high_score'] = newScore;
      }
    }
  }

  /// Gets leaderboard
  Future<List<Map<String, dynamic>>> getSnakeLeaderboard() async {
    final List<Map<String, dynamic>> allUsers = _localUserCache.values.toList();
    allUsers.sort((a, b) {
      int scoreA = a['snake_high_score'] ?? 0;
      int scoreB = b['snake_high_score'] ?? 0;
      return scoreB.compareTo(scoreA); // Descending
    });
    return allUsers.take(10).toList();
  }

  Future<String?> uploadProfilePicture(String email, {File? file, Uint8List? bytes}) async {
    try {
      Uint8List? imageBytes = bytes;
      if (imageBytes == null && file != null) {
        imageBytes = await file.readAsBytes();
      }
      if (imageBytes == null) return null;
      
      final base64String = base64Encode(imageBytes);
      final dataUrl = 'data:image/jpeg;base64,$base64String';
      
      if (_localUserCache.containsKey(email)) {
        _localUserCache[email]!['avatar_path'] = dataUrl;
      }
      return dataUrl;
    } catch (e) {
      return null;
    }
  }

  Future<void> recordInteraction(String myEmail, String targetEmail, bool isLike) async {
    // remove existing interaction if it exists
    _interactions.removeWhere((i) => i['from'] == myEmail && i['to'] == targetEmail);
    _interactions.add({
      'from': myEmail,
      'to': targetEmail,
      'isLike': isLike,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<bool> checkMutualMatch(String myEmail, String targetEmail) async {
    return _interactions.any((i) => i['from'] == targetEmail && i['to'] == myEmail && i['isLike'] == true);
  }

  Future<void> removeInteraction(String myEmail, String targetEmail) async {
    _interactions.removeWhere((i) => i['from'] == myEmail && i['to'] == targetEmail);
  }

  Future<List<String>> getSwipedUsers(String myEmail) async {
    return _interactions.where((i) => i['from'] == myEmail).map((i) => i['to'] as String).toList();
  }

  Future<List<String>> getUsersWhoLikedMe(String currentUserEmail) async {
    return _interactions.where((i) => i['to'] == currentUserEmail && i['isLike'] == true).map((i) => i['from'] as String).toList();
  }

  Future<List<Map<String, dynamic>>> getLikedUsers(String myEmail) async {
    List<String> likedEmails = _interactions.where((i) => i['from'] == myEmail && i['isLike'] == true).map((i) => i['to'] as String).toList();
    List<Map<String, dynamic>> likedProfiles = [];
    for (String email in likedEmails) {
      if (_localUserCache.containsKey(email)) {
        likedProfiles.add(_localUserCache[email]!);
      }
    }
    return likedProfiles;
  }

  String getChatId(String user1, String user2) {
    if (user1.compareTo(user2) > 0) {
      return '${user1}_$user2';
    } else {
      return '${user2}_$user1';
    }
  }

  Future<void> sendMessage(String senderEmail, String receiverEmail, String text, {String? imageUrl}) async {
    final chatId = getChatId(senderEmail, receiverEmail);
    final existingChatIndex = _chats.indexWhere((c) => c['id'] == chatId);
    
    final chatData = {
      'id': chatId,
      'participants': [senderEmail, receiverEmail],
      'lastMessage': imageUrl != null ? '📷 Image' : text,
      'lastMessageTime': DateTime.now().toIso8601String(),
      'lastSender': senderEmail,
    };

    if (existingChatIndex >= 0) {
      _chats[existingChatIndex] = chatData;
    } else {
      _chats.add(chatData);
    }

    _messages.add({
      'chatId': chatId,
      'senderId': senderEmail,
      'receiverId': receiverEmail,
      'text': text,
      'imageUrl': imageUrl,
      'timestamp': DateTime.now().toIso8601String(),
    });

    _notifyChatsUpdated();
    _notifyMessagesUpdated();
  }

  void _notifyChatsUpdated() {
    _chatStreamController.add(_chats);
  }

  void _notifyMessagesUpdated() {
    _messagesStreamController.add(_messages);
  }

  Stream<List<Map<String, dynamic>>> getUserChatsStream(String email) {
    // Send immediate initial data then listen
    Future.microtask(() => _notifyChatsUpdated());
    return _chatStreamController.stream.map((chats) => 
      chats.where((c) => (c['participants'] as List).contains(email)).toList()
        ..sort((a, b) => (b['lastMessageTime'] as String).compareTo(a['lastMessageTime'] as String))
    );
  }

  Stream<List<Map<String, dynamic>>> getChatStream(String chatId) {
    // Send immediate initial data then listen
    Future.microtask(() => _notifyMessagesUpdated());
    return _messagesStreamController.stream.map((msgs) => 
      msgs.where((m) => m['chatId'] == chatId).toList()
        ..sort((a, b) => (b['timestamp'] as String).compareTo(a['timestamp'] as String)) // Descending
    );
  }
  
  Future<void> seedDummyUsers() async {
    if (_localUserCache.containsKey('tester1@example.com')) return; 

    final List<String> availableInterests = ['Music', 'Art', 'Sports', 'Cooking', 'Travel', 'Photography', 'Gaming', 'Fitness'];
    final List<String> genders = ['Male', 'Female'];
    
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
        
        availableInterests.shuffle();
        final selectedInterests = availableInterests.take(4).toList();
        
        final age = 20 + (i % 10);
        final dob = DateTime.now().subtract(Duration(days: age * 365));

        _localUserCache[email] = {
          'email': email,
          'first_name': 'Tester',
          'last_name': '${i + 1}',
          'gender': genders[i % 2],
          'dob': dob.toIso8601String(),
          'avatar_path': photos[i],
          'interests': selectedInterests,
        };
      }
  }
}
