import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  final supabase = Supabase.instance.client;

  DatabaseService._init();

  Future<void> insertUser(Map<String, dynamic> userDetails) async {
    try {
      await supabase.from('users').upsert(userDetails);
    } catch (e) {
      print('Error inserting user: $e');
    }
  }

  Future<void> updateUserProfile(String email, Map<String, dynamic> profileData) async {
    try {
      await supabase.from('users').update(profileData).eq('email', email);
    } catch (e) {
      print('Error updating user: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final res = await supabase.from('users').select();
    return List<Map<String, dynamic>>.from(res);
  }

  Future<Map<String, dynamic>?> getUserProfile(String email) async {
    final res = await supabase.from('users').select().eq('email', email).maybeSingle();
    return res;
  }

  Future<Map<String, int>> getUserStats(String email) async {
    try {
      final likesRes = await supabase.from('interactions').select('id').eq('from_email', email).eq('is_like', true);
      final passesRes = await supabase.from('interactions').select('id').eq('from_email', email).eq('is_like', false);
      final msgRes = await supabase.from('messages').select('id').eq('sender_id', email);
      
      final userDoc = await getUserProfile(email);
      int snakeScore = userDoc?['snake_high_score'] ?? 0;

      return {
        'likes_sent': likesRes.length,
        'passes_sent': passesRes.length,
        'messages_sent': msgRes.length,
        'snake_score': snakeScore,
      };
    } catch (e) {
      return {'likes_sent': 0, 'passes_sent': 0, 'messages_sent': 0, 'snake_score': 0};
    }
  }

  Future<void> deleteUser(String email) async {
    await supabase.from('users').delete().eq('email', email);
  }

  Future<void> updateSnakeHighScore(String email, int newScore) async {
    final userProfile = await getUserProfile(email);
    final int currentHigh = userProfile?['snake_high_score'] ?? 0;
    if (newScore > currentHigh) {
      await updateUserProfile(email, {'snake_high_score': newScore});
    }
  }

  Future<List<Map<String, dynamic>>> getSnakeLeaderboard() async {
    final res = await supabase.from('users').select().order('snake_high_score', ascending: false).limit(10);
    return List<Map<String, dynamic>>.from(res);
  }

  Future<String?> uploadProfilePicture(String email, {File? file, Uint8List? bytes}) async {
    try {
      Uint8List? imageBytes = bytes;
      if (imageBytes == null && file != null) {
        imageBytes = await file.readAsBytes();
      }
      if (imageBytes == null) return null;
      
      final fileName = '$email-${DateTime.now().millisecondsSinceEpoch}.jpg';
      await supabase.storage.from('avatars').uploadBinary(fileName, imageBytes);
      final publicUrl = supabase.storage.from('avatars').getPublicUrl(fileName);
      
      await updateUserProfile(email, {'avatar_path': publicUrl});
      return publicUrl;
    } catch (e) {
      print('Upload error: $e');
      return null;
    }
  }

  Future<void> recordInteraction(String myEmail, String targetEmail, bool isLike) async {
    final interactionId = '${myEmail}_$targetEmail';
    await supabase.from('interactions').upsert({
      'id': interactionId,
      'from_email': myEmail,
      'to_email': targetEmail,
      'is_like': isLike,
    });
  }

  Future<bool> checkMutualMatch(String myEmail, String targetEmail) async {
    final interactionId = '${targetEmail}_$myEmail';
    final response = await supabase.from('interactions').select('is_like').eq('id', interactionId).maybeSingle();
    return response?['is_like'] == true;
  }

  Future<void> removeInteraction(String myEmail, String targetEmail) async {
    final interactionId = '${myEmail}_$targetEmail';
    await supabase.from('interactions').delete().eq('id', interactionId);
  }

  Future<List<String>> getSwipedUsers(String myEmail) async {
    final res = await supabase.from('interactions').select('to_email').eq('from_email', myEmail);
    return res.map((r) => r['to_email'] as String).toList();
  }

  Future<List<String>> getUsersWhoLikedMe(String currentUserEmail) async {
    final res = await supabase.from('interactions').select('from_email').eq('to_email', currentUserEmail).eq('is_like', true);
    return res.map((r) => r['from_email'] as String).toList();
  }

  Future<List<Map<String, dynamic>>> getLikedUsers(String myEmail) async {
    final res = await supabase.from('interactions').select('to_email').eq('from_email', myEmail).eq('is_like', true);
    final List<String> likedEmails = res.map((r) => r['to_email'] as String).toList();
    if (likedEmails.isEmpty) return [];
    
    final usersRes = await supabase.from('users').select().inFilter('email', likedEmails);
    return List<Map<String, dynamic>>.from(usersRes);
  }

  String getChatId(String user1, String user2) {
    if (user1.compareTo(user2) > 0) {
      return '${user1}_$user2';
    } else {
      return '${user2}_$user1';
    }
  }

  Future<void> sendMessage(String senderEmail, String receiverEmail, String text, {String? imageUrl}) async {
    try {
      String? finalImageUrl;
      if (imageUrl != null && imageUrl.startsWith('data:image')) {
        final base64Data = imageUrl.split(',').last;
        final bytes = base64Decode(base64Data);
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        await supabase.storage.from('chat_images').uploadBinary(fileName, bytes);
        finalImageUrl = supabase.storage.from('chat_images').getPublicUrl(fileName);
      } else {
        finalImageUrl = imageUrl;
      }

      final chatId = getChatId(senderEmail, receiverEmail);
      
      // Upsert Chat Info
      await supabase.from('chats').upsert({
        'id': chatId,
        'participants': [senderEmail, receiverEmail],
        'last_message': finalImageUrl != null ? '📷 Image' : text,
        'last_message_time': DateTime.now().toIso8601String(),
        'last_sender': senderEmail,
      });

      // Insert Message
      await supabase.from('messages').insert({
        'chat_id': chatId,
        'sender_id': senderEmail,
        'receiver_id': receiverEmail,
        'text_content': text,
        'image_url': finalImageUrl,
      });
    } catch (e) {
      print('Send msg error: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> getUserChatsStream(String email) {
    return supabase.from('chats').stream(primaryKey: ['id']).map((chats) {
      return chats.where((c) {
        final participants = List<String>.from(c['participants'] ?? []);
        return participants.contains(email);
      }).toList()..sort((a, b) => (b['last_message_time'] as String? ?? '').compareTo(a['last_message_time'] as String? ?? ''));
    }).map((chats) {
        // Map to legacy property names for UI bindings
        return chats.map((c) => {
            ...c, 
            'lastMessage': c['last_message'],
            'lastMessageTime': c['last_message_time']
        }).toList();
    });
  }

  Stream<List<Map<String, dynamic>>> getChatStream(String chatId) {
    return supabase.from('messages').stream(primaryKey: ['id']).eq('chat_id', chatId).order('created_at', ascending: false).map((msgs) {
        // Map to legacy property names expected by UI
        return msgs.map((m) => {
            ...m,
            'senderId': m['sender_id'],
            'text': m['text_content'],
            'imageUrl': m['image_url'],
            'timestamp': m['created_at']
        }).toList();
    });
  }
  
  Future<void> seedDummyUsers() async {
    final existing = await getUserProfile('tester1@example.com');
    if (existing != null) return; 

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

        await supabase.from('users').upsert({
          'email': email,
          'first_name': 'Tester',
          'last_name': '${i + 1}',
          'gender': genders[i % 2],
          'dob': dob.toIso8601String(),
          'avatar_path': photos[i],
          'interests': selectedInterests,
        });
      }
  }
}
