import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/tokens.dart';
import '../../core/network/models.dart';

class ShareLinkScreen extends StatefulWidget {
  final String albumId;
  final AlbumDetailResponse albumDetail;

  const ShareLinkScreen({
    super.key,
    required this.albumId,
    required this.albumDetail,
  });

  @override
  State<ShareLinkScreen> createState() => _ShareLinkScreenState();
}

class _ShareLinkScreenState extends State<ShareLinkScreen> {
  late String _groupLink;
  late String _uCode;

  @override
  void initState() {
    super.initState();
    // Use the dynamic sharing code for direct invite URLs
    _uCode = widget.albumDetail.sharingCode.toUpperCase();
    _groupLink = "https://lumina.app/join/$_uCode";
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    _showSnackBar("$label copied to clipboard!", isError: false);
  }

  void _shareContent(String text) {
    Share.share(text);
  }

  void _showSnackBar(String msg, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? LuminaTokens.error : LuminaTokens.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final qrApiUrl = "https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=$_groupLink";

    return Scaffold(
      backgroundColor: LuminaTokens.darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Share Link",
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group Link Section
            Text(
              "Group Link",
              style: GoogleFonts.outfit(
                color: LuminaTokens.primaryLight,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            _buildCopyField(
              text: _groupLink,
              icon: Icons.link_rounded,
              onCopy: () => _copyToClipboard(_groupLink, "Group Link"),
            ),

            const SizedBox(height: 24),

            // U-Code Section
            Text(
              "U-Code",
              style: GoogleFonts.outfit(
                color: LuminaTokens.primaryLight,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            _buildCopyField(
              text: "# $_uCode",
              icon: Icons.tag_rounded,
              onCopy: () => _copyToClipboard(_uCode, "U-Code"),
            ),

            const SizedBox(height: 28),

            // QR Code Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "QR Code",
                  style: GoogleFonts.outfit(
                    color: LuminaTokens.primaryLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                GestureDetector(
                  onTap: () => _shareContent("Scan QR code to join our photo sharing album: $_groupLink"),
                  child: Row(
                    children: [
                      const Icon(Icons.share_rounded, color: LuminaTokens.primaryLight, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        "SHARE",
                        style: GoogleFonts.inter(
                          color: LuminaTokens.primaryLight,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),

            // QR Code Image container matching Image 4
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Image.network(
                  qrApiUrl,
                  width: 180,
                  height: 180,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const SizedBox(
                      width: 180,
                      height: 180,
                      child: Center(
                        child: CircularProgressIndicator(color: LuminaTokens.primary),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 180,
                      height: 180,
                      color: Colors.grey.shade200,
                      alignment: Alignment.center,
                      child: const Icon(Icons.qr_code_2_rounded, size: 64, color: Colors.grey),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 36),

            // Divider line matching UI
            Container(
              height: 1,
              color: LuminaTokens.darkBorder.withOpacity(0.3),
            ),
            
            const SizedBox(height: 24),

            // Group Joining Tutorial Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Group Joining Tutorial",
                  style: GoogleFonts.outfit(
                    color: LuminaTokens.primaryLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                GestureDetector(
                  onTap: () => _shareContent("Watch this video to see how to join the photo sharing album: https://youtu.be/demo"),
                  child: Row(
                    children: [
                      const Icon(Icons.share_rounded, color: LuminaTokens.primaryLight, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        "SHARE",
                        style: GoogleFonts.inter(
                          color: LuminaTokens.primaryLight,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Video tutorial card matching Image 4
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: LuminaTokens.darkSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: LuminaTokens.darkBorder.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  // Video Thumbnail Placeholder
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 110,
                          height: 70,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF2E6B9E), Color(0xFF1E4366)],
                            ),
                          ),
                          child: const Icon(Icons.video_collection_rounded, color: Colors.white24, size: 32),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 16),
                      ),
                    ],
                  ),
                  
                  const SizedBox(width: 16),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Group joining demo",
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "1:30 secs",
                          style: GoogleFonts.inter(
                            color: LuminaTokens.darkTextMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildCopyField({
    required String text,
    required IconData icon,
    required VoidCallback onCopy,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: LuminaTokens.darkSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: LuminaTokens.primaryLight.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: LuminaTokens.primaryLight, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onCopy,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: LuminaTokens.darkSurfaceSecondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.copy_all_rounded, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
