import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/database_service.dart';
import 'chat_room_screen.dart';
import 'discover_screen.dart'; // Only if we needed _showUserDetails, but we'll build a simplified card

class SearchUsersScreen extends StatefulWidget {
  final String currentUserEmail;

  const SearchUsersScreen({
    super.key,
    required this.currentUserEmail,
  });

  @override
  State<SearchUsersScreen> createState() => _SearchUsersScreenState();
}

class _SearchUsersScreenState extends State<SearchUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allValidUsers = [];
  List<Map<String, dynamic>> _displayedUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final fetchedUsers = await DatabaseService.instance.getAllUsers();
      
      setState(() {
        _allValidUsers = fetchedUsers.where((user) {
          final email = user['email']?.toString() ?? '';
          return email != widget.currentUserEmail;
        }).toList();
        
        _displayedUsers = _allValidUsers;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading users for search: $e');
      setState(() => _isLoading = false);
    }
  }

  void _filterUsers(String query) {
    setState(() {
      if (query.isEmpty) {
        _displayedUsers = _allValidUsers;
      } else {
        _displayedUsers = _allValidUsers.where((user) {
          final first = user['first_name']?.toString().toLowerCase() ?? '';
          final last = user['last_name']?.toString().toLowerCase() ?? '';
          final fullName = '$first $last';
          return fullName.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDE8F5), // Light pinkish background completely seamless
      appBar: AppBar(
        title: Text(
          'Search',
          style: GoogleFonts.nunito(
            color: const Color(0xFF322369),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF5E5088)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterUsers,
                  style: GoogleFonts.nunito(color: const Color(0xFF322369)),
                  decoration: InputDecoration(
                    hintText: 'Search by name...',
                    hintStyle: GoogleFonts.nunito(color: Colors.grey[400]),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFFC76CD9)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ),
            
            // Search Results
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFF14C86)))
                  : _displayedUsers.isEmpty
                      ? Center(
                          child: Text(
                            'No matches found.',
                            style: GoogleFonts.nunito(
                              fontSize: 16,
                              color: const Color(0xFF5E5088),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _displayedUsers.length,
                          itemBuilder: (context, index) {
                            final user = _displayedUsers[index];
                            final first = user['first_name']?.toString() ?? 'Unknown';
                            final last = user['last_name']?.toString() ?? '';
                            final fullName = '$first $last';
                            final avatarPath = user['avatar_path']?.toString() ?? '';
                            
                            // Determine compatibility
                            final targetInterests = List<String>.from(user['interests'] ?? []);

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12.0),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 2,
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                leading: CircleAvatar(
                                  radius: 28,
                                  backgroundColor: const Color(0xFF322369),
                                  backgroundImage: avatarPath.isNotEmpty ? NetworkImage(avatarPath) : null,
                                  child: avatarPath.isEmpty ? const Icon(Icons.person, color: Colors.white) : null,
                                ),
                                title: Text(
                                  fullName,
                                  style: GoogleFonts.nunito(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: const Color(0xFF322369),
                                  ),
                                ),
                                subtitle: Text(
                                  targetInterests.isNotEmpty ? targetInterests.join(', ') : 'No interests listed',
                                  style: GoogleFonts.nunito(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Container(
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [Color(0xFFF14C86), Color(0xFF8B51E5)],
                                    ),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 20),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ChatRoomScreen(
                                            currentUserEmail: widget.currentUserEmail,
                                            targetUserEmail: user['email'] ?? '',
                                            targetUserName: fullName,
                                            targetUserAvatar: avatarPath,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
