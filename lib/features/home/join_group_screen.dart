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

class JoinGroupScreen extends ConsumerStatefulWidget {
  final String? prefilledCode;
  const JoinGroupScreen({super.key, this.prefilledCode});

  @override
  ConsumerState<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends ConsumerState<JoinGroupScreen> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.prefilledCode != null && widget.prefilledCode!.isNotEmpty) {
      _codeController.text = widget.prefilledCode!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _resolveCode(widget.prefilledCode!);
      });
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
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

      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getStringList('recent_albums') ?? [];
      if (!current.contains(album.id)) {
        current.insert(0, album.id);
        await prefs.setStringList('recent_albums', current);
      }

      _showSnackBar("Successfully joined group!", isError: false);
      
      if (mounted) {
        context.pop();
        context.push('/album/${album.id}', extra: code.trim());
      }
    } catch (e) {
      _showSnackBar(e is DioException ? (e.response?.data['detail'] ?? "Group not found") : "Failed to resolve code", isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
                title: const Text("Scan Group QR", style: TextStyle(color: Colors.white)),
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
                            Navigator.pop(context);
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
    return Scaffold(
      backgroundColor: LuminaTokens.darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: LuminaTokens.primaryLight),
          onPressed: () => context.pop(),
        ),
        titleSpacing: 0,
        title: Text(
          "Join a Group",
          style: GoogleFonts.outfit(
            color: LuminaTokens.darkText,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Enter Group Code",
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: LuminaTokens.darkText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Enter the 6-digit sharing code to join the photo album.",
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: LuminaTokens.darkTextMuted,
                  ),
                ),
                
                const SizedBox(height: 48),
                
                TextFormField(
                  controller: _codeController,
                  style: GoogleFonts.outfit(
                    color: LuminaTokens.darkText,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    labelText: "Sharing Code",
                    labelStyle: TextStyle(color: LuminaTokens.darkTextMuted, fontSize: 14),
                    hintText: "evt123",
                    hintStyle: TextStyle(color: LuminaTokens.darkTextMuted, fontSize: 24),
                    prefixIcon: Icon(Icons.vpn_key_rounded, color: LuminaTokens.primaryLight),
                    filled: true,
                    fillColor: LuminaTokens.darkSurface,
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: LuminaTokens.darkBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: LuminaTokens.primaryLight),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Please enter a group sharing code";
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 40),
                
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: LuminaTokens.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                          ),
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
                              : Text(
                                  "Join Group",
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton.filled(
                      onPressed: _showQRScanner,
                      style: IconButton.styleFrom(
                        backgroundColor: LuminaTokens.darkSurface,
                        foregroundColor: LuminaTokens.primaryLight,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: LuminaTokens.darkBorder),
                        ),
                        padding: const EdgeInsets.all(14),
                      ),
                      icon: const Icon(Icons.qr_code_scanner_rounded, size: 24),
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
}
