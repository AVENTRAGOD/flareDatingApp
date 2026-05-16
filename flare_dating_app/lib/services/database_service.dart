import 'dart:typed_data';
import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  final supabase = Supabase.instance.client;

  // Single source of truth for interest names to ensure matching works perfectly
  static const List<String> availableInterests = [
    'Photography',
    'Cooking',
    'Video Games',
    'Music',
    'Travelling',
    'Shopping',
    'Speeches',
    'Art & Crafts',
    'Swimming',
    'Drinking',
    'Extreme Sports',
    'Fitness',
  ];

  DatabaseService._init();

  Future<void> insertUser(Map<String, dynamic> userDetails) async {
    try {
      await supabase.from('users').upsert(userDetails);
    } catch (e) {
      print('Error inserting user: $e');
      rethrow;
    }
  }

  Future<void> updateUserProfile(
    String email,
    Map<String, dynamic> profileData,
  ) async {
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
    final res = await supabase
        .from('users')
        .select()
        .eq('email', email)
        .maybeSingle();
    return res;
  }

  Future<Map<String, int>> getUserStats(String email) async {
    try {
      final likesRes = await supabase
          .from('interactions')
          .select('from_email')
          .eq('from_email', email)
          .eq('is_like', true);
      final passesRes = await supabase
          .from('interactions')
          .select('from_email')
          .eq('from_email', email)
          .eq('is_like', false);

      // Messages might not have an 'id' column, so we select 'sender_id'
      final msgRes = await supabase
          .from('messages')
          .select('sender_id')
          .eq('sender_id', email);

      final userDoc = await getUserProfile(email);
      int snakeScore = userDoc?['snake_high_score'] ?? 0;
      int pongScore = userDoc?['pingpong_high_score'] ?? 0;

      return {
        'likes_sent': likesRes.length,
        'passes_sent': passesRes.length,
        'messages_sent': msgRes.length,
        'snake_score': snakeScore,
        'pong_score': pongScore,
      };
    } catch (e, stacktrace) {
      debugPrint('ERROR in getUserStats: $e');
      debugPrint('Stacktrace: $stacktrace');
      return {
        'likes_sent': 0,
        'passes_sent': 0,
        'messages_sent': 0,
        'snake_score': 0,
        'pong_score': 0,
      };
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

  Future<void> updatePongHighScore(String email, int newScore) async {
    final userProfile = await getUserProfile(email);
    final int currentHigh = userProfile?['pingpong_high_score'] ?? 0;
    if (newScore > currentHigh) {
      await updateUserProfile(email, {'pingpong_high_score': newScore});
    }
  }

  Future<List<Map<String, dynamic>>> getSnakeLeaderboard() async {
    final res = await supabase
        .from('users')
        .select()
        .not('snake_high_score', 'is', null)
        .order('snake_high_score', ascending: false)
        .limit(10);
    return List<Map<String, dynamic>>.from(res);
  }

  Future<List<Map<String, dynamic>>> getPongLeaderboard() async {
    final res = await supabase
        .from('users')
        .select()
        .not('pingpong_high_score', 'is', null)
        .order('pingpong_high_score', ascending: false)
        .limit(10);
    return List<Map<String, dynamic>>.from(res);
  }

  Future<String?> uploadProfilePicture(String email, {Uint8List? bytes}) async {
    try {
      if (bytes == null) return null;

      final fileName = '$email-${DateTime.now().millisecondsSinceEpoch}.jpg';
      await supabase.storage.from('avatars').uploadBinary(fileName, bytes);
      final publicUrl = supabase.storage.from('avatars').getPublicUrl(fileName);

      await updateUserProfile(email, {'avatar_path': publicUrl});
      return publicUrl;
    } catch (e) {
      print('Upload error: $e');
      return null;
    }
  }

  Future<void> recordInteraction(
    String myEmail,
    String targetEmail,
    bool isLike,
  ) async {
    try {
      final interactionId = '${myEmail}_$targetEmail';
      await supabase.from('interactions').upsert({
        'id': interactionId,
        'from_email': myEmail,
        'to_email': targetEmail,
        'is_like': isLike,
      });
    } catch (e) {
      print('Error recording interaction: $e');
    }
  }

  Future<void> forceMutualMatch(String myEmail, String targetEmail) async {
    try {
      await supabase.from('interactions').upsert([
        {
          'id': '${myEmail}_$targetEmail',
          'from_email': myEmail,
          'to_email': targetEmail,
          'is_like': true,
        },
        {
          'id': '${targetEmail}_$myEmail',
          'from_email': targetEmail,
          'to_email': myEmail,
          'is_like': true,
        },
      ]);
    } catch (e) {
      debugPrint('Error forcing mutual match: $e');
    }
  }

  Future<bool> checkMutualMatch(String myEmail, String targetEmail) async {
    try {
      final interactionId = '${targetEmail}_$myEmail';
      final response = await supabase
          .from('interactions')
          .select('is_like')
          .eq('id', interactionId)
          .maybeSingle();
      return response?['is_like'] == true;
    } catch (e) {
      print('Error checking mutual match: $e');
      return false;
    }
  }

  Future<void> removeInteraction(String myEmail, String targetEmail) async {
    try {
      final interactionId = '${myEmail}_$targetEmail';
      await supabase.from('interactions').delete().eq('id', interactionId);
    } catch (e) {
      print('Error removing interaction: $e');
    }
  }

  Future<List<String>> getSwipedUsers(String myEmail) async {
    try {
      final res = await supabase
          .from('interactions')
          .select('to_email')
          .eq('from_email', myEmail);
      return res.map((r) => r['to_email'] as String).toList();
    } catch (e) {
      print('Error getting swiped users: $e');
      return [];
    }
  }

  Future<List<String>> getUsersWhoLikedMe(String currentUserEmail) async {
    try {
      final res = await supabase
          .from('interactions')
          .select('from_email')
          .eq('to_email', currentUserEmail)
          .eq('is_like', true);
      return res.map((r) => r['from_email'] as String).toList();
    } catch (e) {
      print('Error getting users who liked me: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getLikedUsers(String myEmail) async {
    try {
      final res = await supabase
          .from('interactions')
          .select('to_email')
          .eq('from_email', myEmail)
          .eq('is_like', true);
      final List<String> likedEmails = res
          .map((r) => r['to_email'] as String)
          .toList();
      if (likedEmails.isEmpty) return [];

      final usersRes = await supabase
          .from('users')
          .select()
          .inFilter('email', likedEmails);
      return List<Map<String, dynamic>>.from(usersRes);
    } catch (e) {
      print('Error getting liked users: $e');
      return [];
    }
  }

  String getChatId(String user1, String user2) {
    if (user1.compareTo(user2) > 0) {
      return '${user1}_$user2';
    } else {
      return '${user2}_$user1';
    }
  }

  Future<void> sendMessage(
    String senderEmail,
    String receiverEmail,
    String text, {
    String? imageUrl,
    String? audioUrl,
  }) async {
    try {
      String? finalImageUrl;
      String? finalAudioUrl;

      // Handle Image Upload
      if (imageUrl != null && imageUrl.startsWith('data:image')) {
        final base64Data = imageUrl.split(',').last;
        final bytes = base64Decode(base64Data);
        final fileName = 'img_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await supabase.storage.from('chat_images').uploadBinary(fileName, bytes);
        finalImageUrl = supabase.storage.from('chat_images').getPublicUrl(fileName);
      } else {
        finalImageUrl = imageUrl;
      }

      // Handle Audio Upload
      if (audioUrl != null && audioUrl.startsWith('data:audio')) {
        final base64Data = audioUrl.split(',').last;
        final bytes = base64Decode(base64Data);
        final fileName = 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await supabase.storage.from('chat_images').uploadBinary(fileName, bytes);
        finalAudioUrl = supabase.storage.from('chat_images').getPublicUrl(fileName);
      } else {
        finalAudioUrl = audioUrl;
      }

      final chatId = getChatId(senderEmail, receiverEmail);

      // Upsert Chat Info (Last message preview)
      String lastMsgPreview = text;
      if (finalAudioUrl != null) lastMsgPreview = '🎤 Voice message';
      if (finalImageUrl != null) lastMsgPreview = '📷 Image';

      await supabase.from('chats').upsert({
        'id': chatId,
        'participants': [senderEmail, receiverEmail],
        'last_message': lastMsgPreview,
        'last_message_time': DateTime.now().toIso8601String(),
        'last_sender': senderEmail,
      });

      // Insert Message
      final messageData = {
        'chat_id': chatId,
        'sender_id': senderEmail,
        'receiver_id': receiverEmail,
        'text_content': text,
        'image_url': finalImageUrl,
        'audio_url': finalAudioUrl, // Note: Ensure this column exists in Supabase
      };

      await supabase.from('messages').insert(messageData);
      print('Message sent successfully to $chatId');
    } catch (e) {
      print('Critical error in sendMessage: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> getUserChatsStream(String email) {
    return supabase
        .from('chats')
        .stream(primaryKey: ['id'])
        .map((chats) {
          return chats.where((c) {
            final participants = List<String>.from(c['participants'] ?? []);
            return participants.contains(email);
          }).toList()..sort(
            (a, b) => (b['last_message_time'] as String? ?? '').compareTo(
              a['last_message_time'] as String? ?? '',
            ),
          );
        })
        .map((chats) {
          // Map to legacy property names for UI bindings
          return chats
              .map(
                (c) => {
                  ...c,
                  'lastMessage': c['last_message'],
                  'lastMessageTime': c['last_message_time'],
                },
              )
              .toList();
        });
  }

  Stream<List<Map<String, dynamic>>> getChatStream(String chatId) {
    return supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('created_at', ascending: false)
        .map((msgs) {
          // Map to legacy property names expected by UI
          return msgs
              .map(
                (m) => {
                  ...m,
                  'senderId': m['sender_id'],
                  'text': m['text_content'],
                  'imageUrl': m['image_url'],
                  'audioUrl': m['audio_url'],
                  'timestamp': m['created_at'],
                },
              )
              .toList();
        });
  }

  Future<void> seedDummyUsers() async {
    try {
      final List<String> testEmails = [
        'tester1@example.com',
        'nisalsayuranga0710@gmail.com',
      ];
      bool needsSeeding = false;
      for (var email in testEmails) {
        final existing = await getUserProfile(email);
        if (existing == null) {
          needsSeeding = true;
          break;
        }
      }

      if (!needsSeeding) {
        print('Seed: Dummy users already exist. Skipping.');
        return;
      }

      final List<String> genders = ['Male', 'Female'];
      final List<String> locations = [
        'New York, USA',
        'London, UK',
        'Tokyo, Japan',
        'Paris, France',
        'Berlin, Germany',
        'Sydney, Australia',
      ];

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

      final List<String> firstNames = [
        'Sarah',
        'Emma',
        'Jessica',
        'David',
        'Michael',
        'Chloe',
        'Daniel',
        'Olivia',
        'James',
        'Mia',
      ];
      final List<String> bios = [
        'Love traveling and exploring new cultures.',
        'Tech enthusiast and amateur photographer.',
        'Coffee lover and bookworm.',
        'Always up for a good adventure!',
        'Professional foodie and chef.',
        'Music is my life.',
        'Hiking and fitness are my passions.',
        'Art is where my heart is.',
        'Living life to the fullest.',
        'Dreaming big and working hard.',
      ];

      final Random random = Random();

      for (int i = 0; i < 10; i++) {
        final email = 'tester${i + 1}@example.com';

        final List<String> interestsPool = List.from(availableInterests)
          ..shuffle();
        final selectedInterests = interestsPool.take(4).toList();

        final age = 22 + (i % 8);
        final dob = DateTime.now().subtract(
          Duration(days: age * 365 + (i * 10)),
        );

        // Generate random high scores for the leaderboards
        final int randomSnakeScore = 5 + random.nextInt(45);
        final int randomPongScore = 5 + random.nextInt(35);

        await supabase.from('users').upsert({
          'email': email,
          'first_name': firstNames[i],
          'last_name': 'Tester',
          'gender': genders[i % 2],
          'dob': dob.toIso8601String(),
          'avatar_path': photos[i],
          'interests': selectedInterests,
          'location': locations[i % locations.length],
          'bio': bios[i],
          'snake_high_score': randomSnakeScore,
          'pingpong_high_score': randomPongScore,
        });
      }

      // Specifically seed the user's email if it doesn't exist
      await supabase.from('users').upsert({
        'email': 'nisalsayuranga0710@gmail.com',
        'first_name': 'Nisal',
        'last_name': 'Sayuranga',
        'gender': 'Male',
        'dob': DateTime(2000, 1, 1).toIso8601String(),
        'avatar_path': photos[3],
        'interests': ['Photography', 'Music', 'Travelling'],
        'location': 'Colombo, Sri Lanka',
        'bio': 'Flare Dating App Developer Extraordinaire!',
        'snake_high_score': 100,
        'pingpong_high_score': 85,
      });

      print('Seed: Successfully seeded 11 dummy users.');
    } catch (e) {
      print('Seed: Critical error during seeding: $e');
    }
  }
}
