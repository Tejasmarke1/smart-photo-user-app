import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import '../../core/theme/tokens.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/network/api_client.dart';
import '../../core/network/models.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // Navigation tabs: 0 = Home (Groups), 1 = My Photos (Selfie Matches)
  int _currentNavIndex = 0;
  
  bool _isResolvingAlbums = false;
  List<String> _recentAlbums = [];
  List<AlbumDetailResponse> _resolvedAlbums = [];

  // Profile metadata
  String? _profilePicUrl;
  bool _isDownloadingProfilePic = false;

  // My Photos Tab State
  bool _isSearchingSelfie = false;
  List<GlobalSearchMatch> _matchedPhotos = [];
  bool _groupByDate = true; // true = Date, false = Group (Album)

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final authState = ref.read(authProvider);
        if (authState.isAuthenticated) {
          _loadAndResolveAlbums();
          _fetchUserProfile();
        }
      }
    });
  }

  Future<void> _fetchUserProfile() async {
    try {
      final authState = ref.read(authProvider);
      if (!authState.isAuthenticated) return;
      
      final dio = Dio(BaseOptions(headers: {
        'Authorization': 'Bearer ${authState.accessToken}',
      }));
      final client = ApiClient(dio);
      final profile = await client.getCurrentUser();
      
      final name = profile['name']?.toString();
      final email = profile['email']?.toString();
      if (name != null || email != null) {
        await ref.read(authProvider.notifier).updateProfile(
          name: name,
          email: email,
        );
      }

      if (mounted) {
        setState(() {
          _profilePicUrl = profile['profile_picture_url']?.toString();
        });
        
        if (_profilePicUrl != null) {
          _downloadProfilePicAndSearch();
        }
      }
    } catch (e) {
      debugPrint("Failed to fetch user profile: $e");
      if (e is DioException && e.response?.statusCode == 401) {
        await ref.read(authProvider.notifier).logout();
        if (mounted) {
          context.go('/login');
        }
      }
    }
  }

  Future<void> _downloadProfilePicAndSearch() async {
    if (_profilePicUrl == null || _isDownloadingProfilePic) return;
    
    setState(() {
      _isDownloadingProfilePic = true;
      _isSearchingSelfie = true;
    });
    
    try {
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/user_profile_pic_cache.jpg';
      final file = File(filePath);
      
      final dio = Dio();
      
      await dio.download(_profilePicUrl!, filePath);
      
      if (mounted) {
        setState(() {
          _isDownloadingProfilePic = false;
        });
        
        await _runAutomaticGlobalSearch(file);
      }
    } catch (e) {
      debugPrint("Failed to download profile picture: $e");
      if (mounted) {
        setState(() {
          _isDownloadingProfilePic = false;
          _isSearchingSelfie = false;
        });
      }
    }
  }

  Future<void> _loadAndResolveAlbums() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('recent_albums') ?? [];
    setState(() {
      _recentAlbums = list;
    });
    await _resolveAllAlbums();
    await _fetchUserProfile();
  }

  Future<void> _resolveAllAlbums() async {
    if (_recentAlbums.isEmpty) {
      setState(() {
        _resolvedAlbums = [];
        _isResolvingAlbums = false;
      });
      return;
    }
    
    setState(() {
      _isResolvingAlbums = true;
    });

    try {
      final authState = ref.read(authProvider);
      final dio = Dio(BaseOptions(headers: {
        'Authorization': 'Bearer ${authState.accessToken}',
      }));
      final client = ApiClient(dio);
      
      final futures = _recentAlbums.map((id) => client.getAlbumDetail(id, null).catchError((e) {
        debugPrint("Failed to load album $id: $e");
        if (e is DioException && e.response?.statusCode == 401) {
          ref.read(authProvider.notifier).logout().then((_) {
            if (mounted) {
              context.go('/login');
            }
          });
        }
        return AlbumDetailResponse(
          id: id,
          title: "Unknown Album",
          sharingCode: "",
          isPublic: false,
          passwordProtected: false,
          photoCount: 0,
        );
      }));
      
      final results = await Future.wait(futures);
      
      if (mounted) {
        setState(() {
          _resolvedAlbums = results.where((a) => a.title != "Unknown Album").toList();
          _isResolvingAlbums = false;
        });
      }
    } catch (e) {
      debugPrint("Failed to resolve albums: $e");
      if (mounted) {
        setState(() {
          _isResolvingAlbums = false;
        });
      }
      if (e is DioException && e.response?.statusCode == 401) {
        await ref.read(authProvider.notifier).logout();
        if (mounted) {
          context.go('/login');
        }
      }
    }
  }

  Future<void> _runAutomaticGlobalSearch(File file) async {
    if (_resolvedAlbums.isEmpty) {
      setState(() {
        _isSearchingSelfie = false;
      });
      return;
    }

    setState(() {
      _isSearchingSelfie = true;
      _matchedPhotos.clear();
    });

    try {
      final authState = ref.read(authProvider);
      final dio = Dio(BaseOptions(headers: {
        'Authorization': 'Bearer ${authState.accessToken}',
      }));
      final client = ApiClient(dio);

      final futures = _resolvedAlbums.map((album) async {
        try {
          final matches = await client.searchBySelfie(
            file,
            album.id,
            album.sharingCode.isNotEmpty ? album.sharingCode : null,
            50,
            0.55,
          );
          return matches.map((m) => GlobalSearchMatch(
            match: m,
            albumId: album.id,
            albumName: album.title,
            photoDate: m.photoDate != null ? DateTime.parse(m.photoDate!) : DateTime.now(),
          )).toList();
        } catch (e) {
          debugPrint("Failed auto search in ${album.title}: $e");
          return <GlobalSearchMatch>[];
        }
      });

      final lists = await Future.wait(futures);
      final flattened = lists.expand((x) => x).toList();
      
      // Sort by date (newest first)
      flattened.sort((a, b) => b.photoDate.compareTo(a.photoDate));

      if (mounted) {
        setState(() {
          _matchedPhotos = flattened;
          _isSearchingSelfie = false;
        });
      }
    } catch (e) {
      debugPrint("Failed global auto search: $e");
      if (mounted) {
        setState(() {
          _isSearchingSelfie = false;
        });
      }
    }
  }



  Map<String, List<GlobalSearchMatch>> _groupPhotosByDate() {
    final Map<String, List<GlobalSearchMatch>> groups = {};
    for (final match in _matchedPhotos) {
      final dateStr = _formatDateHeader(match.photoDate);
      if (!groups.containsKey(dateStr)) {
        groups[dateStr] = [];
      }
      groups[dateStr]!.add(match);
    }
    return groups;
  }

  Map<String, List<GlobalSearchMatch>> _groupPhotosByAlbum() {
    final Map<String, List<GlobalSearchMatch>> groups = {};
    for (final match in _matchedPhotos) {
      final name = match.albumName;
      if (!groups.containsKey(name)) {
        groups[name] = [];
      }
      groups[name]!.add(match);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.isAuthenticated && !(previous?.isAuthenticated ?? false)) {
        _loadAndResolveAlbums();
        _fetchUserProfile();
      }
    });

    return Scaffold(
      backgroundColor: LuminaTokens.darkBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),

            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _currentNavIndex == 0 ? _buildHomeTab() : _buildMyPhotosTab(),
              ),
            ),

            _buildBottomNavigationBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final authState = ref.watch(authProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: LuminaTokens.spacingLg,
        vertical: LuminaTokens.spacingMd,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: LuminaTokens.primary.withOpacity(0.1),
                backgroundImage: _profilePicUrl != null
                    ? NetworkImage(_profilePicUrl!)
                    : null,
                child: _profilePicUrl == null
                    ? const Icon(Icons.person_rounded, color: LuminaTokens.primaryLight)
                    : null,
              ),
              const SizedBox(width: LuminaTokens.spacingSm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Hello,",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: LuminaTokens.darkTextMuted,
                    ),
                  ),
                  Text(
                    authState.userName ?? 'Lumina Guest',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: LuminaTokens.darkText,
                    ),
                  ),
                ],
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded, color: LuminaTokens.darkTextMuted),
            onPressed: () => context.push('/settings'),
            style: IconButton.styleFrom(
              backgroundColor: LuminaTokens.darkSurface,
              padding: const EdgeInsets.all(10),
              shadowColor: Colors.black.withOpacity(0.2),
              elevation: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: LuminaTokens.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: LuminaTokens.spacingSm),
          
          _buildActionCards(),
          
          const SizedBox(height: LuminaTokens.spacingLg),

          Text(
            "Joined Groups",
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: LuminaTokens.darkText,
            ),
          ),
          const SizedBox(height: LuminaTokens.spacingMd),

          if (_isResolvingAlbums)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(color: LuminaTokens.primaryLight),
              ),
            )
          else if (_resolvedAlbums.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(LuminaTokens.spacingLg),
              decoration: BoxDecoration(
                color: LuminaTokens.darkSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: LuminaTokens.darkBorder.withOpacity(0.1)),
              ),
              alignment: Alignment.center,
              child: Text(
                "No groups joined yet.",
                style: GoogleFonts.inter(
                  color: LuminaTokens.darkTextMuted,
                  fontSize: 14,
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _resolvedAlbums.length,
              itemBuilder: (context, index) {
                final album = _resolvedAlbums[index];
                return _buildGroupCard(album).animate().fade(delay: (index * 50).ms);
              },
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildActionCards() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => context.push('/join-group').then((_) => _loadAndResolveAlbums()),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: LuminaTokens.darkSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: LuminaTokens.darkBorder.withOpacity(0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      offset: const Offset(0, 4),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E6B9E).withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.group_add_rounded, color: Color(0xFF2E6B9E), size: 24),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Join Group",
                      style: GoogleFonts.outfit(
                        color: LuminaTokens.darkText,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Enter code or scan QR",
                      style: GoogleFonts.inter(
                        color: LuminaTokens.darkTextMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: () => context.push('/create-group').then((_) => _loadAndResolveAlbums()),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: LuminaTokens.darkSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: LuminaTokens.darkBorder.withOpacity(0.2)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      offset: const Offset(0, 4),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: LuminaTokens.primaryLight.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add_box_rounded, color: LuminaTokens.primaryLight, size: 24),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Create Group",
                      style: GoogleFonts.outfit(
                        color: LuminaTokens.darkText,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Start a new event album",
                      style: GoogleFonts.inter(
                        color: LuminaTokens.darkTextMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCard(AlbumDetailResponse album) {
    final String timeAgo = _formatTimeAgo(album.createdAt);
    final String subtitleText = album.photoCount > 0 
        ? "Last upload on ${_formatDate(album.createdAt)}"
        : "Joined on ${_formatDate(album.createdAt)}";

    return Container(
      margin: const EdgeInsets.only(bottom: LuminaTokens.spacingSm),
      decoration: BoxDecoration(
        color: LuminaTokens.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: LuminaTokens.darkBorder.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push('/album/${album.id}', extra: album.sharingCode),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: LuminaTokens.primaryLight,
                      width: 2.0,
                    ),
                  ),
                  child: ClipOval(
                    child: album.coverPhotoUrl != null
                        ? Image.network(
                            album.coverPhotoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildDefaultThumbnail(album.title),
                          )
                        : _buildDefaultThumbnail(album.title),
                  ),
                ),
                const SizedBox(width: 14),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        album.title,
                        style: GoogleFonts.outfit(
                          color: LuminaTokens.darkText,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitleText,
                        style: GoogleFonts.inter(
                          color: LuminaTokens.darkTextMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      timeAgo,
                      style: GoogleFonts.inter(
                        color: LuminaTokens.darkTextMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: LuminaTokens.primaryLight,
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultThumbnail(String title) {
    final char = title.isNotEmpty ? title[0].toUpperCase() : 'G';
    return Container(
      color: LuminaTokens.darkSurfaceSecondary,
      alignment: Alignment.center,
      child: Text(
        char,
        style: GoogleFonts.outfit(
          color: LuminaTokens.primaryLight,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
    );
  }

  Widget _buildMyPhotosTab() {
    if (_profilePicUrl == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.face_retouching_off_rounded, size: 64, color: LuminaTokens.darkTextMuted),
              const SizedBox(height: 16),
              Text(
                "Selfie Required",
                style: GoogleFonts.outfit(
                  color: LuminaTokens.darkText,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "You must upload a selfie in your settings to automatically scan and find your photos.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: LuminaTokens.darkTextMuted,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_isSearchingSelfie || _isDownloadingProfilePic) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: LuminaTokens.primaryLight),
            const SizedBox(height: LuminaTokens.spacingLg),
            Text(
              "Syncing your photos...",
              style: GoogleFonts.outfit(
                color: LuminaTokens.darkText,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Automatically scanning joined groups.",
              style: GoogleFonts.inter(
                color: LuminaTokens.darkTextMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    if (_matchedPhotos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.photo_library_outlined, size: 64, color: LuminaTokens.darkTextMuted),
            const SizedBox(height: 16),
            Text(
              "No Photos Found",
              style: GoogleFonts.outfit(
                color: LuminaTokens.darkText,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                "None of the photos in your joined groups match your profile selfie yet.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: LuminaTokens.darkTextMuted,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: () => _loadAndResolveAlbums(),
              icon: const Icon(Icons.refresh_rounded, color: LuminaTokens.primaryLight),
              label: Text("Refresh", style: GoogleFonts.inter(color: LuminaTokens.primaryLight, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    // Dynamic grouping
    final groupedData = _groupByDate ? _groupPhotosByDate() : _groupPhotosByAlbum();
    final keys = groupedData.keys.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Gallery Header & Toggle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "My Photos",
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: LuminaTokens.darkText,
                ),
              ),
              
              // Date vs Album Segments toggle
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: LuminaTokens.darkSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: LuminaTokens.darkBorder.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    _buildSegmentButton("Date", _groupByDate, () {
                      setState(() => _groupByDate = true);
                    }),
                    _buildSegmentButton("Group", !_groupByDate, () {
                      setState(() => _groupByDate = false);
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: keys.length,
            itemBuilder: (context, sectionIndex) {
              final sectionKey = keys[sectionIndex];
              final sectionItems = groupedData[sectionKey]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Header
                  Padding(
                    padding: const EdgeInsets.only(top: 20, bottom: 10),
                    child: Text(
                      sectionKey,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: LuminaTokens.primaryLight,
                      ),
                    ),
                  ),
                  
                  // Section Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: sectionItems.length,
                    itemBuilder: (context, photoIndex) {
                      final matchItem = sectionItems[photoIndex];
                      final url = matchItem.match.thumbnailUrl ?? "";

                      return GestureDetector(
                        onTap: () {
                          final photo = PhotoResponse(
                            id: matchItem.match.photoId,
                            albumId: matchItem.albumId,
                            filename: "Matched_${matchItem.match.faceId}.jpg",
                            thumbnailMediumUrl: matchItem.match.thumbnailUrl,
                          );
                          context.push('/photo-viewer', extra: {
                            'photo': photo,
                          });
                        },
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                url,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    color: LuminaTokens.darkSurface,
                                    child: const Center(
                                      child: SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 1.5, color: LuminaTokens.primaryLight),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            if (!_groupByDate)
                              Positioned(
                                bottom: 6,
                                right: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _formatDateShort(matchItem.photoDate),
                                    style: GoogleFonts.inter(color: Colors.white, fontSize: 8),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentButton(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? LuminaTokens.darkSurfaceSecondary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: isSelected ? Colors.white : LuminaTokens.darkTextMuted,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: LuminaTokens.spacingLg,
        vertical: LuminaTokens.spacingSm,
      ),
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: LuminaTokens.darkSurface,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            offset: const Offset(0, 4),
            blurRadius: 16,
          ),
        ],
        border: Border.all(color: LuminaTokens.darkBorder.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(0, Icons.home_rounded, Icons.home_outlined),
          _buildNavItem(1, Icons.photo_library_rounded, Icons.photo_library_outlined),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon) {
    final isSelected = _currentNavIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _currentNavIndex = index);
        if (index == 1) {
          _fetchUserProfile();
        }
      },
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
        child: Icon(
          isSelected ? activeIcon : inactiveIcon,
          color: isSelected ? LuminaTokens.primaryLight : LuminaTokens.darkTextMuted,
          size: 28,
        ),
      ),
    );
  }

  String _formatTimeAgo(String? dateStr) {
    if (dateStr == null) return "Just now";
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final diff = DateTime.now().difference(date);
      if (diff.inDays > 0) {
        return "${diff.inDays} hours ago";
      } else if (diff.inHours > 0) {
        return "${diff.inHours} hours ago";
      } else if (diff.inMinutes > 0) {
        return "${diff.inMinutes} mins ago";
      }
      return "Just now";
    } catch (_) {
      return "Just now";
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return "28/06/2026";
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString();
      return "$day/$month/$year";
    } catch (_) {
      return "28/06/2026";
    }
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final checkDate = DateTime(date.year, date.month, date.day);
    
    if (checkDate == today) {
      return "Today";
    } else if (checkDate == yesterday) {
      return "Yesterday";
    } else {
      final day = date.day.toString().padLeft(2, '0');
      final month = _getMonthName(date.month);
      final year = date.year;
      return "$day $month $year";
    }
  }

  String _formatDateShort(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return "$day/$month";
  }

  String _getMonthName(int month) {
    const months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun",
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    if (month >= 1 && month <= 12) {
      return months[month - 1];
    }
    return "";
  }
}

class GlobalSearchMatch {
  final FaceSearchResponse match;
  final String albumId;
  final String albumName;
  final DateTime photoDate;

  GlobalSearchMatch({
    required this.match,
    required this.albumId,
    required this.albumName,
    required this.photoDate,
  });
}
