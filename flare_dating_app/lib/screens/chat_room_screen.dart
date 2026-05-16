import 'dart:ui';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:io';
import '../services/database_service.dart';
import '../services/achievement_service.dart';

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
  
  // Voice Recording
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  String? _recordingPath;
  
  // Audio Playback
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Optimistic UI
  final List<Map<String, dynamic>> _pendingMessages = [];

  @override
  void initState() {
    super.initState();
    _chatId = DatabaseService.instance.getChatId(widget.currentUserEmail, widget.targetUserEmail);
    _msgController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _msgController.dispose();
    _recorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _sendMessage({String? imageUrl, String? audioUrl}) async {
    final text = _msgController.text.trim();
    if (text.isEmpty && imageUrl == null && audioUrl == null) return;

    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    final pendingMsg = {
      'id': tempId,
      'senderId': widget.currentUserEmail,
      'text': text,
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
      'timestamp': DateTime.now().toIso8601String(),
      'isPending': true,
    };

    setState(() {
      _pendingMessages.insert(0, pendingMsg);
      _msgController.clear();
    });

    try {
      await DatabaseService.instance.sendMessage(
        widget.currentUserEmail,
        widget.targetUserEmail,
        text,
        imageUrl: imageUrl,
        audioUrl: audioUrl,
      );
      
      // We don't remove from _pendingMessages immediately; 
      // the StreamBuilder will handle the "real" message arrival.
      
      if (mounted) {
        AchievementService.instance.checkAndNotify(widget.currentUserEmail, context);
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
      setState(() {
        _pendingMessages.removeWhere((m) => m['id'] == tempId);
      });
    }
  }

  Future<void> _pickAndSendImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 60);
      if (image == null) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sending image...'), duration: Duration(seconds: 1)),
      );

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

  Future<void> _startRecording() async {
    try {
      if (await _recorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
        const config = RecordConfig();
        await _recorder.start(config, path: path);
        
        setState(() {
          _isRecording = true;
          _recordingPath = path;
        });
      }
    } catch (e) {
      debugPrint('Start recording error: $e');
    }
  }

  Future<void> _stopAndSendRecording() async {
    try {
      final path = await _recorder.stop();
      setState(() => _isRecording = false);
      
      if (path != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sending voice message...'), duration: Duration(seconds: 1)),
        );
        
        // In a real app, upload this file. For now, we'll simulate by passing the path
        // and let DatabaseService handle the "audio" upload similar to images.
        // We'll read it as base64 for simplicity in this demo environment.
        final bytes = await File(path).readAsBytes();
        final base64Audio = 'data:audio/m4a;base64,${base64Encode(bytes)}';
        
        _sendMessage(audioUrl: base64Audio);
      }
    } catch (e) {
      debugPrint('Stop recording error: $e');
      setState(() => _isRecording = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
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
                        Icon(Icons.chat_bubble_outline_rounded, size: 64, color: Colors.grey[200]),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: GoogleFonts.nunito(color: Colors.grey[400], fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                final docs = snapshot.data!;
                
                // Merge pending messages with confirmed ones, avoiding duplicates
                final confirmedTexts = docs.map((d) => d['text']).toSet();
                final confirmedImages = docs.map((d) => d['imageUrl']).toSet();
                
                final displayPending = _pendingMessages.where((p) {
                  if (p['text'] != null && p['text'].isNotEmpty) return !confirmedTexts.contains(p['text']);
                  if (p['imageUrl'] != null) return !confirmedImages.contains(p['imageUrl']);
                  return true;
                }).toList();

                final allMessages = [...displayPending, ...docs];

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                  itemCount: allMessages.length,
                  itemBuilder: (context, index) {
                    final data = allMessages[index];
                    final isMe = data['senderId'] == widget.currentUserEmail;
                    final text = data['text'] as String? ?? '';
                    final imageUrl = data['imageUrl'] as String?;
                    final audioUrl = data['audioUrl'] as String?;
                    final dt = data['timestamp'] != null ? DateTime.tryParse(data['timestamp']) : null;
                    final isPending = data['isPending'] == true;
                    
                    return _buildMessageBubble(isMe, text, imageUrl, audioUrl, dt, isPending);
                  },
                );
              },
            ),
          ),
          
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildCustomHeader() {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, bottom: 16, left: 16, right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF333333), size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[100],
              image: _resolveAvatar(widget.targetUserAvatar) != null
                  ? DecorationImage(image: _resolveAvatar(widget.targetUserAvatar)!, fit: BoxFit.cover)
                  : null,
            ),
            child: _resolveAvatar(widget.targetUserAvatar) == null
                ? const Icon(Icons.person_rounded, color: Colors.grey, size: 20)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.targetUserName,
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF333333),
                  ),
                ),
                Text(
                  'Online',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: const Color(0xFF20D04A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.more_horiz_rounded, color: Colors.grey[400]),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(bool isMe, String text, String? imageUrl, String? audioUrl, DateTime? dt, bool isPending) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (imageUrl != null && imageUrl.isNotEmpty)
            Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image(image: _resolveAvatar(imageUrl)!, fit: BoxFit.cover),
              ),
            ),
            
          if (audioUrl != null && audioUrl.isNotEmpty)
            _buildAudioBubble(isMe, audioUrl),

          if (text.isNotEmpty)
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 14, 45, 14), // Added padding for ticks
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                  decoration: BoxDecoration(
                    gradient: isMe
                        ? const LinearGradient(
                            colors: [Color(0xFFF14C86), Color(0xFF8B51E5)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isMe ? null : const Color(0xFFF9F9F9),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(24),
                      topRight: const Radius.circular(24),
                      bottomLeft: isMe ? const Radius.circular(24) : Radius.zero,
                      bottomRight: isMe ? Radius.zero : const Radius.circular(24),
                    ),
                    border: isMe ? null : Border.all(color: Colors.grey[100]!),
                  ),
                  child: Text(
                    text,
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      color: isMe ? Colors.white : const Color(0xFF333333),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                
                // Status Ticks
                if (isMe)
                  Positioned(
                    bottom: 8,
                    right: 12,
                    child: Icon(
                      isPending ? Icons.done : Icons.done_all,
                      size: 14,
                      color: isPending ? Colors.white70 : Colors.white,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildAudioBubble(bool isMe, String audioUrl) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFFF14C86).withOpacity(0.1) : const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isMe ? const Color(0xFFF14C86).withOpacity(0.2) : Colors.grey[100]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.play_arrow_rounded, color: isMe ? const Color(0xFFF14C86) : Colors.grey[600]),
            onPressed: () async {
              // Simulating playback for now as audioUrl is base64 or publicUrl
              // In production, use _audioPlayer.play(UrlSource(audioUrl))
            },
          ),
          const SizedBox(width: 8),
          Container(
            width: 100,
            height: 2,
            decoration: BoxDecoration(
              color: isMe ? const Color(0xFFF14C86).withOpacity(0.3) : Colors.grey[300],
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(width: 12),
          Icon(Icons.mic_none_rounded, size: 16, color: isMe ? const Color(0xFFF14C86) : Colors.grey[400]),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey[100]!)),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: _pickAndSendImage,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFF9F9F9), borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.add_rounded, color: Colors.grey[600], size: 24),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F9F9),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey[100]!),
                ),
                child: TextField(
                  controller: _msgController,
                  style: GoogleFonts.nunito(color: const Color(0xFF333333)),
                  decoration: InputDecoration(
                    hintText: 'Message...',
                    hintStyle: GoogleFonts.nunito(color: Colors.grey[400]),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onLongPressStart: (_) => _startRecording(),
              onLongPressEnd: (_) => _stopAndSendRecording(),
              onTap: () => _sendMessage(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isRecording ? const Color(0xFF20D04A) : const Color(0xFFF14C86),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (_isRecording ? const Color(0xFF20D04A) : const Color(0xFFF14C86)).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  _isRecording ? Icons.mic_rounded : (_msgController.text.isEmpty ? Icons.mic_none_rounded : Icons.send_rounded),
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ],
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
