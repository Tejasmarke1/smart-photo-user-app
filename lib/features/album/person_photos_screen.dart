import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:shimmer/shimmer.dart';
import 'package:dio/dio.dart';
import '../../core/theme/tokens.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/network/api_client.dart';
import '../../core/config/app_config.dart';
import '../../core/network/models.dart';

class PersonPhotosScreen extends ConsumerStatefulWidget {
  final String personId;
  final String? personName;

  const PersonPhotosScreen({
    super.key,
    required this.personId,
    this.personName,
  });

  @override
  ConsumerState<PersonPhotosScreen> createState() => _PersonPhotosScreenState();
}

class _PersonPhotosScreenState extends ConsumerState<PersonPhotosScreen> {
  bool _isLoading = true;
  String? _error;
  List<PhotoResponse> _photos = [];
  String? _personName;

  @override
  void initState() {
    super.initState();
    _personName = widget.personName;
    _loadPersonPhotos();
  }

  Future<void> _loadPersonPhotos() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authState = ref.read(authProvider);
      final dio = Dio(BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        headers: {'Authorization': 'Bearer ${authState.accessToken}'},
      ));
      final apiClient = ApiClient(dio);

      // Fetch person's photo IDs
      final personPhotos = await apiClient.getPersonPhotos(widget.personId, 0, 100);
      _personName = personPhotos.name ?? _personName;

      // Fetch each photo's detail (in practice we'd batch, but for now we use the IDs)
      // The person photos endpoint returns photo_ids, we need to fetch them
      // For now we'll use basic photo response structure
      final List<PhotoResponse> loadedPhotos = [];
      for (final photoId in personPhotos.photoIds) {
        try {
          final response = await dio.get('/photos/$photoId');
          if (response.data != null) {
            loadedPhotos.add(PhotoResponse.fromJson(response.data));
          }
        } catch (_) {
          // Skip individual photo errors
        }
      }

      if (mounted) {
        setState(() {
          _photos = loadedPhotos;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load photos for this person';
          _isLoading = false;
        });
      }
    }
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
          _personName ?? 'Person Photos',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: LuminaTokens.fontWeightSemibold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: LuminaTokens.darkTextMuted),
            onPressed: _showRenameDialog,
            tooltip: 'Rename person',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingGrid();
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: LuminaTokens.errorLight),
            const SizedBox(height: LuminaTokens.spacingMd),
            Text(
              _error!,
              style: GoogleFonts.inter(color: LuminaTokens.darkTextMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: LuminaTokens.spacingLg),
            ElevatedButton.icon(
              onPressed: _loadPersonPhotos,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_photos.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.photo_library_outlined, size: 64, color: LuminaTokens.darkTextMuted.withOpacity(0.4)),
            const SizedBox(height: LuminaTokens.spacingMd),
            Text(
              'No photos found for this person',
              style: GoogleFonts.inter(
                color: LuminaTokens.darkTextMuted,
                fontSize: LuminaTokens.textMd,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPersonPhotos,
      color: LuminaTokens.primaryLight,
      child: Padding(
        padding: const EdgeInsets.all(LuminaTokens.spacingXs),
        child: MasonryGridView.count(
          crossAxisCount: 3,
          mainAxisSpacing: 3,
          crossAxisSpacing: 3,
          itemCount: _photos.length,
          itemBuilder: (context, index) {
            final photo = _photos[index];
            return GestureDetector(
              onTap: () {
                context.push('/photo-viewer', extra: {
                  'photo': photo,
                  'sharingCode': null,
                });
              },
              child: Hero(
                tag: 'photo_${photo.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: CachedNetworkImage(
                    imageUrl: photo.thumbnailMediumUrl ?? photo.watermarkedUrl ?? '',
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: LuminaTokens.darkSurface,
                      highlightColor: LuminaTokens.darkSurfaceSecondary,
                      child: Container(
                        height: index % 3 == 0 ? 200 : 150,
                        color: LuminaTokens.darkSurface,
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 150,
                      color: LuminaTokens.darkSurface,
                      child: const Icon(Icons.broken_image_rounded, color: LuminaTokens.darkTextMuted),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingGrid() {
    return Padding(
      padding: const EdgeInsets.all(LuminaTokens.spacingXs),
      child: MasonryGridView.count(
        crossAxisCount: 3,
        mainAxisSpacing: 3,
        crossAxisSpacing: 3,
        itemCount: 12,
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: LuminaTokens.darkSurface,
            highlightColor: LuminaTokens.darkSurfaceSecondary,
            child: Container(
              height: index % 3 == 0 ? 200 : 150,
              decoration: BoxDecoration(
                color: LuminaTokens.darkSurface,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showRenameDialog() {
    final controller = TextEditingController(text: _personName ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: LuminaTokens.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Rename Person',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: LuminaTokens.fontWeightBold),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: GoogleFonts.inter(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter name',
            hintStyle: GoogleFonts.inter(color: LuminaTokens.darkTextMuted),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: LuminaTokens.darkBorder),
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFF38BDF8)),
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: LuminaTokens.darkBg,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.outfit(color: LuminaTokens.darkTextMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                try {
                  final authState = ref.read(authProvider);
                  final dio = Dio(BaseOptions(
                    baseUrl: AppConfig.apiBaseUrl,
                    headers: {'Authorization': 'Bearer ${authState.accessToken}'},
                  ));
                  await dio.patch('/persons/${widget.personId}', data: {'name': newName});
                  setState(() => _personName = newName);
                } catch (_) {
                  // Silently fail rename
                }
              }
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E6091),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Save', style: GoogleFonts.outfit(fontWeight: LuminaTokens.fontWeightSemibold)),
          ),
        ],
      ),
    );
  }
}
