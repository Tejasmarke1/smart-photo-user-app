import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/tokens.dart';

class CloseFriend {
  final String id;
  final String name;
  final String email;
  final String avatarUrl;

  CloseFriend({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarUrl,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'avatarUrl': avatarUrl,
      };

  factory CloseFriend.fromJson(Map<String, dynamic> json) => CloseFriend(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        avatarUrl: json['avatarUrl'] as String? ?? '',
      );
}

class CloseFriendsScreen extends ConsumerStatefulWidget {
  const CloseFriendsScreen({super.key});

  @override
  ConsumerState<CloseFriendsScreen> createState() => _CloseFriendsScreenState();
}

class _CloseFriendsScreenState extends ConsumerState<CloseFriendsScreen> {
  final _searchController = TextEditingController();
  List<CloseFriend> _closeFriends = [];
  List<CloseFriend> _suggestions = [];
  List<CloseFriend> _filteredSuggestions = [];
  bool _isLoading = true;
  PermissionStatus _permissionStatus = PermissionStatus.denied;

  // Mock suggestion list from mutual album contacts
  final List<CloseFriend> _mockContacts = [
    CloseFriend(id: 'cf_1', name: 'Aarav Sharma', email: 'aarav.sharma@example.com', avatarUrl: ''),
    CloseFriend(id: 'cf_2', name: 'Aditi Patel', email: 'aditi.patel@example.com', avatarUrl: ''),
    CloseFriend(id: 'cf_3', name: 'Rohan Mehta', email: 'rohan.mehta@example.com', avatarUrl: ''),
    CloseFriend(id: 'cf_4', name: 'Neha Gupta', email: 'neha.gupta@example.com', avatarUrl: ''),
    CloseFriend(id: 'cf_5', name: 'Vikram Singh', email: 'vikram.singh@example.com', avatarUrl: ''),
    CloseFriend(id: 'cf_6', name: 'Ananya Iyer', email: 'ananya.iyer@example.com', avatarUrl: ''),
  ];

