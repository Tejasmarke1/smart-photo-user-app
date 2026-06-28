import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

  String _formatLastUpdated() {
    if (_photos.isEmpty) return "Recently";
    final lastPhoto = _photos.first;
    if (lastPhoto.createdAt != null) {
      try {
        final date = DateTime.parse(lastPhoto.createdAt!).toLocal();
        final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
        final ampm = date.hour >= 12 ? "pm" : "am";
        final minute = date.minute.toString().padLeft(2, '0');
        return "$hour:$minute $ampm";
      } catch (_) {}
    }
    return "Recently";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: Colors.white10,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.group_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _album?.title ?? "My Trip",
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    "Last updated on ${_formatLastUpdated()}",
                    style: GoogleFonts.inter(
                      color: const Color(0xFF4C7AA8),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Invite button (Image Link Icon with Text underneath)
          GestureDetector(
            onTap: () {
              if (_album != null) {
                context.push('/share-link/${widget.id}', extra: _album);
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.link_rounded, color: Color(0xFF4C7AA8), size: 20),
                  const SizedBox(height: 2),
                  Text(
                    "Invite",
                    style: GoogleFonts.inter(
                      color: const Color(0xFF4C7AA8),
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
            onPressed: () {
              if (_album != null) {
                context.push('/group-settings/${widget.id}', extra: _album);
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingShimmer()
          : _photos.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    TabBar(
                      controller: _tabController,
                      indicatorColor: LuminaTokens.primaryLight,
                      labelColor: Colors.white,
                      unselectedLabelColor: LuminaTokens.darkTextMuted,
                      indicatorSize: TabBarIndicatorSize.tab,
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
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'upload_fab',
            onPressed: () {
              context.push('/upload-photos/${widget.id}', extra: _album?.title).then((val) {
                if (val == true) _loadAlbumDetails();
              });
            },
            backgroundColor: LuminaTokens.primary,
            foregroundColor: Colors.white,
            child: const Icon(Icons.arrow_upward_rounded, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            "UPLOAD",
            style: GoogleFonts.inter(
              color: LuminaTokens.primaryLight,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      color: Colors.black,
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          // Illustration asset copied earlier matching Image 1
          Image.asset(
            'assets/images/no_photos_illustration.png',
            width: 260,
            height: 260,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.collections_bookmark_rounded,
                size: 100,
                color: LuminaTokens.primaryLight.withOpacity(0.5),
              );
            },
          ).animate().fade(duration: 500.ms).scale(delay: 100.ms),
          const SizedBox(height: 24),
          Text(
            "No Photos Found",
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          // Gradient start uploading capsule button
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2E6B9E), Color(0xFF1E4366)],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 12),
              ),
              onPressed: () => context.push('/upload-photos/${widget.id}', extra: _album?.title).then((val) {
                if (val == true) _loadAlbumDetails();
              }),
              child: Text(
                "Start Uploading",
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildPhotosTab() {
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
          const SizedBox(height: 16),
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
