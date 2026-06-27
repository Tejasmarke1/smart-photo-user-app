import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
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
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  List<String> _recentAlbums = [];

  @override
  void initState() {
    super.initState();
    _loadRecentAlbums();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentAlbums() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentAlbums = prefs.getStringList('recent_albums') ?? [];
    });
  }

  Future<void> _saveAlbumToRecent(String albumId) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList('recent_albums') ?? [];
    if (!current.contains(albumId)) {
      current.insert(0, albumId);
      if (current.length > 5) current.removeLast(); // Cache last 5 albums
      await prefs.setStringList('recent_albums', current);
      _loadRecentAlbums();
    }
  }

  Future<void> _resolveCode(String code) async {
    if (code.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authState = ref.read(authProvider);
      final dio = Dio(BaseOptions(headers: {
        'Authorization': 'Bearer ${authState.accessToken}',
      }));
      final client = ApiClient(dio);
      final album = await client.resolveAlbumCode(code.trim());

      await _saveAlbumToRecent(album.id);
      
      if (mounted) {
        context.push('/album/${album.id}', extra: code.trim());
      }
    } catch (e) {
      _showError(e is DioException ? (e.response?.data['detail'] ?? "Album not found") : "Failed to resolve code");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: LuminaTokens.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showQRScanner() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.85,
          child: Column(
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                title: const Text("Scan Album QR", style: TextStyle(color: Colors.white)),
                leading: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    MobileScanner(
                      onDetect: (capture) {
                        final List<Barcode> barcodes = capture.barcodes;
                        for (final barcode in barcodes) {
                          final String? rawVal = barcode.rawValue;
                          if (rawVal != null) {
                            Navigator.pop(context); // Close sheet
                            // Example URL: http://localhost:3000/public/albumCode1234
                            final uri = Uri.tryParse(rawVal);
                            if (uri != null && uri.pathSegments.isNotEmpty) {
                              final code = uri.pathSegments.last;
                              _resolveCode(code);
                            } else {
                              _resolveCode(rawVal);
                            }
                            break;
                          }
                        }
                      },
                    ),
                    // Oval QR guides
                    Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        border: Border.all(color: LuminaTokens.primaryLight, width: 2.0),
                        borderRadius: LuminaTokens.borderRadiusXl,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: LuminaTokens.darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: LuminaTokens.primary.withOpacity(0.2),
              child: const Icon(Icons.person_rounded, color: LuminaTokens.primaryLight),
            ),
            const SizedBox(width: LuminaTokens.spacingSm),
            Text(
              "Hi, ${authState.userName ?? 'Guest'}",
              style: GoogleFonts.outfit(
                fontSize: LuminaTokens.textLg,
                fontWeight: LuminaTokens.fontWeightBold,
                color: LuminaTokens.darkText,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded, color: LuminaTokens.darkText),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(LuminaTokens.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: LuminaTokens.spacingLg),
            
            // Search card entry
            Container(
              padding: const EdgeInsets.all(LuminaTokens.spacingLg),
              decoration: BoxDecoration(
                color: LuminaTokens.darkSurface,
                borderRadius: LuminaTokens.borderRadiusXl,
                border: Border.all(color: LuminaTokens.darkBorder),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Enter Event Code",
                      style: GoogleFonts.outfit(
                        fontSize: LuminaTokens.textXl,
                        fontWeight: LuminaTokens.fontWeightBold,
                        color: LuminaTokens.darkText,
                      ),
                    ),
                    const SizedBox(height: LuminaTokens.spacingXxs),
                    Text(
                      "Type the 16-character album code or scan a photographer's event QR.",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: LuminaTokens.spacingLg),
                    
                    TextFormField(
                      controller: _codeController,
                      style: GoogleFonts.outfit(letterSpacing: 1.2),
                      decoration: const InputDecoration(
                        labelText: "Album Sharing Code",
                        hintText: "e.g., evt_abc123xyz789",
                        prefixIcon: Icon(Icons.vpn_key_rounded, color: LuminaTokens.darkTextMuted),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Please enter a code";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: LuminaTokens.spacingLg),
                    
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _isLoading 
                                  ? null 
                                  : () {
                                      if (_formKey.currentState!.validate()) {
                                        _resolveCode(_codeController.text);
                                      }
                                    },
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Text("Enter Album"),
                            ),
                          ),
                        ),
                        const SizedBox(width: LuminaTokens.spacingSm),
                        // QR scan shortcut button
                        IconButton.filled(
                          onPressed: _showQRScanner,
                          style: IconButton.styleFrom(
                            backgroundColor: LuminaTokens.darkSurfaceSecondary,
                            shape: RoundedRectangleBorder(
                              borderRadius: LuminaTokens.borderRadiusMd,
                              side: const BorderSide(color: LuminaTokens.darkBorder),
                            ),
                            padding: const EdgeInsets.all(12),
                          ),
                          icon: const Icon(Icons.qr_code_scanner_rounded, color: LuminaTokens.primaryLight),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: LuminaTokens.spacingXxl),

            // Recent Albums segment
            Text(
              "Recently Accessed",
              style: GoogleFonts.outfit(
                fontSize: LuminaTokens.textXl,
                fontWeight: LuminaTokens.fontWeightBold,
                color: LuminaTokens.darkText,
              ),
            ),
            const SizedBox(height: LuminaTokens.spacingMd),
            
            if (_recentAlbums.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(LuminaTokens.spacingLg),
                decoration: BoxDecoration(
                  color: LuminaTokens.darkSurface.withOpacity(0.5),
                  borderRadius: LuminaTokens.borderRadiusMd,
                  border: Border.all(color: LuminaTokens.darkBorder.withOpacity(0.5)),
                ),
                alignment: Alignment.center,
                child: Text(
                  "No albums accessed yet.",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: LuminaTokens.darkTextMuted.withOpacity(0.5),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recentAlbums.length,
                itemBuilder: (context, index) {
                  final albumId = _recentAlbums[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: LuminaTokens.spacingSm),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(LuminaTokens.spacingXs),
                        decoration: BoxDecoration(
                          color: LuminaTokens.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.photo_library_rounded, color: LuminaTokens.primaryLight),
                      ),
                      title: Text(
                        "Album Reference",
                        style: GoogleFonts.outfit(fontWeight: LuminaTokens.fontWeightSemibold),
                      ),
                      subtitle: Text(
                        albumId,
                        style: GoogleFonts.inter(fontSize: LuminaTokens.textXs),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded, color: LuminaTokens.darkTextMuted),
                      onTap: () {
                        // Launch album with cached ID
                        context.push('/album/$albumId');
                      },
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