  @override
  void initState() {
    super.initState();
    _checkPermission();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.contacts.status;
    setState(() {
      _permissionStatus = status;
    });

    if (status.isGranted) {
      _loadData();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _requestPermission() async {
    final status = await Permission.contacts.request();
    setState(() {
      _permissionStatus = status;
    });

    if (status.isGranted) {
      _loadData();
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('close_friends_list');
    
    List<CloseFriend> loadedFriends = [];
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        loadedFriends = decoded.map((item) => CloseFriend.fromJson(item as Map<String, dynamic>)).toList();
      } catch (e) {
        debugPrint('Failed to decode close friends: $e');
      }
    }

    final addedIds = loadedFriends.map((f) => f.id).toSet();
    final suggestionsList = _mockContacts.where((contact) => !addedIds.contains(contact.id)).toList();

    setState(() {
      _closeFriends = loadedFriends;
      _suggestions = suggestionsList;
      _filteredSuggestions = suggestionsList;
      _isLoading = false;
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(_closeFriends.map((f) => f.toJson()).toList());
    await prefs.setString('close_friends_list', jsonStr);
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _filteredSuggestions = _suggestions;
      });
      return;
    }

    setState(() {
      _filteredSuggestions = _suggestions.where((contact) {
        return contact.name.toLowerCase().contains(query) ||
            contact.email.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _addFriend(CloseFriend friend) {
    setState(() {
      _closeFriends.add(friend);
      _suggestions.remove(friend);
      _onSearchChanged();
    });
    _saveData();
    _showSnackBar('${friend.name} added to Close Friends!');
  }

  void _removeFriend(CloseFriend friend) {
    setState(() {
      _closeFriends.remove(friend);
      _suggestions.add(friend);
      _onSearchChanged();
    });
    _saveData();
    _showSnackBar('${friend.name} removed from Close Friends');
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter(color: Colors.white, fontSize: 13)),
        backgroundColor: LuminaTokens.darkSurface,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuminaTokens.darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Close Friends',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: LuminaTokens.fontWeightSemibold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: LuminaTokens.primaryLight))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Explanation Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Text(
                    'Get priority notifications and enable smart background downloads when photos of your Close Friends are matching.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: LuminaTokens.darkTextMuted,
                      height: 1.4,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Permission Warning / Banner if denied
                if (!_permissionStatus.isGranted)
                  _buildPermissionBanner()
                else ...[
                  // Search Input
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      decoration: BoxDecoration(
                        color: LuminaTokens.darkSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: LuminaTokens.darkBorder.withOpacity(0.3)),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Search friends by name or email...',
                          hintStyle: GoogleFonts.inter(color: LuminaTokens.darkTextMuted, fontSize: 13),
                          prefixIcon: const Icon(Icons.search_rounded, color: LuminaTokens.darkTextMuted, size: 20),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, color: LuminaTokens.darkTextMuted, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // List Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Current Close Friends Section (does not require contacts permission to view already added items)
                        if (_closeFriends.isNotEmpty) ...[
                          Text(
                            'Close Friends (${_closeFriends.length})',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _closeFriends.length,
                            itemBuilder: (context, index) {
                              final friend = _closeFriends[index];
                              return _buildFriendTile(friend, isAdded: true)
                                  .animate()
                                  .fade(duration: 200.ms)
                                  .slideY(begin: 0.05, curve: Curves.easeOut);
                            },
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Suggestions / Search Results Section (only if permission granted)
                        if (_permissionStatus.isGranted) ...[
                          if (_filteredSuggestions.isNotEmpty) ...[
                            Text(
                              _searchController.text.isEmpty ? 'Suggested Contacts' : 'Search Results',
                              style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            const SizedBox(height: 12),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _filteredSuggestions.length,
                              itemBuilder: (context, index) {
                                final friend = _filteredSuggestions[index];
                                return _buildFriendTile(friend, isAdded: false)
                                    .animate()
                                    .fade(duration: 200.ms)
                                    .slideY(begin: 0.05, curve: Curves.easeOut);
                              },
                            ),
                          ] else if (_searchController.text.isNotEmpty && _filteredSuggestions.isEmpty) ...[
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 40),
                                child: Column(
                                  children: [
                                    const Icon(Icons.person_search_rounded, size: 48, color: LuminaTokens.darkTextMuted),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No contacts found',
                                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Try searching for another name or email.',
                                      style: GoogleFonts.inter(color: LuminaTokens.darkTextMuted, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],

                        // Empty State (No Close Friends added yet)
                        if (_closeFriends.isEmpty && (!_permissionStatus.isGranted || (_filteredSuggestions.isEmpty && _searchController.text.isEmpty))) ...[
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: Column(
                                children: [
                                  const Icon(Icons.favorite_border_rounded, size: 54, color: LuminaTokens.darkTextMuted),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No friends added yet',
                                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _permissionStatus.isGranted
                                        ? 'Search your group contacts above to add close friends.'
                                        : 'Grant contacts permission above to search and find friends.',
                                    style: GoogleFonts.inter(color: LuminaTokens.darkTextMuted, fontSize: 12),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPermissionBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LuminaTokens.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LuminaTokens.darkBorder.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.contacts_rounded, color: LuminaTokens.primaryLight, size: 20),
              const SizedBox(width: 8),
              Text(
                'Contacts Access Required',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Grant contacts permission to search and connect with mutual participants in your shared albums.',
            style: GoogleFonts.inter(
              color: LuminaTokens.darkTextMuted,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: LuminaTokens.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onPressed: _requestPermission,
              child: Text(
                _permissionStatus.isPermanentlyDenied ? 'Open Settings' : 'Grant Permission',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendTile(CloseFriend friend, {required bool isAdded}) {
    final String initial = friend.name.isNotEmpty ? friend.name[0].toUpperCase() : 'F';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: LuminaTokens.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LuminaTokens.darkBorder.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          // Circular Initials Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isAdded ? LuminaTokens.primary.withOpacity(0.2) : LuminaTokens.darkSurfaceSecondary,
              border: Border.all(
                color: isAdded ? LuminaTokens.primaryLight.withOpacity(0.4) : LuminaTokens.darkBorder.withOpacity(0.5),
                width: 1.5,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: GoogleFonts.outfit(
                color: isAdded ? LuminaTokens.primaryLight : Colors.white70,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Name and Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.name,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  friend.email,
                  style: GoogleFonts.inter(
                    color: LuminaTokens.darkTextMuted,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Action Button
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isAdded ? Colors.red.withOpacity(0.12) : LuminaTokens.primary.withOpacity(0.15),
              foregroundColor: isAdded ? Colors.redAccent : LuminaTokens.primaryLight,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () => isAdded ? _removeFriend(friend) : _addFriend(friend),
            child: Text(
              isAdded ? 'Remove' : 'Add',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
