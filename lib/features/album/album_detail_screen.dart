import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/tokens.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/network/api_client.dart';
import '../../core/network/models.dart';

class AlbumDetailScreen extends ConsumerStatefulWidget {
  final String id;
  final String? sharingCode;

  const AlbumDetailScreen({
    super.key,
    required this.id,
    this.sharingCode,
  });

  @override
  ConsumerState<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends ConsumerState<AlbumDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  bool _isLoading = true;
  AlbumDetailResponse? _album;
  List<PhotoResponse> _photos = [];
  
  int _page = 1;
  final int _size = 50;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAlbumDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAlbumDetails() async {
    try {
      final authState = ref.read(authProvider);
      final dio = Dio(BaseOptions(headers: {
        'Authorization': 'Bearer ${authState.accessToken}',
      }));
      final client = ApiClient(dio);
      
      // Get album details (supports sharing_code override if guest is accessing)
      final albumDetail = await client.getAlbumDetail(widget.id, widget.sharingCode);
      
      // List photos inside album
      final photosList = await client.listPhotos(widget.id, widget.sharingCode, _page, _size);
      
      setState(() {
        _album = albumDetail;
        _photos = photosList.items;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Failed to load album photos"),
            backgroundColor: LuminaTokens.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuminaTokens.darkBg,
      body: _isLoading
          ? _buildLoadingShimmer()
          : NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  _buildSliverAppBar(),
                ];
              },
              body: Column(
                children: [
                  TabBar(
                    controller: _tabController,
                    indicatorColor: LuminaTokens.primary,
                    labelColor: LuminaTokens.darkText,
                    unselectedLabelColor: LuminaTokens.darkTextMuted,
                    tabs: const [
                      Tab(text: "Photos"),
                      Tab(text: "People"),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildPhotosTab(),
                        _buildPeopleTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/selfie-search/${widget.id}', extra: widget.sharingCode);
        },
        backgroundColor: LuminaTokens.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.face_retouching_natural_rounded),
        label: const Text("Find My Photos"),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    final coverUrl = _album?.coverPhotoUrl;
    
    return SliverAppBar(
      expandedHeight: 240.0,
      floating: false,
      pinned: true,
      backgroundColor: LuminaTokens.darkBg,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          _album?.title ?? "Album details",
          style: GoogleFonts.outfit(
            fontWeight: LuminaTokens.fontWeightBold,
            color: Colors.white,
            fontSize: LuminaTokens.textXl,
            shadows: [
              const Shadow(blurRadius: 10.0, color: Colors.black54, offset: Offset(0, 2))
            ],
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            coverUrl != null
                ? CachedNetworkImage(
                    imageUrl: coverUrl,
                    fit: Cover.cover.fit,
                    errorWidget: (context, url, error) => _buildPlaceholderBackground(),
                  )
                : _buildPlaceholderBackground(),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.85)],
                ),
              ),
            ),
            // Event Details overlay
            Positioned(
              bottom: 48,
              left: LuminaTokens.spacingLg,
              right: LuminaTokens.spacingLg,
              child: Row(
                children: [
                  const Icon(Icons.location_on_rounded, color: LuminaTokens.primaryLight, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    _album?.location ?? "Virtual Event",
                    style: GoogleFonts.inter(color: Colors.white70, fontSize: LuminaTokens.textXs),
                  ),
                  const Spacer(),
                  const Icon(Icons.camera_alt_rounded, color: LuminaTokens.primaryLight, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    "${_album?.photoCount ?? 0} photos",
                    style: GoogleFonts.inter(color: Colors.white70, fontSize: LuminaTokens.textXs),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LuminaTokens.primaryGradient,
      ),
      child: Icon(
        Icons.photo_library_rounded,
        size: 64,
        color: Colors.white.withOpacity(0.4),
      ),
    );
  }

  Widget _buildPhotosTab() {
    if (_photos.isEmpty) {
      return Center(
        child: Text(
          "No photos found in this album.",
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return MasonryGridView.count(
      padding: const EdgeInsets.all(LuminaTokens.spacingMd),
      crossAxisCount: 2,
      mainAxisSpacing: LuminaTokens.spacingSm,
      crossAxisSpacing: LuminaTokens.spacingSm,
      itemCount: _photos.length,
      itemBuilder: (context, index) {
        final photo = _photos[index];
        final displayUrl = photo.thumbnailMediumUrl ?? photo.thumbnailSmallUrl ?? "";
        
        return GestureDetector(
          onTap: () {
            context.push('/photo-viewer', extra: {
              'photo': photo,
              'sharingCode': widget.sharingCode,
            });
          },
          child: Hero(
            tag: 'photo_${photo.id}',
            child: ClipRRect(
              borderRadius: LuminaTokens.borderRadiusMd,
              child: CachedNetworkImage(
                imageUrl: displayUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 150,
                  color: LuminaTokens.darkSurfaceSecondary,
                ),
                errorWidget: (context, url, error) => const Icon(Icons.broken_image_rounded),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPeopleTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people_alt_rounded, size: 48, color: LuminaTokens.darkTextMuted),
          const SizedBox(height: LuminaTokens.spacingMd),
          Text(
            "Face Clusters is ready",
            style: GoogleFonts.outfit(
              fontSize: LuminaTokens.textLg,
              fontWeight: LuminaTokens.fontWeightBold,
              color: LuminaTokens.darkText,
            ),
          ),
          const SizedBox(height: LuminaTokens.spacingXxs),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: LuminaTokens.spacingXl),
            child: Text(
              "Perform a selfie search using the button below to group all matches of your face.",
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: LuminaTokens.darkSurface,
      highlightColor: LuminaTokens.darkSurfaceSecondary,
      child: Column(
        children: [
          Container(height: 240, color: Colors.white),
          const SizedBox(height: LuminaTokens.spacingLg),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(LuminaTokens.spacingMd),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: 8,
              itemBuilder: (context, index) => Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: LuminaTokens.borderRadiusMd,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper enum/class for layout matching
enum Cover {
  cover(BoxFit.cover);
  final BoxFit fit;
  const Cover(this.fit);
}
