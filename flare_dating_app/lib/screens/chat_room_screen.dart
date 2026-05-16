import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../services/database_service.dart';

class ChatRoomScreen extends StatefulWidget {
  final String currentUserEmail;
  final String targetUserEmail;
  final String targetUserName;
  final String targetUserAvatar;

  const ChatRoomScreen({
    super.key,
    required this.currentUserEmail,
    required this.targetUserEmail,
    required this.targetUserName,
    required this.targetUserAvatar,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _msgController = TextEditingController();
  late final String _chatId;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _chatId = DatabaseService.instance.getChatId(widget.currentUserEmail, widget.targetUserEmail);
  }

  Future<void> _sendMessage({String? imageUrl}) async {
    final text = _msgController.text.trim();
    if (text.isEmpty && imageUrl == null) return;

    _msgController.clear();
    await DatabaseService.instance.sendMessage(
      widget.currentUserEmail,
      widget.targetUserEmail,
      text,
      imageUrl: imageUrl,
    );
  }

  Future<void> _pickAndSendImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 60);
      if (image == null) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sending image...'), duration: Duration(seconds: 1)),
      );

      // Encode image as base64 and embed inline — no Firebase Storage needed
      final bytes = await image.readAsBytes();
      final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      _sendMessage(imageUrl: base64String);
    } catch (e) {
      debugPrint('Error sending chat image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send image')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topLeft,
                  radius: 1.5,
                  colors: [Color(0xFF1A1635), Color(0xFF0D0B1F)],
                ),
              ),
            ),
          ),
          
          Column(
            children: [
              _buildCustomHeader(),
              
              // Messages Stream
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: DatabaseService.instance.getChatStream(_chatId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFFF14C86)));
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline_rounded, size: 48, color: Colors.white.withOpacity(0.1)),
                            const SizedBox(height: 16),
                            Text(
                              'Start your story...',
                              style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.3)),
                            ),
                          ],
                        ),
                      );
                    }

                    final docs = snapshot.data!;
                    return ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index];
                        final isMe = data['senderId'] == widget.currentUserEmail;
                        final text = data['text'] as String? ?? '';
                        final imageUrl = data['imageUrl'] as String?;
                        final dt = data['timestamp'] != null ? DateTime.tryParse(data['timestamp']) : null;
                        
                        return _buildMessageBubble(isMe, text, imageUrl, dt);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          
          // Floating Input Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildInputBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomHeader() {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, bottom: 16, left: 8, right: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF16122D).withOpacity(0.8),
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFF14C86).withOpacity(0.3), width: 1.5),
              image: _resolveAvatar(widget.targetUserAvatar) != null
                  ? DecorationImage(image: _resolveAvatar(widget.targetUserAvatar)!, fit: BoxFit.cover)
                  : null,
            ),
            child: _resolveAvatar(widget.targetUserAvatar) == null
                ? const Icon(Icons.person_rounded, color: Colors.white, size: 20)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.targetUserName,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: Color(0xFF00F5A0), shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Online',
                      style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF00F5A0).withOpacity(0.8)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.more_vert_rounded, color: Colors.white.withOpacity(0.5)),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(bool isMe, String text, String? imageUrl, DateTime? dt) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (imageUrl != null && imageUrl.isNotEmpty)
            Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image(image: _resolveAvatar(imageUrl)!, fit: BoxFit.cover),
              ),
            ),
          if (text.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
              decoration: BoxDecoration(
                gradient: isMe
                    ? const LinearGradient(
                        colors: [Color(0xFFF14C86), Color(0xFF8B51E5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isMe ? null : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isMe ? const Radius.circular(20) : Radius.zero,
                  bottomRight: isMe ? Radius.zero : const Radius.circular(20),
                ),
                border: isMe ? null : Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Text(
                text,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        height: 60,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.add_rounded, color: Colors.white.withOpacity(0.5)),
                    onPressed: _pickAndSendImage,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      style: GoogleFonts.outfit(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Message...',
                        hintStyle: GoogleFonts.outfit(color: Colors.white.withOpacity(0.3)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _sendMessage(),
                    child: Container(
                      margin: const EdgeInsets.all(6),
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF14C86),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  ImageProvider? _resolveAvatar(String path) {
    if (path.isEmpty) return null;
    if (path.startsWith('data:image')) {
      try {
        return MemoryImage(base64Decode(path.split(',').last));
      } catch (_) {
        return null;
      }
    }
    return NetworkImage(path);
  }
}
