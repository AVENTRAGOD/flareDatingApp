import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database_service.dart';
import 'chat_room_screen.dart';

class ChatsListScreen extends StatefulWidget {
  final String currentUserEmail;

  const ChatsListScreen({super.key, required this.currentUserEmail});

  @override
  State<ChatsListScreen> createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends State<ChatsListScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDE8F5), // Light pinkish background
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Text(
                'All Messages',
                style: GoogleFonts.nunito(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF322369),
                ),
              ),
            ),
            
            // Chat List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: DatabaseService.instance.getUserChatsStream(widget.currentUserEmail),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        'No messages yet. Say hi to a match!',
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    );
                  }

                  final chatDocs = snapshot.data!.docs;

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: chatDocs.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final chatData = chatDocs[index].data() as Map<String, dynamic>;
                      final participants = List<String>.from(chatData['participants'] ?? []);
                      
                      // Find the other person's email
                      final targetEmail = participants.firstWhere(
                        (email) => email != widget.currentUserEmail,
                        orElse: () => widget.currentUserEmail,
                      );

                      final lastMessage = chatData['lastMessage'] as String? ?? '';
                      final lastMessageTime = chatData['lastMessageTime'] as Timestamp?;
                      
                      return _buildChatCardTile(
                        context: context,
                        targetEmail: targetEmail,
                        lastMessage: lastMessage,
                        lastMessageTime: lastMessageTime,
                        chatId: chatDocs[index].id,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatCardTile({
    required BuildContext context,
    required String targetEmail,
    required String lastMessage,
    required Timestamp? lastMessageTime,
    required String chatId,
  }) {
    // Format time roughly
    String timeString = '';
    if (lastMessageTime != null) {
      final dt = lastMessageTime.toDate();
      final now = DateTime.now();
      if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
        // Today: display hours
        final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
        final ampm = dt.hour >= 12 ? 'PM' : 'AM';
        final minute = dt.minute.toString().padLeft(2, '0');
        timeString = '$hour:$minute $ampm';
      } else if (dt.year == now.year && dt.month == now.month && dt.day == now.day - 1) {
        timeString = 'Yesterday';
      } else {
        timeString = '${dt.month}/${dt.day}';
      }
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(targetEmail).get(),
      builder: (context, userSnapshot) {
        String name = 'Loading...';
        String avatarPath = '';
        
        if (userSnapshot.hasData && userSnapshot.data != null && userSnapshot.data!.exists) {
          final userData = userSnapshot.data!.data() as Map<String, dynamic>;
          final first = userData['first_name']?.toString() ?? 'User';
          final last = userData['last_name']?.toString() ?? '';
          name = '$first $last'.trim();
          avatarPath = userData['avatar_path']?.toString() ?? '';
        }

        return GestureDetector(
          onTap: () {
            // Navigate to Chat Room
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatRoomScreen(
                  currentUserEmail: widget.currentUserEmail,
                  targetUserEmail: targetEmail,
                  targetUserName: name,
                  targetUserAvatar: avatarPath,
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Avatar (Rounded Rectangle like Figma)
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: avatarPath.isEmpty ? const Color(0xFF322369) : Colors.grey[300],
                    borderRadius: BorderRadius.circular(16),
                    image: avatarPath.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(avatarPath),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: avatarPath.isEmpty 
                    ? const Icon(Icons.person, color: Colors.white, size: 30)
                    : null,
                ),
                
                const SizedBox(width: 16),
                
                // Name and Last Message
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: GoogleFonts.nunito(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF322369),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Green online dot
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Color(0xFF20D04A), // Figma green dot
                              shape: BoxShape.circle,
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        lastMessage,
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Time and Unread Badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      timeString,
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFA59BCA), // Light purple text
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Figma unread badge dummy
                    // In real life, calculate this. For now, empty or small pink circle
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
