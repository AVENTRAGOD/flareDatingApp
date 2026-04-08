import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
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
      Uint8List bytes;
      if (kIsWeb) {
        bytes = await image.readAsBytes();
      } else {
        bytes = await File(image.path).readAsBytes();
      }
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
      backgroundColor: const Color(0xFFFDE8F5), // Light pink background
      body: Column(
        children: [
          _buildCustomHeader(),
          
          // Action Icons below Header
          Padding(
            padding: const EdgeInsets.only(top: 40, bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildCircularIcon(Icons.chat_bubble, Colors.blue),
                const SizedBox(width: 16),
                _buildCircularIcon(Icons.videocam, Colors.pink),
              ],
            ),
          ),
          
          const SizedBox(height: 8),

          // Messages Stream
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: DatabaseService.instance.getChatStream(_chatId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      'No messages yet. Start chatting!',
                      style: GoogleFonts.nunito(color: Colors.grey[600]),
                    ),
                  );
                }

                final docs = snapshot.data!;
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index];
                    final isMe = data['senderId'] == widget.currentUserEmail;
                    final text = data['text'] as String? ?? '';
                    final imageUrl = data['imageUrl'] as String?;
                    final timestampStr = data['timestamp'] as String?;
                    final dt = timestampStr != null ? DateTime.tryParse(timestampStr) : null;
                    
                    return _buildMessageBubble(isMe, text, imageUrl, dt);
                  },
                );
              },
            ),
          ),

          // Input Bar
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildCustomHeader() {
    return SizedBox(
      height: 200,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 120,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF14C86), Color(0xFFC76CD9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0, top: 4.0),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _resolveAvatar(widget.targetUserAvatar) == null ? const Color(0xFF322369) : Colors.grey[300],
                        shape: BoxShape.circle,
                        image: _resolveAvatar(widget.targetUserAvatar) != null
                            ? DecorationImage(
                                image: _resolveAvatar(widget.targetUserAvatar)!,
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _resolveAvatar(widget.targetUserAvatar) == null
                        ? const Icon(Icons.person, color: Colors.white, size: 40)
                        : null,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.targetUserName,
                      style: GoogleFonts.nunito(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF322369),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFF20D04A),
                        shape: BoxShape.circle,
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildMessageBubble(bool isMe, String text, String? imageUrl, DateTime? dt) {
    String timeStr = '';
    if (dt != null) {
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      final min = dt.minute.toString().padLeft(2, '0');
      timeStr = '$hour:$min $ampm';
    }

    return Padding(
      padding: EdgeInsets.only(
        top: 8.0,
        bottom: 8.0,
        left: isMe ? 60.0 : 0.0,
        right: isMe ? 0.0 : 60.0,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isMe ? Colors.white : const Color(0xFFE8D7E8), // Pinkish tint for receiver
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: isMe ? const Radius.circular(20) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 5,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isMe ? "You" : widget.targetUserName.split(' ').first,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: isMe ? const Color(0xFF322369) : const Color(0xFFF14C86),
                  ),
                ),
                Text(
                  timeStr,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: isMe ? const Color(0xFF8B51E5) : Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Image Attachment
            if (imageUrl != null && imageUrl.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Builder(builder: (context) {
                    final imgProvider = _resolveAvatar(imageUrl);
                    if (imgProvider != null) {
                      return Image(image: imgProvider, fit: BoxFit.cover);
                    }
                    return const SizedBox.shrink();
                  }),
                ),
              ),

            // Text
            if (text.isNotEmpty)
              Text(
                text,
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  color: const Color(0xFF322369),
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12).copyWith(
        bottom: 12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _msgController,
              keyboardType: TextInputType.text, // Setting generic type. Native emoji accessible via system keyboard.
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF322369),
              ),
              decoration: InputDecoration(
                hintText: 'Type Message',
                hintStyle: GoogleFonts.nunito(
                  color: const Color(0xFF322369).withOpacity(0.5),
                  fontWeight: FontWeight.w600,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          
          // Send Text Button
          IconButton(
            icon: const Icon(Icons.send, color: Color(0xFF322369)),
            onPressed: () => _sendMessage(),
          ),
          
          // Real Emoji Button (Focuses Keyboard)
          IconButton(
            icon: const Icon(Icons.emoji_emotions, color: Color(0xFFC76CD9)),
            // This pops a manual snackbar if they wanted a custom drawer, 
            // but the user requested native keyboard, so we just tap to focus.
            // On real devices, users just change their keyboard.
            onPressed: () {
               FocusScope.of(context).unfocus();
               Future.delayed(const Duration(milliseconds: 100), () {
                 FocusScope.of(context).requestFocus();
               });
            },
          ),

          // Attachment Button
          IconButton(
            icon: const Icon(Icons.attach_file, color: Color(0xFFC76CD9)),
            onPressed: _pickAndSendImage,
          ),
        ],
      ),
    );
  }
  ImageProvider? _resolveAvatar(String path) {
    if (path.isEmpty) return null;
    if (path.startsWith('data:image')) {
      try { return MemoryImage(base64Decode(path.split(',').last)); } catch (_) { return null; }
    }
    return NetworkImage(path);
  }
}
